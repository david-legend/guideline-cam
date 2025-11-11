import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'processing_config.dart';

/// Core image processing engine.
class ImageProcessor {
  /// Maximum image dimension (width or height) to prevent OOM.
  /// Images larger than this will be downsampled before processing.
  static const int maxImageDimension = 4096;

  /// Default JPEG quality for cropped images (0-100).
  static const int defaultCropQuality = 95;

  /// Minimum valid dimension for crop region (width or height).
  static const int minValidCropDimension = 1;

  /// Threshold for auto-enhancement. If dynamic range is below this, apply enhancement.
  static const int autoEnhanceThreshold = 200;

  /// Low percentile for histogram analysis (1st percentile).
  static const double histogramLowPercentile = 0.01;

  /// High percentile for histogram analysis (99th percentile).
  static const double histogramHighPercentile = 0.99;

  /// ITU-R BT.601 luminance coefficient for red channel.
  static const double luminanceRedCoeff = 0.299;

  /// ITU-R BT.601 luminance coefficient for green channel.
  static const double luminanceGreenCoeff = 0.587;

  /// ITU-R BT.601 luminance coefficient for blue channel.
  static const double luminanceBlueCoeff = 0.114;

  /// Process an image file according to the given configuration.
  /// Returns a new XFile with the processed image.
  static Future<XFile> processImage(
    XFile file,
    ImageProcessingConfig config,
  ) async {
    if (!config.enabled) {
      return file;
    }

    // Read image from file
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Image file is empty: ${file.path}');
    }

    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image from ${file.path}. File may be corrupted or in an unsupported format.');
    }

    // Downsample if image is too large to prevent OOM
    image = _downsampleIfNeeded(image);

    // Apply processing steps in order
    if (config.autoEnhance) {
      image = await _autoEnhance(image);
    }

    if (config.brightness != 0.0) {
      image = _adjustBrightness(image, config.brightness);
    }

    if (config.contrast != 0.0) {
      image = _adjustContrast(image, config.contrast);
    }

    if (config.grayscale) {
      image = _toGrayscale(image);
    } else if (config.saturation != 0.0) {
      image = _adjustSaturation(image, config.saturation);
    }

    if (config.reduceNoise) {
      image = _reduceNoise(image, config.noiseReductionStrength);
    }

    if (config.sharpen) {
      image = await _sharpen(image, config.sharpenStrength);
    }

    // Encode with specified quality
    final processedBytes = img.encodeJpg(image, quality: config.quality);

    // Save to temporary file
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempFile = File('${tempDir.path}/processed_$timestamp.jpg');
    await tempFile.writeAsBytes(processedBytes);

    return XFile(tempFile.path);
  }

  /// Downsamples an image if either dimension exceeds [maxImageDimension].
  ///
  /// This prevents out-of-memory errors when processing very large images.
  /// The image is scaled down proportionally to fit within the max dimension
  /// while maintaining aspect ratio.
  ///
  /// Parameters:
  /// * [image] - The image to potentially downsample
  ///
  /// Returns the downsampled image, or the original if no downsampling needed.
  static img.Image _downsampleIfNeeded(img.Image image) {
    final maxDim = math.max(image.width, image.height);

    if (maxDim <= maxImageDimension) {
      // Image is within acceptable size limits
      return image;
    }

    // Calculate scale factor to fit within max dimension
    final scale = maxImageDimension / maxDim;
    final newWidth = (image.width * scale).round();
    final newHeight = (image.height * scale).round();

    // Use high-quality interpolation for downsampling
    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.average,
    );
  }

  /// Convert image to grayscale.
  static img.Image _toGrayscale(img.Image image) {
    return img.grayscale(image);
  }

  /// Adjust brightness (-1.0 to 1.0).
  static img.Image _adjustBrightness(img.Image image, double brightness) {
    // Convert brightness from -1.0..1.0 to multiplier
    final offset = (brightness * 100).round();
    return img.adjustColor(image, brightness: offset.toDouble());
  }

  /// Adjust contrast (-1.0 to 1.0).
  static img.Image _adjustContrast(img.Image image, double contrast) {
    // Convert contrast from -1.0..1.0 to multiplier
    final factor = (contrast + 1.0) * 100;
    return img.adjustColor(image, contrast: factor);
  }

  /// Adjust saturation (-1.0 to 1.0).
  static img.Image _adjustSaturation(img.Image image, double saturation) {
    // Convert saturation from -1.0..1.0 to multiplier
    final factor = (saturation + 1.0) * 100;
    return img.adjustColor(image, saturation: factor);
  }

  /// Apply noise reduction using median filter.
  static img.Image _reduceNoise(
    img.Image image,
    int strength,
  ) {
    // Use median filter blur for noise reduction
    // Strength 1-10 maps to radius 1-5
    final radius = ((strength / 2) + 0.5).round();
    return img.gaussianBlur(image, radius: radius);
  }

  /// Apply sharpening filter.
  /// Runs in separate isolate to avoid blocking UI thread.
  static Future<img.Image> _sharpen(img.Image image, double strength) async {
    return compute(_sharpenIsolate, _SharpenParams(image, strength));
  }

  /// Auto-enhance image (brightness and contrast).
  /// Runs in separate isolate to avoid blocking UI thread.
  static Future<img.Image> _autoEnhance(img.Image image) async {
    return compute(_autoEnhanceIsolate, _AutoEnhanceParams(image));
  }

  /// Crop image to a rectangular region.
  static Future<XFile> cropImage(
    XFile file, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    if (width <= 0 || height <= 0) {
      throw Exception('Invalid crop dimensions: width=$width, height=$height. Both must be positive.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Image file is empty: ${file.path}');
    }

    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image from ${file.path}. File may be corrupted or in an unsupported format.');
    }

    // Downsample if image is too large to prevent OOM
    image = _downsampleIfNeeded(image);

    // Ensure crop region is within image bounds
    final cropX = math.max(0, x);
    final cropY = math.max(0, y);
    final cropWidth = math.min(width, image.width - cropX);
    final cropHeight = math.min(height, image.height - cropY);

    // Validate adjusted crop region
    if (cropWidth < minValidCropDimension || cropHeight < minValidCropDimension) {
      throw Exception(
        'Invalid crop region after bounds adjustment: $cropWidth×$cropHeight. '
        'Original request: ($x, $y, $width×$height), Image: ${image.width}×${image.height}'
      );
    }

    if (cropX + cropWidth > image.width || cropY + cropHeight > image.height) {
      throw Exception(
        'Crop region exceeds image bounds: '
        'region ($cropX, $cropY, $cropWidth×$cropHeight) vs image ${image.width}×${image.height}'
      );
    }

    final cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    // Save to temporary file
    final croppedBytes = img.encodeJpg(cropped, quality: defaultCropQuality);
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempFile = File('${tempDir.path}/cropped_$timestamp.jpg');
    await tempFile.writeAsBytes(croppedBytes);

    return XFile(tempFile.path);
  }

  /// Crop image to a circular region.
  static Future<XFile> cropCircular(
    XFile file, {
    required int centerX,
    required int centerY,
    required int radius,
  }) async {
    if (radius <= 0) {
      throw Exception('Invalid radius: $radius. Radius must be positive.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Image file is empty: ${file.path}');
    }

    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image from ${file.path}. File may be corrupted or in an unsupported format.');
    }

    // Create a new image with transparency
    final result = img.Image(
      width: radius * 2,
      height: radius * 2,
      numChannels: 4,
    );

    // Copy pixels within circle
    for (int y = 0; y < radius * 2; y++) {
      for (int x = 0; x < radius * 2; x++) {
        final dx = x - radius;
        final dy = y - radius;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance <= radius) {
          final srcX = centerX + dx;
          final srcY = centerY + dy;

          if (srcX >= 0 && srcX < image.width && srcY >= 0 && srcY < image.height) {
            final pixel = image.getPixel(srcX, srcY);
            result.setPixel(x, y, pixel);
          }
        }
      }
    }

    // Save to temporary file
    final croppedBytes = img.encodePng(result);
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempFile = File('${tempDir.path}/cropped_circular_$timestamp.png');
    await tempFile.writeAsBytes(croppedBytes);

    return XFile(tempFile.path);
  }
}

