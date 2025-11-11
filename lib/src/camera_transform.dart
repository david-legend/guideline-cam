import 'dart:math' as math;
import 'dart:ui' as ui;

/// A utility class that handles coordinate transformation from screen space
/// (where the overlay is drawn) to image space (where cropping occurs).
///
/// This class accounts for:
/// * Camera sensor orientation (rotation)
/// * Preview vs capture resolution differences
/// * Non-uniform scaling on different axes
/// * Device orientation changes
///
/// ## Why Transformation Matrices Are Needed
///
/// Camera preview and captured images have different characteristics:
/// * **Preview**: Rendered at screen resolution (e.g., 390x844)
/// * **Capture**: High resolution from sensor (e.g., 4000x3000)
/// * **Rotation**: Sensor may be rotated relative to screen (0°, 90°, 180°, 270°)
/// * **Aspect Ratio**: Screen and sensor may have different ratios
///
/// Simple linear scaling (`imageWidth / screenWidth`) fails because:
/// 1. It doesn't account for rotation
/// 2. It assumes uniform scaling on both axes
/// 3. It ignores sensor orientation metadata
///
/// ## Usage Example
///
/// ```dart
/// final transform = CameraTransform(
///   previewSize: Size(390, 844),
///   captureSize: Size(4000, 3000),
///   sensorOrientation: 90,
/// );
///
/// // Transform screen bounds to image coordinates
/// final screenBounds = Rect.fromLTWH(50, 100, 300, 200);
/// final imageBounds = transform.transformBounds(screenBounds);
///
/// // Use imageBounds for cropping the captured image
/// ```
class CameraTransform {
  /// Creates a camera coordinate transformation.
  ///
  /// Parameters:
  /// * [previewSize] - The size of the camera preview widget on screen
  /// * [captureSize] - The resolution of the captured image
  /// * [sensorOrientation] - Camera sensor orientation in degrees (0, 90, 180, 270)
  const CameraTransform({
    required this.previewSize,
    required this.captureSize,
    required this.sensorOrientation,
  });

  /// The size of the camera preview as rendered on screen.
  ///
  /// This is the size of the area where the overlay guideline is drawn.
  /// Typically matches the screen dimensions or a portion of it.
  final ui.Size previewSize;

  /// The resolution of the captured image from the camera sensor.
  ///
  /// This is usually much higher than the preview size (e.g., 4000x3000).
  /// The actual dimensions depend on the device camera hardware.
  final ui.Size captureSize;

  /// The camera sensor orientation in degrees.
  ///
  /// Common values:
  /// * 0° - Sensor aligned with device (rare)
  /// * 90° - Sensor rotated 90° clockwise (most common on phones)
  /// * 180° - Sensor rotated 180°
  /// * 270° - Sensor rotated 270° (or 90° counter-clockwise)
  ///
  /// This value comes from `CameraController.value.deviceOrientation` or
  /// camera description metadata.
  final int sensorOrientation;

  /// Transforms a rectangle from screen coordinates to image coordinates.
  ///
  /// Takes a [Rect] representing the overlay bounds on screen and returns
  /// a [Rect] representing the corresponding region in the captured image.
  ///
  /// This method handles:
  /// * Rotation based on sensor orientation
  /// * Scaling from preview to capture resolution
  /// * Proper coordinate system transformation
  ///
  /// Example:
  /// ```dart
  /// final screenBounds = Rect.fromLTWH(50, 100, 300, 200);
  /// final imageBounds = transform.transformBounds(screenBounds);
  /// // imageBounds is now in captured image coordinates
  /// ```
  ui.Rect transformBounds(ui.Rect screenBounds) {
    // Handle rotation first - sensor orientation affects how we map coordinates
    final needsRotation = sensorOrientation == 90 || sensorOrientation == 270;

    // Determine which dimensions to use based on rotation
    final effectivePreviewWidth = needsRotation ? previewSize.height : previewSize.width;
    final effectivePreviewHeight = needsRotation ? previewSize.width : previewSize.height;
    final effectiveCaptureWidth = needsRotation ? captureSize.height : captureSize.width;
    final effectiveCaptureHeight = needsRotation ? captureSize.width : captureSize.height;

    // Calculate scale factors - use UNIFORM scaling to preserve aspect ratio
    // Use the minimum scale to ensure the overlay fits within the captured image
    final scaleX = effectiveCaptureWidth / effectivePreviewWidth;
    final scaleY = effectiveCaptureHeight / effectivePreviewHeight;
    final uniformScale = math.min(scaleX, scaleY);

    // Calculate offset for centering (if aspect ratios don't match)
    final scaledPreviewWidth = effectivePreviewWidth * uniformScale;
    final scaledPreviewHeight = effectivePreviewHeight * uniformScale;
    final offsetX = (effectiveCaptureWidth - scaledPreviewWidth) / 2;
    final offsetY = (effectiveCaptureHeight - scaledPreviewHeight) / 2;

    // Transform the bounds based on sensor orientation
    double left, top, width, height;

    switch (sensorOrientation) {
      case 90:
        // Rotate 90° clockwise: x' = y, y' = width - x
        left = screenBounds.top * uniformScale + offsetX;
        top = (previewSize.width - screenBounds.right) * uniformScale + offsetY;
        width = screenBounds.height * uniformScale;
        height = screenBounds.width * uniformScale;
        break;

      case 180:
        // Rotate 180°: x' = width - x, y' = height - y
        left = (previewSize.width - screenBounds.right) * uniformScale + offsetX;
        top = (previewSize.height - screenBounds.bottom) * uniformScale + offsetY;
        width = screenBounds.width * uniformScale;
        height = screenBounds.height * uniformScale;
        break;

      case 270:
        // Rotate 270° clockwise (90° counter-clockwise): x' = height - y, y' = x
        left = (previewSize.height - screenBounds.bottom) * uniformScale + offsetX;
        top = screenBounds.left * uniformScale + offsetY;
        width = screenBounds.height * uniformScale;
        height = screenBounds.width * uniformScale;
        break;

      case 0:
      default:
        // No rotation needed
        left = screenBounds.left * uniformScale + offsetX;
        top = screenBounds.top * uniformScale + offsetY;
        width = screenBounds.width * uniformScale;
        height = screenBounds.height * uniformScale;
        break;
    }

    return ui.Rect.fromLTWH(left, top, width, height);
  }

