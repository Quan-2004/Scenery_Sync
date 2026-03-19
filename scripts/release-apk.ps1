param(
    [ValidateSet("major", "minor", "patch")]
    [string]$Bump = "minor",
    [string]$Version,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

function Parse-VersionLine {
    param([string]$line)

    $match = [regex]::Match($line, '^\s*version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$')
    if (-not $match.Success) {
        throw "Khong doc duoc dong version trong pubspec.yaml. Dinh dang can la: version: x.y.z+n"
    }

    return [pscustomobject]@{
        Major = [int]$match.Groups[1].Value
        Minor = [int]$match.Groups[2].Value
        Patch = [int]$match.Groups[3].Value
        Build = [int]$match.Groups[4].Value
    }
}

function New-Version {
    param(
        [pscustomobject]$current,
        [string]$bump,
        [string]$versionOverride
    )

    $major = $current.Major
    $minor = $current.Minor
    $patch = $current.Patch

    if ($versionOverride) {
        $overrideMatch = [regex]::Match($versionOverride, '^(\d+)\.(\d+)\.(\d+)$')
        if (-not $overrideMatch.Success) {
            throw "Tham so -Version phai co dinh dang x.y.z, vi du: 1.1.0"
        }

        $major = [int]$overrideMatch.Groups[1].Value
        $minor = [int]$overrideMatch.Groups[2].Value
        $patch = [int]$overrideMatch.Groups[3].Value
    }
    else {
        switch ($bump) {
            "major" {
                $major += 1
                $minor = 0
                $patch = 0
            }
            "minor" {
                $minor += 1
                $patch = 0
            }
            "patch" {
                $patch += 1
            }
        }
    }

    $build = $current.Build + 1

    return [pscustomobject]@{
        Major = $major
        Minor = $minor
        Patch = $patch
        Build = $build
        BuildName = "$major.$minor.$patch"
        FullVersion = "$major.$minor.$patch+$build"
        DisplayVersion = "$major.$minor"
        VersionTag = "$major.$minor.$patch-build$build"
    }
}

$workspace = Split-Path -Parent $PSScriptRoot
Set-Location $workspace

$pubspecPath = Join-Path $workspace "pubspec.yaml"
$pubspec = Get-Content -Raw -Path $pubspecPath

$versionLineMatch = [regex]::Match($pubspec, '(?m)^\s*version:\s*\d+\.\d+\.\d+\+\d+\s*$')
if (-not $versionLineMatch.Success) {
    throw "Khong tim thay dong version trong pubspec.yaml"
}

$current = Parse-VersionLine -line $versionLineMatch.Value
$next = New-Version -current $current -bump $Bump -versionOverride $Version

$updatedPubspec = [regex]::Replace(
    $pubspec,
    '(?m)^\s*version:\s*\d+\.\d+\.\d+\+\d+\s*$',
    "version: $($next.FullVersion)",
    1
)

Set-Content -Path $pubspecPath -Value $updatedPubspec -NoNewline
Write-Host "Da cap nhat pubspec version: $($next.FullVersion)"

if (-not $SkipBuild) {
    Write-Host "Dang build APK release..."
    & flutter build apk --release --dart-define-from-file=.env.local.json --dart-define=CLOUDINARY_CLOUD_NAME=dvcebine7 --dart-define=CLOUDINARY_UPLOAD_PRESET=scenery_upload
}

$apkSource = Join-Path $workspace "build/app/outputs/flutter-apk/app-release.apk"
if (-not (Test-Path $apkSource)) {
    $apkSource = Join-Path $workspace "build/app/outputs/apk/release/app-release.apk"
}
if (-not (Test-Path $apkSource)) {
    throw "Khong tim thay app-release.apk sau khi build"
}

$webDir = Join-Path $workspace "web"
$apkLatest = Join-Path $webDir "scenery_sync.apk"
$apkVersioned = Join-Path $webDir "scenery_sync-v$($next.VersionTag).apk"

Copy-Item -Path $apkSource -Destination $apkLatest -Force
Copy-Item -Path $apkSource -Destination $apkVersioned -Force

$apkInfo = Get-Item $apkLatest
$sizeMB = [math]::Round($apkInfo.Length / 1MB, 1)

$releaseInfo = [ordered]@{
    version = $next.BuildName
    displayVersion = $next.DisplayVersion
    buildNumber = $next.Build
    apkFile = "scenery_sync.apk"
    versionedApkFile = (Split-Path $apkVersioned -Leaf)
    sizeMB = "$sizeMB"
    androidMin = "8.0+"
    updatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
}

$releaseJsonPath = Join-Path $webDir "latest-release.json"
($releaseInfo | ConvertTo-Json -Depth 5) | Set-Content -Path $releaseJsonPath

Write-Host "Hoan tat phat hanh APK"
Write-Host "- Version: $($next.FullVersion)"
Write-Host "- APK latest: $apkLatest"
Write-Host "- APK versioned: $apkVersioned"
Write-Host "- Metadata: $releaseJsonPath"