// ============================================================================
// Isolate-compatible top-level functions for heavy pixel operations
// ============================================================================

/// Parameter class for sharpen isolate operation.
class _SharpenParams {
  final img.Image image;
  final double strength;

  _SharpenParams(this.image, this.strength);
}

/// Parameter class for auto-enhance isolate operation.
class _AutoEnhanceParams {
  final img.Image image;

  _AutoEnhanceParams(this.image);
}

/// Parameter class for auto-levels isolate operation.
class _AutoLevelsParams {
  final img.Image image;
  final int minLevel;
  final int maxLevel;

  _AutoLevelsParams(this.image, this.minLevel, this.maxLevel);
}

/// Top-level function for sharpening in isolate.
img.Image _sharpenIsolate(_SharpenParams params) {
  final image = params.image;
  final strength = params.strength;

  // Use convolution for sharpening
  final blurred = img.gaussianBlur(image, radius: 1);
  final sharpened = img.Image.from(image);

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final original = image.getPixel(x, y);
      final blur = blurred.getPixel(x, y);

      // Unsharp mask: original + strength * (original - blurred)
      final r = _clampIsolate(
        original.r + (strength * (original.r - blur.r)),
        0,
        255,
      );
      final g = _clampIsolate(
        original.g + (strength * (original.g - blur.g)),
        0,
        255,
      );
      final b = _clampIsolate(
        original.b + (strength * (original.b - blur.b)),
        0,
        255,
      );

      sharpened.setPixelRgba(x, y, r.round(), g.round(), b.round(), original.a.round());
    }
  }

  return sharpened;
}

