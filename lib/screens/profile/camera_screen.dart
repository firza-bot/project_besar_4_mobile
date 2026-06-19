import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/constants.dart';

class InAppCameraScreen extends StatefulWidget {
  const InAppCameraScreen({super.key});

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isFrontCamera = false;
  String? _errorMessage;

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
        setState(() => _errorMessage = 'Tidak ada kamera tersedia di perangkat ini.');
        return;
      }
      await _startCamera(_isFrontCamera ? 1 : 0);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal inisialisasi kamera: $e');
    }
  }

  Future<void> _startCamera(int index) async {
    if (_cameras.isEmpty) return;
    final cameraIndex = index.clamp(0, _cameras.length - 1);

    final controller = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (mounted) {
        await _controller?.dispose();
        setState(() {
          _controller = controller;
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      controller.dispose();
      setState(() => _errorMessage = 'Kamera tidak bisa dibuka: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isInitialized = false;
    });
    await _startCamera(_isFrontCamera ? 1 : 0);
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await _controller!.takePicture();

      // Salin ke direktori permanen
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(photo.path).copy('${appDir.path}/$fileName');

      if (mounted) {
        Navigator.pop(context, savedFile.path);
      }
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(_isFrontCamera ? 1 : 0);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Camera Preview
            if (_isInitialized && _controller != null)
              Positioned.fill(
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: isPortrait ? 1080 : 1080 * _controller!.value.aspectRatio,
                      height: isPortrait ? 1080 * _controller!.value.aspectRatio : 1080,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.no_photography_rounded,
                          color: Colors.white54, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _initCamera,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tombol kembali
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      const Text(
                        'Ambil Foto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Tombol flip kamera
                      GestureDetector(
                        onTap: _cameras.length > 1 ? _switchCamera : null,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.flip_camera_ios_rounded,
                            color: _cameras.length > 1 ? Colors.white : Colors.white38,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom controls (shutter button)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shutter button
                    GestureDetector(
                      onTap: _isCapturing ? null : _capturePhoto,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: _isCapturing ? 68 : 72,
                        height: _isCapturing ? 68 : 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing
                              ? Colors.white60
                              : Colors.white,
                          border: Border.all(
                            color: Colors.white54,
                            width: 4,
                          ),
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black54,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
