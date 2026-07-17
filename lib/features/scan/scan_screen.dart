import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/scan_provider.dart';

/// Screen 6 — Crop Scan.
/// Camera Preview, Gallery Upload, Flash Control, Capture Button.
/// After capture: uploads to backend, shows a loading animation, then
/// navigates to the Results screen with the AI prediction.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _isFlashOn = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _initError = 'No camera found on this device.';
          _isInitializing = false;
        });
        return;
      }
      final backCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      final controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _initError = 'Could not access the camera. Please check camera permissions.';
        _isInitializing = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
    await _controller!.setFlashMode(newMode);
    setState(() => _isFlashOn = !_isFlashOn);
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) return;
    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      await _handleImage(bytes, file.name);
    } catch (e) {
      _showError('Failed to capture image. Please try again.');
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      await _handleImage(bytes, picked.name);
    }
  }

  Future<void> _handleImage(Uint8List bytes, String fileName) async {
    final success = await ref.read(scanUploadProvider.notifier).uploadImage(bytes, fileName);
    if (!mounted) return;

    if (success) {
      ref.invalidate(dashboardStatsProvider); // refresh dashboard counts/recents
      final scan = ref.read(scanUploadProvider).result;
      ref.read(scanUploadProvider.notifier).reset();
      context.pushReplacementNamed('results', extra: scan);
    } else {
      final message = ref.read(scanUploadProvider).errorMessage ?? 'Scan failed. Please try again.';
      ref.read(scanUploadProvider.notifier).reset();
      _showError(message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.infected));
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(scanUploadProvider);
    final isUploading = uploadState.status == ScanUploadStatus.uploading;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),
          if (isUploading) _buildUploadingOverlay(context),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconButton(icon: Icons.close, onTap: () => context.goNamed('dashboard')),
                  _CircleIconButton(
                    icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    onTap: _toggleFlash,
                  ),
                ],
              ),
            ),
          ),
          if (!isUploading)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CircleIconButton(icon: Icons.photo_library_outlined, onTap: _pickFromGallery, size: 52),
                      GestureDetector(
                        onTap: _capture,
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 62,
                              height: 62,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 52), // balances the gallery button for centered capture
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(_initError!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _pickFromGallery,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                child: const Text('Choose from Gallery'),
              ),
            ],
          ),
        ),
      );
    }
    return CameraPreview(_controller!);
  }

  Widget _buildUploadingOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text('Analyzing your crop...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Our AI is checking for disease patterns', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _CircleIconButton({required this.icon, required this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.4)),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
