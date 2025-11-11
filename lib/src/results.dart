import 'package:camera/camera.dart';

/// The result of a successful image capture operation.
///
/// This class contains all the information about a captured image, including
/// the file reference, timestamp, and camera metadata. It's provided to the
/// [GuidelineCamBuilder.onCapture] callback when an image is successfully captured.
///
/// ## Usage Example
///
/// ```dart
/// GuidelineCamBuilder(
///   controller: _controller,
///   onCapture: (result) {
///     // Access the captured image file
///     final imageFile = result.file;
///     print('Image saved to: ${imageFile.path}');
///
///     // Access cropped images (if auto-crop is enabled)
///     if (result.croppedFiles.isNotEmpty) {
///       print('Cropped to ${result.croppedFiles.length} images');
///       for (final cropped in result.croppedFiles) {
///         print('Cropped file: ${cropped.path}');
///       }
///     }
///
///     // Access processed image (if processing is enabled)
///     if (result.processedFile != null) {
///       print('Processed image: ${result.processedFile!.path}');
///     }
///
///     // Get capture metadata
///     print('Captured at: ${result.capturedAt}');
///     print('Camera lens: ${result.lens}');
///
///     // Process the image
///     _processCapturedImage(result);
///   },
/// )
///
/// Future<void> _processCapturedImage(GuidelineCaptureResult result) async {
///   // Use processed file if available, otherwise original
///   final fileToUse = result.processedFile ?? result.file;
///
///   // Read image bytes
///   final bytes = await fileToUse.readAsBytes();
///
///   // Save to gallery
///   await GallerySaver.saveImage(fileToUse.path);
///
///   // Upload to server
///   await _uploadImage(fileToUse);
///
///   // Navigate to preview
///   Navigator.push(
///     context,
///     MaterialPageRoute(
///       builder: (context) => ImagePreviewPage(fileToUse),
///     ),
///   );
/// }
/// ```
///
/// ## File Handling
///
/// The captured image is saved as a temporary file that you should process
/// or move to permanent storage. The file path is accessible through [file.path]
/// and the file can be read using [XFile.readAsBytes()] or [XFile.readAsString()].
///
/// See also:
/// * [XFile], for file operations
/// * [GuidelineCamBuilder.onCapture], for the capture callback
/// * [GuidelineCamController.capture()], for manual capture
class GuidelineCaptureResult {
  /// Creates a new capture result with the given properties.
  ///
  /// Parameters:
  /// * [file] - The captured image file (or processed file if processing was applied)
  /// * [capturedAt] - The timestamp when the image was captured
  /// * [lens] - The camera lens direction used for capture
  /// * [originalFile] - The original unmodified captured image (optional)
  /// * [croppedFiles] - List of cropped images if auto-crop is enabled (optional)
  /// * [processedFile] - The processed image if image processing was applied (optional)
  /// * [cropError] - Exception if cropping failed (optional)
  /// * [processingError] - Exception if image processing failed (optional)
  const GuidelineCaptureResult({
    required this.file,
    required this.capturedAt,
    required this.lens,
    this.originalFile,
    this.croppedFiles = const [],
    this.processedFile,
    this.cropError,
    this.processingError,
  });

  /// The captured image file.
  ///
  /// This [XFile] contains the captured image data and provides access to
  /// the file path, bytes, and other file operations. The file is typically
  /// saved in the device's temporary directory.
  ///
  /// Example:
  /// ```dart
  /// // Get file path
  /// final path = result.file.path;
  /// print('Image saved to: $path');
  ///
  /// // Read image bytes
  /// final bytes = await result.file.readAsBytes();
  /// final size = bytes.length;
  /// print('Image size: ${size} bytes');
  ///
  /// // Get file name
  /// final name = result.file.name;
  /// print('File name: $name');
  ///
  /// // Get file size
  /// final length = await result.file.length();
  /// print('File size: $length bytes');
  /// ```
  ///
  /// See also:
  /// * [XFile], for file operations and properties
  final XFile file;

  /// The timestamp when the image was captured.
  ///
  /// This [DateTime] represents the exact moment when the image capture
  /// was initiated. It's useful for organizing captured images, creating
  /// unique filenames, or tracking capture timing.
  ///
  /// Example:
  /// ```dart
  /// // Format timestamp for display
  /// final formatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(result.capturedAt);
  /// print('Captured at: $formatted');
  ///
  /// // Create unique filename
  /// final timestamp = result.capturedAt.millisecondsSinceEpoch;
  /// final filename = 'capture_$timestamp.jpg';
  ///
  /// // Check if capture was recent
  /// final now = DateTime.now();
  /// final difference = now.difference(result.capturedAt);
  /// if (difference.inSeconds < 5) {
  ///   print('Image captured just now');
  /// }
  /// ```
  ///
  /// See also:
  /// * [DateTime], for date and time operations
  final DateTime capturedAt;

