param(
    [ValidateSet("major", "minor", "patch")]
    [string]$Bump = "patch",
    [string]$PubspecPath = "pubspec.yaml"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $PubspecPath)) {
    throw "Khong tim thay pubspec.yaml tai: $PubspecPath"
}

$content = Get-Content -Raw -Path $PubspecPath
$pattern = '(?m)^\s*version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$'
$match = [regex]::Match($content, $pattern)

if (-not $match.Success) {
    throw "Khong doc duoc dong version trong pubspec.yaml"
}

$major = [int]$match.Groups[1].Value
$minor = [int]$match.Groups[2].Value
$patch = [int]$match.Groups[3].Value
$build = [int]$match.Groups[4].Value

switch ($Bump) {
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

$build += 1
$newVersion = "$major.$minor.$patch+$build"
$newLine = "version: $newVersion"

$updated = [regex]::Replace($content, $pattern, $newLine, 1)
Set-Content -Path $PubspecPath -Value $updated -NoNewline

Write-Output $newVersion