/// Top-level function for auto-enhance in isolate.
img.Image _autoEnhanceIsolate(_AutoEnhanceParams params) {
  final image = params.image;

  // Calculate histogram
  final histogram = List.generate(256, (_) => 0);
  int totalPixels = 0;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final luminance = (ImageProcessor.luminanceRedCoeff * pixel.r +
          ImageProcessor.luminanceGreenCoeff * pixel.g +
          ImageProcessor.luminanceBlueCoeff * pixel.b).round();
      histogram[luminance.clamp(0, 255)]++;
      totalPixels++;
    }
  }

  // Find 1st and 99th percentile for auto-levels
  int accumulated = 0;
  int minLevel = 0;
  int maxLevel = 255;

  for (int i = 0; i < 256; i++) {
    accumulated += histogram[i];
    if (accumulated > totalPixels * ImageProcessor.histogramLowPercentile && minLevel == 0) {
      minLevel = i;
    }
    if (accumulated > totalPixels * ImageProcessor.histogramHighPercentile && maxLevel == 255) {
      maxLevel = i;
      break;
    }
  }

  // Apply auto-levels if there's significant room for improvement
  if (maxLevel - minLevel < ImageProcessor.autoEnhanceThreshold) {
    return _autoLevelsIsolate(_AutoLevelsParams(image, minLevel, maxLevel));
  }

  return image;
}

/// Top-level function for auto-levels in isolate.
img.Image _autoLevelsIsolate(_AutoLevelsParams params) {
  final image = params.image;
  final minLevel = params.minLevel;
  final maxLevel = params.maxLevel;

  final range = maxLevel - minLevel;
  if (range == 0) return image;

  final result = img.Image.from(image);

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);

      final r = _clampIsolate(
        ((pixel.r - minLevel) * 255 / range),
        0,
        255,
      );
      final g = _clampIsolate(
        ((pixel.g - minLevel) * 255 / range),
        0,
        255,
      );
      final b = _clampIsolate(
        ((pixel.b - minLevel) * 255 / range),
        0,
        255,
      );

      result.setPixelRgba(x, y, r.round(), g.round(), b.round(), pixel.a.round());
    }
  }

  return result;
}

/// Clamp function for isolate (duplicate of class method).
double _clampIsolate(double value, double min, double max) {
  return math.max(min, math.min(max, value));
}
