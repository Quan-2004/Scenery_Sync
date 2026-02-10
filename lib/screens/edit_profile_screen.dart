import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import '../screens/camera_capture_screen.dart';
import '../utils/avatar_image.dart';
import '../theme/colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  bool _initialized = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final firebaseService = context.read<FirebaseService>();
    if (firebaseService.isLoggedIn) {
      _nameController.text = (firebaseService.userName ?? '').trim();
      _emailController.text = (firebaseService.userEmail ?? '').trim();
      _bioController.text = (firebaseService.userProfile?['bio'] ?? '').toString();
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseService>(
      builder: (context, firebaseService, _) {
        if (!firebaseService.isLoggedIn) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundLight,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                ),
              ),
            ),
            body: const Center(
              child: Text(
                'Bạn cần đăng nhập để chỉnh sửa hồ sơ.',
                style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain),
              onPressed: _isSaving ? null : () => Navigator.pop(context),
            ),
            title: const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Picture
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha((0.3 * 255).round()),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: firebaseService.userPhotoUrl != null
                            ? Image.network(
                                firebaseService.userPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar(firebaseService.userName);
                                },
                              )
                            : _buildDefaultAvatar(firebaseService.userName),
                      ),
                    ),
                    if (_isUploadingAvatar)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((0.45 * 255).round()),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              height: 28,
                              width: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: (_isUploadingAvatar || _isSaving)
                            ? null
                            : () => _showChangeAvatarSheet(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Name Field
                _buildTextField(
                  controller: _nameController,
                  label: 'Display Name',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 16),
                // Email Field (readonly)
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: false,
                ),
                const SizedBox(height: 16),
                // Bio Field
                _buildTextField(
                  controller: _bioController,
                  label: 'Bio',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                // Additional Options (giữ nguyên)
                _buildOptionTile(
                  'Change Password',
                  Icons.lock_outline_rounded,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password coming soon!')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  'Privacy Settings',
                  Icons.shield_outlined,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy settings coming soon!')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  'Connected Accounts',
                  Icons.link_rounded,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connected accounts coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted.withAlpha((0.5 * 255).round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String? name) {
    final initials = (name ?? 'U').trim().isNotEmpty
        ? (name ?? 'U').trim().split(RegExp(r'\s+')).take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase()
        : 'U';

    return Container(
      color: AppColors.primary.withAlpha((0.15 * 255).round()),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'U' : initials,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final firebaseService = context.read<FirebaseService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final bio = _bioController.text.trim();

      final error = await firebaseService.updateUserProfile({
        'name': name,
        'bio': bio,
      });

      if (!mounted) return;

      if (error != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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

  Widget _buildChangeAvatarOption(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: (_isUploadingAvatar || _isSaving) ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    if (_isUploadingAvatar || _isSaving) return;

    final firebaseService = context.read<FirebaseService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final XFile pickedFile;

      // On Windows, `image_picker` camera is often unsupported.
      if (source == ImageSource.camera && defaultTargetPlatform == TargetPlatform.windows) {
        final captured = await Navigator.of(context).push<XFile>(
          MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
        );
        if (captured == null) return;
        pickedFile = captured;
      } else {
        try {
          pickedFile = await _imagePicker.pickImage(
                source: source,
                maxWidth: 900,
                maxHeight: 900,
                imageQuality: 85,
              ) ??
              (throw StateError('No file selected'));
        } on UnimplementedError {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                source == ImageSource.camera
                    ? 'Thiết bị này không hỗ trợ chụp ảnh'
                    : 'Tính năng chọn ảnh không được hỗ trợ',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        } on StateError {
          return;
        }
      }

      if (!mounted) return;

      setState(() => _isUploadingAvatar = true);

      final bytes = await prepareAvatarBytes(pickedFile);

      final error = await firebaseService.uploadAvatar(bytes);

      if (!mounted) return;
      if (error != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Ảnh đại diện đã được cập nhật'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể cập nhật ảnh: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _removeAvatar() async {
    if (_isUploadingAvatar || _isSaving) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final firebaseService = context.read<FirebaseService>();
      final error = await firebaseService.removeAvatar();

      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xoá ảnh đại diện'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xoá ảnh: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }
}
