# PDF Expert 🚀

Sebuah aplikasi editor PDF modern dan tangguh yang dibangun dengan Flutter. Menggunakan pola **Clean Architecture**, **Riverpod** untuk state management, dan **Syncfusion** (`syncfusion_flutter_pdfviewer`, `syncfusion_flutter_pdf`) untuk logika PDF.

## 🌟 Fitur Utama

Aplikasi ini dapat menangani manipulasi PDF native tingkat lanjut secara mulus:

- **AcroForm Filling**: Mendeteksi secara otomatis field form PDF standar dan mengubahnya menjadi entitas yang dapat diedit langsung.
- **Free Text Insertion**: Menggunakan deteksi *Tap* untuk menambahkan elemen teks baru secara presisi di area mana saja pada dokumen PDF.
- **High-Precision Sync**: Teks yang ditambahkan (Free Text) akan selalu mengikuti *scroll* dan *zoom* dengan sinkronisasi koordinat yang akurat.
- **Improved Multi-page**: Mendukung file PDF multi-halaman berkat perhitungan dinamis untuk *page-offset*.
- **Pixel-Perfect Save**: Output PDF yang disimpan mensejajarkan elemen dengan posisi yang terlihat di UI editor secara persis.
- **Smooth Dragging**: Fitur *Drag & Drop* untuk memindahkan elemen teks ke posisi mana pun di seluruh tingkat zoom.
- **Delete Functionality**: Memungkinkan pengguna untuk menghapus teks kustom yang telah dimasukkan dengan mudah.
- **Save with Custom Name**: Pengguna bisa memilih nama file baru sebelum menyimpannya ke memori lokal.
- **Native Sharing**: Integrasi dengan `share_plus` untuk membagikan hasil editan langsung ke aplikasi lain.

## 🛠 Fitur Mendatang (Next Tasks)

Pengembangan PDF Expert akan terus dilanjutkan! Ini adalah target fitur selanjutnya:

- [ ] **Kustomisasi Teks (Warna, Bold, Italic)**
- [ ] **Dukungan Menyisipkan Gambar & Tanda Tangan (Signature)**
- [ ] **Fungsi Undo / Redo**
- [ ] **UI/UX Refinement (Modern & Premium Look)**

## 📁 Gambaran Arsitektur

### Domain Layer (Inti)
- **Entities**: `PdfDocumentEntity`, `PdfFieldEntity`.
- **Use Cases**: `LoadPdfUseCase`, `SavePdfUseCase`.
- **Repository Interface**: `IPdfRepository`.

### Data Layer
- **SyncfusionPdfService**: *Core logic* untuk mem-parsing, merender, dan memanipulasi *bytes* PDF ke file.
- **PdfRepositoryImpl**: Implementasi konkret yang bertugas atas file lokal dan fitur sharing.

### Presentation Layer
- **PdfEditorProvider**: Mengelola UI *state* untuk dokumen yang sedang aktif.
- **PdfEditorPage**: Tampilan UI utama dengan file picking, render PDF, logik koordinasi *drag/drop*, dan *save dialog*.

## 🚀 Cara Penggunaan

1. **Clone repository ini**
2. **Install dependencies**: 
   ```bash
   flutter pub get
   ```
3. **Generate kode Freezed/Riverpod** (jika ada perubahan entity/provider):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. **Jalankan aplikasi**:
   ```bash
   flutter run
   ```
