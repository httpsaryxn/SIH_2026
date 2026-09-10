# Changelog

All notable changes to the LabelLens project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.10] - 2026-09-10

### Added
- **Dynamic AI Label Summary & Harmful Ingredient Engine (Groq LLM)**:
  - Replaced hardcoded static summaries with live packaging OCR analysis powered by Groq Cloud AI with fast model fallbacks (`qwen/qwen3.8-27b`, `openai/gpt-oss-120b`, `llama-3.3-70b-versatile`).
  - **Harmful Ingredients & Additives Detection**: Automatically flags synthetic artificial food dyes (Tartrazine / INS 102, Sunset Yellow / INS 110, Allura Red / INS 129, Brilliant Blue / INS 133, Carmoisine / INS 122), chemical preservatives (BHA / INS 320, BHT / INS 321, Sodium Benzoate / INS 211, Sulphites), palm olein, MSG, and intense artificial sweeteners.
  - **Nutritional Threshold Violations**: Real-time evaluation against safe health thresholds, warning for excessive sodium (> 600mg / 100g) and high sugar (> 15g / 100g).
  - **Wholesome & Clean Label Reassurances**: Positive, encouraging endorsement section (`### ✅ Clean Formulation & Safe Nutrition`) and high health scores for clean formulations without synthetic chemicals.
  - **Multi-Panel OCR Extraction**: Ingests and merges text from both front PDP area and back/side nutrition panels.
  - **Intelligent Offline Heuristic Fallback**: Full on-device regex ingredient & threshold parsing guaranteeing real label insights even without an active internet connection.
  - **Rich Markdown Presentation**: Formatted headers, warning badges, and bold alerts rendered using `MarkdownContentView`.

---

## [1.0.9] - 2026-09-10

### Added
- **Real Live Camera Viewfinder**:
  - Embedded real-time hardware and emulator camera streaming directly into [`MultiCaptureScreen`](file:///home/shivam/Coding/SIH%20PROJECT/apps/mobile/lib/screens/shared/multi_capture_screen.dart) for all three capture steps:
    1. **Front Label**
    2. **Curved Surface**
    3. **Scale Reference**
  - Embedded real-time camera streaming into the packaging audit viewfinder in [`RegulatorAuditIntakeScreen`](file:///home/shivam/Coding/SIH%20PROJECT/apps/mobile/lib/screens/regulator/regulator_audit_intake_screen.dart).
  - Integrated center targeting reticle guides and live pulsating status badge (**"Live Camera Feed"**).
  - Supported direct in-place tap-to-snap shutter directly on the viewfinder with fallback to gallery upload.
  - Added [`LiveCameraService`](file:///home/shivam/Coding/SIH%20PROJECT/apps/mobile/lib/core/services/live_camera_service.dart) for safe camera lifecycle management, high-resolution frame snapping, and graceful fallback in test/mock environments.
- **Persistent Regulator Navigation Shell**:
  - Created [`RegulatorShellScreen`](file:///home/shivam/Coding/SIH%20PROJECT/apps/mobile/lib/screens/regulator/regulator_shell_screen.dart) managing chrome and tabs centrally.
  - Implemented invariant [`DirectionalIndexedStack`](file:///home/shivam/Coding/SIH%20PROJECT/apps/mobile/lib/core/motion/directional_page_route.dart) hosting Home, Violations, Audit Intake, Complaints Inbox, and Profile tabs.
  - Tab state (form inputs, audit product details, active filters, search queries, and scroll positions) is 100% preserved across tab switches with zero resets.
- **Core Motion System**:
  - Centralized design tokens in [`AppDurations`](file:///home/shivam/Coding/SIH%20PROJECT/apps/mobile/lib/core/motion/app_durations.dart) and [`AppCurves`](file:///home/shivam/Coding/SIH%20PROJECT/apps/mobile/lib/core/motion/app_curves.dart).
  - Added [`DrillInPageRoute`](file:///home/shivam/Coding/SIH%20PROJECT/apps/mobile/lib/core/motion/directional_page_route.dart) providing iOS Cupertino / Material Shared Axis forward and pop transitions.
  - Added [`DirectionalTabSwitcher`](file:///home/shivam/Coding/SIH%20PROJECT/apps/mobile/lib/core/motion/directional_page_route.dart) for spatial horizontal sliding between tabs.
  - Added [`Pressable`](file:///home/shivam/Coding/SIH%20PROJECT/apps/mobile/lib/core/motion/pressable.dart) providing physics-based scale-down and spring rebound with haptic feedback.
  - Added [`SlideFadeEntrance`](file:///home/shivam/Coding/SIH%20PROJECT/apps/mobile/lib/core/motion/slide_fade_entrance.dart) with stagger animations.

### Fixed
- **Scroll Layout Constraints**: Fixed `StackFit.expand` inside unbounded `SingleChildScrollView` layout in `DirectionalTabSwitcher`, resolving blank unpainted white screen errors and `NEEDS-LAYOUT` exceptions.
- **Hot-Reload Resilience**: Guarded `widget.isStandalone` boolean evaluations against null during live hot reassembly across regulator tabs.
- **Bottom Navigation Chrome**: Removed blurry green gradient halo artifacts and fixed dead zones on the regulator center circular QR audit action button.
- **Manifest Merger**: Resolved Android `WRITE_EXTERNAL_STORAGE` manifest merger conflict between `camera_android_camerax` and application config using `tools:replace`.

---

## [1.0.8] - 2026-09-08

### Added
- **Regulatory PDF Reports Redesign**: Structured 2-column findings tables, status badges, and clean Section II layout.
- **Markdown Formatting**: Native parsing of headings, bold/italics, and status icons in mobile summary screens.
- **Green UI Theme**: Styled 'Open Formal PDF' button matching primary application theme.
- **Slim APK Build**: Added automated split-per-abi `arm64-v8a` APK build alongside Universal APK.

---

## [1.0.7] - 2026-09-07

### Added
- Multi-label capture workflow foundations.
- Local parallel health probing with instant fallback for ML services.

---

## [1.0.6] - 2026-09-06

### Added
- Enhanced regulatory compliance auditing tools.
- Export specifications for SVG, PDF, and JSON formats.

---

## [1.0.5] - 2026-09-04

### Added
- Initial consumer scanning and regulator audit tracking features.
