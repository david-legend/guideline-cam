import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:async/async.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import 'package:guideline_cam/src/config.dart';
import 'package:guideline_cam/src/crop_config.dart';
import 'package:guideline_cam/src/debug_logger.dart';
import 'package:guideline_cam/src/enums.dart';
import 'package:guideline_cam/src/image_processor.dart';
import 'package:guideline_cam/src/processing_config.dart';
import 'package:guideline_cam/src/results.dart';
import 'package:image/image.dart' as img;

/// A controller for the [GuidelineCamBuilder] widget.
///
/// This controller manages the camera lifecycle, state, and capture functionality.
/// It provides methods to initialize the camera, capture images, switch cameras,
/// and control flash settings.
///
/// ## Lifecycle
///
/// The controller follows this lifecycle:
/// 1. **Initialization**: Call [initialize()] to set up the camera
/// 2. **Ready State**: Camera is ready for capture operations
/// 3. **Capture**: Use [capture()] to take photos
/// 4. **Disposal**: Call [dispose()] to clean up resources
///
/// ## State Management
///
/// The controller notifies listeners of state changes through:
/// * [state] - Current state of the controller
/// * [stateStream] - Stream of state changes
/// * [ChangeNotifier.notifyListeners] - For UI updates
///
/// ## Example Usage
///
/// ```dart
/// class CameraPage extends StatefulWidget {
///   @override
///   _CameraPageState createState() => _CameraPageState();
/// }
///
/// class _CameraPageState extends State<CameraPage> {
///   late GuidelineCamController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = GuidelineCamController();
///     _controller.addListener(_onControllerStateChanged);
///     _initializeCamera();
///   }
///
///   void _onControllerStateChanged() {
///     if (_controller.state == GuidelineState.error) {
///       // Handle error state
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text('Camera error occurred')),
///       );
///     }
///   }
///
///   Future<void> _initializeCamera() async {
///     try {
///       await _controller.initialize();
///     } catch (e) {
///       // Handle initialization error
///       print('Failed to initialize camera: $e');
///     }
///   }
///
///   Future<void> _captureImage() async {
///     try {
///       final result = await _controller.capture();
///       if (result != null) {
///         // Process captured image
///         print('Image captured: ${result.path}');
///       }
///     } catch (e) {
///       // Handle capture error
///       print('Failed to capture image: $e');
///     }
///   }
///
///   @override
///   void dispose() {
///     _controller.removeListener(_onControllerStateChanged);
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return GuidelineCamBuilder(
///       controller: _controller,
///       onCapture: (result) {
///         // Handle capture result
///         print('Captured at: ${result.capturedAt}');
///       },
///     );
///   }
/// }
/// ```
///
/// See also:
/// * [GuidelineCamBuilder], the widget that uses this controller
/// * [GuidelineState], for available states
/// * [GuidelineCaptureResult], for capture results
class GuidelineCamController extends ChangeNotifier {
  /// The underlying camera controller.
  CameraController? _cameraController;

  /// The current state of the controller.
  GuidelineState _state = GuidelineState.initializing;

  /// A stream of guideline states.
  final StreamController<GuidelineState> _stateStreamController =
      StreamController.broadcast();

  /// The current flash mode.
  FlashMode _flashMode = FlashMode.off;

  /// The current camera lens direction.
  CameraLensDirection _lensDirection = CameraLensDirection.back;

  /// The current guideline configuration (for cropping and processing).
  GuidelineOverlayConfig? _config;

  /// The overlay bounds for guideline-based cropping.
  ui.Rect? _overlayBounds;

  /// Individual shape bounds for multi-shape cropping (used with eachShape strategy).
  List<ui.Rect>? _shapeBounds;

  /// The screen/widget size where the overlay is drawn.
  ui.Size? _screenSize;

  /// The camera description for accessing sensor information.
  CameraDescription? _cameraDescription;

  /// Set of temporary files created during processing that need cleanup.
  final Set<String> _tempFiles = {};

  /// Lock for thread-safe access to temp files.
  final Lock _tempFilesLock = Lock();

  /// Current ongoing processing operation (for cancellation support).
  CancelableOperation<GuidelineCaptureResult?>? _processingOperation;

  /// Maximum image dimension (width or height) to prevent OOM.
  /// Images larger than this will be downsampled.
  static const int maxImageDimension = 4096;

  /// Minimum acceptable crop dimension (width or height) in pixels.
  /// Crop regions smaller than this are likely invalid.
  static const int minCropDimension = 10;

  /// Default JPEG quality for cropped images (0-100).
  static const int defaultCropQuality = 95;

  /// Creates a new [GuidelineCamController] with optional initial camera direction.
  ///
  /// Parameters:
  /// * [initialCameraDirection] - The initial camera direction to use. Defaults to `CameraLensDirection.back`.
  ///
  /// Example:
  /// ```dart
  /// // Default back camera
  /// final controller = GuidelineCamController();
  ///
  /// // Start with front camera
  /// final controller = GuidelineCamController(
  ///   initialCameraDirection: CameraLensDirection.front,
  /// );
  /// ```
  GuidelineCamController({
    CameraLensDirection initialCameraDirection = CameraLensDirection.back,
  }) : _lensDirection = initialCameraDirection;

  /// The underlying camera controller from the camera package.
  ///
  /// This provides direct access to the [CameraController] for advanced
  /// camera operations. Use with caution as direct manipulation may
  /// interfere with the guideline camera's state management.
  ///
  /// Returns `null` if the camera has not been initialized yet.
  ///
  /// See also:
  /// * [CameraController], for the underlying camera controller
  CameraController? get cameraController => _cameraController;

  /// The current state of the camera controller.
  ///
  /// This property indicates the current operational state of the camera:
  /// * [GuidelineState.initializing] - Camera is being set up
  /// * [GuidelineState.ready] - Camera is ready for capture
  /// * [GuidelineState.capturing] - Camera is currently taking a picture
  /// * [GuidelineState.error] - An error has occurred
  ///
  /// Example:
  /// ```dart
  /// if (controller.state == GuidelineState.ready) {
  ///   // Safe to capture images
  ///   await controller.capture();
  /// }
  /// ```
  ///
  /// See also:
  /// * [stateStream], for listening to state changes
  /// * [GuidelineState], for all available states
  GuidelineState get state => _state;

  /// A broadcast stream of guideline state changes.
  ///
  /// This stream emits a new [GuidelineState] whenever the controller's
  /// state changes. It's useful for reactive UI updates and state monitoring.
  ///
  /// Example:
  /// ```dart
  /// controller.stateStream.listen((state) {
  ///   switch (state) {
  ///     case GuidelineState.ready:
  ///       // Enable capture button
  ///       break;
  ///     case GuidelineState.error:
  ///       // Show error message
  ///       break;
  ///   }
  /// });
  /// ```
  ///
  /// See also:
  /// * [state], for the current state
  /// * [GuidelineState], for available states
  Stream<GuidelineState> get stateStream => _stateStreamController.stream;

  /// The current flash mode setting.
  ///
  /// This property indicates how the camera flash is currently configured:
  /// * [FlashMode.off] - Flash is disabled
  /// * [FlashMode.always] - Flash is always on
  /// * [FlashMode.auto] - Flash is automatically controlled
  /// * [FlashMode.torch] - Flash is used as a torch (always on)
  ///
  /// Example:
  /// ```dart
  /// if (controller.flashMode == FlashMode.off) {
  ///   // Show flash off icon
  /// }
  /// ```
  ///
  /// See also:
  /// * [setFlashMode()], to change the flash mode
  /// * [FlashMode], for all available flash modes
  FlashMode get flashMode => _flashMode;

  /// The current camera lens direction.
  ///
  /// This property indicates which camera lens is currently active:
  /// * [CameraLensDirection.back] - Back/rear camera (default)
  /// * [CameraLensDirection.front] - Front/selfie camera
  ///
  /// Example:
  /// ```dart
  /// if (controller.lensDirection == CameraLensDirection.front) {
  ///   // Show selfie mode indicator
  /// }
  /// ```
  ///
  /// See also:
  /// * [switchCamera()], to change the camera lens
  /// * [CameraLensDirection], for all available directions
  CameraLensDirection get lensDirection => _lensDirection;

  /// Initializes the camera controller and sets up the camera for use.
  ///
  /// This method:
  /// 1. Discovers available cameras on the device
  /// 2. Selects the appropriate camera (prefers back camera)
  /// 3. Initializes the camera controller with medium resolution
  /// 4. Updates the controller state to [GuidelineState.ready]
  ///
  /// The method handles errors gracefully by setting the state to
  /// [GuidelineState.error] without throwing exceptions, allowing
  /// the UI to handle error states appropriately.
  ///
  /// Example:
  /// ```dart
  /// final controller = GuidelineCamController();
  /// try {
  ///   await controller.initialize();
  ///   print('Camera ready: ${controller.state}');
  /// } catch (e) {
  ///   print('Initialization failed: $e');
  /// }
  /// ```
  ///
  /// Throws [CameraException] if no cameras are available on the device.
  ///
  /// See also:
  /// * [state], to check the current state
  /// * [stateStream], to listen for state changes
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
            'NoCamerasAvailable', 'No cameras found on this device');
      }

      final camera = cameras.firstWhere(
          (c) => c.lensDirection == _lensDirection,
          orElse: () => cameras.first);

      // Store camera description for transform creation
      _cameraDescription = camera;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      _state = GuidelineState.ready;
    } catch (e) {
      _state = GuidelineState.error;
      _stateStreamController.add(_state);
      notifyListeners();
      // Don't rethrow - let the UI handle the error state
    } finally {
      if (_state != GuidelineState.error) {
        _stateStreamController.add(_state);
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    // Cancel any ongoing processing operations
    _processingOperation?.cancel();

    _cameraController?.dispose();
    _stateStreamController.close();
    // Cleanup temp files synchronously (dispose is not async)
    _tempFilesLock.synchronized(() {
      _cleanupTempFilesSync();
    });
    super.dispose();
  }

  /// Cleans up all temporary files created during image processing (synchronous).
  ///
  /// This method should be called when the controller is disposed or when
  /// temporary files are no longer needed. It deletes all files tracked in
  /// [_tempFiles] and clears the set.
  ///
  /// Failures to delete individual files are logged but don't throw exceptions
  /// to ensure cleanup continues for remaining files.
  ///
  /// **Note:** This method is not thread-safe. Use [cleanupTempFiles] for
  /// thread-safe cleanup from external callers.
  void _cleanupTempFilesSync() {
    for (final path in _tempFiles) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
          GuidelineCamLogger.verbose('Cleaned up temp file: $path');
        }
      } catch (e) {
        GuidelineCamLogger.warn('Failed to delete temp file: $path', error: e);
        // Continue cleanup even if one file fails
      }
    }
    _tempFiles.clear();
  }

  /// Manually cleanup temporary files before disposal.
  ///
  /// This method is **thread-safe** and can be called at any time, even while
  /// capture operations are in progress. It will wait for any ongoing operations
  /// to complete before cleaning up.
  ///
  /// This can be called after processing is complete to free up storage
  /// immediately rather than waiting for controller disposal.
  ///
  /// Example:
  /// ```dart
  /// final result = await controller.captureWithProcessing();
  /// // Process the result...
  /// await controller.cleanupTempFiles(); // Free storage immediately
  /// ```
  Future<void> cleanupTempFiles() async {
    await _tempFilesLock.synchronized(() {
      _cleanupTempFilesSync();
    });
  }

  /// Adds a temp file path to the cleanup set in a thread-safe manner.
  Future<void> _addTempFile(String path) async {
    await _tempFilesLock.synchronized(() {
      _tempFiles.add(path);
    });
  }

  /// Captures an image using the current camera.
  ///
  /// This method:
  /// 1. Sets the state to [GuidelineState.capturing]
  /// 2. Takes a picture using the camera controller
  /// 3. Returns the captured image file
  /// 4. Resets the state to [GuidelineState.ready]
  ///
  /// The captured image is saved to the device's temporary directory
  /// and can be accessed via the returned [XFile].
  ///
  /// Example:
  /// ```dart
  /// final result = await controller.capture();
  /// if (result != null) {
  ///   print('Image saved to: ${result.path}');
  ///   // Process the image file
  ///   final bytes = await result.readAsBytes();
  /// }
  /// ```
  ///
  /// Returns an [XFile] containing the captured image, or `null` if:
  /// * The camera controller is not initialized
  /// * The camera is not ready for capture
  ///
  /// Throws [CameraException] if capture fails due to camera issues.
  ///
  /// See also:
  /// * [state], to check if camera is ready for capture
  /// * [GuidelineCaptureResult], for structured capture results
  Future<XFile?> capture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }

    try {
      _state = GuidelineState.capturing;
      _stateStreamController.add(_state);
      notifyListeners();

      final image = await _cameraController!.takePicture();

      _state = GuidelineState.ready;
      _stateStreamController.add(_state);
      notifyListeners();

      return image;
    } catch (e) {
      _state = GuidelineState.error;
      _stateStreamController.add(_state);
      notifyListeners();
      rethrow;
    }
  }

  /// Switches the camera between front and back lenses.
  ///
  /// This method:
  /// 1. Disposes the current camera controller
  /// 2. Toggles between [CameraLensDirection.back] and [CameraLensDirection.front]
  /// 3. Reinitializes the camera with the new lens direction
  /// 4. Updates the state accordingly
  ///
  /// The camera switching process involves disposing the current controller
  /// and creating a new one, which may cause a brief delay in the UI.
  ///
  /// Example:
  /// ```dart
  /// // Switch from back to front camera
  /// await controller.switchCamera();
  /// print('Current lens: ${controller.lensDirection}');
  /// ```
  ///
  /// The method automatically handles errors during the switching process
  /// and will set the state to [GuidelineState.error] if switching fails.
  ///
  /// See also:
  /// * [lensDirection], to check the current camera direction
  /// * [initialize()], which is called internally during switching
  Future<void> switchCamera() async {
    // Dispose current controller before switching
    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;

    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    _state = GuidelineState.initializing;
    _stateStreamController.add(_state);
    notifyListeners();

    await initialize();
  }

  /// Sets the flash mode for the camera.
  ///
  /// This method configures the camera's flash behavior for subsequent captures.
  /// The flash mode affects how the camera handles lighting during image capture.
  ///
  /// Example:
  /// ```dart
  /// // Enable flash for all captures
  /// await controller.setFlashMode(FlashMode.always);
  ///
  /// // Disable flash
  /// await controller.setFlashMode(FlashMode.off);
  ///
  /// // Auto flash (camera decides)
  /// await controller.setFlashMode(FlashMode.auto);
  /// ```
  ///
  /// Parameters:
  /// * [mode] - The flash mode to set. See [FlashMode] for available options.
  ///
  /// The method only applies the flash mode if the camera controller is
  /// initialized and ready. If the camera is not ready, the method
  /// will silently ignore the request.
  ///
  /// See also:
  /// * [flashMode], to check the current flash mode
  /// * [FlashMode], for available flash mode options
  Future<void> setFlashMode(FlashMode mode) async {
    if (_cameraController != null) {
      await _cameraController!.setFlashMode(mode);
      _flashMode = mode;
      notifyListeners();
    }
  }

  /// Sets the guideline configuration for cropping and processing.
  ///
  /// This method should be called by the GuidelineCamBuilder to provide
  /// the configuration needed for auto-crop and image processing.
  ///
  /// Parameters:
  /// * [config] - The guideline overlay configuration
  ///
  /// This is typically called internally by the builder widget.
  void setConfig(GuidelineOverlayConfig config) {
    _config = config;
  }

  /// Sets the overlay bounds for guideline-based cropping.
  ///
  /// This method should be called by the overlay painter to provide
  /// the actual bounds of the guideline overlay for accurate cropping.
  ///
  /// Parameters:
  /// * [bounds] - The overlay bounds in pixels
  /// * [screenSize] - The screen/widget size where the overlay is drawn
  /// * [shapeBounds] - Optional list of individual shape bounds for multi-shape cropping
  ///
  /// This is typically called internally by the overlay painter.
  void setOverlayBounds(
    ui.Rect bounds,
    ui.Size screenSize, {
    List<ui.Rect>? shapeBounds,
  }) {
    // Validate bounds
    if (bounds.width <= 0 || bounds.height <= 0) {
      throw ArgumentError(
        'Invalid overlay bounds: width and height must be positive. '
        'Got: ${bounds.width}×${bounds.height}'
      );
    }
    if (bounds.width.isNaN || bounds.height.isNaN ||
        bounds.width.isInfinite || bounds.height.isInfinite) {
      throw ArgumentError(
        'Invalid overlay bounds: contains NaN or Infinity values'
      );
    }

    // Validate screen size
    if (screenSize.width <= 0 || screenSize.height <= 0) {
      throw ArgumentError(
        'Invalid screen size: width and height must be positive. '
        'Got: ${screenSize.width}×${screenSize.height}'
      );
    }
    if (screenSize.width.isNaN || screenSize.height.isNaN ||
        screenSize.width.isInfinite || screenSize.height.isInfinite) {
      throw ArgumentError(
        'Invalid screen size: contains NaN or Infinity values'
      );
    }

    // Validate shape bounds if provided
    if (shapeBounds != null) {
      for (int i = 0; i < shapeBounds.length; i++) {
        final shape = shapeBounds[i];
        if (shape.width <= 0 || shape.height <= 0) {
          throw ArgumentError(
            'Invalid shape bounds at index $i: width and height must be positive. '
            'Got: ${shape.width}×${shape.height}'
          );
        }
        if (shape.width.isNaN || shape.height.isNaN ||
            shape.width.isInfinite || shape.height.isInfinite) {
          throw ArgumentError(
            'Invalid shape bounds at index $i: contains NaN or Infinity values'
          );
        }
      }
    }

    _overlayBounds = bounds;
    _screenSize = screenSize;
    _shapeBounds = shapeBounds;
  }

  /// Captures an image with optional cropping and processing.
  ///
  /// This method extends [capture()] to support auto-crop and image processing
  /// based on the guideline configuration. It:
  /// 1. Captures the image
  /// 2. Applies cropping if enabled
  /// 3. Applies image processing if enabled
  /// 4. Returns a [GuidelineCaptureResult] with all versions
  ///
  /// Example:
  /// ```dart
  /// final result = await controller.captureWithProcessing();
  /// if (result != null) {
  ///   // Access the original file
  ///   print('Original: ${result.originalFile?.path}');
  ///
  ///   // Access cropped files
  ///   for (final cropped in result.croppedFiles) {
  ///     print('Cropped: ${cropped.path}');
  ///   }
  ///
  ///   // Access processed file
  ///   if (result.processedFile != null) {
  ///     print('Processed: ${result.processedFile!.path}');
  ///   }
  /// }
  /// ```
  ///
  /// Returns a [GuidelineCaptureResult] with the captured and processed images,
  /// or `null` if capture fails.
  ///
  /// This operation can be cancelled by calling [dispose()] on the controller.
  /// If cancelled, the operation will stop immediately and cleanup any temporary files.
  Future<GuidelineCaptureResult?> captureWithProcessing() async {
    // Wrap in cancelable operation for cancellation support
    _processingOperation = CancelableOperation.fromFuture(_captureWithProcessingInternal());

    try {
      final result = await _processingOperation!.value;
      return result;
    } catch (e) {
      // Operation was cancelled or failed
      GuidelineCamLogger.warn('Capture operation cancelled or failed', error: e);
      return null;
    } finally {
      _processingOperation = null;
    }
  }

  /// Internal implementation of captureWithProcessing (cancelable).
  Future<GuidelineCaptureResult?> _captureWithProcessingInternal() async {
    final capturedFile = await capture();
    if (capturedFile == null) {
      return null;
    }

    final capturedAt = DateTime.now();
    XFile? originalFile;
    List<XFile> croppedFiles = [];
    XFile? processedFile;
    Exception? cropError;
    Exception? processingError;
    XFile finalFile = capturedFile;

    // Store original if we're going to modify it
    if (_config != null &&
        (_config!.cropConfig.enabled ||
            (_config!.processing?.enabled ?? false))) {
      originalFile = capturedFile;
    }

    // Apply cropping if enabled
    if (_config != null && _config!.cropConfig.enabled) {
      try {
        croppedFiles = await _applyCropping(capturedFile, _config!.cropConfig);
        if (croppedFiles.isNotEmpty) {
          finalFile = croppedFiles.first;
        } else {
          // Empty result indicates failure
          cropError = Exception('Cropping failed: no valid crop region detected');
        }
      } catch (e) {
        cropError = e is Exception ? e : Exception('Cropping failed: $e');
        GuidelineCamLogger.error('Cropping failed', error: e);
        // Continue with original file if cropping fails
      }
    }

    // Apply processing if enabled
    if (_config != null &&
        _config!.processing != null &&
        _config!.processing!.enabled) {
      try {
        processedFile = await ImageProcessor.processImage(
          finalFile,
          _config!.processing!,
        );
        finalFile = processedFile;

        // Track temp file for cleanup
        await _addTempFile(processedFile.path);
      } catch (e) {
        processingError = e is Exception ? e : Exception('Processing failed: $e');
        GuidelineCamLogger.error('Processing failed', error: e);
        // Continue with unprocessed file if processing fails
      }
    }

    return GuidelineCaptureResult(
      file: finalFile,
      capturedAt: capturedAt,
      lens: _lensDirection,
      originalFile: originalFile,
      croppedFiles: croppedFiles,
      processedFile: processedFile,
      cropError: cropError,
      processingError: processingError,
    );
  }

  /// Apply cropping to the captured image based on configuration.
  ///
  /// Simple approach:  scale and crop.
  /// This ensures the cropped image aspect ratio matches the guideline.
  Future<List<XFile>> _applyCropping(XFile file, CropConfig config) async {
    final List<XFile> results = [];

    if (_overlayBounds == null || _screenSize == null) {
      throw Exception(
        'Cannot crop: overlay bounds or screen size not set. '
        'This usually indicates the camera preview was not fully initialized before capture.'
      );
    }

    try {
      // Read and decode the captured image
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Image file is empty: ${file.path}');
      }

      var image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image from ${file.path}. File may be corrupted or in an unsupported format.');
      }

      // Downsample if image is too large to prevent OOM
      final maxDim = math.max(image.width, image.height);
      if (maxDim > maxImageDimension) {
        final scale = maxImageDimension / maxDim;
        final newWidth = (image.width * scale).round();
        final newHeight = (image.height * scale).round();
        image = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.average,
        );
      }

      final sensorOrientation = _cameraDescription?.sensorOrientation ?? 0;

      // STEP 2: Calculate uniform scale to preserve aspect ratios
      final scaleX = image.width / _screenSize!.width;
      final scaleY = image.height / _screenSize!.height;
      final scale = math.min(scaleX, scaleY);

      // STEP 3: Calculate offset for centering
      final scaledScreenWidth = _screenSize!.width * scale;
      final scaledScreenHeight = _screenSize!.height * scale;
      final offsetX = (image.width - scaledScreenWidth) / 2;
      final offsetY = (image.height - scaledScreenHeight) / 2;

      // Check if we should crop each shape individually
      if (config.strategy == CropStrategy.eachShape &&
          _shapeBounds != null &&
          _shapeBounds!.isNotEmpty) {
        // Crop each shape individually
        GuidelineCamLogger.debug('Starting multi-crop operation with ${_shapeBounds!.length} shapes');
        GuidelineCamLogger.verbose('Multi-crop - Image dimensions: ${image.width}×${image.height}');

        for (int i = 0; i < _shapeBounds!.length; i++) {
          final shapeBound = _shapeBounds![i];

          GuidelineCamLogger.verbose('Shape ${i + 1} - Screen bounds: ${shapeBound.width.toInt()}×${shapeBound.height.toInt()} at (${shapeBound.left.toInt()}, ${shapeBound.top.toInt()})');

          // Map shape coordinates to image coordinates
          var cropX = (shapeBound.left * scale + offsetX - config.padding)
              .clamp(0.0, image.width.toDouble());
          var cropY = (shapeBound.top * scale + offsetY - config.padding)
              .clamp(0.0, image.height.toDouble());
          var cropWidth = (shapeBound.width * scale + config.padding * 2)
              .clamp(0.0, image.width - cropX);
          var cropHeight = (shapeBound.height * scale + config.padding * 2)
              .clamp(0.0, image.height - cropY);

          // Validate crop region
          if (cropWidth < minCropDimension || cropHeight < minCropDimension) {
            throw Exception(
              'Crop region too small for shape ${i + 1}: ${cropWidth.toInt()}×${cropHeight.toInt()}. '
              'The guideline may be positioned outside the camera frame or the padding is too large.'
            );
          }

          if (cropX + cropWidth > image.width || cropY + cropHeight > image.height) {
            throw Exception(
              'Crop region exceeds image bounds for shape ${i + 1}: '
              'region (${cropX.toInt()}, ${cropY.toInt()}, ${cropWidth.toInt()}×${cropHeight.toInt()}) '
              'vs image ${image.width}×${image.height}'
            );
          }

          GuidelineCamLogger.verbose('Shape ${i + 1} - Crop region: ${cropWidth.toInt()}×${cropHeight.toInt()} at (${cropX.toInt()}, ${cropY.toInt()})');

          // Crop the shape
          final croppedImage = img.copyCrop(
            image,
            x: cropX.round(),
            y: cropY.round(),
            width: cropWidth.round(),
            height: cropHeight.round(),
          );

          GuidelineCamLogger.verbose('Shape ${i + 1} - Result: ${croppedImage.width}×${croppedImage.height}');

          // Save to file
          final croppedBytes = img.encodeJpg(croppedImage, quality: defaultCropQuality);
          final tempDir = Directory.systemTemp;
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final tempFile =
              File('${tempDir.path}/cropped_shape${i + 1}_$timestamp.jpg');
          await tempFile.writeAsBytes(croppedBytes);

          // Track temp file for cleanup
          await _addTempFile(tempFile.path);

          results.add(XFile(tempFile.path));
        }

        GuidelineCamLogger.debug('Multi-crop operation completed successfully');
      } else {
        // Crop using combined bounds (outermost strategy)
        GuidelineCamLogger.debug('Starting auto-crop operation');
        GuidelineCamLogger.verbose('Auto-crop - Image: ${image.width}×${image.height}, Screen: ${_screenSize!.width.toInt()}×${_screenSize!.height.toInt()}');
        GuidelineCamLogger.verbose('Auto-crop - Sensor orientation: ${sensorOrientation}°');
        GuidelineCamLogger.verbose('Auto-crop - Scale: X=$scaleX, Y=$scaleY, uniform=$scale, Offset: ($offsetX, $offsetY)');

        // STEP 4: Map guideline coordinates to image coordinates
        var cropX = (_overlayBounds!.left * scale + offsetX - config.padding)
            .clamp(0.0, image.width.toDouble());
        var cropY = (_overlayBounds!.top * scale + offsetY - config.padding)
            .clamp(0.0, image.height.toDouble());
        var cropWidth = (_overlayBounds!.width * scale + config.padding * 2)
            .clamp(0.0, image.width - cropX);
        var cropHeight = (_overlayBounds!.height * scale + config.padding * 2)
            .clamp(0.0, image.height - cropY);

        // Validate crop region
        if (cropWidth < minCropDimension || cropHeight < minCropDimension) {
          throw Exception(
            'Crop region too small: ${cropWidth.toInt()}×${cropHeight.toInt()}. '
            'The guideline may be positioned outside the camera frame or the padding is too large.'
          );
        }

        if (cropX + cropWidth > image.width || cropY + cropHeight > image.height) {
          throw Exception(
            'Crop region exceeds image bounds: '
            'region (${cropX.toInt()}, ${cropY.toInt()}, ${cropWidth.toInt()}×${cropHeight.toInt()}) '
            'vs image ${image.width}×${image.height}'
          );
        }

        GuidelineCamLogger.verbose('Auto-crop - Region: ${cropWidth.toInt()}×${cropHeight.toInt()} at (${cropX.toInt()}, ${cropY.toInt()})');
      GuidelineCamLogger.verbose('Auto-crop - Aspect ratio: ${(cropWidth / cropHeight).toStringAsFixed(3)}');

        // STEP 5: Crop the image
        final croppedImage = img.copyCrop(
          image,
          x: cropX.round(),
          y: cropY.round(),
          width: cropWidth.round(),
          height: cropHeight.round(),
        );

        GuidelineCamLogger.verbose('Auto-crop - Result: ${croppedImage.width}×${croppedImage.height}, Aspect ratio: ${(croppedImage.width / croppedImage.height).toStringAsFixed(3)}');

        // Save to file
        final croppedBytes = img.encodeJpg(croppedImage, quality: defaultCropQuality);
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempFile = File('${tempDir.path}/cropped_$timestamp.jpg');
        await tempFile.writeAsBytes(croppedBytes);

        // Track temp file for cleanup
        await _addTempFile(tempFile.path);

        results.add(XFile(tempFile.path));
      }
    } catch (e, stackTrace) {
      GuidelineCamLogger.error('Auto-crop failed', error: e, stackTrace: stackTrace);
    }

    return results;
  }

  /// Process an image file with the specified configuration.
  ///
  /// This method allows manual image processing after capture.
  /// It can be used for custom processing workflows.
  ///
  /// Example:
  /// ```dart
  /// final captured = await controller.capture();
  /// if (captured != null) {
  ///   final processed = await controller.processImage(
  ///     captured,
  ///     ImageProcessingConfig.documentScan,
  ///   );
  ///   print('Processed: ${processed.path}');
  /// }
  /// ```
  ///
  /// Parameters:
  /// * [file] - The image file to process
  /// * [config] - The processing configuration
  ///
  /// Returns the processed image file.
  Future<XFile> processImage(XFile file, ImageProcessingConfig config) async {
    final processed = await ImageProcessor.processImage(file, config);

    // Track temp file for cleanup
    await _addTempFile(processed.path);

    return processed;
  }

  /// Crop an image file to a rectangular region.
  ///
  /// This method allows manual cropping after capture.
  ///
  /// Example:
  /// ```dart
  /// final captured = await controller.capture();
  /// if (captured != null) {
  ///   final cropped = await controller.cropImage(
  ///     captured,
  ///     x: 100,
  ///     y: 100,
  ///     width: 200,
  ///     height: 300,
  ///   );
  ///   print('Cropped: ${cropped.path}');
  /// }
  /// ```
  ///
  /// Parameters:
  /// * [file] - The image file to crop
  /// * [x] - The x-coordinate of the crop region
  /// * [y] - The y-coordinate of the crop region
  /// * [width] - The width of the crop region
  /// * [height] - The height of the crop region
  ///
  /// Returns the cropped image file.
  Future<XFile> cropImage(
    XFile file, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    final cropped = await ImageProcessor.cropImage(
      file,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    // Track temp file for cleanup
    await _addTempFile(cropped.path);

    return cropped;
  }
}