  /// Gets the transformation matrix for this camera configuration.
  ///
  /// This method builds a [Matrix4] that can be used for more complex
  /// transformations or debugging purposes. For most use cases,
  /// [transformBounds] is more convenient.
  ///
  /// The matrix applies:
  /// 1. Translation to origin
  /// 2. Rotation based on sensor orientation
  /// 3. Scaling to capture dimensions
  /// 4. Translation back
  ///
  /// Returns a [Matrix4] representing the complete transformation.
  Matrix4 getTransformMatrix() {
    final matrix = Matrix4.identity();

    // Calculate scale factors
    final scaleX = captureSize.width / previewSize.width;
    final scaleY = captureSize.height / previewSize.height;

    // Apply rotation around center if needed
    if (sensorOrientation != 0) {
      // Translate to origin (center of preview)
      matrix.translate(-previewSize.width / 2, -previewSize.height / 2);

      // Rotate based on sensor orientation
      final radians = (sensorOrientation * math.pi) / 180.0;
      matrix.rotateZ(radians);

      // Scale to capture dimensions
      matrix.scale(scaleX, scaleY);

      // Translate back (center of capture)
      matrix.translate(captureSize.width / 2, captureSize.height / 2);
    } else {
      // No rotation, just scale
      matrix.scale(scaleX, scaleY);
    }

    return matrix;
  }

  /// Calculates the aspect ratio difference between preview and capture.
  ///
  /// Returns a value representing how much the aspect ratios differ:
  /// * 1.0 means identical aspect ratios
  /// * < 1.0 means capture is narrower than preview
  /// * > 1.0 means capture is wider than preview
  ///
  /// This can be useful for debugging or adjusting UI elements.
  double get aspectRatioDifference {
    final previewRatio = previewSize.width / previewSize.height;
    final captureRatio = captureSize.width / captureSize.height;
    return captureRatio / previewRatio;
  }

  @override
  String toString() {
    return 'CameraTransform('
        'preview: ${previewSize.width.toInt()}x${previewSize.height.toInt()}, '
        'capture: ${captureSize.width.toInt()}x${captureSize.height.toInt()}, '
        'orientation: $sensorOrientation°, '
        'aspectRatioDiff: ${aspectRatioDifference.toStringAsFixed(2)})';
  }
}

/// A simple implementation of Matrix4 for transformation matrices.
///
/// This is a minimal implementation focusing on the transformations needed
/// for camera coordinate conversion. Uses column-major ordering like OpenGL.
class Matrix4 {
  /// Creates an identity matrix.
  Matrix4.identity() : _m = List.filled(16, 0.0) {
    _m[0] = 1.0;
    _m[5] = 1.0;
    _m[10] = 1.0;
    _m[15] = 1.0;
  }

  /// The internal matrix storage (column-major order).
  final List<double> _m;

  /// Translates the matrix by (x, y, z).
  void translate(double x, [double y = 0.0, double z = 0.0]) {
    _m[12] += x;
    _m[13] += y;
    _m[14] += z;
  }

  /// Rotates the matrix around the Z axis by [radians].
  void rotateZ(double radians) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);

    final m00 = _m[0];
    final m01 = _m[1];
    final m10 = _m[4];
    final m11 = _m[5];

    _m[0] = m00 * cos + m10 * sin;
    _m[1] = m01 * cos + m11 * sin;
    _m[4] = m10 * cos - m00 * sin;
    _m[5] = m11 * cos - m01 * sin;
  }

  /// Scales the matrix by (x, y, z).
  void scale(double x, [double? y, double? z]) {
    final sy = y ?? x;
    final sz = z ?? 1.0;

    _m[0] *= x;
    _m[5] *= sy;
    _m[10] *= sz;
  }

  /// Gets the matrix data as a list.
  List<double> get storage => _m;

  @override
  String toString() {
    return 'Matrix4(\n'
        '  [${_m[0].toStringAsFixed(2)}, ${_m[4].toStringAsFixed(2)}, ${_m[8].toStringAsFixed(2)}, ${_m[12].toStringAsFixed(2)}],\n'
        '  [${_m[1].toStringAsFixed(2)}, ${_m[5].toStringAsFixed(2)}, ${_m[9].toStringAsFixed(2)}, ${_m[13].toStringAsFixed(2)}],\n'
        '  [${_m[2].toStringAsFixed(2)}, ${_m[6].toStringAsFixed(2)}, ${_m[10].toStringAsFixed(2)}, ${_m[14].toStringAsFixed(2)}],\n'
        '  [${_m[3].toStringAsFixed(2)}, ${_m[7].toStringAsFixed(2)}, ${_m[11].toStringAsFixed(2)}, ${_m[15].toStringAsFixed(2)}]\n'
        ')';
  }
}
