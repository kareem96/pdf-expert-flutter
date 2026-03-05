# PDF Expert - Project Roadmap & Task List

## 1. Completed Development Phases
- [x] **Project Infrastructure**
    - [x] Clean Architecture setup (Domain, Data, Presentation).
    - [x] Riverpod state management integration.
    - [x] Syncfusion PDF Engine integration.
- [x] **Core PDF Features**
    - [x] Digital Text Detection & Editing (AcroForms).
    - [x] Free Text Interaction (Dragging, Resizing, Scaling).
    - [x] Text Styling (Colors, Multi-font support, Bold/Italic).
    - [x] Image & Digital Signature placement.
- [x] **Advanced Editing Tools**
    - [x] **Text Eraser**: Precision white-out with "Surgical View" (Dual-engine: Syncfusion + ML Kit AI).
    - [x] **Marker Tools**: Dedicated popup for Check, Close, Square, and Circle markers with custom colors.
    - [x] **Eraser Confirmation**: Preview mode with Confirm/Cancel/Resize buttons.
- [x] **UI/UX Refinements**
    - [x] Premium Dark Theme & Glassmorphic elements.
    - [x] Dual-row adaptive toolbar with horizontal scroll indicators.
    - [x] Zoom-stabilized InteractiveViewer with floating reset button.
    - [x] Safe Navigation guards and optimized state synchronization.

## 2. Future Feature Roadmap (Upcoming)
### [ ] 2.1 Redaction Tool (Sensor Data Rahasia)
- Dedicated tool to permanently wipe out sensitive text areas (ID numbers, etc.) from the PDF structure, not just drawing a box over it.
### [ ] 2.2 Page Manager (Thumbnail Grid)
- UI mode to reorder (drag & drop), rotate, delete, or split pages.
### [ ] 2.3 Smart Freehand Pen (Ink/Stylus Support)
- Vector-based drawing with Bezier curves for smooth natural ink textures and dynamic thickness.
### [ ] 2.4 Global Watermark Injector
- High-speed engine to inject confidential overlays across all pages simultaneously.
### [ ] 2.5 Text Eraser Refinement (AI OCR Optimization)
- Further optimization of the ML Kit OCR fall-back for scanned/handwritten documents.
### [x] 2.6 Theme & Language Settings
- **Multi-Theme**: Switch between Premium Dark Mode and Clean Light Mode.
- **Localization**: Support for multiple languages (Bahasa Indonesia, English, etc.).

---
*Note: This file is the single source of truth for all project progress and future planning.*
