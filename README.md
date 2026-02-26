# PDF Expert - Flutter

A premium, full-featured PDF editor and viewer application built with Flutter. PDF Expert allows users to read, annotate, edit, and sign PDF documents locally on their devices with a beautiful, smooth, and highly responsive user interface.

## 🌟 Key Features

### 📄 Advanced PDF Viewer & Manager
- **Dynamic Recent Files**: Automatically tracks and saves up to 50 of your most recently opened files with beautiful thumbnail previews.
- **Glassmorphism UI & Animations**: Premium user interface featuring staggered list animations, floating sticky headers, and smooth screen transitions to ensure a modern feel.
- **Smart Search & Filtering**: Global document search with categorized tab filtering (*All, Originals, Edited by Me*).

### ✍️ Powerful PDF Editing Tools
- **Free Text Injection**: Add custom text anywhere on the PDF with full control over font family, size, color, bold, and italic styling.
- **Sticky Notes**: Instantly drop highly visible yellow "Post-it" style notes onto your documents for quick annotations or review comments.
- **Digital Signatures**: Built-in native signature pad supporting freehand drawing to append secure signatures directly onto document pages.
- **Image Insertion**: Overlay images seamlessly from your gallery onto any specific coordinate of the PDF.
- **Drag, Drop, and Resize**: Interactively move your signatures, images, and text overlays with touch gestures before committing the save.

### 🛡️ Secure Core & Sync
- **AcroForm Compatibility**: Fully supports filling out existing native PDF forms (text boxes, checkboxes).
- **Intelligent Flattening**: Custom engine algorithms to safely flatten annotations and purge bugged native rendering layers, ensuring your exported PDF looks identical to your screen across all viewers.
- **Draft States**: Remembers the edits and modifications you haven't saved yet, allowing you to resume your work later.
- **Quick Share**: Native intent integration to quickly share your modified documents via WhatsApp, Email, etc.

## 🛠️ Technology Stack & Architecture

This application strictly adheres to **Clean Architecture** principles, dividing the codebase into `Domain`, `Data`, and `Presentation` layers to ensure maximum scalability and testability.

### Primary Technologies
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [Riverpod 2.0+](https://riverpod.dev/) (with Code Generation `riverpod_generator`)
- **PDF Engine**: [Syncfusion Flutter PDF Viewer](https://pub.dev/packages/syncfusion_flutter_pdfviewer) & [Syncfusion Flutter PDF](https://pub.dev/packages/syncfusion_flutter_pdf)
- **Immutable State**: [Freezed](https://pub.dev/packages/freezed) & `json_serializable`

### UI & Utility Packages
- **Animations**: `flutter_animate`, `flutter_staggered_animations`
- **File System**: `file_picker`, `path_provider`
- **Native OS Hooks**: `share_plus`, `shared_preferences`
- **Typography**: `google_fonts`
- **Colors**: `flutter_colorpicker`

## 🚀 Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/kareem96/pdf-expert-flutter.git
   cd pdf_expert
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Riverpod & Freezed classes**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

## 📝 License

This project is intended for private use. All rights reserved.
