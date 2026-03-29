class AppStrings {
  static String _currentLanguage = 'id';

  static String get currentLanguage => _currentLanguage;

  static void setLanguage(String code) {
    if (code == 'en' || code == 'id') {
      _currentLanguage = code;
    }
  }

  static String get _s => _currentLanguage;

  // General
  static String get appName => 'PDF Expert';
  static String get cancel => _s == 'id' ? 'Batal' : 'Cancel';
  static String get save => _s == 'id' ? 'Simpan' : 'Save';
  static String get delete => _s == 'id' ? 'Hapus' : 'Delete';
  static String get ok => 'OK';
  static String get add => _s == 'id' ? 'Tambah' : 'Add';
  static String get gotIt => _s == 'id' ? 'Mengerti' : 'Got it';

  // PDF Editor Page
  static String get leaveEditorTitle => _s == 'id' ? 'Tinggalkan Editor?' : 'Leave Editor?';
  static String get leaveEditorBody => _s == 'id' ? 'Apa yang ingin Anda lakukan dengan perubahan Anda?' : 'What would you like to do with your changes?';
  static String get stay => _s == 'id' ? 'Tetap di Sini' : 'Stay';
  static String get saveDraft => _s == 'id' ? 'Simpan Draf' : 'Save Draft';
  static String get discard => _s == 'id' ? 'Buang' : 'Discard';

  // Toolbar Modes
  static String get modeSign => _s == 'id' ? 'Tanda Tangan' : 'Sign';
  static String get modeImage => _s == 'id' ? 'Gambar' : 'Image';
  static String get modeText => _s == 'id' ? 'Teks' : 'Text';
  static String get modeErase => _s == 'id' ? 'Hapus' : 'Erase';
  static String get modeAiTools => _s == 'id' ? 'AI Tools' : 'AI Tools';
  static String get modeMarker => _s == 'id' ? 'Penanda' : 'Marker';
  static String get modeNote => _s == 'id' ? 'Catatan' : 'Note';
  static String get modeSave => _s == 'id' ? 'Simpan' : 'Save';
  static String get modeShare => _s == 'id' ? 'Bagikan' : 'Share';

  // Toast Messages
  static String get toastEraserActive => _s == 'id' ? 'Mode Penghapus Aktif. Ketuk teks manapun di PDF untuk menghapusnya.' : 'Eraser Mode Active. Tap any text on the PDF to wipe it.';
  static String get toastMarkerActive => _s == 'id' ? 'Mode Penanda Aktif. Ketuk PDF untuk menaruh penanda.' : 'Marker Mode Active. Tap on PDF to place a marker.';
  static String get toastTextActive => _s == 'id' ? 'Mode Teks Aktif. Ketuk pada PDF untuk mulai menulis.' : 'Text Mode Active. Tap on the PDF to start typing.';
  static String get toastSignActive => _s == 'id' ? 'Mode Tanda Tangan Aktif. Ketuk pada PDF untuk menaruh tanda tangan.' : 'Signature Mode Active. Tap on the PDF to place your signature.';
  static String get toastTextErased => _s == 'id' ? 'Teks Berhasil Dihapus Permanen!' : 'Text Erased Permanently!';
  static String get toastSaveSuccess => _s == 'id' ? 'Tersimpan sebagai ' : 'Saved as ';
  static String get toastSaveFailed => _s == 'id' ? 'Gagal menyimpan: ' : 'Save failed: ';
  static String get toastTextEmpty => _s == 'id' ? 'Teks tidak boleh kosong' : 'Text cannot be empty';
  static String get toastExtractingBounds => _s == 'id' ? 'Mengekstrak batas teks...' : 'Extracting boundaries...';
  static String get toastPreviewingErase => _s == 'id' ? 'Menampilkan pratinjau area yang akan dihapus...' : 'Previewing area to erase...';
  static String get fileDeleted => _s == 'id' ? 'File berhasil dihapus dari perangkat' : 'File deleted from device';
  static String get removedFromHistory => _s == 'id' ? 'Dihapus dari riwayat' : 'Removed from history';
  static String get toastSelectFolder => _s == 'id' ? 'Silakan pilih folder penyimpanan terlebih dahulu!' : 'Please select a save folder first!';
  static String get toastRenameSuccess => _s == 'id' ? 'File berhasil diubah namanya' : 'File renamed successfully';
  static String get hintSwipeDelete => _s == 'id' ? 'Geser kiri untuk menghapus riwayat' : 'Swipe left to remove from history';

  // Dialogs
  static String get dialogAddText => _s == 'id' ? 'Tambah Teks' : 'Add Text';
  static String get dialogEditText => _s == 'id' ? 'Edit Teks' : 'Edit Text';
  static String get dialogTextContent => _s == 'id' ? 'Konten Teks' : 'Text Content';
  static String get dialogSize => _s == 'id' ? 'Ukuran: ' : 'Size: ';
  static String get dialogFont => _s == 'id' ? 'Font: ' : 'Font: ';
  static String get dialogTextColor => _s == 'id' ? 'Warna Teks: ' : 'Text Color: ';
  static String get dialogPickColor => _s == 'id' ? 'Pilih warna!' : 'Pick a color!';

  // ML Kit / OCR
  static String get textNotFoundTitle => _s == 'id' ? 'Teks Tidak Ditemukan' : 'Text Not Found';
  static String get textNotFoundBody => _s == 'id'
      ? 'Mesin Syncfusion tidak dapat menemukan teks digital di sini.\n\nJika ini adalah dokumen scan/foto, silakan aktifkan "AI Scan (ML Kit)" di bagian bawah.'
      : 'Syncfusion engine could not find any digital text here.\n\nIf this is a scanned document/photo, please turn ON the "AI Scan (ML Kit)" toggle at the bottom.';
  static String get mlKitNotImplemented => _s == 'id' ? 'Mode AI ML Kit aktif. (Menunggu Implementasi Fase 2!)' : 'AI ML Kit mode is active. (Waiting for Phase 2 Implementation!)';
  
  // AI Tools specific
  static String get modeAiToolsLabel => _s == 'id' ? 'Fitur AI' : 'AI Features';
  static String get aiSubErase => _s == 'id' ? 'AI Eraser' : 'AI Eraser';
  static String get aiSubEdit => _s == 'id' ? 'Magic Edit' : 'Magic Edit';
  static String get aiSubCopy => _s == 'id' ? 'Smart Copy' : 'Smart Copy';
  static String get aiDownloadRequired => _s == 'id' ? 'Model Belum Diunduh' : 'Model Not Downloaded';
  static String get aiDownloadBody => _s == 'id' 
      ? 'Fitur AI Scan memerlukan koneksi internet untuk mengunduh modul pengenalan cerdas (~15MB). Pastikan internet menyala dan ketuk "Mulai Unduh".' 
      : 'AI Scan features require an internet connection to download the smart recognition engine (~15MB). Please ensure you are connected and tap "Start Download".';
  static String get btnDownload => _s == 'id' ? 'Mulai Unduh' : 'Start Download';
  static String get toastDownloadWait => _s == 'id' ? 'Sedang mengunduh di latar belakang...' : 'Downloading in background...';
  static String get toastDownloadFailed => _s == 'id' ? 'Unduhan gagal. Tidak ada koneksi internet.' : 'Download failed. No internet connection.';
  static String get toastErrorInit => _s == 'id' ? 'Kesalahan inisialisasi: ' : 'Error initializing: ';
  static String get toastAiScannerReady => _s == 'id' ? 'AI Scanner siap digunakan!' : 'AI Scanner is ready!';
  static String get toastAiNoTextFound => _s == 'id' ? 'Mesin AI tidak dapat menemukan teks di sini.' : 'AI Engine could not find any text here.';
  static String get toastPagesUpdated => _s == 'id' ? 'Halaman berhasil diperbarui' : 'Pages updated successfully';
  static String get labelBeta => 'Beta';
  static String get labelBasic => _s == 'id' ? 'Dasar' : 'Basic';
  static String get comingSoonTitle => _s == 'id' ? 'Segera Hadir!' : 'Coming Soon!';
  static String get magicEditDesc => _s == 'id' 
      ? 'Gunakan kekuatan AI untuk mengubah isi teks PDF secara cerdas tanpa merusak format.' 
      : 'Use AI power to smartly change PDF text content without breaking the format.';
  static String get smartCopyDesc => _s == 'id' 
      ? 'Salin data tabel atau teks kompleks dari PDF scan dengan struktur yang tetap rapi.' 
      : 'Copy table data or complex text from scanned PDFs while keeping the structure neat.';

  // Field Options Dialog
  static String optionsTitle(String type) => _s == 'id' ? 'Opsi $type' : '$type Options';
  static String deleteConfirmation(String type) => _s == 'id' ? 'Apakah Anda ingin menghapus $type ini?' : 'Do you want to delete this $type?';

  // Others
  static String get resetView => _s == 'id' ? 'Reset Tampilan' : 'Reset View';
  static String get drawSignature => _s == 'id' ? 'Buat Tanda Tangan' : 'Draw Signature';
  static String get clear => _s == 'id' ? 'Bersihkan' : 'Clear';
  static String get savePdf => _s == 'id' ? 'Simpan PDF' : 'Save PDF';
  static String get fileName => _s == 'id' ? 'Nama File' : 'File Name';
  static String get fileNameHint => _s == 'id' ? 'contoh: dokumenKu.pdf' : 'e.g. myDocument.pdf';
  static String get chooseSaveFolder => _s == 'id' ? 'Pilih Folder Penyimpanan' : 'Choose Save Folder';
  static String get tapToChooseFolder => _s == 'id' ? 'Ketuk untuk memilih folder...' : 'Tap to choose folder...';
  static String get noFolderSelectedError => _s == 'id' ? 'Wajib pilih folder tujuan agar file bisa ditemukan di File Manager HP.' : 'Must choose a destination folder so the file can be found in the Phone File Manager.';

  // Home Page Tabs
  static String get tabAll => _s == 'id' ? 'Semua' : 'All';
  static String get tabRecent => _s == 'id' ? 'Terbaru' : 'Recent';
  static String get tabDrafts => _s == 'id' ? 'Draf' : 'Drafts';
  static String get searchHint => _s == 'id' ? 'Cari file...' : 'Search files...';

  // Home Page Content
  static String get openNewPdf => _s == 'id' ? 'Buka PDF Baru' : 'Open New PDF';
  static String get continueEditing => _s == 'id' ? 'Lanjutkan Editing' : 'Continue Editing';
  static String get preparingDocument => _s == 'id' ? 'Menyiapkan Dokumen...' : 'Preparing Document...';
  static String get noRecentFiles => _s == 'id' ? 'Tidak ada file terbaru' : 'No recent files';
  static String get noMatchesInTab => _s == 'id' ? 'Tidak ada hasil di tab ini' : 'No matches found in this tab';
  static String get noFilesInCategory => _s == 'id' ? 'Tidak ada file dalam kategori ini' : 'No files in this category';
  static String get appSubtitle => _s == 'id' ? 'Edit, beri anotasi & tanda tangani PDF Anda' : 'Edit, annotate & sign your PDFs';

  // Home Page Dialogs
  static String get settings => _s == 'id' ? 'Pengaturan' : 'Settings';
  static String get theme => _s == 'id' ? 'Tema' : 'Theme';
  static String get language => _s == 'id' ? 'Bahasa' : 'Language';
  static String get themeDark => _s == 'id' ? 'Gelap' : 'Dark';
  static String get themeLight => _s == 'id' ? 'Terang' : 'Light';
  static String get resumeEditing => _s == 'id' ? 'Lanjutkan Editing?' : 'Resume Editing?';
  static String get resumeEditingBody => _s == 'id' ? 'File ini memiliki draf yang belum disimpan. Lanjutkan editing atau buka ulang dari awal?' : 'This file has unsaved draft edits. Would you like to continue editing or open fresh?';
  static String get openFresh => _s == 'id' ? 'Buka Baru' : 'Open Fresh';
  static String get resumeDraft => _s == 'id' ? 'Lanjutkan Draf' : 'Resume Draft';
  static String get removeFile => _s == 'id' ? 'Hapus File?' : 'Remove File?';
  static String removeFileBody(String name) => _s == 'id'
      ? 'Apa yang ingin dilakukan dengan "$name"?\n\nIni juga akan menghapus status draf yang tersimpan.'
      : 'What would you like to do with "$name"?\n\nThis will also clear any saved draft states.';
  static String get removeFromHistory => _s == 'id' ? 'Hapus dari Riwayat' : 'Remove from History';
  static String get deleteFromDevice => _s == 'id' ? 'Hapus File dari Perangkat' : 'Delete File from Device';
  static String get actionRename => _s == 'id' ? 'Ubah Nama' : 'Rename';
  static String get actionDelete => _s == 'id' ? 'Hapus' : 'Delete';
  static String get dialogRenameTitle => _s == 'id' ? 'Ubah Nama File' : 'Rename File';
  static String get dialogRenameHint => _s == 'id' ? 'Masukkan nama baru' : 'Enter new name';
  static String get couldNotDeleteFile => _s == 'id' ? 'Tidak bisa menghapus file: ' : 'Could not delete file: ';

  // New Audit Strings
  static String get error => _s == 'id' ? 'Kesalahan' : 'Error';
  static String get page => _s == 'id' ? 'Halaman' : 'Page';
  static String get standardA4 => _s == 'id' ? 'Standar A4' : 'Standard A4';
  static String get selectColor => _s == 'id' ? 'Pilih Warna' : 'Select Color';
  static String get docNotFound => _s == 'id' ? 'Dokumen tidak ditemukan' : 'Document not found';
  static String get langIndo => '🇮🇩 Indo';
  static String get langEnglish => '🇺🇸 English';
  static String get labelDraft => _s == 'id' ? 'Draf' : 'Draft';
  static String get deletePageTitle => _s == 'id' ? 'Hapus Halaman?' : 'Delete Page?';
  static String deletePageContent(int index) => _s == 'id' 
      ? 'Apakah Anda yakin ingin menghapus Halaman $index?' 
      : 'Are you sure you want to delete Page $index?';
  static String get cannotDeleteLastPage => _s == 'id' ? 'Tidak bisa menghapus halaman terakhir' : 'Cannot delete the last page';
  static String get byKDevLab => 'by K-Dev Lab';
  static String get labelEdited => _s == 'id' ? 'Diedit' : 'Edited';
}
