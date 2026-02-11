import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
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
  final _phoneController = TextEditingController();

  String? _gender;
  DateTime? _birthday;

  bool _initialized = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final firebaseService = context.read<FirebaseService>();
    if (firebaseService.isLoggedIn) {
      final user = firebaseService.currentUser;
      final profile = firebaseService.userProfile;

      _nameController.text = (user?.displayName ?? '').trim();
      _emailController.text = (user?.email ?? '').trim();

      if (profile != null) {
        if (profile.containsKey('bio'))
          _bioController.text = profile['bio'] ?? '';
        if (profile.containsKey('phone'))
          _phoneController.text = profile['phone'] ?? '';
        if (profile.containsKey('gender')) _gender = profile['gender'];
        if (profile.containsKey('birthday')) {
          final timestamp = profile['birthday'];
          if (timestamp is Timestamp) {
            _birthday = timestamp.toDate();
          } else if (timestamp is String) {
            _birthday = DateTime.tryParse(timestamp);
          }
        }
      }
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
            // ignore: deprecated_member_use
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthday) {
      setState(() {
        _birthday = picked;
      });
    }
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
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textMain,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(
              child: Text(
                'Bạn cần đăng nhập để chỉnh sửa hồ sơ.',
                style: TextStyle(color: AppColors.textMain),
              ),
            ),
          );
        }

        final user = firebaseService.currentUser;
        final photoUrl = user?.photoURL;

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: const Text(
              'Edit Profile',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withAlpha(
                              (0.2 * 255).round(),
                            ),
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: _isUploadingAvatar
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : (photoUrl != null && photoUrl.isNotEmpty)
                                  ? Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Image.asset(
                                            'assets/images/default_avatar.png',
                                            fit: BoxFit.cover,
                                          ),
                                    )
                                  : Image.asset(
                                      'assets/images/default_avatar.png',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: (_isUploadingAvatar || _isSaving)
                            ? null
                            : () => _showChangeAvatarSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
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

                  // Fields
                  _buildTextField(
                    controller: _nameController,
                    label: 'Display Name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Gender
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.people_outline,
                            color: AppColors.primary,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ['Male', 'Female', 'Other']
                            .map(
                              (label) => DropdownMenuItem(
                                value: label,
                                child: Text(label),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _gender = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Birthday
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: TextEditingController(
                          text: _birthday != null
                              ? "${_birthday!.day}/${_birthday!.month}/${_birthday!.year}"
                              : "",
                        ),
                        label: 'Birthday',
                        icon: Icons.cake_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _bioController,
                    label: 'Bio',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Options
                  _buildOptionTile(
                    'Change Password',
                    Icons.lock_outline_rounded,
                    () => _showChangePasswordDialog(context),
                  ),
                  const SizedBox(height: 12),
                  _buildOptionTile(
                    'Privacy Settings',
                    Icons.shield_outlined,
                    () => _showPrivacySettingsBottomSheet(context),
                  ),
                  const SizedBox(height: 12),
                  _buildOptionTile(
                    'Connected Accounts',
                    Icons.link_rounded,
                    () => _showConnectedAccountsBottomSheet(context),
                  ),
                ],
              ),
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

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final firebaseService = context.read<FirebaseService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final bio = _bioController.text.trim();
      final phone = _phoneController.text.trim();

      final error = await firebaseService.updateUserProfile({
        'name': name,
        'bio': bio,
        'phone': phone,
        'gender': _gender,
        'birthday': _birthday,
      });

      if (!mounted) return;

      if (error != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) navigator.pop();
      }
    } catch (e) {
      if (mounted)
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  Widget _buildChangeAvatarOption(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
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
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

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
      if (mounted)
        messenger.showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xoá ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    if (!firebaseService.linkedProviders.contains('password')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are logged in via a social account. Please manage your password there.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPassController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: newPassController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                    ),
                    validator: (v) =>
                        (v?.length ?? 0) < 6 ? 'Min 6 chars' : null,
                  ),
                  TextFormField(
                    controller: confirmPassController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                    ),
                    validator: (v) => v != newPassController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isUpdating = true);
                          final error = await firebaseService.changePassword(
                            currentPassword: currentPassController.text,
                            newPassword: newPassController.text,
                          );
                          if (!mounted) return;

                          if (error == null) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            setDialogState(() => isUpdating = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPrivacySettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Public Profile'),
              subtitle: const Text('Allow others to see your profile'),
              value: true,
              onChanged: (val) {},
            ),
            SwitchListTile(
              title: const Text('Show Email'),
              subtitle: const Text('Display your email on your profile'),
              value: false,
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectedAccountsBottomSheet(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    final providers = firebaseService.linkedProviders;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connected Accounts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildProviderTile(
              Icons.email,
              'Email/Password',
              providers.contains('password'),
            ),
            _buildProviderTile(
              Icons.g_mobiledata,
              'Google',
              providers.contains('google.com'),
            ),
            _buildProviderTile(
              Icons.facebook,
              'Facebook',
              providers.contains('facebook.com'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTile(IconData icon, String name, bool isConnected) {
    return ListTile(
      leading: Icon(icon, color: isConnected ? AppColors.primary : Colors.grey),
      title: Text(name),
      trailing: isConnected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Text('Not Linked', style: TextStyle(color: Colors.grey)),
    );
  }
}
