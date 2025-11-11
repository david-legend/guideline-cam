# Auto-Crop & Image Processing

This guide covers the automatic image cropping and processing features available in guideline_cam package.

## Table of Contents

- [Overview](#overview)
- [Auto-Crop Feature](#auto-crop-feature)
  - [Crop Modes](#crop-modes)
  - [Crop Strategies](#crop-strategies)
  - [Configuration](#configuration)
- [Image Processing](#image-processing)
  - [Available Filters](#available-filters)
  - [Presets](#presets)
  - [Custom Configuration](#custom-configuration)
- [Usage Examples](#usage-examples)
- [Manual Processing](#manual-processing)
- [Best Practices](#best-practices)
- [Performance Considerations](#performance-considerations)

---

## Overview

Starting from version 0.1.0, guideline_cam includes powerful auto-crop and image processing capabilities that work seamlessly with the existing guideline overlay system. These features are:

- **Lightweight**: Uses only the pure Dart `image` package (~500KB)
- **Optional**: All features are opt-in with sensible defaults
- **Flexible**: Supports both automatic and manual processing
- **Backward compatible**: Existing code continues to work without changes

### Key Features

✅ **Auto-Crop**: Automatically crop captured images to guideline boundaries
✅ **Smart Detection**: AI-free edge detection for document boundaries
✅ **Multi-Shape Support**: Handle nested shapes with multiple crop outputs
✅ **Image Enhancement**: Grayscale, brightness, contrast, saturation
✅ **Noise Reduction**: Gaussian blur-based noise filtering
✅ **Sharpening**: Unsharp mask for clearer images
✅ **Auto-Enhancement**: Automatic brightness/contrast optimization

---

## Auto-Crop Feature

Auto-crop automatically crops the captured image based on the guideline overlay boundaries.

### Crop Modes

#### **Guideline Mode** (`CropMode.guideline`) - **Default**
Crops the image to match the exact guideline overlay shape shown during capture.

```dart
cropConfig: CropConfig(
  mode: CropMode.guideline,
  padding: 10.0, // Optional padding around crop area
)
```

**Best for**: ID cards, passports, documents, and all scanning use cases

### Crop Strategies

For multi-shape or nested shape overlays, you can choose how to handle cropping:

#### 1. **Outermost** (`CropStrategy.outermost`) - **Default**
Crops to the outermost boundary, returning a single image.

```dart
cropConfig: CropConfig(
  strategy: CropStrategy.outermost,
)
```

#### 2. **Each Shape** (`CropStrategy.eachShape`)
Crops each shape separately, returning multiple images.

```dart
cropConfig: CropConfig(
  strategy: CropStrategy.eachShape,
)
```

**Use case**: Capturing front and back of ID card in single shot with two overlays.

### Configuration

Full `CropConfig` options:

```dart
CropConfig(
  enabled: true,                           // Enable/disable auto-crop
  mode: CropMode.guideline,                // Crop mode
  strategy: CropStrategy.outermost,        // Multi-shape strategy
  padding: 0.0,                            // Padding around crop area (pixels)
)
```

---

## Image Processing

Image processing allows you to automatically enhance captured images for better quality and readability.

### Available Filters

#### Grayscale Conversion
Convert images to grayscale or black & white.

```dart
processing: ImageProcessingConfig(
  enabled: true,
  grayscale: true,
)
```

#### Brightness, Contrast, Saturation
Adjust image appearance with fine-grained control.

```dart
processing: ImageProcessingConfig(
  enabled: true,
  brightness: 0.2,   // Range: -1.0 to 1.0
  contrast: 0.15,    // Range: -1.0 to 1.0
  saturation: 0.1,   // Range: -1.0 to 1.0 (ignored if grayscale)
)
```

#### Noise Reduction
Apply Gaussian blur to reduce image noise.

```dart
processing: ImageProcessingConfig(
  enabled: true,
  reduceNoise: true,
  noiseReductionStrength: 3, // Range: 1-10 (higher = stronger)
)
```

#### Sharpening
Enhance image sharpness using unsharp mask.

```dart
processing: ImageProcessingConfig(
  enabled: true,
  sharpen: true,
  sharpenStrength: 1.0, // Range: 0.0-2.0 (1.0 = standard)
)
```

#### Auto-Enhancement
Automatically optimize brightness and contrast based on histogram analysis.

```dart
processing: ImageProcessingConfig(
  enabled: true,
  autoEnhance: true,
)
```

### Presets

Three built-in presets for common use cases:

#### 1. Document Scan Preset
Optimized for scanning documents (grayscale, enhanced, sharpened).

```dart
GuidelineOverlayConfig(
  processing: ImageProcessingConfig.documentScan,
)
```

Equivalent to:
```dart
ImageProcessingConfig(
  enabled: true,
  autoEnhance: true,
  grayscale: true,
  sharpen: true,
  sharpenStrength: 1.2,
  quality: 90,
)
```

#### 2. ID Card Preset
Optimized for ID cards and documents with color (enhanced, sharpened).

```dart
GuidelineOverlayConfig(
  processing: ImageProcessingConfig.idCard,
)
```

Equivalent to:
```dart
ImageProcessingConfig(
  enabled: true,
  autoEnhance: true,
  sharpen: true,
  quality: 95,
)
```

### Custom Configuration

Full `ImageProcessingConfig` options:

```dart
ImageProcessingConfig(
  enabled: true,                    // Enable/disable processing
  autoEnhance: false,               // Auto brightness/contrast
  grayscale: false,                 // Convert to grayscale
  brightness: 0.0,                  // -1.0 to 1.0
  contrast: 0.0,                    // -1.0 to 1.0
  saturation: 0.0,                  // -1.0 to 1.0
  reduceNoise: false,               // Apply noise reduction
  noiseReductionStrength: 3,        // 1-10
  sharpen: false,                   // Apply sharpening
  sharpenStrength: 1.0,             // 0.0-2.0
  quality: 85,                      // JPEG quality 0-100
)
```

---

## Usage Examples

### Example 1: Basic Document Scanning

```dart
GuidelineCamBuilder(
  controller: _controller,
  guideline: GuidelineOverlayConfig(
    shape: GuidelineShape.rect,
    aspectRatio: 1.414, // A4 ratio
    // Auto-crop enabled by default
    cropConfig: CropConfig(
      mode: CropMode.guideline,
    ),
    // Apply document scan preset
    processing: ImageProcessingConfig.documentScan,
  ),
  onCapture: (result) {
    // result.file contains the final processed & cropped image
    print('Original: ${result.originalFile?.path}');
    print('Processed: ${result.processedFile?.path}');
  },
)
```

### Example 2: ID Card Capture

```dart
GuidelineOverlayConfig(
  shape: GuidelineShape.roundedRect,
  aspectRatio: 1.586, // ID card ratio
  frameColor: Colors.white,
  cropConfig: CropConfig(
    mode: CropMode.guideline,
    padding: 5.0, // Small padding to avoid edge cutoff
  ),
  processing: ImageProcessingConfig.idCard,
)
```

### Example 3: Disable Auto-Crop

```dart
GuidelineOverlayConfig(
  shape: GuidelineShape.circle,
  cropConfig: CropConfig(
    enabled: false, // Disable auto-crop
  ),
  processing: null, // No processing
)
```

### Example 4: Custom Processing

```dart
GuidelineOverlayConfig(
  cropConfig: CropConfig(enabled: true),
  processing: ImageProcessingConfig(
    enabled: true,
    autoEnhance: true,
    brightness: 0.1,
    contrast: 0.2,
    sharpen: true,
    sharpenStrength: 1.5,
    quality: 95,
  ),
)
```

### Example 5: Multi-Shape with Separate Crops

```dart
GuidelineOverlayConfig(
  shapes: [
    ShapeConfig(
      shape: GuidelineShape.rect,
      bounds: Rect.fromLTWH(50, 100, 300, 200),
    ),
    ShapeConfig(
      shape: GuidelineShape.rect,
      bounds: Rect.fromLTWH(50, 350, 300, 200),
    ),
  ],
  cropConfig: CropConfig(
    mode: CropMode.guideline,
    strategy: CropStrategy.eachShape, // Crop each shape separately
  ),
  processing: ImageProcessingConfig.idCard,
  onCapture: (result) {
    // result.croppedFiles contains 2 images (one for each shape)
    print('Front: ${result.croppedFiles[0].path}');
    print('Back: ${result.croppedFiles[1].path}');
  },
)
```

### Example 6: Accessing All Image Versions

```dart
onCapture: (result) async {
  // Original unmodified image
  if (result.originalFile != null) {
    print('Original: ${result.originalFile!.path}');
  }

  // Cropped images (if cropping was enabled)
  if (result.croppedFiles.isNotEmpty) {
    print('Cropped images: ${result.croppedFiles.length}');
    for (final cropped in result.croppedFiles) {
      print('  - ${cropped.path}');
    }
  }

  // Processed image (if processing was enabled)
  if (result.processedFile != null) {
    print('Processed: ${result.processedFile!.path}');
  }

  // Final image (processed > cropped > original)
  print('Final: ${result.file.path}');

  // Use the final processed image
  await uploadToServer(result.file);
}
```

---

## Manual Processing

You can also manually process images after capture using the controller methods.

### Process an Image

```dart
final captured = await controller.capture();
if (captured != null) {
  // Apply document scan processing
  final processed = await controller.processImage(
    captured,
    ImageProcessingConfig.documentScan,
  );

  print('Processed: ${processed.path}');
}
```

### Crop an Image

```dart
final captured = await controller.capture();
if (captured != null) {
  // Manually crop to specific region
  final cropped = await controller.cropImage(
    captured,
    x: 100,
    y: 100,
    width: 400,
    height: 300,
  );

  print('Cropped: ${cropped.path}');
}
```

### Combined Manual Processing

```dart
final captured = await controller.capture();
if (captured != null) {
  // First crop
  final cropped = await controller.cropImage(
    captured,
    x: 50,
    y: 50,
    width: 500,
    height: 400,
  );

  // Then process
  final processed = await controller.processImage(
    cropped,
    ImageProcessingConfig(
      enabled: true,
      grayscale: true,
      autoEnhance: true,
      sharpen: true,
    ),
  );

  print('Final: ${processed.path}');
}
```

---

## Best Practices

### 1. Use Guideline Mode

`CropMode.guideline` is ideal for:
- Precise document capture with visual guidance
- Consistent crop boundaries across captures
- All document types (ID cards, passports, receipts, etc.)
- Any background complexity

### 2. Optimize Processing Settings

- **For documents**: Use `ImageProcessingConfig.documentScan`
- **For ID cards**: Use `ImageProcessingConfig.idCard`
- **For custom needs**: Start with a preset and adjust

### 3. Handle Multiple Image Versions

```dart
onCapture: (result) {
  // Prefer processed over cropped over original
  final bestImage = result.processedFile ??
                    (result.croppedFiles.isNotEmpty
                      ? result.croppedFiles.first
                      : result.file);

  // Keep original for comparison or backup
  if (result.originalFile != null) {
    await saveBackup(result.originalFile!);
  }

  // Use the best image for main purpose
  await uploadToServer(bestImage);
}
```

### 4. Use Padding for Safety

Add small padding to avoid cutting off edges:

```dart
cropConfig: CropConfig(
  padding: 5.0, // 5 pixels padding around crop area
)
```

---

## Performance Considerations

### Processing Time

Image processing and cropping are performed asynchronously and typically complete in:

- **Cropping**: 50-200ms (depending on image size)
- **Image processing**: 200-1000ms (depending on filters applied)

### Memory Usage

The `image` package processes images in memory. For typical mobile camera resolutions:

- **Low resolution (1280x720)**: ~5MB memory
- **Medium resolution (1920x1080)**: ~10MB memory
- **High resolution (3840x2160)**: ~40MB memory

### Optimization Tips

1. **Use medium resolution**: The controller already uses `ResolutionPreset.medium` by default, which provides a good balance.

2. **Disable unnecessary processing**: Only enable filters you need.

```dart
// Good: Only essential processing
processing: ImageProcessingConfig(
  enabled: true,
  autoEnhance: true,
  sharpen: true,
)

// Avoid: Too many filters
processing: ImageProcessingConfig(
  enabled: true,
  autoEnhance: true,
  grayscale: true,
  brightness: 0.2,
  contrast: 0.2,
  saturation: 0.1,
  reduceNoise: true,
  sharpen: true,
)
```

3. **Process in background**: The processing is already async, but consider showing a loading indicator:

```dart
onCapture: (result) async {
  showLoadingDialog();

  // Processing happens here
  await uploadToServer(result.file);

  hideLoadingDialog();
}
```

### Image Quality vs File Size

Adjust the `quality` parameter to balance quality and file size:

```dart
processing: ImageProcessingConfig(
  enabled: true,
  quality: 95, // Higher quality, larger file (~500KB)
  // quality: 85, // Good quality, medium file (~200KB)
  // quality: 75, // Acceptable quality, smaller file (~100KB)
)
```

---

## Troubleshooting

### Images Too Dark/Light

**Problem**: Processed images are too dark or too bright.

**Solutions**:
1. Use `autoEnhance: true` for automatic adjustment
2. Manually adjust `brightness` parameter

### Cropping Cuts Off Content

**Problem**: Auto-crop is cutting off important parts of the document.

**Solutions**:
1. Add padding: `CropConfig(padding: 10.0)`
2. Increase overlay size relative to screen
3. Ensure document is properly aligned with the guideline overlay

### Performance Issues

**Problem**: Processing takes too long.

**Solutions**:
1. Reduce image resolution (already optimized with medium preset)
2. Disable unnecessary filters
3. Use simpler processing configurations
4. Consider manual processing only when needed

---

## Migration Guide

### From v0.0.3 to v0.1.0

The new features are completely backward compatible. Existing code will work without changes.

**Before (v0.0.3)**:
```dart
GuidelineOverlayConfig(
  shape: GuidelineShape.rect,
  aspectRatio: 1.586,
)
```

**After (v0.1.0)** - Same code still works:
```dart
GuidelineOverlayConfig(
  shape: GuidelineShape.rect,
  aspectRatio: 1.586,
  // Auto-crop is enabled by default
  // No processing by default
)
```

**To opt-in to new features**:
```dart
GuidelineOverlayConfig(
  shape: GuidelineShape.rect,
  aspectRatio: 1.586,
  cropConfig: CropConfig(enabled: true), // Explicitly enable crop
  processing: ImageProcessingConfig.documentScan, // Add processing
)
```

**To disable auto-crop** (get old behavior):
```dart
GuidelineOverlayConfig(
  shape: GuidelineShape.rect,
  cropConfig: CropConfig(enabled: false),
)
```

---

## API Reference

For detailed API documentation, see:

- [`CropConfig`](lib/src/crop_config.dart) - Cropping configuration
- [`CropMode`](lib/src/crop_config.dart) - Crop mode enum
- [`CropStrategy`](lib/src/crop_config.dart) - Multi-shape strategy enum
- [`ImageProcessingConfig`](lib/src/processing_config.dart) - Processing configuration
- [`GuidelineCaptureResult`](lib/src/results.dart) - Extended capture result
- [`GuidelineCamController`](lib/src/controller.dart) - Controller with processing methods

---

## Support

If you encounter issues or have questions:

- [Report an issue](https://github.com/ricky-irfandi/guideline-cam/issues)
- [View examples](example/)
- [Read the main README](README.md)
