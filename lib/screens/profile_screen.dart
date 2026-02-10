import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scenery_sync/utils/avatar_image.dart';
import 'package:scenery_sync/screens/camera_capture_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/colors.dart';
import '../services/app_language.dart';
import '../services/firebase_service.dart';
import '../services/cloudinary_service.dart';
import 'settings_screen.dart';
import 'downloads_screen.dart';
import 'chat_bot_screen.dart';
import 'help_support_screen.dart';
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
  final AppLanguage _appLanguage = AppLanguage();

  @override
  void initState() {
    super.initState();
    _appLanguage.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _appLanguage.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

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
                  const _UploadMusicSection(),
                  const SizedBox(height: 32),
                  _StatsSection(),
                  const SizedBox(height: 32),
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
  final AppLanguage _appLanguage = AppLanguage();

  @override
  void initState() {
    super.initState();
    _appLanguage.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _appLanguage.translate('profile'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textMain,
              size: 28,
            ),
          ),
        ],
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
  final AppLanguage _appLanguage = AppLanguage();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _appLanguage.addListener(() => setState(() {}));
  }

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
                                    return _buildDefaultAvatar(
                                      firebaseService.userName,
                                    );
                                  },
                                )
                              : _buildDefaultAvatar(firebaseService.userName),
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

                // Edit Profile & Logout Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => _handleLogout(context, firebaseService),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar(String? name) {
    final initial = (name?.isNotEmpty == true) ? name![0].toUpperCase() : '?';
    return Container(
      color: AppColors.primary.withAlpha((0.2 * 255).round()),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
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
            Container(
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
            const SizedBox(height: 16),
            const Text(
              'Guest User',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in to save your music',
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
              child: const Text(
                'Sign In',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

      // On Windows, `image_picker` camera is often unsupported.
      if (source == ImageSource.camera &&
          defaultTargetPlatform == TargetPlatform.windows) {
        final captured = await Navigator.of(context).push<XFile>(
          MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
        );
        if (captured == null) return;
        pickedFile = captured;
      } else {
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
                ? 'Thiết bị này không hỗ trợ chụp ảnh'
                : 'Tính năng chọn ảnh không được hỗ trợ',
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
        _showSnack(messenger, 'Ảnh đại diện đã được cập nhật');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(messenger, 'Không thể cập nhật ảnh: $e', isError: true);
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
        _showSnack(messenger, 'Đã xoá ảnh đại diện');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(messenger, 'Không thể xoá ảnh: $e', isError: true);
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
              const Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 24),
              _buildChangeAvatarOption(
                Icons.camera_alt_rounded,
                'Take Photo',
                () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _buildChangeAvatarOption(
                Icons.photo_library_rounded,
                'Choose from Gallery',
                () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
              _buildChangeAvatarOption(
                Icons.delete_outline_rounded,
                'Remove Photo',
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

  void _handleLogout(
    BuildContext context,
    FirebaseService firebaseService,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await firebaseService.logout();
      if (context.mounted) {
        // Clear all routes and go back to login screen
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
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
  final AppLanguage _appLanguage = AppLanguage();

  @override
  void initState() {
    super.initState();
    _appLanguage.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
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
              child: _StatCard(
                icon: Icons.music_note_rounded,
                value: '142',
                label: _appLanguage.translate('songs'),
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
              child: _StatCard(
                icon: Icons.playlist_play_rounded,
                value: '23',
                label: _appLanguage.translate('playlists'),
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
              child: _StatCard(
                icon: Icons.favorite_rounded,
                value: '89',
                label: _appLanguage.translate('favorites'),
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
  final AppLanguage _appLanguage = AppLanguage();

  @override
  void initState() {
    super.initState();
    _appLanguage.addListener(() => setState(() {}));
  }

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
              title: _appLanguage.translate('notifications'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                thumbColor: WidgetStateProperty.all(AppColors.primary),
              ),
            ),
            const Divider(height: 1),
            _SettingItem(
              icon: Icons.download_outlined,
              title: _appLanguage.translate('downloaded_songs'),
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
              icon: Icons.data_usage_rounded,
              title: _appLanguage.translate('data_usage'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showDataUsageDialog(context);
              },
            ),
            const Divider(height: 1),
            _SettingItem(
              icon: Icons.dark_mode_outlined,
              title: _appLanguage.translate('dark_mode'),
              trailing: Switch(
                value: false,
                onChanged: (value) {},
                thumbColor: WidgetStateProperty.all(AppColors.primary),
              ),
            ),
            const Divider(height: 1),
            _SettingItem(
              icon: Icons.language_rounded,
              title: _appLanguage.translate('language'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showLanguageDialog(context, () {
                  setState(() {}); // Refresh UI when language changes
                });
              },
            ),
            const Divider(height: 1),
            _SettingItem(
              icon: Icons.smart_toy_rounded,
              title: _appLanguage.translate('ai_assistant'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatBotScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _SettingItem(
              icon: Icons.help_outline_rounded,
              title: _appLanguage.translate('help_support'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _SettingItem(
              icon: Icons.info_outline_rounded,
              title: _appLanguage.translate('about'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showAboutDialog(context);
              },
            ),
            const Divider(height: 1),
            _SettingItem(
              icon: Icons.logout_rounded,
              title: _appLanguage.translate('logout'),
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
void _showDataUsageDialog(BuildContext context) {
  final AppLanguage appLanguage = AppLanguage();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        appLanguage.translate('data_usage'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DataUsageItem(
            appLanguage.translate('streaming'),
            '2.4 GB',
            Icons.wifi_rounded,
          ),
          const SizedBox(height: 12),
          _DataUsageItem(
            appLanguage.translate('downloads'),
            '1.8 GB',
            Icons.download_rounded,
          ),
          const SizedBox(height: 12),
          _DataUsageItem(
            appLanguage.translate('cache'),
            '456 MB',
            Icons.cached_rounded,
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appLanguage.translate('total_usage'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                '4.7 GB',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(appLanguage.translate('close')),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(appLanguage.translate('cache_cleared'))),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(appLanguage.translate('clear_cache')),
        ),
      ],
    ),
  );
}

void _showLanguageDialog(BuildContext context, Function() onLanguageChanged) {
  final AppLanguage appLanguage = AppLanguage();
  final languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
  ];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            appLanguage.translate('select_language'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: languages.map((language) {
                final isSelected =
                    appLanguage.currentLanguage == language['code'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withAlpha((0.1 * 255).round())
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.withAlpha((0.3 * 255).round()),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Text(
                      language['flag'] as String,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      language['name'] as String,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMain,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      // Thay đổi ngôn ngữ
                      appLanguage.setLanguage(language['code'] as String);
                      onLanguageChanged();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${appLanguage.translate('language_changed')} ${language['name']}',
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLanguage.translate('cancel')),
            ),
          ],
        );
      },
    ),
  );
}

void _showAboutDialog(BuildContext context) {
  final AppLanguage appLanguage = AppLanguage();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        appLanguage.translate('about_scenery_sync'),
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
            appLanguage.translate('version'),
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            appLanguage.translate('music_companion'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            appLanguage.translate('copyright'),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(appLanguage.translate('close')),
        ),
      ],
    ),
  );
}

void _showLogoutDialog(BuildContext context) {
  final AppLanguage appLanguage = AppLanguage();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        appLanguage.translate('logout'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text(appLanguage.translate('logout_confirm')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(appLanguage.translate('cancel')),
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
          child: Text(appLanguage.translate('logout')),
        ),
      ],
    ),
  );
}

class _DataUsageItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DataUsageItem(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }
}

// Upload Music Section (Admin only)
class _UploadMusicSection extends StatefulWidget {
  const _UploadMusicSection();

  @override
  State<_UploadMusicSection> createState() => _UploadMusicSectionState();
}

class _UploadMusicSectionState extends State<_UploadMusicSection> {
  bool _uploading = false;

  bool _isAdmin(BuildContext context) {
    final firebase = Provider.of<FirebaseService>(context, listen: false);
    final profile = firebase.userProfile;
    return profile is Map<String, dynamic> && profile['isAdmin'] == true;
  }

  Future<void> _uploadAudioToCloudinary() async {
    if (_uploading) return;

    if (!_isAdmin(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ Admin mới được upload nhạc.')),
      );
      return;
    }

    // Show dialog to get track info and files
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _UploadTrackDialog(),
    );

    if (result == null) return;

    setState(() => _uploading = true);
    try {
      final cloudinary = const CloudinaryService();

      final name = result['name'] as String;
      final artistName = result['artistName'] as String;
      final albumName = result['albumName'] as String;
      final hasImage = result['hasImage'] == 'true';
      final imageBytes = result['imageBytes'] as Uint8List?;
      final audioBytes = result['audioBytes'] as Uint8List?;
      final audioName = result['audioName'] as String;

      if (audioBytes == null) {
        throw StateError('Không có dữ liệu file nhạc');
      }

      // Step 1: Upload cover image (if selected)
      String imageUrl = '';
      if (hasImage && imageBytes != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang upload ảnh bìa...'),
              duration: Duration(seconds: 30),
            ),
          );
        }

        final imageUploaded = await cloudinary.uploadTrackCover(
          bytes: imageBytes,
          publicId: 'track_${DateTime.now().millisecondsSinceEpoch}',
        );
        imageUrl = imageUploaded.secureUrl;
      }

      // Step 2: Upload audio file
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang upload file nhạc...'),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Upload audio to Cloudinary
      final audioUploaded = await cloudinary.uploadAudio(
        bytes: audioBytes,
        filename: audioName,
      );

      // Save to Firestore
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang lưu vào Firebase...'),
            duration: Duration(seconds: 30),
          ),
        );
      }

      await FirebaseFirestore.instance.collection('tracks').add({
        'name': name,
        'artistName': artistName,
        'albumName': albumName,
        'imageUrl': imageUrl,
        'previewUrl': audioUploaded.secureUrl,
        'cloudinaryPublicId': audioUploaded.publicId,
        'durationMs': 0,
        'popularity': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Upload thành công! Bài hát hiện ở trang chủ.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload thất bại: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin(context);
    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.secondary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Nhạc',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Chia sẻ nhạc lên trang chủ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _uploading ? null : _uploadAudioToCloudinary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(_uploading ? 'Đang upload...' : 'Thêm bài hát'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const _ManageTracksScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Xóa nhạc'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog for uploading track with info
class _UploadTrackDialog extends StatefulWidget {
  const _UploadTrackDialog();

  @override
  State<_UploadTrackDialog> createState() => _UploadTrackDialogState();
}

class _UploadTrackDialogState extends State<_UploadTrackDialog> {
  final _nameController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  String? _selectedImageName;
  String? _selectedAudioName;
  Uint8List? _imageBytes;
  Uint8List? _audioBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImageName = result.files.single.name;
        _imageBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav'],
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedAudioName = result.files.single.name;
        _audioBytes = result.files.single.bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Thông tin bài hát',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên bài hát
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên bài hát *',
                  hintText: 'Nhập tên bài hát',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nghệ sĩ
              TextField(
                controller: _artistController,
                decoration: InputDecoration(
                  labelText: 'Nghệ sĩ',
                  hintText: 'Nhập tên nghệ sĩ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Album
              TextField(
                controller: _albumController,
                decoration: InputDecoration(
                  labelText: 'Album (tùy chọn)',
                  hintText: 'Nhập tên album',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Divider
              const Divider(),
              const SizedBox(height: 16),

              // Chọn ảnh bìa
              const Text(
                '1. Chọn ảnh bìa (tùy chọn)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _selectedImageName != null
                        ? AppColors.primary
                        : AppColors.textMuted,
                    width: 2,
                  ),
                  backgroundColor: _selectedImageName != null
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
                icon: Icon(
                  _selectedImageName != null
                      ? Icons.check_circle
                      : Icons.image_outlined,
                  color: _selectedImageName != null
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    _selectedImageName ?? 'Chọn ảnh JPG/PNG',
                    style: TextStyle(
                      color: _selectedImageName != null
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontWeight: _selectedImageName != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Chọn file nhạc
              const Text(
                '2. Chọn file nhạc *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickAudio,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _selectedAudioName != null
                        ? AppColors.primary
                        : AppColors.textMuted,
                    width: 2,
                  ),
                  backgroundColor: _selectedAudioName != null
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
                icon: Icon(
                  _selectedAudioName != null
                      ? Icons.check_circle
                      : Icons.audio_file_outlined,
                  color: _selectedAudioName != null
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    _selectedAudioName ?? 'Chọn file MP3/M4A/WAV',
                    style: TextStyle(
                      color: _selectedAudioName != null
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontWeight: _selectedAudioName != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Hủy',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final artist = _artistController.text.trim();
            final album = _albumController.text.trim();

            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập tên bài hát')),
              );
              return;
            }

            if (_selectedAudioName == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng chọn file nhạc')),
              );
              return;
            }

            Navigator.pop(context, {
              'name': name,
              'artistName': artist.isEmpty ? 'Unknown Artist' : artist,
              'albumName': album,
              'hasImage': _selectedImageName != null ? 'true' : 'false',
              'imageName': _selectedImageName ?? '',
              'audioName': _selectedAudioName ?? '',
              'imageBytes': _imageBytes,
              'audioBytes': _audioBytes,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Tiếp tục'),
        ),
      ],
    );
  }
}

// Screen to manage (delete) uploaded tracks
class _ManageTracksScreen extends StatefulWidget {
  const _ManageTracksScreen();

  @override
  State<_ManageTracksScreen> createState() => _ManageTracksScreenState();
}

class _ManageTracksScreenState extends State<_ManageTracksScreen> {
  Future<void> _deleteTrack(String trackId, String trackName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Xóa bài hát?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa "$trackName"?\nHành động này không thể hoàn tác.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang xóa bài hát...'),
          duration: Duration(seconds: 2),
        ),
      );

      await FirebaseFirestore.instance
          .collection('tracks')
          .doc(trackId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "$trackName"'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quản lý nhạc',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('tracks')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Lỗi: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off_rounded,
                    size: 80,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có bài hát nào',
                    style: TextStyle(fontSize: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final trackId = doc.id;
              final name = data['name'] ?? 'Unknown';
              final artist = data['artistName'] ?? 'Unknown Artist';
              final imageUrl = data['imageUrl'] ?? '';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              height: 56,
                              width: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 56,
                                  width: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.music_note_rounded,
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 56,
                              width: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            artist,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded),
                      color: Colors.red,
                      onPressed: () => _deleteTrack(trackId, name),
                      tooltip: 'Xóa bài hát',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
