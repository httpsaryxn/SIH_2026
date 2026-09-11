# Changelog

All notable changes to the LabelLens project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.1] - 2026-09-11

### Added
- **Live Barcode & QR Code Webscraping Registry Enrichment**:
  - Integrated `BarcodeScanner` across all intake images (front, back, ruler, barcode).
  - Live query against Open Food Facts, UPCItemDB, and GS1 registry to enrich package metadata (product name, brand, net quantity, manufacturer).
  - Verified QR code destination domains and extracted page headers for metrology compliance audits.
- **Small Business Label Studio Enhancements**:
  - Multi-format label artwork downloads (Vector SVG, Print-Ready 300 DPI PDF, and JSON compliance metadata).
  - Nutrition % RDA daily value calculations and FoSCoS portal verification links.
  - GS1 EAN-13 barcode generator and brand logo image inclusion in exported labels.
  - Timestamped export filenames and Android Scoped Storage download manager fallback.

### Fixed
- **Eliminated Mock Data Handoff in Regulator Flow**:
  - In-memory audit violation cache registration prevents `getViolationById()` from falling back to hardcoded mock products when reviewing newly captured packaging scans.
  - Direct `initialViolation` handoff in `RegulatorViolationReviewScreen` ensuring 100% authentic data pipeline.
- **Latency Optimization via Gemini Vision Header**:
  - Automatic transmission of `X-Gemini-Api-Key` prevents slow multi-pass EasyOCR CPU fallbacks on backend scanners.
- **Android Gradle 9.x Build Compatibility**:
  - Resolved CameraX `CallbackToFutureAdapter` compilation error by upgrading `camera` and injecting `androidx.concurrent:concurrent-futures:1.2.0`.

---

## [2.0.0] - 2026-09-11

### Added
- **Small Business Persistent Navigation Shell & Studio Hub**:
  - Replaced placeholder navigation with a fully interactive 4-tab bottom navigation bar: **Home**, **Inventory**, **Notifications**, and **Profile**.
  - Built with `Pressable` spring rebound physics, `HapticFeedback.selectionClick()`, smooth active indicator pill, and live dynamic unread alerts badge.
  - Powered by spatial `DirectionalIndexedStack` featuring direction-aware sliding and fading (`AppDurations.medium`, `AppCurves.entrance`, with `ClipRect` boundary clipping) while preserving all form state, scroll positions, and query filters.
- **Label Inventory Screen (`SmallBusinessInventoryScreen`)**:
  - Centralized catalog displaying all labels drafted and published by the business owner.
  - Category selector bottom sheet and status filter chips (**All**, **Ready**, **Needs Review**, **Drafts**) with live counter badges.
  - Quick drill-in action: seamlessly opens `CreateLabelDeclarationScreen` for drafts or `LabelReviewExportScreen` for finalized labels.
  - Real-time search by title, brand, category, batch number, and FSSAI license number.
- **Activity & Compliance Notifications Center (`SmallBusinessNotificationsScreen`)**:
  - Direct integration with `SmallBusinessNotificationService` providing real-time compliance updates, activity logs, and status alerts.
  - Filter chips for **All**, **Alerts**, **Success**, and **Legal** notices with timestamp tracking and one-tap clear dialog.
- **Instant Inline Search Results**:
  - Typing in the Studio search box opens an inline search dropdown directly below the search bar.
  - Displays product thumbnails, brand, batch number, status pill, and FSSAI number with direct navigation on click.
- **Top Header Modernization**:
  - Removed duplicate notification bell and profile avatar from the top header on the Studio Home screen, streamlining the user experience to the bottom navbar.

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
