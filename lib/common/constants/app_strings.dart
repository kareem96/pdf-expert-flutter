class AppStrings {
  static String _currentLanguage = 'id';

  static void setLanguage(String code) {
    if (code == 'en' || code == 'id') {
      _currentLanguage = code;
    }
  }

  static String get _s => _currentLanguage;

  // General
  static String get appName => _s == 'id' ? 'PDF Expert' : 'PDF Expert';
  static String get cancel => _s == 'id' ? 'Batal' : 'Cancel';
  static String get save => _s == 'id' ? 'Simpan' : 'Save';
  static String get delete => _s == 'id' ? 'Hapus' : 'Delete';
  static String get ok => _s == 'id' ? 'OK' : 'OK';
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
  static String get modeMarker => _s == 'id' ? 'Penanda' : 'Marker';
  static String get modeNote => _s == 'id' ? 'Catatan' : 'Note';
  static String get modeSave => _s == 'id' ? 'Simpan' : 'Save';
  static String get modeShare => _s == 'id' ? 'Bagikan' : 'Share';
  
  // Toast Messages
  static String get toastEraserActive => _s == 'id' ? 'Mode Penghapus Aktif. Ketuk teks manapun di PDF untuk menghapusnya.' : 'Eraser Mode Active. Tap any text on the PDF to wipe it.';
  static String get toastMarkerActive => _s == 'id' ? 'Mode Penanda Aktif. Ketuk PDF untuk menaruh penanda.' : 'Marker Mode Active. Tap on PDF to place a marker.';
  static String get toastTextErased => _s == 'id' ? 'Teks Berhasil Dihapus Permanen!' : 'Text Erased Permanently!';
  static String get toastSaveSuccess => _s == 'id' ? 'Tersimpan sebagai ' : 'Saved as ';
  static String get toastSaveFailed => _s == 'id' ? 'Gagal menyimpan: ' : 'Save failed: ';
  static String get toastTextEmpty => _s == 'id' ? 'Teks tidak boleh kosong' : 'Text cannot be empty';
  static String get toastExtractingBounds => _s == 'id' ? 'Mengekstrak batas teks...' : 'Extracting boundaries...';
  static String get toastPreviewErase => _s == 'id' ? 'Menampilkan pratinjau area yang akan dihapus...' : 'Previewing area to erase...';
  
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
  static String get textNotFoundBody => _s == 'id' ? 'Mesin Syncfusion tidak dapat menemukan teks digital di sini.\n\nJika ini adalah dokumen scan/foto, silakan aktifkan "AI Scan (ML Kit)" di bagian bawah.' : 'Syncfusion engine could not find any digital text here.\n\nIf this is a scanned document/photo, please turn ON the "AI Scan (ML Kit)" toggle at the bottom to use machine learning.';
  static String get mlKitNotImplemented => _s == 'id' ? 'Mode AI ML Kit aktif. (Menunggu Implementasi Fase 2!)' : 'AI ML Kit mode is active. (Waiting for Phase 2 Implementation!)';
  
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
  static String get noFolderSelectedWarning => _s == 'id' ? 'Tidak ada folder dipilih — akan disimpan ke penyimpanan aplikasi.' : 'No folder selected — will save to app storage.';
  static String get toastPreviewingErase => _s == 'id' ? 'Menampilkan pratinjau area yang akan dihapus...' : 'Previewing area to erase...';

  // Home Page Tabs
  static String get tabAll => _s == 'id' ? 'Semua' : 'All';
  static String get tabRecent => _s == 'id' ? 'Terbaru' : 'Recent';
  static String get tabDrafts => _s == 'id' ? 'Draf' : 'Drafts';
  static String get searchHint => _s == 'id' ? 'Cari file...' : 'Search files...';
}
