import 'dart:io';

import 'package:flutter/material.dart';
import 'package:guideline_cam/guideline_cam.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  GuidelineCam.configureLogging(LoggerConfig.verbose);
  GuidelineCam.enablePerformanceTiming = true;
  
  runApp(const GuidelineCamDemoApp());
}

class GuidelineCamDemoApp extends StatelessWidget {
  const GuidelineCamDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late GuidelineCamController _controller;
  Color _maskColor = Colors.black54;
  Color _frameColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _controller = GuidelineCamController();
    _controller.initialize();
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    try {
      final result = await _controller.capture();
      if (result != null) {
        if (mounted) {
          await _showCaptureDialog(
            file: result,
            capturedAt: DateTime.now(),
            lens: _controller.lensDirection,
          );
        }
      }
    } catch (e, st) {
      // You can also provide onError to GuidelineCamBuilder
      debugPrint('Capture error: $e\n$st');
    }
  }

  Future<void> _showCaptureDialog({
    required XFile file,
    required DateTime capturedAt,
    required CameraLensDirection lens,
  }) async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 300,
                      height: 200,
                      child: Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Captured: ${capturedAt.toLocal()}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text('Direction: ${lens.name}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showFab = ![0, 3, 6].contains(_tabController
        .index); // Hide on Static API, Overlay Builder & Crop/Processing tab
    return Scaffold(
      appBar: AppBar(
        title: const Text('GuidelineCam Example'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Static API'),
            Tab(text: 'Basic'),
            Tab(text: 'Custom Buttons'),
            Tab(text: 'Overlay Builder'),
            Tab(text: 'Multi/Nested'),
            Tab(text: 'Instruction'),
            Tab(text: 'Crop & Process'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StaticApiDemo(
              onCaptured: (x) async {
                if (x != null) {
                  await _showCaptureDialog(
                    file: x,
                    capturedAt: DateTime.now(),
                    lens: CameraLensDirection.back,
                  );
                }
              },
              maskColor: _maskColor,
              frameColor: _frameColor),
          _BasicDemo(
              controller: _controller,
              onCaptured: (x) async {
                if (x != null) {
                  await _showCaptureDialog(
                    file: x,
                    capturedAt: DateTime.now(),
                    lens: _controller.lensDirection,
                  );
                }
              },
              maskColor: _maskColor,
              frameColor: _frameColor),
          _CustomButtonsDemo(
              controller: _controller,
              onCaptured: (x) async {
                if (x != null) {
                  await _showCaptureDialog(
                    file: x,
                    capturedAt: DateTime.now(),
                    lens: _controller.lensDirection,
                  );
                }
              },
              maskColor: _maskColor,
              frameColor: _frameColor),
          _OverlayBuilderDemo(
              controller: _controller,
              onCaptured: (x) async {
                if (x != null) {
                  await _showCaptureDialog(
                    file: x,
                    capturedAt: DateTime.now(),
                    lens: _controller.lensDirection,
                  );
                }
              },
              maskColor: _maskColor,
              frameColor: _frameColor),
          _MultiNestedDemo(
              controller: _controller,
              onCaptured: (x) async {
                if (x != null) {
                  await _showCaptureDialog(
                    file: x,
                    capturedAt: DateTime.now(),
                    lens: _controller.lensDirection,
                  );
                }
              },
              maskColor: _maskColor),
          _InstructionDemo(
              controller: _controller,
              onCaptured: (x) async {
                if (x != null) {
                  await _showCaptureDialog(
                    file: x,
                    capturedAt: DateTime.now(),
                    lens: _controller.lensDirection,
                  );
                }
              },
              maskColor: _maskColor,
              frameColor: _frameColor),
          _CropProcessingDemo(
              controller: _controller,
              maskColor: _maskColor,
              frameColor: _frameColor),
        ],
      ),
      bottomNavigationBar: _CapturePreviewBar(
        maskColor: _maskColor,
        frameColor: _frameColor,
        onMaskChanged: (c) => setState(() => _maskColor = c),
        onFrameChanged: (c) => setState(() => _frameColor = c),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: _capture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _CapturePreviewBar extends StatelessWidget {
  const _CapturePreviewBar({
    required this.maskColor,
    required this.frameColor,
    required this.onMaskChanged,
    required this.onFrameChanged,
  });

  final Color maskColor;
  final Color frameColor;
  final ValueChanged<Color> onMaskChanged;
  final ValueChanged<Color> onFrameChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        border: const Border(top: BorderSide(color: Color(0x14000000))),
      ),
      child: Row(
        children: [
          _ColorChip(
            label: 'Mask',
            color: maskColor,
            onTap: () => _showPalette(context, maskColor, onMaskChanged,
                enableOpacity: true),
          ),
          const SizedBox(width: 12),
          _ColorChip(
            label: 'Frame',
            color: frameColor,
            onTap: () => _showPalette(context, frameColor, onFrameChanged),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Adjust mask and frame colors in real-time.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showPalette(
      BuildContext context, Color current, ValueChanged<Color> onPick,
      {bool enableOpacity = false}) {
    final List<Color> palette = <Color>[
      Colors.black54,
      Colors.black45,
      Colors.white,
      Colors.teal,
      Colors.blueAccent,
      Colors.amber,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.deepPurpleAccent,
      Colors.pinkAccent,
      Colors.orangeAccent,
      Colors.cyan,
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        double opacity = enableOpacity ? current.a : 1.0;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (enableOpacity) ...[
                      const Text('Mask Opacity'),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: opacity,
                              onChanged: (v) =>
                                  setModalState(() => opacity = v),
                              min: 0.0,
                              max: 0.9,
                              divisions: 9,
                              label: (opacity).toStringAsFixed(1),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child:
                                Text('${(opacity * 100).toStringAsFixed(0)}%'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final c in palette)
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              onPick(enableOpacity
                                  ? c.withValues(alpha: opacity)
                                  : c);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: enableOpacity
                                    ? c.withValues(alpha: opacity)
                                    : c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: c.computeLuminance() > 0.5
                                      ? Colors.black26
                                      : Colors.white24,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip(
      {required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _BasicDemo extends StatelessWidget {
  const _BasicDemo(
      {required this.controller,
      required this.onCaptured,
      required this.maskColor,
      required this.frameColor});

  final GuidelineCamController controller;
  final ValueChanged<XFile?> onCaptured;
  final Color maskColor;
  final Color frameColor;

  @override
  Widget build(BuildContext context) {
    return GuidelineCamBuilder(
      controller: controller,
      guideline: GuidelineOverlayConfig(
        shape: GuidelineShape.roundedRect,
        aspectRatio: 1.586,
        frameColor: frameColor,
        maskColor: maskColor,
        borderRadius: 40,
        cornerLength: 0,
      ),
      onCapture: (result) => onCaptured(result.file),
    );
  }
}

class _CustomButtonsDemo extends StatelessWidget {
  const _CustomButtonsDemo(
      {required this.controller,
      required this.onCaptured,
      required this.maskColor,
      required this.frameColor});

  final GuidelineCamController controller;
  final ValueChanged<XFile?> onCaptured;
  final Color maskColor;
  final Color frameColor;

  @override
  Widget build(BuildContext context) {
    return GuidelineCamBuilder(
      controller: controller,
      guideline: GuidelineOverlayConfig(
        shape: GuidelineShape.circle,
        frameColor: frameColor,
        maskColor: maskColor,
      ),
      flashButtonBuilder: (context, flashMode, onPressed) {
        return Container(
          decoration: BoxDecoration(
            color: flashMode == FlashMode.off ? Colors.red : Colors.green,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onPressed,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      flashMode == FlashMode.off
                          ? Icons.flash_off
                          : Icons.flash_on,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      flashMode == FlashMode.off ? 'Flash OFF' : 'Flash ON',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      cameraSwitchButtonBuilder: (context, lensDirection, onPressed) {
        return FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: Colors.teal,
          child: Icon(
            lensDirection == CameraLensDirection.back
                ? Icons.camera_front
                : Icons.camera_rear,
          ),
        );
      },
      onCapture: (result) => onCaptured(result.file),
    );
  }
}

class _OverlayBuilderDemo extends StatelessWidget {
  const _OverlayBuilderDemo(
      {required this.controller,
      required this.onCaptured,
      required this.maskColor,
      required this.frameColor});

  final GuidelineCamController controller;
  final ValueChanged<XFile?> onCaptured;
  final Color maskColor;
  final Color frameColor;

  @override
  Widget build(BuildContext context) {
    return GuidelineCamBuilder(
      controller: controller,
      guideline: GuidelineOverlayConfig(
        shape: GuidelineShape.oval,
        aspectRatio: 0.75,
        padding: const EdgeInsets.all(80),
        frameColor: frameColor,
        maskColor: maskColor,
      ),
      overlayBuilder: (context, c) {
        return Stack(
          children: [
            Positioned(
              top: 50,
              right: 20,
              child: FloatingActionButton(
                onPressed: () async {
                  final newMode = c.flashMode == FlashMode.off
                      ? FlashMode.always
                      : FlashMode.off;
                  await c.setFlashMode(newMode);
                },
                backgroundColor: c.flashMode == FlashMode.off
                    ? Colors.black54
                    : Colors.amber,
                child: Icon(
                  c.flashMode == FlashMode.off
                      ? Icons.flash_off
                      : Icons.flash_on,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: FloatingActionButton(
                onPressed: () async {
                  await c.switchCamera();
                },
                backgroundColor: Colors.black54,
                child: const Icon(Icons.switch_camera, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.large(
                  onPressed: () async {
                    final res = await c.capture();
                    onCaptured(res);
                  },
                  child: const Icon(Icons.camera_alt),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'State: ${c.state.name.toUpperCase()}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      onCapture: (result) => onCaptured(result.file),
    );
  }
}

class _MultiNestedDemo extends StatelessWidget {
  const _MultiNestedDemo(
      {required this.controller,
      required this.onCaptured,
      required this.maskColor});

  final GuidelineCamController controller;
  final ValueChanged<XFile?> onCaptured;
  final Color maskColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Responsive rectangles/ovals using absolute bounds based on screen
        final faceOval = ShapeConfig(
          shape: GuidelineShape.oval,
          aspectRatio: 0.75,
          bounds: Rect.fromLTWH(
              width * 0.25, height * 0.10, width * 0.50, height * 0.4),
          frameColor: Colors.lightBlueAccent,
          strokeWidth: 3,
          cornerLength: 0,
        );
        final idCard = ShapeConfig(
          shape: GuidelineShape.roundedRect,
          bounds: Rect.fromLTWH(
              width * 0.15, height * 0.55, width * 0.70, height * 0.275),
          borderRadius: 16,
          frameColor: Colors.greenAccent,
          strokeWidth: 3,
          cornerLength: 0,
          children: [
            ShapeConfig.relativePosition(
              shape: GuidelineShape.rect,
              relativeOffset: const Offset(0.75, 0.5),
              size: const Size(0.3, 0.6),
              frameColor: Colors.white,
              strokeWidth: 2,
            ),
            ShapeConfig.inset(
              shape: GuidelineShape.roundedRect,
              cornerLength: 0,
              insets: const EdgeInsets.fromLTRB(16, 34, 16, 16),
              size: const Size(0.5, 0.2),
              frameColor: Colors.white,
              strokeWidth: 1.5,
            ),
          ],
        );

        return GuidelineCamBuilder(
          controller: controller,
          guideline: GuidelineOverlayConfig(
            shapes: [faceOval, idCard],
            maskColor: maskColor,
          ),
          onCapture: (result) => onCaptured(result.file),
        );
      },
    );
  }
}

class _InstructionDemo extends StatelessWidget {
  const _InstructionDemo(
      {required this.controller,
      required this.onCaptured,
      required this.maskColor,
      required this.frameColor});

  final GuidelineCamController controller;
  final ValueChanged<XFile?> onCaptured;
  final Color maskColor;
  final Color frameColor;

  @override
  Widget build(BuildContext context) {
    return GuidelineCamBuilder(
      controller: controller,
      guideline: GuidelineOverlayConfig(
        shape: GuidelineShape.roundedRect,
        aspectRatio: 1.586,
        frameColor: frameColor,
        maskColor: maskColor,
        showGrid: true,
        debugPaint: true,
      ),
      instructionBuilder: (context, state) {
        String message;
        Color color;
        switch (state) {
          case GuidelineState.initializing:
            message = 'Initializing camera...';
            color = Colors.orange;
            break;
          case GuidelineState.ready:
            message = 'Align the document within the frame.';
            color = Colors.green;
            break;
          case GuidelineState.capturing:
            message = 'Capturing... Hold steady!';
            color = Colors.blue;
            break;
          case GuidelineState.error:
            message = 'An error occurred. Please retry.';
            color = Colors.red;
            break;
        }
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
      onCapture: (result) => onCaptured(result.file),
    );
  }
}

class _StaticApiDemo extends StatelessWidget {
  const _StaticApiDemo({
    required this.onCaptured,
    required this.maskColor,
    required this.frameColor,
  });

  final ValueChanged<XFile?> onCaptured;
  final Color maskColor;
  final Color frameColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: Colors.teal,
              ),
              const SizedBox(height: 24),
              const Text(
                'Static API Demo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the button below to capture a photo using the simplified API.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () async {
                  final photo = await GuidelineCam.takePhoto(
                    context: context,
                    guideline: GuidelineOverlayConfig(
                      shape: GuidelineShape.roundedRect,
                      aspectRatio: 1.586,
                      frameColor: frameColor,
                      maskColor: maskColor,
                      borderRadius: 40,
                      cornerLength: 0,
                    ),
                  );
                  if (photo != null) {
                    onCaptured(photo);
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              const Text(
                'Try Different Shapes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _ShapeButton(
                    label: 'Circle',
                    icon: Icons.circle_outlined,
                    onPressed: () async {
                      final photo = await GuidelineCam.takePhoto(
                        context: context,
                        guideline: GuidelineOverlayConfig(
                          shape: GuidelineShape.circle,
                          frameColor: frameColor,
                          maskColor: maskColor,
                        ),
                      );
                      if (photo != null) {
                        onCaptured(photo);
                      }
                    },
                  ),
                  _ShapeButton(
                    label: 'Oval',
                    icon: Icons.crop_free,
                    onPressed: () async {
                      final photo = await GuidelineCam.takePhoto(
                        context: context,
                        guideline: GuidelineOverlayConfig(
                          shape: GuidelineShape.oval,
                          aspectRatio: 0.75,
                          frameColor: frameColor,
                          maskColor: maskColor,
                        ),
                      );
                      if (photo != null) {
                        onCaptured(photo);
                      }
                    },
                  ),
                  _ShapeButton(
                    label: 'Rectangle',
                    icon: Icons.crop_square,
                    onPressed: () async {
                      final photo = await GuidelineCam.takePhoto(
                        context: context,
                        guideline: GuidelineOverlayConfig(
                          shape: GuidelineShape.rect,
                          aspectRatio: 1.5,
                          frameColor: frameColor,
                          maskColor: maskColor,
                        ),
                      );
                      if (photo != null) {
                        onCaptured(photo);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapeButton extends StatelessWidget {
  const _ShapeButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}

class _CropProcessingDemo extends StatefulWidget {
  const _CropProcessingDemo({
    required this.controller,
    required this.maskColor,
    required this.frameColor,
  });

  final GuidelineCamController controller;
  final Color maskColor;
  final Color frameColor;

  @override
  State<_CropProcessingDemo> createState() => _CropProcessingDemoState();
}

enum DemoShape { roundedRect, circle, oval, nested }

class _CropProcessingDemoState extends State<_CropProcessingDemo> {
  ImageProcessingConfig? _processingConfig; // Default to null (None)
  DemoShape _selectedShape = DemoShape.roundedRect;
  CropStrategy _cropStrategy = CropStrategy.outermost;
  int _selectedImageIndex = 0; // 0=final, 1=original, 2=cropped, 3=processed

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GuidelineCamBuilder(
          controller: widget.controller,
          guideline: _buildGuidelineConfig(),
          onCapture: (result) {
            setState(() {
              _selectedImageIndex = 0;
            });
            _showResultDialog(result);
          },
        ),
        // Settings overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Crop & Processing Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildShapeSelector(),
                    const SizedBox(height: 8),
                    if (_selectedShape == DemoShape.nested) ...[
                      _buildCropStrategySelector(),
                      const SizedBox(height: 8),
                    ],
                    _buildProcessingPresetSelector(),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Capture button
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton.extended(
              onPressed: () async {
                final result = await widget.controller.captureWithProcessing();
                if (result != null && mounted) {
                  setState(() {
                    _selectedImageIndex = 0;
                  });
                  _showResultDialog(result);
                }
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture & Process'),
            ),
          ),
        ),
      ],
    );
  }

  GuidelineOverlayConfig _buildGuidelineConfig() {
    switch (_selectedShape) {
      case DemoShape.roundedRect:
        return GuidelineOverlayConfig(
          shape: GuidelineShape.roundedRect,
          aspectRatio: 1.586, // ID card ratio
          frameColor: widget.frameColor,
          maskColor: widget.maskColor,
          borderRadius: 16.0,
          cropConfig: const CropConfig(
            padding: 5.0,
          ),
          processing: _processingConfig,
        );
      case DemoShape.circle:
        return GuidelineOverlayConfig(
          shape: GuidelineShape.circle,
          aspectRatio: 1.0,
          frameColor: widget.frameColor,
          maskColor: widget.maskColor,
          cropConfig: const CropConfig(
            padding: 5.0,
          ),
          processing: _processingConfig,
        );
      case DemoShape.oval:
        return GuidelineOverlayConfig(
          shape: GuidelineShape.oval,
          aspectRatio: 1.414, // A4 ratio
          frameColor: widget.frameColor,
          maskColor: widget.maskColor,
          cropConfig: const CropConfig(
            padding: 5.0,
          ),
          processing: _processingConfig,
        );
      case DemoShape.nested:
        // Multi-shape configuration: Oval for face + Rounded rect for ID card
        return GuidelineOverlayConfig(
          shapes: [
            // Oval for face (top)
            const ShapeConfig(
              shape: GuidelineShape.oval,
              bounds: Rect.fromLTWH(100, 120, 190, 230), // Portrait oval
              aspectRatio: 0.826, // Portrait ratio for face
              frameColor: Colors.green,
            ),
            // Rounded rectangle for ID card (bottom)
            ShapeConfig(
              shape: GuidelineShape.roundedRect,
              bounds:
                  const Rect.fromLTWH(40, 400, 310, 195), // ID card dimensions
              aspectRatio: 1.586, // Standard ID card ratio
              frameColor: widget.frameColor,
              borderRadius: 12.0,
            ),
          ],
          maskColor: widget.maskColor,
          cropConfig: CropConfig(
            strategy: _cropStrategy,
          ),
          processing: _processingConfig,
        );
    }
  }

  Widget _buildShapeSelector() {
    return Row(
      children: [
        const Text(
          'Shape: ',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            children: [
              _buildShapeChip('Rounded', DemoShape.roundedRect),
              _buildShapeChip('Circle', DemoShape.circle),
              _buildShapeChip('Oval', DemoShape.oval),
              _buildShapeChip('Nested', DemoShape.nested),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShapeChip(String label, DemoShape shape) {
    final isSelected = _selectedShape == shape;
    return GestureDetector(
      onTap: () => setState(() => _selectedShape = shape),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCropStrategySelector() {
    return Row(
      children: [
        const Text(
          'Strategy: ',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            children: [
              _buildStrategyChip('Outermost', CropStrategy.outermost),
              _buildStrategyChip('Each Shape', CropStrategy.eachShape),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStrategyChip(String label, CropStrategy strategy) {
    final isSelected = _cropStrategy == strategy;
    return GestureDetector(
      onTap: () => setState(() => _cropStrategy = strategy),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingPresetSelector() {
    return Row(
      children: [
        const Text(
          'Process: ',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            children: [
              _buildProcessingChip('None', null),
              _buildProcessingChip(
                  'Document', ImageProcessingConfig.documentScan),
              _buildProcessingChip('ID Card', ImageProcessingConfig.idCard),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingChip(String label, ImageProcessingConfig? config) {
    final isSelected = _processingConfig == config;
    return GestureDetector(
      onTap: () => setState(() => _processingConfig = config),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showResultDialog(GuidelineCaptureResult result) {
    // Check if we have multiple cropped images (eachShape strategy)
    if (result.croppedFiles.length > 1) {
      _showMultiImageDialog(result);
    } else {
      _showSingleImageDialog(result);
    }
  }

  void _showSingleImageDialog(GuidelineCaptureResult result) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            XFile displayFile = result.file;
            String displayLabel = 'Final Image';

            switch (_selectedImageIndex) {
              case 1:
                displayFile = result.originalFile ?? result.file;
                displayLabel = 'Original';
                break;
              case 2:
                displayFile = result.croppedFiles.isNotEmpty
                    ? result.croppedFiles.first
                    : result.file;
                displayLabel = 'Cropped';
                break;
              case 3:
                displayFile = result.processedFile ?? result.file;
                displayLabel = 'Processed';
                break;
              default:
                displayFile = result.file;
                displayLabel = 'Final Image';
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(12),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_camera, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          displayLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 250,
                        child: Image.file(
                          File(displayFile.path),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 250,
                            child: Center(
                              child: Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Image Versions:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildVersionChip(
                          'Final',
                          0,
                          Icons.check_circle,
                          setDialogState,
                        ),
                        if (result.originalFile != null)
                          _buildVersionChip(
                            'Original',
                            1,
                            Icons.image,
                            setDialogState,
                          ),
                        if (result.croppedFiles.isNotEmpty)
                          _buildVersionChip(
                            'Cropped',
                            2,
                            Icons.crop,
                            setDialogState,
                          ),
                        if (result.processedFile != null)
                          _buildVersionChip(
                            'Processed',
                            3,
                            Icons.auto_fix_high,
                            setDialogState,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildResultInfo(result),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildVersionChip(
    String label,
    int index,
    IconData icon,
    StateSetter setDialogState,
  ) {
    final isSelected = _selectedImageIndex == index;
    return GestureDetector(
      onTap: () => setDialogState(() => _selectedImageIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultInfo(GuidelineCaptureResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Capture Info:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Processing',
          _processingConfig == null ? 'None' : 'Applied',
        ),
        _buildInfoRow('Cropped Files', '${result.croppedFiles.length}'),
        _buildInfoRow(
          'Has Original',
          result.originalFile != null ? 'Yes' : 'No',
        ),
        _buildInfoRow(
          'Has Processed',
          result.processedFile != null ? 'Yes' : 'No',
        ),
        _buildInfoRow('Camera', result.lens.name),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showMultiImageDialog(GuidelineCaptureResult result) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(12),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.photo_library, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      'Multiple Cropped Images',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.croppedFiles.length} shapes detected',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                // Display all cropped images
                SizedBox(
                  height: 400,
                  child: ListView.builder(
                    itemCount: result.croppedFiles.length,
                    itemBuilder: (context, index) {
                      final croppedFile = result.croppedFiles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Shape ${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  index == 0 ? 'Face (Oval)' : 'ID Card (Rect)',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                height: 180,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.file(
                                  File(croppedFile.path),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    height: 180,
                                    child: Center(
                                      child: Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                _buildMultiImageInfo(result),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMultiImageInfo(GuidelineCaptureResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Capture Info:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Strategy', 'Each Shape'),
        _buildInfoRow('Total Shapes', '${result.croppedFiles.length}'),
        _buildInfoRow(
          'Processing',
          _processingConfig == null ? 'None' : 'Applied',
        ),
        _buildInfoRow('Camera', result.lens.name),
      ],
    );
  }
}
