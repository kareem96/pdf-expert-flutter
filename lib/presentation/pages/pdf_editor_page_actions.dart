part of 'pdf_editor_page.dart';

// ignore_for_file: use_build_context_synchronously

extension _PdfEditorActions on _PdfEditorPageState {

  /// Calculates the [pdfX, pdfY, pageIndex] for the current center of the viewport
  Map<String, dynamic> _getSpawnPoints(PdfDocumentEntity doc) {
    final size = MediaQuery.of(context).size;
    final double screenCenterX = _scrollX + (size.width / 2);
    final double screenCenterY = _scrollY + (size.height / 2);

    double accumulatedHeight = 0;
    int pIdx = 0;
    double pageScale = 1.0;

    for (int i = 0; i < doc.pageWidths.length; i++) {
      double s = (size.width / doc.pageWidths[i]);
      if (s <= 0) s = 1.0;
      
      if (screenCenterY >= (accumulatedHeight * _zoom)) {
        pIdx = i;
        pageScale = s;
      }
      accumulatedHeight += doc.pageHeights[i] * s;
    }

    final double totalScale = pageScale * _zoom;
    final double pdfX = screenCenterX / totalScale;

    double tempH = 0;
    for (int i = 0; i < pIdx; i++) {
      double s = (size.width / doc.pageWidths[i]);
      tempH += doc.pageHeights[i] * s;
    }
    final double pageStartPx = tempH * _zoom;
    final double pdfY = (screenCenterY - pageStartPx) / totalScale;

    return {'x': pdfX, 'y': pdfY, 'pageIndex': pIdx};
  }

