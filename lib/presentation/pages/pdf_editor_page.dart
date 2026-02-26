import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../domain/entities/pdf_document_entity.dart';
import '../../domain/entities/pdf_field_entity.dart';
import '../providers/pdf_editor_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/draft_service.dart';
import '../../data/services/recent_files_service.dart';
import '../../data/services/app_preferences_service.dart';
import '../widgets/custom_toast.dart';

class PdfEditorPage extends ConsumerStatefulWidget {
  const PdfEditorPage({super.key});

  @override
  ConsumerState<PdfEditorPage> createState() => _PdfEditorPageState();
}

class _PdfEditorPageState extends ConsumerState<PdfEditorPage> with WidgetsBindingObserver {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final _draftService = DraftService();
  final _recentService = RecentFilesService();
  final _prefsService = AppPreferencesService();
  int _currentPage = 1;
  double _scrollX = 0;
  double _scrollY = 0;
  double _zoom = 1.0;
  /// Track multiple fingers to detect Pinch Zoom
  int _pointers = 0;
  double? _calibrationRatio; // Pixels per Point (Calibrated from first tap)

  @override
  void initState() {
    super.initState();
    _pdfViewerController.addListener(_onControllerChange);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pdfViewerController.removeListener(_onControllerChange);
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _autoSaveDraft();
    }
  }

  Future<void> _autoSaveDraft() async {
    final doc = ref.read(pdfEditorProvider).asData?.value;
    if (doc != null && doc.isModified) {
      // PENTING: Gunakan originalPath untuk ID Draft agar sinkron dengan dashboard
      await _draftService.saveDraft(doc.originalPath, doc.fields);
      await _recentService.updateDraftStatus(doc.originalPath, hasDraft: true);
    }
  }

  void _onControllerChange() {
    if (!mounted) return;
    try {
      if (_currentPage != _pdfViewerController.pageNumber ||
          _zoom != _pdfViewerController.zoomLevel ||
          _scrollX != _pdfViewerController.scrollOffset.dx ||
          _scrollY != _pdfViewerController.scrollOffset.dy) {
        setState(() {
          _currentPage = _pdfViewerController.pageNumber;
          _zoom = _pdfViewerController.zoomLevel;
          _scrollX = _pdfViewerController.scrollOffset.dx;
          _scrollY = _pdfViewerController.scrollOffset.dy;
        });
      }
    } catch (_) {
      // Viewer controller might not be ready yet
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfState = ref.watch(pdfEditorProvider);
    final doc = pdfState.asData?.value;
    final docName = doc?.fileName ?? '';
    final isEditing = doc != null;

    return PopScope(
      // canPop: false means we handle back ourselves
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!isEditing) {
          // No PDF open (fallback) → just go back
          if (context.mounted) Navigator.of(context).pop();
          return;
        }
        
        // Skip asking if there are no unsaved changes
        if (!doc.isModified) {
          ref.read(pdfEditorProvider.notifier).clearDocument();
          if (context.mounted) Navigator.of(context).pop();
          return;
        }
        
        // PDF is open and modified → ask user what they want
        final result = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave Editor?'),
            content: const Text(
              'What would you like to do with your changes?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'draft'),
                child: const Text('Save Draft'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'discard'),
                child: const Text('Discard', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (result == 'discard') {
          // Delete draft if exists
          final doc = ref.read(pdfEditorProvider).asData?.value;
          if (doc != null) {
            await _draftService.deleteDraft(doc.originalPath);
            await _recentService.updateDraftStatus(doc.originalPath, hasDraft: false);
          }
          ref.read(pdfEditorProvider.notifier).clearDocument();
          if (context.mounted) Navigator.of(context).pop();
        } else if (result == 'draft') {
          await _autoSaveDraft();
          ref.read(pdfEditorProvider.notifier).clearDocument();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E).withOpacity(0.7),
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFF3E3E5A), width: 0.5),
                  ),
                ),
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PDF Expert',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (docName.isNotEmpty)
                      Text(
                        docName,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF8888BB),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.undo_rounded,
                size: 20,
                color: ref.watch(pdfEditorProvider.notifier).canUndo 
                    ? Colors.white 
                    : Colors.white24,
              ),
              onPressed: ref.watch(pdfEditorProvider.notifier).canUndo 
                  ? () => ref.read(pdfEditorProvider.notifier).undo() 
                  : null,
            ),
            IconButton(
              icon: Icon(
                Icons.redo_rounded,
                size: 20,
                color: ref.watch(pdfEditorProvider.notifier).canRedo 
                    ? Colors.white 
                    : Colors.white24,
              ),
              onPressed: ref.watch(pdfEditorProvider.notifier).canRedo 
                  ? () => ref.read(pdfEditorProvider.notifier).redo() 
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          bottom: isEditing
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(44),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF252540).withOpacity(0.6),
                          border: const Border(
                            top: BorderSide(color: Color(0xFF3E3E5A), width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            _ToolbarButton(icon: Icons.draw_outlined,  label: 'Sign',  onTap: () => _onAddSignature(doc)),
                            _ToolbarButton(icon: Icons.image_outlined, label: 'Image', onTap: () => _onAddImage(doc)),
                            _ToolbarButton(icon: Icons.title_rounded,  label: 'Text',  onTap: () => _onAddTextFromToolbar(doc)),
                            _ToolbarButton(icon: Icons.sticky_note_2_outlined, label: 'Note', onTap: () => _onAddStickyNote(doc)),
                            _ToolbarButton(icon: Icons.save_outlined,  label: 'Save',  onTap: () => _onSave(doc)),
                            _ToolbarButton(icon: Icons.share_outlined, label: 'Share', onTap: () => _onShare(doc)),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        body: pdfState.when(
          data: (doc) {
            if (doc == null) {
              // Returning an empty box ensures no scary warnings flash on screen
              // while the page is animating closed.
              return const SizedBox.shrink();
            }

          return LayoutBuilder(
            builder: (context, constraints) {
              final double pageWidth = doc.pageWidth;
              final double baseScale = constraints.maxWidth / pageWidth;
            
              return Listener(
                onPointerDown: (_) {
                  setState(() => _pointers++);
                },
                onPointerUp: (_) {
                  setState(() => _pointers = (_pointers > 0) ? _pointers - 1 : 0);
                },
                onPointerCancel: (_) {
                  setState(() => _pointers = (_pointers > 0) ? _pointers - 1 : 0);
                },
                child: ClipRect(
                  child: Stack(
                    children: [
                      Container(
                        color: Colors.white,
                        child: SfPdfViewer.file(
                          File(doc.filePath),
                          key: ValueKey(doc.filePath),
                          controller: _pdfViewerController,
                          pageSpacing: 0,
                          interactionMode: PdfInteractionMode.pan,
                          onTap: (details) {
                            // AUTO-CALIBRATION: Detect actual scale used by SfPdfViewer
                            if (_calibrationRatio == null && details.pagePosition.dx > 10) {
                              // Gunakan rasio antara logical screen pixels dan PDF points
                              final double currentScale = details.position.dx / details.pagePosition.dx;
                              if (currentScale > 0.1 && currentScale < 10.0) {
                                _calibrationRatio = currentScale;
                                print('PdfEditor CALIBRATION: Ratio set to $_calibrationRatio (Logical Pixels per Point)');
                              }
                            }
                            
                            final double curZoom = _pdfViewerController.zoomLevel;
                            final Offset curScroll = _pdfViewerController.scrollOffset;
                            print('PdfEditor DEBUG: TAP Page:${details.pageNumber} Screen:[${details.position.dx.toStringAsFixed(1)}, ${details.position.dy.toStringAsFixed(1)}] Points:[${details.pagePosition.dx.toStringAsFixed(1)}, ${details.pagePosition.dy.toStringAsFixed(1)}] Scroll:[${curScroll.dx.toStringAsFixed(1)}, ${curScroll.dy.toStringAsFixed(1)}] Zoom:${curZoom.toStringAsFixed(2)}');
                            _onAddCustomText(details.pagePosition, details.pageNumber - 1);
                          },
                          onFormFieldValueChanged: (details) {
                             print('PdfEditor DEBUG: Form field "${details.formField.name}" changed to "${details.newValue}"');
                             ref.read(pdfEditorProvider.notifier).updateField(details.formField.name, details.newValue as String);
                          },
                        onDocumentLoadFailed: (details) {
                          print('SfPdfViewer ERROR: ${details.description}');
                          if (mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Can\'t Open PDF', style: TextStyle(color: Colors.redAccent)),
                                content: Text('Error: ${details.description}\n\nThis file might be corrupted, password-protected, or has an unsupported format.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx); // close dialog
                                      Navigator.of(context).maybePop(); // leave editor
                                    },
                                    child: const Text('Go Back'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      ),
                      // Render overlays via AnimatedBuilder for ZERO lag during scroll/zoom
                      AnimatedBuilder(
                        animation: _pdfViewerController,
                        builder: (context, child) {
                          // Hide overlays strictly when zooming (2+ fingers)
                          if (_pointers > 1) {
                            return const SizedBox.shrink();
                          }
                          // Secara realtime, ambil variabel sinkron dari controller
                          // Secara realtime, ambil variabel sinkron dari controller
                          final currentZoom = _pdfViewerController.zoomLevel;
                          final currentScrollX = _pdfViewerController.scrollOffset.dx;
                          final currentScrollY = _pdfViewerController.scrollOffset.dy;

                              // 1. HITUNG PEMETAAN HALAMAN DINAMIS
                              final List<double> pPixelOffsets = [];
                              final List<double> pScales = [];
                              double accumulatedHeight = 0;

                              for (int i = 0; i < doc.pageWidths.length; i++) {
                                // GUNAKAN RASIO KALIBRASI JIKA ADA, FALLBACK KE LOGICAL WIDTH
                                final double dpr = MediaQuery.of(context).devicePixelRatio;
                                double s = _calibrationRatio ?? (constraints.maxWidth / doc.pageWidths[i]);
                                // Safely handle zero or extreme ratios
                                if (s <= 0) s = 1.0; 
                                
                                pScales.add(s);
                                pPixelOffsets.add(accumulatedHeight);
                                accumulatedHeight += doc.pageHeights[i] * s;
                              }

                          return Stack(
                            children: doc.fields.where((f) => f.isNewField).map((field) {
                              final int pIdx = field.pageIndex;
                              if (pIdx >= pScales.length) return const SizedBox.shrink();

                              final double pageScale = pScales[pIdx];
                              final double pageTopPixel = pPixelOffsets[pIdx];
                              
                              // Proyeksi Koordinat Asli ke Pixel (Zoom 1.0)
                              final double sceneX = field.x * pageScale;
                              final double sceneY = pageTopPixel + (field.y * pageScale);

                              // Proyeksi Pixel ke Layar (Disesuaikan dengan Zoom & Scroll)
                              // RUMUS: (Posisi_Pixel * Zoom) - Scroll + Padding_Centering
                              double paddingY = 0;
                              final double totalDocHeightPixels = accumulatedHeight * currentZoom;
                              if (totalDocHeightPixels < constraints.maxHeight) {
                                paddingY = (constraints.maxHeight - totalDocHeightPixels) / 2;
                              }

                              double paddingX = 0; // Karena halaman sudah Fit to Width (Scale dihitung dari maxWidth)

                              final double screenX = (sceneX * currentZoom) - currentScrollX + paddingX;
                              final double screenY = (sceneY * currentZoom) - currentScrollY + paddingY;
                              final double currentTotalScale = pageScale * currentZoom;

                              return _PdfFieldOverlay(
                                key: ValueKey(field.id),
                                field: field,
                                scale: currentTotalScale,
                                offset: Offset(screenX, screenY),
                                onUpdatePosition: (dx, dy) {
                                  // Konversi balik pixel layar ke Points PDF
                                  final double realDxPoints = dx / currentTotalScale;
                                  final double realDyPoints = dy / currentTotalScale;

                                  ref.read(pdfEditorProvider.notifier).updateFieldPosition(
                                        field.id,
                                        field.x + realDxPoints,
                                        field.y + realDyPoints,
                                      );
                                },
                                onResize: (dw, dh) {
                                  final double realW = field.width + (dw / currentTotalScale);
                                  final double realH = field.height + (dh / currentTotalScale);
                                  ref.read(pdfEditorProvider.notifier).updateFieldSize(
                                    field.id,
                                    realW > 10 ? realW : 10,
                                    realH > 10 ? realH : 10,
                                  );
                                },
                                onEdit: () {
                                  ref.read(pdfEditorProvider.notifier).updateField(field.id, field.value ?? '');
                                  _onEditField(field);
                                },
                              );
                            }).toList(),
                          );
                        }
                      ),
                    ],
                  ),
                ),
              );

            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
      ),    // closes pdfState.when
      ),    // closes Scaffold
    );      // closes PopScope
  }



  Future<void> _onAddImage(PdfDocumentEntity doc) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final pageIndex = _currentPage > 0 ? _currentPage - 1 : 0;
      
      // Hitung posisi Y agar muncul di layar (bukan nyasar di ujung atas Halaman 1)
      final double currentScale = (_calibrationRatio ?? (MediaQuery.of(context).size.width / doc.pageWidth)) * _zoom;
      final double viewTopPoints = _scrollY / currentScale;
      final double pageTopPoints = pageIndex < doc.pageOffsets.length ? doc.pageOffsets[pageIndex] : 0;
      
      double spawnY = viewTopPoints - pageTopPoints + 50; // Muncul 50 points di bawah batas atas layar
      if (spawnY < 0) spawnY = 50;
      if (pageIndex < doc.pageHeights.length && spawnY > doc.pageHeights[pageIndex] - 50) {
        spawnY = doc.pageHeights[pageIndex] - 150;
      }

      ref.read(pdfEditorProvider.notifier).addImage(50, spawnY, image.path, pageIndex, isSignature: false);
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
           title: const Text('Draw Signature'),
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
               child: const Text('Clear', style: TextStyle(color: Colors.red)),
             ),
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: const Text('Cancel'),
             ),
             TextButton(
               onPressed: () async {
                 if (signatureController.isNotEmpty) {
                   final signatureBytes = await signatureController.toPngBytes();
                   if (signatureBytes != null) {
                     final tempDir = await getTemporaryDirectory();
                     final file = await File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png').create();
                     file.writeAsBytesSync(signatureBytes);
                                          final pageIndex = _currentPage > 0 ? _currentPage - 1 : 0;
                      
                      // Hitung posisi Y agar signature muncul di tengah layar saat di-scroll
                      final double currentScale = (_calibrationRatio ?? (MediaQuery.of(context).size.width / doc.pageWidth)) * _zoom;
                      final double viewTopPoints = _scrollY / currentScale;
                      final double pageTopPoints = pageIndex < doc.pageOffsets.length ? doc.pageOffsets[pageIndex] : 0;
                      
                      double spawnY = viewTopPoints - pageTopPoints + 50; 
                      if (spawnY < 0) spawnY = 50;
                      if (pageIndex < doc.pageHeights.length && spawnY > doc.pageHeights[pageIndex] - 50) {
                        spawnY = doc.pageHeights[pageIndex] - 150;
                      }

                      ref.read(pdfEditorProvider.notifier).addImage(50, spawnY, file.path, pageIndex, isSignature: true);
                    }
                    Navigator.pop(context);
                 }
               },
               child: const Text('Add'),
             ),
           ],
         );
       },
    );
  }

  Future<void> _onSave(PdfDocumentEntity doc) async {
    // Dialog: isi nama file dan pilih folder tujuan
    String nameSuggestion = doc.fileName;
    if (nameSuggestion.toLowerCase().endsWith('.pdf')) {
      nameSuggestion = nameSuggestion.substring(0, nameSuggestion.length - 4);
    }
    if (!nameSuggestion.toLowerCase().startsWith('edited')) {
      nameSuggestion = 'Edited_$nameSuggestion';
    }

    final nameController = TextEditingController(
      text: nameSuggestion,
    );
    String? selectedFolder = await _prefsService.getLastSaveDirectory();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Save PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'File Name',
                  hintText: 'e.g. myDocument.pdf',
                  suffixText: '.pdf',
                  prefixIcon: const Icon(Icons.edit_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final folder = await FilePicker.platform.getDirectoryPath(
                    dialogTitle: 'Choose Save Folder',
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
                          selectedFolder ?? 'Tap to choose folder...',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: selectedFolder != null
                                ? Colors.white
                                : const Color(0xFF8888AA),
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
                    'No folder selected — will save to app storage.',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8888AA)),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // Build final file name (ensure .pdf extension)
    String fileName = nameController.text.trim();
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      fileName = '$fileName.pdf';
    }

    final previousOriginalPath = doc.originalPath;

    try {
      await ref.read(pdfEditorProvider.notifier).saveDocument(
        customFileName: fileName,
        customDirectory: selectedFolder,
      );
      
      // Success: Clear the old draft that belonged to the previous original file path
      // because those changes have just been committed successfully to the new file.
      await _draftService.deleteDraft(previousOriginalPath);
      await _recentService.updateDraftStatus(previousOriginalPath, hasDraft: false);

      if (mounted) {
        CustomToast.show(context, message: 'Saved as $fileName');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: 'Save failed: $e', isError: true);
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
  }) async {
    final textController = TextEditingController(text: initialText);
    double currentFontSize = initialFontSize;
    bool isBold = initialIsBold;
    bool isItalic = initialIsItalic;
    String currentColor = initialColor;
    String currentFontFamily = initialFontFamily;

    // Pasangan: label, googleFontName, syncfusionFontName
    // value = googleFontName yang akan disimpan di entity dan dipakai di UI
    final List<Map<String, String>> fontOptions = [
      {'label': 'Arial / Helvetica', 'value': 'Helvetica'},
      {'label': 'Times New Roman',   'value': 'Merriweather'},   // serif via google fonts
      {'label': 'Courier / Mono',    'value': 'Courier Prime'},  // monospace via google fonts
      {'label': 'Roboto',            'value': 'Roboto'},
      {'label': 'Playfair Display',  'value': 'Playfair Display'},
      {'label': 'Dancing Script',    'value': 'Dancing Script'},  // cursive/handwriting
    ];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Text' : 'Add Text'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  autofocus: !isEdit,
                  decoration: const InputDecoration(labelText: 'Text Content'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Size: '),
                    Expanded(
                      child: Slider(
                        value: currentFontSize,
                        min: 8,
                        max: 48,
                        divisions: 40,
                        label: currentFontSize.toInt().toString(),
                        onChanged: (val) {
                          setState(() => currentFontSize = val);
                        },
                      ),
                    ),
                    Text(currentFontSize.toInt().toString()),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('B', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: isBold,
                      onSelected: (val) => setState(() => isBold = val),
                    ),
                    const SizedBox(width: 10),
                    FilterChip(
                      label: const Text('I', style: TextStyle(fontStyle: FontStyle.italic)),
                      selected: isItalic,
                      onSelected: (val) => setState(() => isItalic = val),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Font: '),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: currentFontFamily,
                        items: fontOptions.map((f) => DropdownMenuItem(
                          value: f['value'],
                          child: Text(
                            f['label']!,
                            style: _buildGoogleFontStyle(f['value']!, fontSize: 14),
                          ),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => currentFontFamily = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Text Color: '),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            Color pickerColor = Color(int.parse(currentColor));
                            return AlertDialog(
                              title: const Text('Pick a color!'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: pickerColor,
                                  onColorChanged: (color) {
                                    pickerColor = color;
                                  },
                                ),
                              ),
                              actions: <Widget>[
                                ElevatedButton(
                                  child: const Text('Got it'),
                                  onPressed: () {
                                    setState(() {
                                      // Konversi dari Color ke 0xAARRGGBB format string kustom milik app
                                      currentColor = '0x${pickerColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(int.parse(currentColor)),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            if (isEdit)
               TextButton(
                 onPressed: () => Navigator.pop(context, {'action': 'delete'}),
                 child: const Text('Delete', style: TextStyle(color: Colors.red)),
               ),
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            TextButton(
              onPressed: () {
                if (textController.text.trim().isEmpty) {
                   CustomToast.show(context, message: 'Text cannot be empty', isError: true);
                   return;
                }
                Navigator.pop(context, {
                  'action': 'save',
                  'text': textController.text,
                  'fontSize': currentFontSize,
                  'isBold': isBold,
                  'isItalic': isItalic,
                  'color': currentColor,
                  'fontFamily': currentFontFamily,
                });
              },
              child: Text(isEdit ? 'OK' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddTextFromToolbar(PdfDocumentEntity doc) async {
    // Determine the center of the currently visible screen
    final centerOffsetX = _scrollX + (MediaQuery.of(context).size.width / 2);
    final centerOffsetY = _scrollY + ((MediaQuery.of(context).size.height - 100) / 2); // approximate appBar offset
    final currentScale = _calibrationRatio ?? 1.0;

    // Convert screen coordinates to PDF Points roughly
    final logicalPointDx = centerOffsetX / currentScale;
    final logicalPointDy = centerOffsetY / currentScale;

    // Estimate which page we are currently looking at based on Y scroll
    int targetPage = 0;
    double accumulatedHeight = 0;
    for (int i = 0; i < doc.pageHeights.length; i++) {
        accumulatedHeight += doc.pageHeights[i] * currentScale;
        if (centerOffsetY < accumulatedHeight) {
           targetPage = i;
           break;
        }
    }

    final val = await _showTextEditorDialog();
    if (val != null && val['action'] == 'save' && mounted) {
      final text = val['text'] as String;
      ref.read(pdfEditorProvider.notifier).addFreeText(
        logicalPointDx,
        logicalPointDy,
        text,
        targetPage,
        fontSize: val['fontSize'] as double,
        textColor: val['color'] as String,
        fontFamily: val['fontFamily'] as String,
        isBold: val['isBold'] as bool,
        isItalic: val['isItalic'] as bool,
      );
    }
  }

  void _onAddStickyNote(PdfDocumentEntity doc) async {
    // Determine the center of the currently visible screen
    final centerOffsetX = _scrollX + (MediaQuery.of(context).size.width / 2);
    final centerOffsetY = _scrollY + ((MediaQuery.of(context).size.height - 100) / 2);
    final currentScale = _calibrationRatio ?? 1.0;

    // Convert screen coordinates to PDF Points
    final logicalPointDx = centerOffsetX / currentScale;
    final logicalPointDy = centerOffsetY / currentScale;

    // Estimate which page we are currently looking at based on Y scroll
    int targetPage = 0;
    double accumulatedHeight = 0;
    for (int i = 0; i < doc.pageHeights.length; i++) {
        accumulatedHeight += doc.pageHeights[i] * currentScale;
        if (centerOffsetY < accumulatedHeight) {
           targetPage = i;
           break;
        }
    }

    // Reuse the text editor dialog but with presets specifically styled like a Yellow Post-it Note
    final val = await _showTextEditorDialog(
       initialFontFamily: 'Courier Prime',
       initialFontSize: 14.0,
       initialColor: '0xFF000000', // Black text always
    );
    
    if (val != null && val['action'] == 'save' && mounted) {
      final text = val['text'] as String;
      ref.read(pdfEditorProvider.notifier).addFreeText(
        logicalPointDx,
        logicalPointDy,
        text,
        targetPage,
        fontSize: val['fontSize'] as double,
        textColor: val['color'] as String,
        fontFamily: val['fontFamily'] as String,
        isBold: val['isBold'] as bool,
        isItalic: val['isItalic'] as bool,
        backgroundColor: '0xFFFDFCA8', // Distinct Post-it Note pastel yellow!
      );
    }
  }

  void _onAddCustomText(Offset position, int pageIndex) async {
    final result = await _showTextEditorDialog(isEdit: false);

    if (result != null && result['action'] == 'save') {
      ref.read(pdfEditorProvider.notifier).addFreeText(
        position.dx, 
        position.dy, 
        result['text'], 
        pageIndex,
        fontSize: result['fontSize'],
        textColor: result['color'],
        fontFamily: result['fontFamily'] ?? 'Helvetica',
        isBold: result['isBold'],
        isItalic: result['isItalic'],
      );
    }
  }

  void _onEditField(PdfFieldEntity field) async {
    if (field.type == PdfFieldType.image || field.type == PdfFieldType.signature) {
      // Just show dialog to delete for image/signature since we can reshape them by dragging
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Image Options'),
          content: const Text('Do you want to delete this image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            TextButton(
              onPressed: () {
                 ref.read(pdfEditorProvider.notifier).removeField(field.name);
                 Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
         ref.read(pdfEditorProvider.notifier).removeField(field.name);
      } else if (result['action'] == 'save') {
         ref.read(pdfEditorProvider.notifier).updateField(field.id, result['text']);
         ref.read(pdfEditorProvider.notifier).updateFontSize(field.id, result['fontSize']);
         ref.read(pdfEditorProvider.notifier).updateTextColor(field.id, result['color']);
         ref.read(pdfEditorProvider.notifier).updateFontFamily(field.id, result['fontFamily'] ?? 'Helvetica');
         ref.read(pdfEditorProvider.notifier).updateTextStyle(field.id, isBold: result['isBold'], isItalic: result['isItalic']);
      }
    }
  }
}

class _PdfFieldOverlay extends StatefulWidget {
  final PdfFieldEntity field;
  final double scale;
  final Offset offset;
  final Function(double dx, double dy) onUpdatePosition;
  final Function(double dw, double dh) onResize;
  final VoidCallback onEdit;

  const _PdfFieldOverlay({
    Key? key,
    required this.field,
    required this.scale,
    required this.offset,
    required this.onUpdatePosition,
    required this.onResize,
    required this.onEdit,
  }) : super(key: key);

  @override
  State<_PdfFieldOverlay> createState() => _PdfFieldOverlayState();
}

class _PdfFieldOverlayState extends State<_PdfFieldOverlay> {
  double _dragDx = 0;
  double _dragDy = 0;
  
  double _resizeDw = 0;
  double _resizeDh = 0;

  @override
  void didUpdateWidget(_PdfFieldOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offset != widget.offset) {
      _dragDx = 0;
      _dragDy = 0;
    }
    if (oldWidget.field.width != widget.field.width || oldWidget.field.height != widget.field.height) {
      _resizeDw = 0;
      _resizeDh = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isImageOrSign = widget.field.type == PdfFieldType.image || widget.field.type == PdfFieldType.signature;

    final double currentWidth = math.max(20.0, (widget.field.width * widget.scale) + _resizeDw);
    final double currentHeight = math.max(20.0, (widget.field.height * widget.scale) + _resizeDh);

    return Positioned(
      left: widget.offset.dx + _dragDx,
      top: widget.offset.dy + _dragDy,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _dragDx += details.delta.dx;
                _dragDy += details.delta.dy;
              });
            },
            onPanEnd: (details) {
              widget.onUpdatePosition(_dragDx, _dragDy);
            },
            onTap: widget.onEdit,
            child: Container(
              width: isImageOrSign ? currentWidth : null,
              height: isImageOrSign ? currentHeight : null,
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: (isImageOrSign && (widget.field.value == null || widget.field.value!.isEmpty))
                    ? Colors.transparent 
                    : Colors.white.withOpacity(0.05),
                border: (isImageOrSign && (widget.field.value == null || widget.field.value!.isEmpty))
                    ? null
                    : Border.all(
                        color: Colors.blue.withOpacity(0.8), 
                        width: 1.5, 
                      ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: isImageOrSign
                  ? (widget.field.value != null && widget.field.value!.isNotEmpty)
                      ? Image.file(
                          File(widget.field.value!),
                          width: currentWidth,
                          height: currentHeight,
                          fit: BoxFit.fill,
                        )
                      : const SizedBox.shrink()
                    : Container(
                        padding: widget.field.backgroundColor != null 
                            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                            : EdgeInsets.zero,
                        decoration: widget.field.backgroundColor != null 
                            ? BoxDecoration(
                                color: Color(int.parse(widget.field.backgroundColor!)),
                                border: Border.all(color: Colors.amber.shade600, width: 2),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ) 
                            : null,
                        child: Text(
                          widget.field.value ?? '',
                          style: _buildGoogleFontStyle(
                            widget.field.fontFamily,
                            fontSize: widget.field.fontSize * widget.scale,
                            color: Color(int.parse(widget.field.textColor)),
                            fontWeight: widget.field.isBold ? FontWeight.bold : FontWeight.normal,
                            fontStyle: widget.field.isItalic ? FontStyle.italic : FontStyle.normal,
                          ).copyWith(height: 1.1), // Prevent font vertical padding
                          softWrap: false, // Ensures long text doesn't arbitrarily wrap to match PDF behavior
                          overflow: TextOverflow.visible,
                        ),
                      ),
            ),
          ),
          if (isImageOrSign)
            Positioned(
              right: -20, // compensate for padding to keep it visually at bottom-right
              bottom: -20, // compensate for padding
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // Ensures the entire padded area catches the tap
                onPanUpdate: (details) {
                  setState(() {
                    _resizeDw += details.delta.dx;
                    _resizeDh += details.delta.dy;
                  });
                },
                onPanEnd: (details) {
                  widget.onResize(_resizeDw, _resizeDh);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Massive invisible hitbox area for fat fingers
                  child: Container(
                    width: 28, // Slighly bigger visually 
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.open_in_full, size: 16, color: Colors.blue),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Maps a fontFamily name to a real Google Fonts TextStyle.
/// Falls back to default if font name is not recognized.
TextStyle _buildGoogleFontStyle(
  String fontFamily, {
  double? fontSize,
  Color? color,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
}) {
  final base = TextStyle(
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
  );

  try {
    switch (fontFamily) {
      case 'Merriweather':
        return GoogleFonts.merriweather(textStyle: base);
      case 'Courier Prime':
        return GoogleFonts.courierPrime(textStyle: base);
      case 'Roboto':
        return GoogleFonts.roboto(textStyle: base);
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(textStyle: base);
      case 'Dancing Script':
        return GoogleFonts.dancingScript(textStyle: base);
      case 'Helvetica':
      default:
        return base; // Default system sans-serif
    }
  } catch (_) {
    return base;
  }
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _AppBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                )
              : null,
          color: isPrimary ? null : const Color(0xFF2A2A40),
          borderRadius: BorderRadius.circular(10),
          border: isPrimary
              ? null
              : Border.all(color: const Color(0xFF3A3A55), width: 1),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isPrimary ? Colors.white : const Color(0xFFBBBBCC)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isPrimary ? Colors.white : const Color(0xFFBBBBCC),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact toolbar button used in the secondary action bar row.
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: const Color(0xFFBBBBCC)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFBBBBCC),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
