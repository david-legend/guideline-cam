/// Defines how the image should be cropped after capture.
enum CropMode {
  /// Crop based on the guideline overlay shape boundaries.
  guideline,
}

/// Strategy for handling multi-shape or nested shape cropping.
enum CropStrategy {
  /// Crop to the outermost shape boundary (default).
  /// Returns a single cropped image containing all shapes.
  outermost,

  /// Crop each shape separately.
  /// Returns multiple cropped images, one for each shape.
  eachShape,
}

/// Configuration for automatic image cropping.
class CropConfig {
  /// Whether to enable automatic cropping. Default is true.
  final bool enabled;

  /// The cropping mode to use.
  final CropMode mode;

  /// Strategy for handling multiple or nested shapes.
  final CropStrategy strategy;

  /// Padding to add around the detected crop area in pixels.
  /// Useful to avoid cutting off edges. Default is 0.
  final double padding;

  const CropConfig({
    this.enabled = true,
    this.mode = CropMode.guideline,
    this.strategy = CropStrategy.outermost,
    this.padding = 0.0,
  }) : assert(padding >= 0.0 && padding <= 1000.0,
            'Padding must be between 0 and 1000 pixels. '
            'Large padding values can cause crop regions to become invalid.');

  /// Creates a copy of this config with the given fields replaced.
  CropConfig copyWith({
    bool? enabled,
    CropMode? mode,
    CropStrategy? strategy,
    double? padding,
  }) {
    return CropConfig(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      strategy: strategy ?? this.strategy,
      padding: padding ?? this.padding,
    );
  }
}
