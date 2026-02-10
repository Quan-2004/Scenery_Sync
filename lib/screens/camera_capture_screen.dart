import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  bool _initializing = true;
  bool _takingPicture = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      if (!mounted) return;

      if (cams.isEmpty) {
        setState(() {
          _error = 'No camera device found';
          _initializing = false;
        });
        return;
      }

      _cameras = cams;
      await _setCamera(cams.first);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to initialize camera: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _setCamera(CameraDescription desc) async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    final old = _controller;
    _controller = null;
    await old?.dispose();

    final controller = CameraController(
      desc,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _error = 'Failed to initialize camera: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_takingPicture) return;

    setState(() => _takingPicture = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop<XFile>(file);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to take picture: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _takingPicture = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Camera'),
        actions: [
          if (_cameras.length > 1)
            IconButton(
              tooltip: 'Switch camera',
              icon: const Icon(Icons.cameraswitch_rounded),
              onPressed: _initializing
                  ? null
                  : () async {
                      final current = controller?.description;
                      final next = _cameras.firstWhere(
                        (c) => c.lensDirection != current?.lensDirection,
                        orElse: () => _cameras.first,
                      );
                      await _setCamera(next);
                    },
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _initializing
                ? const Center(child: CircularProgressIndicator())
                : (controller == null || !controller.value.isInitialized)
                    ? Center(
                        child: Text(
                          _error ?? 'Camera unavailable',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : CameraPreview(controller),
          ),
          if (_error != null && !_initializing)
            Positioned(
              left: 16,
              right: 16,
              bottom: 120,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.6 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: (_initializing || _takingPicture || controller == null)
            ? null
            : _capture,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: _takingPicture
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.camera_alt_rounded),
      ),
    );
  }
}
