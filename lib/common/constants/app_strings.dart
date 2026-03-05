/// Centralized strings for the application to support easy changes and future localization.
class AppStrings {
  // General
  static const String appName = 'PDF Expert';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String ok = 'OK';
  static const String add = 'Add';
  static const String gotIt = 'Got it';
  
  // PDF Editor Page
  static const String leaveEditorTitle = 'Leave Editor?';
  static const String leaveEditorBody = 'What would you like to do with your changes?';
  static const String stay = 'Stay';
  static const String saveDraft = 'Save Draft';
  static const String discard = 'Discard';
  
  // Toolbar Modes
  static const String modeSign = 'Sign';
  static const String modeImage = 'Image';
  static const String modeText = 'Text';
  static const String modeErase = 'Erase';
  static const String modeMarker = 'Marker';
  static const String modeNote = 'Note';
  static const String modeSave = 'Save';
  static const String modeShare = 'Share';
  
  // Toast Messages
  static const String toastEraserActive = 'Eraser Mode Active. Tap any text on the PDF to wipe it.';
  static const String toastMarkerActive = 'Marker Mode Active. Tap on PDF to place a marker.';
  static const String toastTextErased = 'Text Erased Permanently!';
  static const String toastSaveSuccess = 'Saved as '; // Needs variable appended
  static const String toastSaveFailed = 'Save failed: '; // Needs variable appended
  static const String toastTextEmpty = 'Text cannot be empty';
  static const String toastExtractingBounds = 'Extracting boundaries...';
  static const String toastPreviewErase = 'Previewing area to erase...';
  
  // Dialogs
  static const String dialogAddText = 'Add Text';
  static const String dialogEditText = 'Edit Text';
  static const String dialogTextContent = 'Text Content';
  static const String dialogSize = 'Size: ';
  static const String dialogFont = 'Font: ';
  static const String dialogTextColor = 'Text Color: ';
  static const String dialogPickColor = 'Pick a color!';
  
  // ML Kit / OCR
  static const String textNotFoundTitle = 'Text Not Found';
  static const String textNotFoundBody = 'Syncfusion engine could not find any digital text here.\n\nIf this is a scanned document/photo, please turn ON the "AI Scan (ML Kit)" toggle at the bottom to use machine learning.';
  static const String mlKitNotImplemented = 'AI ML Kit mode is active. (Waiting for Phase 2 Implementation!)';
  
  // Field Options Dialog
  static String optionsTitle(String type) => '$type Options';
  static String deleteConfirmation(String type) => 'Do you want to delete this $type?';
  
  // Others
  static const String resetView = 'Reset View';
  static const String drawSignature = 'Draw Signature';
  static const String clear = 'Clear';
  static const String savePdf = 'Save PDF';
  static const String fileName = 'File Name';
  static const String fileNameHint = 'e.g. myDocument.pdf';
  static const String chooseSaveFolder = 'Choose Save Folder';
  static const String tapToChooseFolder = 'Tap to choose folder...';
  static const String noFolderSelectedWarning = 'No folder selected — will save to app storage.';
  static const String toastPreviewingErase = 'Previewing area to erase...';
  
}
