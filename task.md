# PDF Expert - Project Roadmap & Task List

## 1. Completed Tasks (Selesai)

### Phase 1: Project Infrastructure
- [x] Clean Architecture setup (Domain, Data, Presentation).
- [x] Riverpod state management integration.
- [x] Syncfusion PDF Engine integration.

### Phase 2: Core PDF Features
- [x] Digital Text Detection & Editing (AcroForms).
- [x] Free Text Interaction (Dragging, Resizing, Scaling).
- [x] Text Styling (Colors, Multi-font support, Bold/Italic).
- [x] Image & Digital Signature placement.

### Phase 3: Advanced Editing Tools
- [x] **Marker Tools**: Dedicated popup for Check, Close, Square, and Circle markers with custom colors.
- [x] **Eraser Confirmation**: Preview mode with Confirm/Cancel/Resize buttons.
- [x] **Text Eraser with ML Kit (AI Scan)**: Precision white-out with "Surgical View" (Dual-engine: Syncfusion + ML Kit AI). Implementation of Google ML Kit Text Recognition for accurate detection on scanned documents.

### Phase 4: UI/UX Refinements
- [x] Premium Dark Theme & Glassmorphic elements.
- [x] Dual-row adaptive toolbar with horizontal scroll indicators.
- [x] Zoom-stabilized InteractiveViewer with floating reset button.
- [x] Safe Navigation guards and optimized state synchronization.

### Phase 5: Additional Features
- [x] **Theme Settings**: Multi-Theme, Switch between Premium Dark Mode and Clean Light Mode.
- [x] **Language Settings (Localization)**: Support for multiple languages (Bahasa Indonesia, English, etc.).

---

## 2. Pending Tasks (Belum Selesai / Future Feature Roadmap)

### [ ] 2.1 Redaction Tool (Sensor Data Rahasia)
- Dedicated tool to permanently wipe out sensitive text areas (ID numbers, etc.) from the PDF structure, not just drawing a box over it.

### [ ] 2.3 Page Manager (Thumbnail Grid)
- UI mode to reorder (drag & drop), rotate, delete, or split pages.

### [ ] 2.4 Smart Freehand Pen (Ink/Stylus Support)
- Vector-based drawing with Bezier curves for smooth natural ink textures and dynamic thickness.

### [ ] 2.5 Global Watermark Injector
- High-speed engine to inject confidential overlays across all pages simultaneously.

### [ ] 2.6 Offline AI Model (Build Flavors)
- Create APK build variants (standard vs offline) to bundle the 15MB ML Kit Text Recognition model for 100% offline usage without initial Play Services download.

### [ ] 2.7 Magic Edit (Smart Edit Illusion)
- Premium feature mimic Adobe/Foxit's "True Text Editing".
- Utilizes Surgical Eraser combined with auto-sizing Text Overlay initialized with extracted text.
- Provides a seamless optical illusion of editing original PDF text.

### [/] 2.8 AI Tools UI Overhaul & Smart Popup
- Separate AI Scan from the standard Eraser tool.
- Create a dedicated "AI Scan" icon in the main toolbar.
- Implement a "Smart Popup" to enforce ML Kit model download via `ModelManager` check before use.

---
*Note: This file is the single source of truth for all project progress and future planning.*
> **ATURAN WAJIB**: Jangan mencentang `[x]` untuk status fitur yang sedang atau baru dikerjakan sampai User (Pengguna) secara eksplisit menyatakan hasil fitur tersebut "sudah sempurna/selesai". Gunakan `[/]` (in progress) untuk fitur yang sedang digarap.
