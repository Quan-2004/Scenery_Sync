import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scenery_sync/utils/avatar_image.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/firebase_service.dart';
import '../services/downloads_service.dart';
import 'downloads_screen.dart';
import 'edit_profile_screen.dart';
import 'my_songs_screen.dart';
import 'my_playlists_screen.dart';
import 'my_favorites_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.background
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withAlpha((0.3 * 255).round()),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 70),
              child: Column(
                children: [
                  const _Header(),
                  const SizedBox(height: 24),
                  const _ProfileCard(),
                  const SizedBox(height: 32),
                  _StatsSection(),
                  const SizedBox(height: 24),
                    const SizedBox(height: 8),
                  const _SettingsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        'profile'.tr(),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard();

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploadingAvatar = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseService>(
      builder: (context, firebaseService, child) {
        if (!firebaseService.isLoggedIn) {
          // Chưa đăng nhập - hiển thị UI khách
          return _buildGuestProfile(context);
        }

        // Đã đăng nhập - hiển thị thông tin user từ Firebase
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.05 * 255).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: _isUploadingAvatar
                      ? null
                      : () => _showChangeAvatarSheet(context),
                  child: Stack(
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(
                                (0.3 * 255).round(),
                              ),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: firebaseService.userPhotoUrl != null
                              ? Image.network(
                                  firebaseService.userPhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/default_avatar.png',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/images/default_avatar.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      if (_isUploadingAvatar)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(
                                (0.45 * 255).round(),
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                height: 28,
                                width: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  firebaseService.userName ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),

                // Email
                Text(
                  firebaseService.userEmail ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted.withAlpha((0.8 * 255).round()),
                  ),
                ),
                const SizedBox(height: 16),

                // Edit Profile Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'edit_profile'.tr(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'guest_user'.tr(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'sign_in_to_save'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                'sign_in'.tr(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    if (_isUploadingAvatar) return;

    final firebaseService = context.read<FirebaseService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final XFile pickedFile;

      // Use image_picker for all platforms
      {
        try {
          pickedFile =
              await _imagePicker.pickImage(
                source: source,
                maxWidth: 900,
                maxHeight: 900,
                imageQuality: 85,
              ) ??
              (throw StateError('No file selected'));
        } on UnimplementedError {
          _showSnack(
            messenger,
            source == ImageSource.camera
                ? 'device_no_camera_short'.tr()
                : 'photo_pick_unsupported'.tr(),
            isError: true,
          );
          return;
        } on StateError {
          return;
        }
      }

      if (!mounted) return;

      setState(() => _isUploadingAvatar = true);

      // Compress on supported platforms; fallback to pure-dart compression on desktop.
      final bytes = await prepareAvatarBytes(pickedFile);

      final error = await firebaseService.uploadAvatar(bytes);

      if (!mounted) return;
      if (error != null) {
        _showSnack(messenger, error, isError: true);
      } else {
        _showSnack(messenger, 'avatar_updated'.tr());
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(messenger, '${'avatar_update_error'.tr()}: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _removeAvatar() async {
    if (_isUploadingAvatar) return;

    final firebaseService = context.read<FirebaseService>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isUploadingAvatar = true);

    try {
      final error = await firebaseService.removeAvatar();

      if (!mounted) return;
      if (error != null) {
        _showSnack(messenger, error, isError: true);
      } else {
        _showSnack(messenger, 'avatar_removed'.tr());
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(messenger, '${'avatar_remove_error'.tr()}: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _showChangeAvatarSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'change_profile_picture'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 24),
              _buildChangeAvatarOption(
                Icons.camera_alt_rounded,
                'take_photo'.tr(),
                () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _buildChangeAvatarOption(
                Icons.photo_library_rounded,
                'choose_from_gallery'.tr(),
                () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
              _buildChangeAvatarOption(
                Icons.delete_outline_rounded,
                'remove_photo'.tr(),
                () {
                  Navigator.pop(sheetContext);
                  _removeAvatar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(
    ScaffoldMessengerState messenger,
    String message, {
    bool isError = false,
  }) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildChangeAvatarOption(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSection extends StatefulWidget {
  @override
  State<_StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<_StatsSection> {
  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MySongsScreen(),
                  ),
                );
              },
              child: ValueListenableBuilder(
                valueListenable: DownloadsService.instance.downloadsListenable(),
                builder: (context, _, __) {
                  final songsCount =
                      DownloadsService.instance.getDownloadedTracks().length;
                  return _StatCard(
                    icon: Icons.download_done_rounded,
                    value: songsCount.toString(),
                    label: 'downloaded_songs'.tr(),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyPlaylistsScreen(),
                  ),
                );
              },
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: firebaseService.getUserPlaylists(),
                builder: (context, snap) => _StatCard(
                  icon: Icons.playlist_play_rounded,
                  value: (snap.data?.length ?? 0).toString(),
                  label: 'playlists'.tr(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyFavoritesScreen(),
                  ),
                );
              },
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: firebaseService.favoritesStream(),
                builder: (context, snap) => _StatCard(
                  icon: Icons.favorite_rounded,
                  value: (snap.data?.length ?? 0).toString(),
                  label: 'favorites'.tr(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatefulWidget {
  const _SettingsSection();

  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _SettingItem(
              icon: Icons.notifications_outlined,
              title: 'notifications'.tr(),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                thumbColor: WidgetStateProperty.all(AppColors.primary),
              ),
            ),
            const Divider(height: 1),
            _SettingItem(
              icon: Icons.download_outlined,
              title: 'downloaded_songs'.tr(),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DownloadsScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _SettingItem(
              icon: Icons.info_outline_rounded,
              title: 'about'.tr(),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showAboutDialog(context);
              },
            ),
            const Divider(height: 1),
            _SettingItem(
              icon: Icons.logout_rounded,
              title: 'logout'.tr(),
              trailing: const Icon(Icons.chevron_right_rounded),
              textColor: Colors.red,
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final Color? textColor;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.trailing,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: textColor ?? AppColors.textMain),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.textMain,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

// Dialog Functions
void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'about_scenery_sync'.tr(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scenery Sync',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'version'.tr(),
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            'music_companion'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            'copyright'.tr(),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('close'.tr()),
        ),
      ],
    ),
  );
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'logout'.tr(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text('logout_confirm'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('logout'.tr()),
        ),
      ],
    ),
  );
}


