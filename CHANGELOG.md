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