  /// The camera lens direction used for the capture.
  ///
  /// This indicates which camera lens was active when the image was captured:
  /// * [CameraLensDirection.back] - Back/rear camera was used
  /// * [CameraLensDirection.front] - Front/selfie camera was used
  ///
  /// This information is useful for:
  /// * Organizing images by camera type
  /// * Applying different processing based on camera
  /// * UI feedback about which camera was used
  ///
  /// Example:
  /// ```dart
  /// // Check which camera was used
  /// if (result.lens == CameraLensDirection.back) {
  ///   print('Captured with back camera');
  ///   // Apply document processing
  /// } else {
  ///   print('Captured with front camera');
  ///   // Apply face processing
  /// }
  ///
  /// // Organize by camera type
  /// final folder = result.lens == CameraLensDirection.back
  ///     ? 'documents'
  ///     : 'selfies';
  /// await _moveToFolder(result.file, folder);
  /// ```
  ///
  /// See also:
  /// * [CameraLensDirection], for available lens directions
  /// * [GuidelineCamController.lensDirection], for current camera direction
  final CameraLensDirection lens;

  /// The original unmodified captured image.
  ///
  /// This is the raw image from the camera before any cropping or processing.
  /// Useful if you need access to the full original image alongside cropped
  /// or processed versions.
  ///
  /// Will be null if no cropping or processing was applied.
  ///
  /// Example:
  /// ```dart
  /// // Compare original and processed
  /// if (result.originalFile != null) {
  ///   print('Original: ${result.originalFile!.path}');
  ///   print('Processed: ${result.file.path}');
  /// }
  /// ```
  final XFile? originalFile;

  /// List of cropped images if auto-crop is enabled.
  ///
  /// When auto-crop is enabled with [CropStrategy.eachShape], this list will
  /// contain separate cropped images for each shape in the overlay.
  ///
  /// For single-shape overlays or [CropStrategy.outermost],
  /// this list will contain a single cropped image.
  ///
  /// Empty list if cropping is disabled.
  ///
  /// Example:
  /// ```dart
  /// // Handle multiple crops (e.g., front and back of ID card)
  /// if (result.croppedFiles.length == 2) {
  ///   final front = result.croppedFiles[0];
  ///   final back = result.croppedFiles[1];
  ///   print('Front: ${front.path}');
  ///   print('Back: ${back.path}');
  /// }
  ///
  /// // Or just get the first crop
  /// if (result.croppedFiles.isNotEmpty) {
  ///   final cropped = result.croppedFiles.first;
  ///   await _processCroppedImage(cropped);
  /// }
  /// ```
  final List<XFile> croppedFiles;

  /// The processed image if image processing was applied.
  ///
  /// When image processing is enabled (grayscale, brightness adjustment, etc.),
  /// this contains the final processed image.
  ///
  /// Will be null if image processing is disabled.
  ///
  /// Note: If both cropping and processing are enabled, processing is applied
  /// after cropping, and this file will be the processed version of the crop.
  ///
  /// Example:
  /// ```dart
  /// // Use processed image if available
  /// final finalImage = result.processedFile ?? result.file;
  /// await _uploadToServer(finalImage);
  ///
  /// // Check if processing was applied
  /// if (result.processedFile != null) {
  ///   print('Image was processed');
  ///   // Maybe show before/after comparison
  ///   _showComparison(result.originalFile!, result.processedFile!);
  /// }
  /// ```
  final XFile? processedFile;

  /// Error that occurred during cropping, if any.
  ///
  /// If cropping was enabled but failed, this field will contain the exception.
  /// Check this field to determine if the requested cropping operation succeeded.
  ///
  /// Will be null if:
  /// * Cropping was disabled
  /// * Cropping succeeded without errors
  ///
  /// Example:
  /// ```dart
  /// if (result.cropError != null) {
  ///   print('Cropping failed: ${result.cropError}');
  ///   // Fall back to original image
  ///   final image = result.originalFile ?? result.file;
  /// } else if (result.croppedFiles.isNotEmpty) {
  ///   print('Cropping succeeded');
  ///   final cropped = result.croppedFiles.first;
  /// }
  /// ```
  final Exception? cropError;

  /// Error that occurred during image processing, if any.
  ///
  /// If image processing was enabled but failed, this field will contain the exception.
  /// Check this field to determine if the requested processing operation succeeded.
  ///
  /// Will be null if:
  /// * Image processing was disabled
  /// * Processing succeeded without errors
  ///
  /// Example:
  /// ```dart
  /// if (result.processingError != null) {
  ///   print('Processing failed: ${result.processingError}');
  ///   // Use unprocessed image
  ///   final image = result.croppedFiles.firstOrNull ?? result.file;
  /// } else if (result.processedFile != null) {
  ///   print('Processing succeeded');
  ///   final processed = result.processedFile!;
  /// }
  /// ```
  final Exception? processingError;
}
