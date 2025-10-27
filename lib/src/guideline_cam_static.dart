import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:guideline_cam/src/config.dart';
import 'package:guideline_cam/src/enums.dart';
import 'package:guideline_cam/src/guideline_cam_page.dart' as internal;

/// Simple static API for camera capture with guideline overlays.
///
/// This class provides a simplified way to capture photos with camera guidelines
/// without needing to manage controllers, widgets, or lifecycle manually.
///
/// ## Usage Example
///
/// ```dart
/// // Simple capture with default settings
/// final XFile? photo = await GuidelineCam.takePhoto(context: context);
///
/// if (photo != null) {
///   print('Photo captured: ${photo.path}');
/// }
///
/// // Capture with custom overlay configuration
/// final XFile? photo = await GuidelineCam.takePhoto(
///   context: context,
///   guideline: GuidelineOverlayConfig(
///     shape: GuidelineShape.circle,
///     frameColor: Colors.blue,
///     maskColor: Colors.black54,
///   ),
/// );
///
/// // Capture with custom instructions
/// final XFile? photo = await GuidelineCam.takePhoto(
///   context: context,
///   guideline: GuidelineOverlayConfig(
///     shape: GuidelineShape.roundedRect,
///     aspectRatio: 1.586, // ID card ratio
///   ),
///   instructionBuilder: (context, state) {
///     String message;
///     switch (state) {
///       case GuidelineState.ready:
///         message = 'Position your ID card within the frame';
///         break;
///       default:
///         message = '';
///     }
///     return Container(
///       padding: const EdgeInsets.all(16),
///       decoration: BoxDecoration(
///         color: Colors.black54,
///         borderRadius: BorderRadius.circular(8),
///       ),
///       child: Text(
///         message,
///         style: const TextStyle(color: Colors.white),
///       ),
///     );
///   },
/// );
/// ```
///
/// ## Return Value
///
/// Returns an [XFile] containing the captured image if successful, or `null` if:
/// - The user cancels the capture (clicks back button)
/// - An error occurs during camera initialization or capture
/// - The camera fails to initialize
///
/// ## Platform Support
///
/// This method requires camera permissions to be configured in your app:
///
/// **Android** (`AndroidManifest.xml`):
/// ```xml
/// <uses-permission android:name="android.permission.CAMERA" />
/// ```
///
/// **iOS** (`Info.plist`):
/// ```xml
/// <key>NSCameraUsageDescription</key>
/// <string>We need access to the camera to capture your document/ID</string>
/// ```
///
/// See also:
/// * [GuidelineCamBuilder], for advanced usage with full controller management
/// * [GuidelineCamController], for manual camera control
/// * [GuidelineOverlayConfig], for overlay customization
class GuidelineCam {
  GuidelineCam._(); // Prevent instantiation

  /// Captures a photo using the camera with a guideline overlay.
  ///
  /// This method displays a full-screen camera interface with customizable
  /// overlay guidelines. It handles all camera initialization, UI presentation,
  /// and resource cleanup automatically.
  ///
  /// Parameters:
  /// * [context] - Build context for navigation. Required.
  /// * [guideline] - Configuration for the overlay appearance and behavior.
  ///   Defaults to a rounded rectangle with ID card aspect ratio.
  /// * [cameraDirection] - Which camera to use (front or back). Defaults to `CameraLensDirection.back`.
  /// * [showFlashToggle] - Whether to show the flash toggle button. Defaults to `true`.
  /// * [showCameraSwitch] - Whether to show the camera switch button. Defaults to `true`.
  /// * [backgroundColor] - Background color for the camera page. Defaults to `Colors.black`.
  /// * [instructionBuilder] - Optional builder for custom instruction widgets.
  ///   If provided, displays contextual instructions based on camera state.
  ///
  /// Returns an [XFile] containing the captured image, or `null` if the user
  /// cancels or an error occurs.
  ///
  /// Example:
  /// ```dart
  /// // Basic usage with default settings (back camera)
  /// final photo = await GuidelineCam.takePhoto(context: context);
  ///
  /// // Use front camera for selfie capture
  /// final photo = await GuidelineCam.takePhoto(
  ///   context: context,
  ///   cameraDirection: CameraLensDirection.front,
  /// );
  ///
  /// // Custom overlay for ID card capture with back camera
  /// final photo = await GuidelineCam.takePhoto(
  ///   context: context,
  ///   cameraDirection: CameraLensDirection.back,
  ///   guideline: GuidelineOverlayConfig(
  ///     shape: GuidelineShape.roundedRect,
  ///     aspectRatio: 1.586,
  ///     frameColor: Colors.white,
  ///     maskColor: Colors.black54,
  ///   ),
  /// );
  ///
  /// // Custom overlay for face capture with front camera
  /// final photo = await GuidelineCam.takePhoto(
  ///   context: context,
  ///   cameraDirection: CameraLensDirection.front,
  ///   guideline: GuidelineOverlayConfig(
  ///     shape: GuidelineShape.circle,
  ///     frameColor: Colors.blue,
  ///   ),
  /// );
  /// ```
  ///
  /// See also:
  /// * [GuidelineOverlayConfig], for overlay customization options
  /// * [XFile], for file operations on the captured image
  /// * [CameraLensDirection], for available camera directions
  static Future<XFile?> takePhoto({
    required BuildContext context,
    GuidelineOverlayConfig? guideline,
    CameraLensDirection cameraDirection = CameraLensDirection.back,
    bool showFlashToggle = true,
    bool showCameraSwitch = true,
    Color backgroundColor = Colors.black,
    Widget Function(BuildContext, GuidelineState)? instructionBuilder,
  }) async {
    final result = await Navigator.of(context, rootNavigator: true).push<XFile>(
      MaterialPageRoute(
        builder: (context) => internal.GuidelineCamPage(
          guideline: guideline ?? const GuidelineOverlayConfig(),
          cameraDirection: cameraDirection,
          showFlashToggle: showFlashToggle,
          showCameraSwitch: showCameraSwitch,
          backgroundColor: backgroundColor,
          instructionBuilder: instructionBuilder,
        ),
        fullscreenDialog: true,
      ),
    );

    return result;
  }
}
