# 0.0.4

## ✨ Major Feature Release: Auto-Crop & Image Processing

### Auto-Crop Features

- **Guideline-Based Cropping**: `CropMode.guideline` - Crop to exact guideline overlay boundaries (default)
- **Multi-Shape Support**: Configurable crop strategies for nested shapes
  - `CropStrategy.outermost` - Crop to outermost boundary (default)
  - `CropStrategy.eachShape` - Crop each shape separately, return multiple images
- **Optional Padding**: Add padding around crop area to avoid edge cutoff
- **Thread-Safe Operations**: Concurrent-safe temp file management with proper locking
- **Cancellation Support**: Stop ongoing operations when navigating away

### Image Processing Features

- **Grayscale Conversion**: Convert images to grayscale or black & white
- **Auto-Enhancement**: Automatic brightness and contrast optimization using histogram analysis (runs in isolate)
- **Manual Adjustments**: Fine-grained control over brightness, contrast, and saturation (-1.0 to 1.0)
- **Noise Reduction**: Gaussian blur-based noise filtering with adjustable strength (1-10)
- **Sharpening**: Unsharp mask for image sharpening with adjustable strength (0.0-2.0) (runs in isolate)
- **Quality Control**: Configurable JPEG compression quality (0-100)
- **Built-in Presets**:
  - `ImageProcessingConfig.documentScan` - Grayscale, enhanced, sharpened (perfect for documents)
  - `ImageProcessingConfig.idCard` - Color, enhanced, sharpened (optimized for ID cards)
- **Non-Blocking UI**: Heavy pixel operations run in separate isolates to maintain smooth UI

### API Enhancements

- **Static API Crop & Processing Support**:
  - `GuidelineCam.takePhoto()` now supports `enableCrop` parameter (default: false)
  - `GuidelineCam.takePhoto()` now supports `enableProcessing` parameter (default: false)
  - Both features are opt-in for backward compatibility
  - Crop always uses outermost strategy in static API (returns single XFile)
- **New `GuidelineCaptureResult` fields**:
  - `originalFile` - Original unmodified capture
  - `croppedFiles` - List of cropped images
  - `processedFile` - Final processed image
  - `file` - Best available version (processed > cropped > original)
- **New Controller Methods**:
  - `captureWithProcessing()` - Capture with automatic crop and processing
  - `processImage(file, config)` - Manually process an image
  - `cropImage(file, x, y, width, height)` - Manually crop an image
  - `setConfig(config)` - Set configuration for auto-crop and processing
- **New Configuration Classes**:
  - `CropConfig` - Auto-crop configuration
  - `ImageProcessingConfig` - Image processing configuration

### Configuration

- Added `cropConfig` parameter to `GuidelineOverlayConfig` (default: auto-crop enabled)
- Added `processing` parameter to `GuidelineOverlayConfig` (default: null/disabled)
- Added `copyWith()` method to `GuidelineOverlayConfig` for easy config modification
- Added `copyWith()` method to `CropConfig` for easy config modification

### Robustness

- **Thread Safety**: Lock-based synchronization for temp file management prevents race conditions
- **Input Validation**: Comprehensive validation on overlay bounds and crop padding (0-1000px)
- **Memory Safety**: Automatic image downsampling (4096px limit) prevents out-of-memory crashes
- **Error Reporting**: Detailed error tracking in `GuidelineCaptureResult` (cropError, processingError fields)
- **Resource Management**: Cancellable operations support clean teardown on navigation
- **Constants**: All magic numbers replaced with documented constants

### Performance Optimizations

- **Isolate-Based Processing**: Heavy pixel operations (sharpening, auto-enhance) run in background isolates
- **Smart Cleanup**: Async temp file cleanup with proper locking mechanism
- **OOM Prevention**: 4096×4096 max dimension with automatic downsampling
- **Non-Blocking**: Maintains 60fps UI during image processing

### Dependencies

- Added `image: ^4.0.0` - Pure Dart image processing library
- Added `synchronized: ^3.1.0+1` - Lock-based synchronization for thread safety
- Added `async: ^2.11.0` - Cancellable operations support

### Documentation

- Added comprehensive `autocrop.md` guide covering all crop and processing features
- Updated `README.md` with new features section
- Updated `llms.txt` with complete API reference for new features
- Added usage examples for document scanning, ID card capture, and manual processing

### Breaking Changes

- None - All new features are opt-in and fully backward compatible
- Existing code works without modifications
- Default behavior: auto-crop enabled (can be disabled with `CropConfig(enabled: false)`)

### Performance

- Image processing is fully asynchronous and non-blocking (runs in isolates)
- Processing time: 200-1000ms depending on filters applied (off main thread)
- Memory capped at ~48MB per image (4096×4096 max)
- Memory efficient with automatic cleanup of temporary files (thread-safe)
- Concurrent operations properly synchronized

# 0.0.3

- Added `GuidelineCam.takePhoto()` static method for simplified camera capture
- Zero boilerplate API - no need to manage controllers or lifecycle manually
- Automatic resource management and cleanup
- Full-screen camera capture interface with customizable overlays
- Returns `XFile?` containing the captured photo or null if cancelled
- Includes default capture button, flash toggle, and camera switch controls
- Supports custom overlay configurations and instruction builders
- Maintains backward compatibility with existing `GuidelineCamBuilder` approach
- Changed default `cornerLength` from 20.0 to 0.0 for minimal corner indicators
- Corner indicators now disabled by default for cleaner overlay appearance

# 0.0.2

- Added `llms.txt`: comprehensive documentation for AI/LLM systems to understand package structure, API, and usage patterns.
- Fixed GIF image not displaying on pub.dev by using absolute URLs.

# 0.0.1

- Initial release of the `guideline_cam` package.
- Camera preview with customizable overlays: rect, roundedRect, circle, oval.
- Multi-shape overlays with unified mask.
- Nested child shapes (absolute, center, relative, inset positioning) with absolute or relative sizing.
- Configurable: aspectRatio, frameColor, strokeWidth, maskColor, borderRadius, cornerLength.
- Optional 3x3 grid and L-corner indicators for rectangular frames.
- Customizable flash and camera switch buttons via builders.
- Full `overlayBuilder` to replace the default overlay UI.
- Debug paint mode for development.
