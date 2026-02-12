import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import '../theme/colors.dart';
import 'chat_bot_screen.dart';

class SceneryCameraScreen extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onClose;

  const SceneryCameraScreen({super.key, this.isActive = false, this.onClose});

  @override
  State<SceneryCameraScreen> createState() => _SceneryCameraScreenState();
}

class _SceneryCameraScreenState extends State<SceneryCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  int _selectedModeIndex = 1; // AI Photo
  FlashMode _flashMode = FlashMode.off;
  bool _isCapturing = false;
  String? _lastImagePath;

  // Settings
  bool _showGrid = false;
  int _timerDuration = 0; // 0, 3, or 10 seconds

  // Filters
  int _selectedFilterIndex = 0; // 0 = Original
  bool _showFilterSelector = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _initializeCamera();
      _loadLastImage();
    }
  }

  @override
  void didUpdateWidget(SceneryCameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _initializeCamera();
        _loadLastImage();
      } else {
        _disposeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![_selectedCameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        await _cameraController!.setFlashMode(_flashMode);
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _loadLastImage() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth) {
        final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          onlyAll: true,
        );
        if (albums.isNotEmpty) {
          final List<AssetEntity> recentAssets = await albums[0].getAssetListRange(
            start: 0,
            end: 1,
          );
          if (recentAssets.isNotEmpty) {
            final file = await recentAssets[0].file;
            if (mounted && file != null) {
              setState(() {
                _lastImagePath = file.path;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading last image: $e');
    }
  }

  void _disposeCamera({bool fromDispose = false}) {
    _cameraController?.dispose();
    _cameraController = null;
    if (mounted && !fromDispose) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _disposeCamera(fromDispose: true);
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.torch; // Always On
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
      default:
        newMode = FlashMode.off;
    }

    try {
      await _cameraController!.setFlashMode(newMode);
      if (mounted) {
        setState(() => _flashMode = newMode);
      }
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    _disposeCamera();
    await _initializeCamera();
  }

  Future<void> _captureImage() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    try {
      setState(() => _isCapturing = true);

      // Haptic feedback
      HapticFeedback.mediumImpact();

      final XFile image = await _cameraController!.takePicture();

      if (!mounted) return;

      // Navigate to chat bot screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatBotScreen(imagePath: image.path),
        ),
      );
    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _openGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatBotScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error open gallery: $e')));
      }
    }
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Camera Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Grid Toggle
              SwitchListTile(
                title: const Text(
                  'Grid',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Show composition grid',
                  style: TextStyle(color: Colors.white60),
                ),
                value: _showGrid,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() => _showGrid = value);
                  setModalState(() {});
                },
              ),
              const Divider(color: Colors.white24),
              // Timer
              ListTile(
                title: const Text(
                  'Timer',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _timerDuration == 0 ? 'Off' : '$_timerDuration seconds',
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [0, 3, 10].map((duration) {
                  final isSelected = _timerDuration == duration;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _timerDuration = duration);
                      setModalState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        duration == 0 ? 'Off' : '${duration}s',
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          _buildCameraPreview(),

          // Viewfinder Overlay
          _buildViewfinderOverlay(),

          // Top Interface
          _buildTopInterface(),

          // Bottom Interface
          _buildBottomInterface(),

          // Filter Selector
          if (_showFilterSelector) _buildFilterSelector(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final preview = SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );

    // Apply filter if selected
    if (_selectedFilterIndex == 0) {
      return preview;
    }

    return ColorFiltered(
      colorFilter: _getColorFilter(_selectedFilterIndex),
      child: preview,
    );
  }

  ColorFilter _getColorFilter(int index) {
    switch (index) {
      case 1: // Warm
        return const ColorFilter.matrix([
          1.2,
          0,
          0,
          0,
          0,
          0,
          1.0,
          0,
          0,
          0,
          0,
          0,
          0.8,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case 2: // Cool
        return const ColorFilter.matrix([
          0.8,
          0,
          0,
          0,
          0,
          0,
          1.0,
          0,
          0,
          0,
          0,
          0,
          1.2,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case 3: // Monochrome
        return const ColorFilter.matrix([
          0.33,
          0.59,
          0.11,
          0,
          0,
          0.33,
          0.59,
          0.11,
          0,
          0,
          0.33,
          0.59,
          0.11,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
  }

  Widget _buildViewfinderOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
        ),
      ),
      child: _showGrid ? _buildGrid() : null,
    );
  }

  Widget _buildGrid() {
    return CustomPaint(painter: GridPainter(), size: Size.infinite);
  }

  Widget _buildTopInterface() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Top Row: Close and Settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Close Button
                  _buildTopButton(
                    Icons.close,
                    onTap: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  _buildTopButton(
                    Icons.settings,
                    onTap: _showSettingsBottomSheet,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Flip camera button (aligned to right, below settings)
              Row(
                children: [
                  // Flash Button (Moved here)
                  _buildTopButton(
                    _flashMode == FlashMode.auto
                        ? Icons.flash_auto
                        : _flashMode == FlashMode.torch
                        ? Icons.flash_on
                        : Icons.flash_off,
                    onTap: _toggleFlash,
                  ),
                  const Spacer(),
                  _buildTopButton(Icons.flip_camera_ios, onTap: _switchCamera),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(icon, color: AppColors.textMainDark, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInterface() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Controls Row
              _buildControlsRow(),
              const SizedBox(height: 32),
              // Mode Selector
              _buildModeSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Gallery Preview
        GestureDetector(
          onTap: _openGallery,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
              color: Colors.black.withValues(alpha: 0.3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _lastImagePath != null
                  ? Image.file(
                      File(_lastImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
        ),
        // Shutter Button
        _buildShutterButton(),
        // Filter Toggle
        GestureDetector(
          onTap: () =>
              setState(() => _showFilterSelector = !_showFilterSelector),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: _showFilterSelector ? 0.3 : 0.1,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_fix_high,
                      color: AppColors.textMainDark,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'FILTERS',
                      style: TextStyle(
                        color: AppColors.textMainDark,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _captureImage,
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 4,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE48744), Color(0xFFce8a5a)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    final modes = ['Standard', 'AI Photo', 'Cinematic'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(modes.length, (index) {
        final isSelected = index == _selectedModeIndex;
        return GestureDetector(
          onTap: () => setState(() => _selectedModeIndex = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  modes[index],
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textMainDark.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFilterSelector() {
    final filters = ['Original', 'Warm', 'Cool', 'Mono'];
    return Positioned(
      bottom: 180,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedFilterIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: Container(
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getFilterPreviewColor(index),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      filters[index],
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMainDark,
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getFilterPreviewColor(int index) {
    switch (index) {
      case 1:
        return Colors.orange.withValues(alpha: 0.6);
      case 2:
        return Colors.blue.withValues(alpha: 0.6);
      case 3:
        return Colors.grey.withValues(alpha: 0.6);
      default:
        return Colors.white.withValues(alpha: 0.6);
    }
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Vertical lines
    final double verticalSpacing = size.width / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(verticalSpacing * i, 0),
        Offset(verticalSpacing * i, size.height),
        paint,
      );
    }

    // Horizontal lines
    final double horizontalSpacing = size.height / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(0, horizontalSpacing * i),
        Offset(size.width, horizontalSpacing * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
