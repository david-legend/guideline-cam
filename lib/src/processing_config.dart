/// Configuration for automatic image processing.
class ImageProcessingConfig {
  /// Whether to enable automatic image processing. Default is false.
  final bool enabled;

  /// Automatically enhance brightness and contrast. Default is false.
  final bool autoEnhance;

  /// Convert image to grayscale. Default is false.
  final bool grayscale;

  /// Brightness adjustment (-1.0 to 1.0, where 0 is no change).
  /// Negative values darken, positive values brighten.
  final double brightness;

  /// Contrast adjustment (-1.0 to 1.0, where 0 is no change).
  /// Negative values reduce contrast, positive values increase contrast.
  final double contrast;

  /// Saturation adjustment (-1.0 to 1.0, where 0 is no change).
  /// Negative values desaturate, positive values saturate.
  /// Ignored if [grayscale] is true.
  final double saturation;

  /// Apply noise reduction filter. Default is false.
  final bool reduceNoise;

  /// Noise reduction strength (1-10, where higher is stronger).
  /// Only applies if [reduceNoise] is true. Default is 3.
  final int noiseReductionStrength;

  /// Apply sharpening filter. Default is false.
  final bool sharpen;

  /// Sharpening strength (0.0 to 2.0, where 1.0 is standard sharpening).
  /// Only applies if [sharpen] is true. Default is 1.0.
  final double sharpenStrength;

  /// Quality for JPEG compression (0-100, where 100 is best quality).
  /// Default is 85.
  final int quality;

  const ImageProcessingConfig({
    this.enabled = false,
    this.autoEnhance = false,
    this.grayscale = false,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.reduceNoise = false,
    this.noiseReductionStrength = 3,
    this.sharpen = false,
    this.sharpenStrength = 1.0,
    this.quality = 85,
  })  : assert(brightness >= -1.0 && brightness <= 1.0,
            'Brightness must be between -1.0 and 1.0'),
        assert(contrast >= -1.0 && contrast <= 1.0,
            'Contrast must be between -1.0 and 1.0'),
        assert(saturation >= -1.0 && saturation <= 1.0,
            'Saturation must be between -1.0 and 1.0'),
        assert(noiseReductionStrength >= 1 && noiseReductionStrength <= 10,
            'Noise reduction strength must be between 1 and 10'),
        assert(sharpenStrength >= 0.0 && sharpenStrength <= 2.0,
            'Sharpen strength must be between 0.0 and 2.0'),
        assert(quality >= 0 && quality <= 100,
            'Quality must be between 0 and 100');

  /// Creates a copy of this config with the given fields replaced.
  ImageProcessingConfig copyWith({
    bool? enabled,
    bool? autoEnhance,
    bool? grayscale,
    double? brightness,
    double? contrast,
    double? saturation,
    bool? reduceNoise,
    int? noiseReductionStrength,
    bool? sharpen,
    double? sharpenStrength,
    int? quality,
  }) {
    return ImageProcessingConfig(
      enabled: enabled ?? this.enabled,
      autoEnhance: autoEnhance ?? this.autoEnhance,
      grayscale: grayscale ?? this.grayscale,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      reduceNoise: reduceNoise ?? this.reduceNoise,
      noiseReductionStrength:
          noiseReductionStrength ?? this.noiseReductionStrength,
      sharpen: sharpen ?? this.sharpen,
      sharpenStrength: sharpenStrength ?? this.sharpenStrength,
      quality: quality ?? this.quality,
    );
  }

  /// Preset for document scanning (grayscale, enhanced, sharpened).
  static const ImageProcessingConfig documentScan = ImageProcessingConfig(
    enabled: true,
    autoEnhance: true,
    grayscale: true,
    sharpen: true,
    sharpenStrength: 1.2,
    quality: 90,
  );

  /// Preset for ID card scanning (color, enhanced, sharp).
  static const ImageProcessingConfig idCard = ImageProcessingConfig(
    enabled: true,
    autoEnhance: true,
    sharpen: true,
    quality: 95,
  );
}
