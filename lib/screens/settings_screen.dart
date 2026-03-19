import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../services/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _newReleasesNotif = true;
  bool _playlistUpdatesNotif = true;
  bool _artistUpdatesNotif = true;
  bool _autoDownload = false;
  String _audioQuality = 'High';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _newReleasesNotif = prefs.getBool('new_releases_notif') ?? true;
      _playlistUpdatesNotif = prefs.getBool('playlist_updates_notif') ?? true;
      _artistUpdatesNotif = prefs.getBool('artist_updates_notif') ?? true;
      _autoDownload = prefs.getBool('auto_download') ?? false;
      _audioQuality = prefs.getString('audio_quality') ?? 'High';
    });
  }

  Future<void> _saveNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'settings'.tr(),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 64, bottom: 16),
              ),
            ),

            // Settings Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Appearance Section
                  _buildSectionTitle('appearance'.tr()),
                  const SizedBox(height: 12),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return _buildSettingCard(
                        icon: Icons.dark_mode_rounded,
                          title: 'dark_mode'.tr(),
                          subtitle: 'toggle_dark_theme'.tr(),
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) async {
                            await themeProvider.setTheme(value);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  themeProvider.isDarkMode
                                      ? 'dark_mode_activated'.tr()
                                      : 'light_mode_active'.tr(),
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          thumbColor: WidgetStateProperty.resolveWith<Color>((
                            Set<WidgetState> states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.primary;
                            }
                            return Colors.white;
                          }),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.language_rounded,
                    title: 'language'.tr(),
                    subtitle: context.locale.languageCode == 'vi'
                        ? 'Tiếng Việt'
                        : 'English',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showLanguageDialog(),
                  ),

                  const SizedBox(height: 32),

                  // Audio Section
                  _buildSectionTitle('audio'.tr()),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.high_quality_rounded,
                    title: 'audio_quality'.tr(),
                    subtitle: _audioQuality,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showQualityDialog(),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.equalizer_rounded,
                    title: 'equalizer'.tr(),
                    subtitle: 'customize_sound'.tr(),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to equalizer
                    },
                  ),

                  const SizedBox(height: 32),

                  // Download Section
                  _buildSectionTitle('downloads'.tr()),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.download_rounded,
                    title: 'auto_download'.tr(),
                    subtitle: 'download_liked_auto'.tr(),
                    trailing: Switch(
                      value: _autoDownload,
                      onChanged: (value) {
                        setState(() => _autoDownload = value);
                      },
                      thumbColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primary;
                        }
                        return Colors.white;
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.storage_rounded,
                    title: 'storage'.tr(),
                    subtitle: '2.4 GB used',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to storage management
                    },
                  ),

                  const SizedBox(height: 32),

                  // Notifications Section
                  _buildSectionTitle('notifications'.tr()),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.notifications_rounded,
                    title: 'push_notifications'.tr(),
                    subtitle: 'enable_disable_notifications'.tr(),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        _saveNotificationSetting(
                          'notifications_enabled',
                          value,
                        );
                      },
                      thumbColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primary;
                        }
                        return Colors.white;
                      }),
                    ),
                  ),
                  if (_notificationsEnabled) ...[
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      icon: Icons.new_releases_rounded,
                      title: 'new_releases'.tr(),
                      subtitle: 'notify_new_releases'.tr(),
                      trailing: Switch(
                        value: _newReleasesNotif,
                        onChanged: (value) {
                          setState(() => _newReleasesNotif = value);
                          _saveNotificationSetting('new_releases_notif', value);
                        },
                        thumbColor: WidgetStateProperty.resolveWith<Color>((
                          Set<WidgetState> states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          return Colors.white;
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      icon: Icons.playlist_play_rounded,
                      title: 'playlist_updates'.tr(),
                      subtitle: 'notify_playlist'.tr(),
                      trailing: Switch(
                        value: _playlistUpdatesNotif,
                        onChanged: (value) {
                          setState(() => _playlistUpdatesNotif = value);
                          _saveNotificationSetting(
                            'playlist_updates_notif',
                            value,
                          );
                        },
                        thumbColor: WidgetStateProperty.resolveWith<Color>((
                          Set<WidgetState> states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          return Colors.white;
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      icon: Icons.person_rounded,
                      title: 'artist_updates'.tr(),
                      subtitle: 'notify_artist'.tr(),
                      trailing: Switch(
                        value: _artistUpdatesNotif,
                        onChanged: (value) {
                          setState(() => _artistUpdatesNotif = value);
                          _saveNotificationSetting(
                            'artist_updates_notif',
                            value,
                          );
                        },
                        thumbColor: WidgetStateProperty.resolveWith<Color>((
                          Set<WidgetState> states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          return Colors.white;
                        }),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // About Section
                  _buildSectionTitle('about'.tr()),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.info_rounded,
                    title: 'app_version'.tr(),
                    subtitle: '1.0.0 (Build 100)',
                    trailing: const SizedBox(),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.code_rounded,
                    title: 'developer'.tr(),
                    subtitle: 'Scenery Sync Team © 2024',
                    trailing: const SizedBox(),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.update_rounded,
                    title: 'last_updated'.tr(),
                    subtitle: 'December 29, 2024',
                    trailing: const SizedBox(),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.library_books_rounded,
                    title: 'open_source_licenses'.tr(),
                    subtitle: 'view_third_party_licenses'.tr(),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showLicensesDialog();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.policy_rounded,
                    title: 'privacy_policy'.tr(),
                    subtitle: 'read_privacy_policy'.tr(),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('opening_privacy_policy'.tr()),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.description_rounded,
                    title: 'terms_of_service'.tr(),
                    subtitle: 'read_terms'.tr(),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('opening_terms'.tr()),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _showLogoutDialog();
                        },
                        child: Center(
                          child: Text(
                            'logout'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = [
      {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'select_language'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: languages.map((language) {
                  final isSelected =
                      ctx.locale.languageCode == language['code'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.withValues(alpha: 0.3),
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
                        ctx.setLocale(Locale(language['code'] as String));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${'language_changed'.tr()} ${language['name']}',
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
          );
        },
      ),
    );
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('audio_quality'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQualityOption('Low', 'audio_quality_low'.tr(), '96 kbps'),
            _buildQualityOption('Medium', 'audio_quality_medium'.tr(), '160 kbps'),
            _buildQualityOption('High', 'audio_quality_high'.tr(), '320 kbps'),
            _buildQualityOption('Lossless', 'audio_quality_lossless'.tr(), 'FLAC'),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityOption(String quality, String label, String bitrate) {
    return RadioListTile<String>(
      value: quality,
      groupValue: _audioQuality,
      onChanged: (value) {
        setState(() => _audioQuality = value!);
        Navigator.pop(context);
      },
      title: Text(label),
      subtitle: Text(bitrate, style: const TextStyle(fontSize: 12)),
      activeColor: AppColors.primary,
    );
  }

  void _showLicensesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'open_source_licenses'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: const [
              _LicenseItem(name: 'Flutter', license: 'BSD 3-Clause'),
              _LicenseItem(name: 'Provider', license: 'MIT'),
              _LicenseItem(name: 'HTTP', license: 'BSD 3-Clause'),
              _LicenseItem(name: 'Shared Preferences', license: 'BSD 3-Clause'),
              _LicenseItem(name: 'Audio Players', license: 'MIT'),
              _LicenseItem(name: 'Cached Network Image', license: 'MIT'),
            ],
          ),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('logout'.tr()),
        content: Text('logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: Text('logout'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _LicenseItem extends StatelessWidget {
  final String name;
  final String license;

  const _LicenseItem({required this.name, required this.license});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              license,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
