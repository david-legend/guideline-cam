# 0.1.0+2
- Fix dart formatting

# 0.1.0+1
- Update dependencies `image: ^4.2.0`

# 0.1.0

## ✨ Auto‑Crop, Image Processing, and Smart Logging

- New: Auto‑crop
  - `CropMode.guideline` with `CropStrategy.outermost` (default) or `CropStrategy.eachShape`
  - Optional padding; cancellation; thread‑safe temp file handling

- New: Image processing
  - Grayscale, auto‑enhance, sharpen, noise reduction, manual brightness/contrast/saturation
  - JPEG quality control, presets: `documentScan`, `idCard`
  - Heavy pixel work runs in isolates (keeps UI smooth)

- New: Debug logging
  - Zero‑config, build‑aware defaults (verbose in debug, minimal in release)
  - Optional performance timing; custom logger integration (e.g., Crashlytics/Sentry)
  - Production‑safe: ~0.1% overhead when enabled; zero string allocation when disabled

- API
  - Logging: `GuidelineCam.configureLogging`, `GuidelineCam.loggingConfig`, `GuidelineCam.enablePerformanceTiming`
  - Capture: `GuidelineCam.takePhoto(enableCrop, enableProcessing)` (opt‑in, outermost crop returns single `XFile`)
  - Results: `GuidelineCaptureResult` adds `originalFile`, `croppedFiles`, `processedFile`, `file`
  - Controller: `captureWithProcessing()`, `processImage(file, config)`, `cropImage(...)`, `setConfig(config)`
  - Configs: `CropConfig`, `ImageProcessingConfig`

- Configuration
  - `GuidelineOverlayConfig` adds `cropConfig` and `processing`
  - `copyWith()` on `GuidelineOverlayConfig` and `CropConfig`

- Robustness & performance
  - Thread‑safe synchronization; input validation; 4096px max dimension with downsampling
  - Detailed error fields (`cropError`, `processingError`)
  - Async cleanup; non‑blocking UI; 60fps target

- Dependencies
  - `image: ^4.0.0`, `synchronized: ^3.1.0+1`, `async: ^2.11.0`

- Docs
  - New `autocrop.md`; updated `README.md`; expanded `llms.txt`; usage examples

- Breaking changes
  - None; features are opt‑in. Default: auto‑crop enabled (`CropConfig(enabled: false)` to disable)
  
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