  Future<void> _onAddImage(PdfDocumentEntity doc) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final spawn = _getSpawnPoints(doc);
      ref.read(pdfEditorProvider.notifier).addImage(
        spawn['x'], spawn['y'], image.path, spawn['pageIndex'], isSignature: false
      );
    }
  }

  Future<void> _onAddSignature(PdfDocumentEntity doc) async {
    final SignatureController signatureController = SignatureController(
      penStrokeWidth: 5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
    );

    await showDialog(
       context: context,
       builder: (context) {
         return AlertDialog(
           title: Text(AppStrings.drawSignature),
           content: Container(
             color: Colors.grey.shade200,
             width: 300,
             height: 200,
             child: Signature(
               controller: signatureController,
               backgroundColor: Colors.transparent,
             ),
           ),
           actions: [
             TextButton(
               onPressed: () => signatureController.clear(),
               child: Text(AppStrings.clear, style: const TextStyle(color: Colors.red)),
             ),
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: Text(AppStrings.cancel),
             ),
             TextButton(
               onPressed: () async {
                 if (signatureController.isEmpty) return;
                 final signatureBytes = await signatureController.toPngBytes();
                 if (signatureBytes == null) return;
                 
                 final tempDir = await getTemporaryDirectory();
                 final file = await File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png').create();
                 file.writeAsBytesSync(signatureBytes);
                 final spawn = _getSpawnPoints(doc);
                 ref.read(pdfEditorProvider.notifier).addImage(
                   spawn['x'], spawn['y'], file.path, spawn['pageIndex'], isSignature: true
                 );
                 Navigator.pop(context);
               },
               child: Text(AppStrings.add),
             ),
           ],
         );
       },
    );
  }

  Future<void> _onSave(PdfDocumentEntity doc) async {
    String nameSuggestion = doc.fileName;
    if (nameSuggestion.toLowerCase().endsWith('.pdf')) {
      nameSuggestion = nameSuggestion.substring(0, nameSuggestion.length - 4);
    }
    if (!nameSuggestion.toLowerCase().startsWith('edited')) {
      nameSuggestion = 'Edited_$nameSuggestion';
    }

    final nameController = TextEditingController(text: nameSuggestion);
    String? selectedFolder = await _prefsService.getLastSaveDirectory();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(AppStrings.savePdf),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppStrings.fileName,
                  hintText: AppStrings.fileNameHint,
                  suffixText: '.pdf',
                  prefixIcon: const Icon(Icons.edit_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final folder = await FilePicker.platform.getDirectoryPath(
                    dialogTitle: AppStrings.chooseSaveFolder,
                  );
                  if (folder != null) {
                    await _prefsService.setLastSaveDirectory(folder);
                    setDState(() => selectedFolder = folder);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF44475A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 18, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedFolder ?? AppStrings.tapToChooseFolder,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: selectedFolder != null ? Colors.white : const Color(0xFF8888AA),
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8888AA)),
                    ],
                  ),
                ),
              ),
              if (selectedFolder == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    AppStrings.noFolderSelectedWarning,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8888AA)),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppStrings.save)),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    String fileName = nameController.text.trim();
    if (!fileName.toLowerCase().endsWith('.pdf')) fileName = '$fileName.pdf';

    final previousOriginalPath = doc.originalPath;

    try {
      await ref.read(pdfEditorProvider.notifier).saveDocument(
        customFileName: fileName,
        customDirectory: selectedFolder,
      );
      await _draftService.deleteDraft(previousOriginalPath);
      await _recentService.updateDraftStatus(previousOriginalPath, hasDraft: false);

      if (mounted) {
        CustomToast.show(context, message: AppStrings.toastSaveSuccess + fileName);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: AppStrings.toastSaveFailed + e.toString(), isError: true);
      }
    }
  }

  Future<void> _onShare(PdfDocumentEntity doc) async {
    await ref.read(pdfEditorProvider.notifier).shareDocument();
  }

  Future<Map<String, dynamic>?> _showTextEditorDialog({
    String initialText = '',
    double initialFontSize = 14,
    bool initialIsBold = false,
    bool initialIsItalic = false,
    String initialColor = '0xFF000000',
    String initialFontFamily = 'Helvetica',
    bool isEdit = false,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TextEditorDialog(
        initialText: initialText,
        initialFontSize: initialFontSize,
        initialIsBold: initialIsBold,
        initialIsItalic: initialIsItalic,
        initialColor: initialColor,
        initialFontFamily: initialFontFamily,
        isEdit: isEdit,
      ),
    );
  }

  void _onAddTextFromToolbar(PdfDocumentEntity doc) async {
    final spawn = _getSpawnPoints(doc);
    final val = await _showTextEditorDialog();
    if (val != null && val['action'] == 'save' && mounted) {
      ref.read(pdfEditorProvider.notifier).addFreeText(
        spawn['x'], spawn['y'], val['text'] as String, spawn['pageIndex'],
        fontSize: val['fontSize'] as double,
        textColor: val['color'] as String,
        fontFamily: val['fontFamily'] as String,
        isBold: val['isBold'] as bool,
        isItalic: val['isItalic'] as bool,
      );
    }
  }

  void _onAddStickyNote(PdfDocumentEntity doc) async {
    final spawn = _getSpawnPoints(doc);
    final val = await _showTextEditorDialog(
       initialFontFamily: 'Courier Prime',
       initialFontSize: 14.0,
       initialColor: '0xFF000000',
    );
    if (val != null && val['action'] == 'save' && mounted) {
      ref.read(pdfEditorProvider.notifier).addFreeText(
        spawn['x'], spawn['y'], val['text'] as String, spawn['pageIndex'],
        fontSize: val['fontSize'] as double,
        textColor: val['color'] as String,
        fontFamily: val['fontFamily'] as String,
        isBold: val['isBold'] as bool,
        isItalic: val['isItalic'] as bool,
        backgroundColor: '0xFFFDFCA8',
      );
    }
  }

  void _onAddCustomText(Offset position, int pageIndex) async {
    final result = await _showTextEditorDialog(isEdit: false);
    if (result != null && result['action'] == 'save') {
      ref.read(pdfEditorProvider.notifier).addFreeText(
        position.dx, position.dy, result['text'], pageIndex,
        fontSize: result['fontSize'],
        textColor: result['color'],
        fontFamily: result['fontFamily'] ?? 'Helvetica',
        isBold: result['isBold'],
        isItalic: result['isItalic'],
      );
    }
  }

  void _onEraseText(Offset position, int pageIndex, double currentZoom, {required bool isAiScan}) async {
    final docState = ref.read(pdfEditorProvider);
    if (docState.value == null) return;

    final doc = docState.value!;
    final repo = ref.read(pdfRepositoryProvider);

    // Provide visual feedback base on which engine is used
    if (isAiScan) {
      CustomToast.show(context, message: AppStrings.toastExtractingBounds);
    }

    final double dynamicHitPad = 6.0 / currentZoom;
    
    // Process extraction 
    final Rect? bounds = await repo.extractWordBounds(
      doc.filePath, 
      pageIndex, 
      position.dx, 
      position.dy, 
      pad: dynamicHitPad,
      useAiScan: isAiScan,
    );

    if (bounds != null) {
      _update(() {
        _pendingEraser = PdfFieldEntity(
          id: 'pending_erase',
          name: 'Pending Erase',
          type: PdfFieldType.eraser,
          x: bounds.left,
          y: bounds.top,
          width: bounds.width,
          height: bounds.height,
          pageIndex: pageIndex,
          isNewField: true,
          isModified: false,
        );
      });
      CustomToast.show(context, message: AppStrings.toastPreviewingErase);
    } else {
      if (isAiScan) {
          // If ML Kit fails, show a simple toast that nothing was found on the image
          CustomToast.show(context, message: AppStrings.toastAiNoTextFound);
      } else {
          // If Syncfusion fails, show the classic dialog offering AI Scan
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(AppStrings.textNotFoundTitle, style: const TextStyle(color: Colors.amber)),
              content: Text(AppStrings.textNotFoundBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppStrings.gotIt),
                ),
              ],
            ),
          );
      }
    }
  }

  void _onEditField(PdfFieldEntity field) async {
    if (field.type == PdfFieldType.marker) {
      final result = await _showMarkerSelectorDialog(
        initialType: field.value ?? 'check',
        initialColor: field.textColor,
        isEdit: true,
      );
      if (result != null) {
        if (result['action'] == 'delete') {
          ref.read(pdfEditorProvider.notifier).removeField(field.id);
        } else if (result['action'] == 'save') {
          ref.read(pdfEditorProvider.notifier).updateField(field.id, result['type']);
          ref.read(pdfEditorProvider.notifier).updateTextColor(field.id, result['color']);
        }
      }
      return;
    }

    if (field.type == PdfFieldType.image || field.type == PdfFieldType.signature || field.type == PdfFieldType.eraser) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.optionsTitle(field.type.name)),
          content: Text(AppStrings.deleteConfirmation(field.type.name)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
            TextButton(
              onPressed: () {
                 ref.read(pdfEditorProvider.notifier).removeField(field.id);
                 Navigator.pop(context);
              },
              child: Text(AppStrings.delete, style: const TextStyle(color: Colors.red)),
            ),
          ],
        )
      );
    }

    final result = await _showTextEditorDialog(
       initialText: field.value ?? '',
       initialFontSize: field.fontSize,
       initialIsBold: field.isBold,
       initialIsItalic: field.isItalic,
       initialColor: field.textColor,
       initialFontFamily: field.fontFamily,
       isEdit: true,
    );

    if (result != null) {
      if (result['action'] == 'delete') {
         ref.read(pdfEditorProvider.notifier).removeField(field.id);
      } else if (result['action'] == 'save') {
         ref.read(pdfEditorProvider.notifier).updateField(field.id, result['text']);
         ref.read(pdfEditorProvider.notifier).updateFontSize(field.id, result['fontSize']);
         ref.read(pdfEditorProvider.notifier).updateTextColor(field.id, result['color']);
         ref.read(pdfEditorProvider.notifier).updateFontFamily(field.id, result['fontFamily'] ?? 'Helvetica');
         ref.read(pdfEditorProvider.notifier).updateTextStyle(field.id, isBold: result['isBold'], isItalic: result['isItalic']);
      }
    }
  }

  void _onAddMarker(Offset pos, int pageIndex) async {
    final result = await _showMarkerSelectorDialog(initialType: _selectedMarkerType);
    if (result != null && result['action'] == 'save') {
      _update(() => _selectedMarkerType = result['type']);
      ref.read(pdfEditorProvider.notifier).addMarker(
        result['type'], pos.dx - 12.5, pos.dy - 12.5, 25, 25, pageIndex,
        color: result['color'],
      );
    }
  }

  Future<Map<String, dynamic>?> _showMarkerSelectorDialog({
    String initialType = 'check',
    String initialColor = '0xFF000000',
    bool isEdit = false,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => MarkerSelectorDialog(
        initialType: initialType,
        initialColor: initialColor,
        isEdit: isEdit,
      ),
    );
  }

  Future<void> _showAiScanDownloadPopup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cloud_download_outlined, color: Color(0xFF6C63FF)),
            const SizedBox(width: 8),
            Text(AppStrings.aiDownloadRequired, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(AppStrings.aiDownloadBody, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _startModelDownload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: Text(AppStrings.btnDownload),
          ),
        ],
      ),
    );
  }

  Future<void> _startModelDownload() async {
    if (_isAiScanDownloading) return;

    _update(() => _isAiScanDownloading = true);
    CustomToast.show(context, message: AppStrings.toastDownloadWait);

    try {
      await _mlKitModelService.downloadModel();
      if (mounted) {
        _update(() {
          _isAiScanDownloading = false;
          _isModelDownloaded = true;
          _activeMode = EditorMode.aiTools;
          _activeAiTool = 'erase';
        });
        CustomToast.show(context, message: AppStrings.toastAiScannerReady);
      }
    } catch (e) {
      if (mounted) {
        _update(() => _isAiScanDownloading = false);
        CustomToast.show(context, message: 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _onPageManagerTap(String path) async {
    final result = await Navigator.push<List<PageAction>>(
      context,
      MaterialPageRoute(
        builder: (context) => PageManagerPage(pdfPath: path),
      ),
    );

    if (result != null && result.isNotEmpty) {
      ref.read(pdfEditorProvider.notifier).applyPageActions(result);
      CustomToast.show(context, message: AppStrings.toastPagesUpdated);
    }
  }
}
