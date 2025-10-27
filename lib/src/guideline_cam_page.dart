import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:guideline_cam/src/config.dart';
import 'package:guideline_cam/src/controller.dart';
import 'package:guideline_cam/src/enums.dart';
import 'package:guideline_cam/src/guideline_cam_view.dart';

/// Internal page widget that manages camera capture with automatic lifecycle.
///
/// This widget is used internally by [GuidelineCam.takePhoto] to provide
/// a simplified camera capture experience. It manages the controller lifecycle,
/// displays the camera UI, and handles navigation.
class GuidelineCamPage extends StatefulWidget {
  const GuidelineCamPage({
    super.key,
    required this.guideline,
    required this.cameraDirection,
    required this.showFlashToggle,
    required this.showCameraSwitch,
    required this.backgroundColor,
    this.instructionBuilder,
  });

  final GuidelineOverlayConfig guideline;
  final CameraLensDirection cameraDirection;
  final bool showFlashToggle;
  final bool showCameraSwitch;
  final Color backgroundColor;
  final Widget Function(BuildContext, GuidelineState)? instructionBuilder;

  @override
  State<GuidelineCamPage> createState() => _GuidelineCamPageState();
}

class _GuidelineCamPageState extends State<GuidelineCamPage> {
  late GuidelineCamController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = GuidelineCamController(
      initialCameraDirection: widget.cameraDirection,
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  Future<void> _handleCapture() async {
    try {
      final result = await _controller.capture();
      if (result != null && mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      // Handle capture error silently or show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: _hasError
            ? _buildErrorWidget()
            : _isInitialized
                ? _buildCameraWidget()
                : _buildLoadingWidget(),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Initializing camera...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Failed to initialize camera. Please check your permissions and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraWidget() {
    return Stack(
      fit: StackFit.expand,
      children: [
        GuidelineCamBuilder(
          controller: _controller,
          guideline: widget.guideline,
          showFlashToggle: false,
          showCameraSwitch: false,
          instructionBuilder: widget.instructionBuilder,
          onCapture: (result) {
            Navigator.of(context).pop(result.file);
          },
          onError: (error, stackTrace) {
            // Handle errors gracefully
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Camera error: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        // Button container with proper spacing
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Camera switch button (left)
              if (widget.showCameraSwitch)
                GestureDetector(
                  onTap: () async {
                    await _controller.switchCamera();
                    setState(() {});
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black54,
                    ),
                    child: Icon(
                      _controller.lensDirection == CameraLensDirection.back
                          ? Icons.camera_front
                          : Icons.camera_rear,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                )
              else
                const SizedBox(width: 56),
              // Main capture button (center)
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: IconButton(
                  onPressed: _handleCapture,
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.black87,
                    size: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              // Flash toggle button (right)
              if (widget.showFlashToggle)
                GestureDetector(
                  onTap: () async {
                    final currentMode = _controller.flashMode;
                    final newMode = currentMode == FlashMode.off
                        ? FlashMode.always
                        : FlashMode.off;
                    await _controller.setFlashMode(newMode);
                    setState(() {});
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black54,
                    ),
                    child: Icon(
                      _controller.flashMode == FlashMode.off
                          ? Icons.flash_off
                          : Icons.flash_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                )
              else
                const SizedBox(width: 56),
            ],
          ),
        ),
        // Close button (top right)
        Positioned(
          top: 16,
          right: 16,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black54,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(null),
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
              padding: EdgeInsets.zero,
              iconSize: 20,
            ),
          ),
        ),
      ],
    );
  }
}
