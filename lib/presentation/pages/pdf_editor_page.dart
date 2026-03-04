import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../domain/entities/pdf_document_entity.dart';
import '../../domain/entities/pdf_field_entity.dart';
import '../providers/pdf_editor_provider.dart';
import '../providers/repository_providers.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/draft_service.dart';
import '../../data/services/recent_files_service.dart';
import '../../data/services/app_preferences_service.dart';
import '../widgets/custom_toast.dart';

enum EditorMode { none, erase, sign, text, image, note, marker }

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
  int _pointers = 0; 
  String _searchQuery = '';
  final TransformationController _transformationController = TransformationController();

  // Toolbar Modes
  EditorMode _activeMode = EditorMode.none;
  bool _useMlKit = false;
  PdfFieldEntity? _pendingEraser; // Temporary field for previewing eraser
  String _selectedMarkerType = 'check'; // 'check', 'close', 'square', 'circle'
  
  // Toolbar Scroll Indicators
  final ScrollController _toolbarScrollController = ScrollController();
  bool _showLeftIndicator = false;
  bool _showRightIndicator = false;


  @override
  void initState() {
    super.initState();
    _pdfViewerController.addListener(_onControllerChange);
    _toolbarScrollController.addListener(_onToolbarScroll);
    WidgetsBinding.instance.addObserver(this);
    
    // Check initial scroll state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _onToolbarScroll());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pdfViewerController.removeListener(_onControllerChange);
    _toolbarScrollController.removeListener(_onToolbarScroll);
    _pdfViewerController.dispose();
    _transformationController.dispose();
    _toolbarScrollController.dispose();
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

  void _onToolbarScroll() {
    if (!_toolbarScrollController.hasClients) return;
    
    final bool showLeft = _toolbarScrollController.offset > 5;
    final bool showRight = _toolbarScrollController.offset < (_toolbarScrollController.position.maxScrollExtent - 5);
    
    if (showLeft != _showLeftIndicator || showRight != _showRightIndicator) {
      setState(() {
        _showLeftIndicator = showLeft;
        _showRightIndicator = showRight;
      });
    }
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _zoom = 1.0;
      _scrollX = 0;
      _scrollY = 0;
      _activeMode = EditorMode.none; // Clear mode on reset
      _pendingEraser = null; 
    });
    CustomToast.show(context, message: 'View Reset');
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
                  preferredSize: const Size.fromHeight(80), // Increased height for new toolbar button style
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        height: 80, // Increased height
                        decoration: BoxDecoration(
                          color: const Color(0xFF252540).withOpacity(0.6),
                          border: const Border(
                            top: BorderSide(color: Color(0xFF3E3E5A), width: 0.5),
                          ),
                        ),
                        child: Stack(
                          children: [
                            SingleChildScrollView( // Added for horizontal scrolling if many buttons
                              controller: _toolbarScrollController,
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  const SizedBox(width: 16), // Increased padding for gradients
                                  _ToolbarButton(
                                    icon: Icons.draw_outlined,  
                                    label: 'Sign',  
                                    isActive: _activeMode == EditorMode.sign,
                                    onTap: () {
                                      setState(() {
                                        _activeMode = _activeMode == EditorMode.sign ? EditorMode.none : EditorMode.sign;
                                        _pendingEraser = null;
                                      });
                                      _onAddSignature(doc!);
                                    }
                                  ),
                                  _ToolbarButton(
                                    icon: Icons.image_outlined, 
                                    label: 'Image', 
                                    isActive: _activeMode == EditorMode.image,
                                    onTap: () {
                                      setState(() {
                                        _activeMode = _activeMode == EditorMode.image ? EditorMode.none : EditorMode.image;
                                        _pendingEraser = null;
                                      });
                                      _onAddImage(doc!);
                                    }
                                  ),
                                  _ToolbarButton(
                                    icon: Icons.title_rounded,  
                                    label: 'Text',  
                                    isActive: _activeMode == EditorMode.text,
                                    onTap: () {
                                      setState(() {
                                        _activeMode = _activeMode == EditorMode.text ? EditorMode.none : EditorMode.text;
                                        _pendingEraser = null;
                                      });
                                      _onAddTextFromToolbar(doc!);
                                    }
                                  ),
                                  _ToolbarButton(
                                    icon: Icons.cleaning_services_rounded, 
                                    label: 'Erase', 
                                    isActive: _activeMode == EditorMode.erase,
                                    onTap: () {
                                      setState(() {
                                        _activeMode = _activeMode == EditorMode.erase ? EditorMode.none : EditorMode.erase;
                                        _pendingEraser = null;
                                      });
                                      if (_activeMode == EditorMode.erase) {
                                        CustomToast.show(context, message: 'Eraser Mode Active. Tap any text on the PDF to wipe it.');
                                      }
                                    }
                                  ),
                                  _ToolbarButton(
                                    icon: _getMarkerIcon(_selectedMarkerType),
                                    label: 'Marker',
                                    isActive: _activeMode == EditorMode.marker,
                                    onTap: () {
                                      setState(() {
                                        _activeMode = _activeMode == EditorMode.marker ? EditorMode.none : EditorMode.marker;
                                        _pendingEraser = null;
                                      });
                                      if (_activeMode == EditorMode.marker) {
                                        CustomToast.show(context, message: 'Marker Mode Active. Tap on PDF to place a marker.');
                                      }
                                    }
                                  ),
                                  _ToolbarButton(
                                    icon: Icons.sticky_note_2_outlined, 
                                    label: 'Note', 
                                    isActive: _activeMode == EditorMode.note,
                                    onTap: () {
                                      setState(() {
                                        _activeMode = _activeMode == EditorMode.note ? EditorMode.none : EditorMode.note;
                                        _pendingEraser = null;
                                      });
                                      _onAddStickyNote(doc!);
                                    }
                                  ),
                                  _ToolbarButton(
                                    icon: Icons.save_outlined,  
                                    label: 'Save',  
                                    onTap: () {
                                      setState(() {
                                        _activeMode = EditorMode.none;
                                        _pendingEraser = null;
                                      });
                                      _onSave(doc!);
                                    }
                                  ),
                                  _ToolbarButton(
                                    icon: Icons.share_outlined, 
                                    label: 'Share', 
                                    onTap: () {
                                      setState(() {
                                        _activeMode = EditorMode.none;
                                        _pendingEraser = null;
                                      });
                                      _onShare(doc!);
                                    }
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            ),
                            
                            // LEFT INDICATOR
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: AnimatedOpacity(
                                opacity: _showLeftIndicator ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  width: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        const Color(0xFF252540),
                                        const Color(0xFF252540).withOpacity(0),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(Icons.chevron_left_rounded, color: Colors.white38, size: 20),
                                ),
                              ),
                            ),
                            
                            // RIGHT INDICATOR
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: AnimatedOpacity(
                                opacity: _showRightIndicator ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  width: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                      colors: [
                                        const Color(0xFF252540),
                                        const Color(0xFF252540).withOpacity(0),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        bottomNavigationBar: _activeMode == EditorMode.erase 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF1E1E2E),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Text('AI Scan (ML Kit) for Scanned PDFs', style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                    Switch(
                      value: _useMlKit,
                      activeColor: Colors.amber,
                      onChanged: (val) {
                        setState(() {
                          _useMlKit = val;
                        });
                        if (val) CustomToast.show(context, message: 'AI ML Kit Engine Enabled. Scanned documents will now be analyzed.');
                      },
                    ),
                  ],
                ),
              ) 
            : null,
        body: pdfState.when(
          data: (doc) {
            if (doc == null) return const SizedBox.shrink();

            return LayoutBuilder(
              builder: (context, constraints) {
                // 1. Calculate the total logical document height and dimensions at base width
                double totalDocHeight = 0;
                final List<double> pagePixelOffsets = [];
                final List<double> pageScales = [];
                
                for (int i = 0; i < doc.pageWidths.length; i++) {
                  double s = (constraints.maxWidth / doc.pageWidths[i]);
                  if (s <= 0) s = 1.0; 
                  
                  pageScales.add(s);
                  pagePixelOffsets.add(totalDocHeight);
                  totalDocHeight += doc.pageHeights[i] * s;
                }

                return Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 6.0,
                      panEnabled: true,
                      scaleEnabled: true,
                      constrained: false,
                      alignment: Alignment.topLeft, 
                      boundaryMargin: EdgeInsets.zero, // Tight containment
                      onInteractionUpdate: (details) {
                    final Matrix4 matrix = _transformationController.value;
                    final double scale = matrix.getMaxScaleOnAxis();
                    final double tx = -matrix.storage[12];
                    final double ty = -matrix.storage[13];

                    // 1. Determine current page based on scroll Y
                    int detectedPage = 0;
                    for (int i = 0; i < pagePixelOffsets.length; i++) {
                       if (ty >= (pagePixelOffsets[i] * scale) - 100) {
                         detectedPage = i;
                       }
                    }

                    setState(() {
                       _zoom = scale;
                       _scrollX = tx;
                       _scrollY = ty;
                       _currentPage = detectedPage + 1;
                    });
                  },
                  child: GestureDetector(
                    onDoubleTap: _resetView, // Double tap to reset
                    child: Container(
                      width: constraints.maxWidth,
                      height: totalDocHeight,
                      color: Colors.white,
                      child: Stack(
                        children: [
                        AbsorbPointer(
                          absorbing: true, // Prevent SfPdfViewer from stealing scroll/zoom gestures
                          child: SfPdfViewer.file(
                            File(doc.filePath),
                            key: ValueKey(doc.filePath),
                            controller: _pdfViewerController,
                            pageSpacing: 0,
                            enableDoubleTapZooming: false,
                            enableTextSelection: false,
                          ),
                        ),
                        
                        // GESTURE LAYER for onTap (Since AbsorbPointer is above the PDF)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapUp: (details) {
                              if (_pendingEraser != null) return; // FIX: Block background taps if preview is active
                              final Offset localPos = details.localPosition;
                              
                              // 1. Determine which page was tapped based on Y offset
                              int tappedPageIdx = -1;
                              for (int i = 0; i < pagePixelOffsets.length; i++) {
                                final double startY = pagePixelOffsets[i];
                                final double endY = (i == pagePixelOffsets.length - 1) 
                                    ? totalDocHeight 
                                    : pagePixelOffsets[i + 1];
                                
                                if (localPos.dy >= startY && localPos.dy < endY) {
                                  tappedPageIdx = i;
                                  break;
                                }
                              }
                              
                              if (tappedPageIdx != -1) {
                                final double scale = pageScales[tappedPageIdx];
                                final Offset pageRelativePos = Offset(
                                  localPos.dx / scale, 
                                  (localPos.dy - pagePixelOffsets[tappedPageIdx]) / scale
                                );
    
                                if (_activeMode == EditorMode.erase) {
                                  _onEraseText(pageRelativePos, tappedPageIdx, 1.0);
                                } else if (_activeMode == EditorMode.marker) {
                                  _onAddMarker(pageRelativePos, tappedPageIdx);
                                } else {
                                  _onAddCustomText(pageRelativePos, tappedPageIdx);
                                }
                              }
                            },
                            child: Container(color: Colors.transparent),
                          ),
                        ),

                        // THE OVERLAYS
                        ...doc.fields.where((f) => f.isNewField).map((field) {
                          final int pIdx = field.pageIndex;
                          if (pIdx >= pageScales.length) return const SizedBox.shrink();

                          final double pageScale = pageScales[pIdx];
                          final double pageTopPixel = pagePixelOffsets[pIdx];
                          
                          final double screenX = (field.x * pageScale);
                          final double screenY = (pageTopPixel) + (field.y * pageScale);

                          return _PdfFieldOverlay(
                            key: ValueKey(field.id),
                            field: field,
                            scale: pageScale,
                            offset: Offset(screenX, screenY),
                            onUpdatePosition: (dx, dy) {
                              final double realDxPoints = dx / pageScale;
                              final double realDyPoints = dy / pageScale;

                              ref.read(pdfEditorProvider.notifier).updateFieldPosition(
                                    field.id,
                                    field.x + realDxPoints,
                                    field.y + realDyPoints,
                                  );
                            },
                            onResize: (dw, dh) {
                              final double realW = field.width + (dw / pageScale);
                              final double realH = field.height + (dh / pageScale);
                              ref.read(pdfEditorProvider.notifier).updateFieldSize(
                                field.id,
                                realW > 10 ? realW : 10,
                                realH > 10 ? realH : 10,
                              );
                            },
                            onEdit: () {
                              _onEditField(field);
                            },
                            isEraserMode: _activeMode == EditorMode.erase,
                            onErase: () {
                              ref.read(pdfEditorProvider.notifier).removeField(field.id);
                            },
                          );
                        }).toList(),

                        // PENDING ERASER PREVIEW
                        if (_pendingEraser != null) ..._buildPendingEraserOverlay(pageScales, pagePixelOffsets),
                      ],
                    ),
                  ),
                ),
              ),
              // Floating Reset Button (Only shows when zoomed)
              Positioned(
                  bottom: 20,
                  right: 20,
                  child: AnimatedOpacity(
                    opacity: _zoom > 1.05 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: _zoom <= 1.05,
                      child: GestureDetector(
                        onTap: _resetView,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white24, width: 0.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.aspect_ratio_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reset View',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
          error: (err, stack) => Center(
            child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
          ),
        )
      ),    // closes Scaffold
    );      // closes PopScope
  }



  /// HELPER: Calculates the [pdfX, pdfY, pageIndex] for the current center of the viewport
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

    double pageStartPx = 0;
    double tempH = 0;
    for (int i = 0; i < pIdx; i++) {
      double s = (size.width / doc.pageWidths[i]);
      tempH += doc.pageHeights[i] * s;
    }
    pageStartPx = tempH * _zoom;

    final double pdfY = (screenCenterY - pageStartPx) / totalScale;

    return {
      'x': pdfX,
      'y': pdfY,
      'pageIndex': pIdx,
    };
  }

  List<Widget> _buildPendingEraserOverlay(List<double> pageScales, List<double> pagePixelOffsets) {
    if (_pendingEraser == null) return [];

    final pIdx = _pendingEraser!.pageIndex;
    final double pageScale = pageScales[pIdx];
    final double pageTopPixel = pagePixelOffsets[pIdx];
    
    final double screenX = (_pendingEraser!.x * pageScale);
    final double screenY = (pageTopPixel) + (_pendingEraser!.y * pageScale);
    final double screenW = _pendingEraser!.width * pageScale;
    final double screenH = _pendingEraser!.height * pageScale;

    return [
      // 1. THE PREVIEW BOX (Transparent area with border)
      Positioned(
        left: screenX,
        top: screenY,
        child: Container(
          width: screenW,
          height: screenH,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.25),
            border: Border.all(color: Colors.amber, width: 2),
          ),
        ),
      ),
      // 2. THE ACTION BUTTONS & RESIZE HANDLE
      Positioned(
        top: screenY + screenH + 8,
        left: screenX + (screenW / 2) - 55, // Adjusted to center wider bar
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF252540),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // CONFIRM
              GestureDetector(
                onTap: () {
                  ref.read(pdfEditorProvider.notifier).addEraser(
                    _pendingEraser!.x,
                    _pendingEraser!.y,
                    _pendingEraser!.width,
                    _pendingEraser!.height,
                    _pendingEraser!.pageIndex,
                  );
                  setState(() => _pendingEraser = null);
                  CustomToast.show(context, message: 'Text Erased Permanently!');
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              // CANCEL
              GestureDetector(
                onTap: () => setState(() => _pendingEraser = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 20, color: Colors.white12), // Divider
              const SizedBox(width: 8),
              // RESIZE HANDLE (In the button bar)
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _pendingEraser = _pendingEraser!.copyWith(
                      width: math.max(10.0, _pendingEraser!.width + (details.delta.dx / pageScale)),
                      height: math.max(10.0, _pendingEraser!.height + (details.delta.dy / pageScale)),
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.open_in_full, size: 16, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Future<void> _onAddImage(PdfDocumentEntity doc) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final spawn = _getSpawnPoints(doc);
      ref.read(pdfEditorProvider.notifier).addImage(
        spawn['x'], 
        spawn['y'], 
        image.path, 
        spawn['pageIndex'], 
        isSignature: false
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

                      final spawn = _getSpawnPoints(doc);
                      ref.read(pdfEditorProvider.notifier).addImage(
                        spawn['x'], 
                        spawn['y'], 
                        file.path, 
                        spawn['pageIndex'], 
                        isSignature: true
                      );
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
    final spawn = _getSpawnPoints(doc);

    final val = await _showTextEditorDialog();
    if (val != null && val['action'] == 'save' && mounted) {
      final text = val['text'] as String;
      ref.read(pdfEditorProvider.notifier).addFreeText(
        spawn['x'],
        spawn['y'],
        text,
        spawn['pageIndex'],
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

    // Reuse the text editor dialog but with presets specifically styled like a Yellow Post-it Note
    final val = await _showTextEditorDialog(
       initialFontFamily: 'Courier Prime',
       initialFontSize: 14.0,
       initialColor: '0xFF000000', // Black text always
    );
    
    if (val != null && val['action'] == 'save' && mounted) {
      final text = val['text'] as String;
      ref.read(pdfEditorProvider.notifier).addFreeText(
        spawn['x'],
        spawn['y'],
        text,
        spawn['pageIndex'],
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

  void _onEraseText(Offset position, int pageIndex, double currentZoom) async {
    if (_useMlKit) {
      // TODO: Implement ML Kit OCR and smart erase later
      CustomToast.show(context, message: 'AI ML Kit mode is active. (Waiting for Phase 2 Implementation!)');
    } else {
      final docState = ref.read(pdfEditorProvider);
      if (docState.value == null) return;
      
      final doc = docState.value!;
      final repo = ref.read(pdfRepositoryProvider);
      
      CustomToast.show(context, message: 'Extracting boundaries...');
      
      // Perkecil hitbox saat zoom-in, perbesar hitbox saat zoom-out
      final double dynamicHitPad = 6.0 / currentZoom;

      final Rect? bounds = await repo.extractWordBounds(doc.filePath, pageIndex, position.dx, position.dy, pad: dynamicHitPad);
      
      if (bounds != null) {
        setState(() {
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
        CustomToast.show(context, message: 'Previewing area to erase...');
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Text Not Found', style: TextStyle(color: Colors.amber)),
            content: const Text('Syncfusion engine could not find any digital text here.\n\nIf this is a scanned document/photo, please turn ON the "AI Scan (ML Kit)" toggle at the bottom to use machine learning.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
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
      // Just show dialog to delete for image/signature/eraser since we can reshape them by dragging
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${field.type.name} Options'),
          content: Text('Do you want to delete this ${field.type.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            TextButton(
              onPressed: () {
                 ref.read(pdfEditorProvider.notifier).removeField(field.id);
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


  IconData _getMarkerIcon(String type) {
    switch (type) {
      case 'check': return Icons.check;
      case 'close': return Icons.close;
      case 'square': return Icons.square;
      case 'circle': return Icons.circle;
      default: return Icons.check;
    }
  }

  void _onAddMarker(Offset pos, int pageIndex) async {
    final result = await _showMarkerSelectorDialog(
      initialType: _selectedMarkerType,
    );

    if (result != null && result['action'] == 'save') {
      setState(() {
        _selectedMarkerType = result['type'];
      });
      
      ref.read(pdfEditorProvider.notifier).addMarker(
        result['type'],
        pos.dx - 12.5, 
        pos.dy - 12.5,
        25, 
        25, 
        pageIndex,
        color: result['color'],
      );
    }
  }

  Future<Map<String, dynamic>?> _showMarkerSelectorDialog({
    String initialType = 'check',
    String initialColor = '0xFF000000',
    bool isEdit = false,
  }) async {
    String selectedType = initialType;
    Color selectedColor = Color(int.parse(initialColor));

    final List<Color> availableColors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.brown,
      Colors.grey,
      Colors.teal,
      Colors.pink,
    ];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          surfaceTintColor: Colors.transparent,
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          title: Text(
            isEdit ? 'Edit Marker' : 'Select Marker',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MarkerOption(
                    icon: Icons.check,
                    isSelected: selectedType == 'check',
                    onTap: () => setDialogState(() => selectedType = 'check'),
                  ),
                  _MarkerOption(
                    icon: Icons.close,
                    isSelected: selectedType == 'close',
                    onTap: () => setDialogState(() => selectedType = 'close'),
                  ),
                  _MarkerOption(
                    icon: Icons.square,
                    isSelected: selectedType == 'square',
                    onTap: () => setDialogState(() => selectedType = 'square'),
                  ),
                  _MarkerOption(
                    icon: Icons.circle,
                    isSelected: selectedType == 'circle',
                    onTap: () => setDialogState(() => selectedType = 'circle'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Select Color',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: availableColors.map((color) {
                  final bool isColorSelected = selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isColorSelected ? Colors.amber : Colors.white24,
                          width: isColorSelected ? 2 : 1,
                        ),
                        boxShadow: isColorSelected ? [
                          BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 4),
                        ] : null,
                      ),
                      child: isColorSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            if (isEdit)
              TextButton(
                onPressed: () => Navigator.pop(context, {'action': 'delete'}),
                child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60, fontSize: 13)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, {
                'action': 'save',
                'type': selectedType,
                'color': '0x${selectedColor.value.toRadixString(16).toUpperCase()}',
              }),
              child: Text(isEdit ? 'Update' : 'Add', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkerOption extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MarkerOption({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.amber : Colors.white60,
          size: 22,
        ),
      ),
    );
  }
}

class _PdfFieldOverlay extends StatefulWidget {
  final PdfFieldEntity field;
  final double scale;
  final Offset offset;
  final Function(double dx, double dy) onUpdatePosition;
  final Function(double dw, double dh) onResize;
  final VoidCallback onEdit;
  final bool isEraserMode;
  final VoidCallback onErase;

  const _PdfFieldOverlay({
    Key? key,
    required this.field,
    required this.scale,
    required this.offset,
    required this.onUpdatePosition,
    required this.onResize,
    required this.onEdit,
    required this.isEraserMode,
    required this.onErase,
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
    // Hanya reset drag manual apabila layar bergeser secara signifikan (di atas 5 pixel per frame)
    // atau ketika proses Drag sudah selesai, untuk mencegah lompatan saat PdfViewer sedang berkedut (tick) dalam zoom.
    if ((oldWidget.offset.dx - widget.offset.dx).abs() > 5.0 || (oldWidget.offset.dy - widget.offset.dy).abs() > 5.0) {
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
    final bool isEraser = widget.field.type == PdfFieldType.eraser;

    final bool isMarker = widget.field.type == PdfFieldType.marker;

    final double currentWidth = (isEraser || isMarker) 
        ? ((widget.field.width * widget.scale) + _resizeDw)
        : math.max(20.0, (widget.field.width * widget.scale) + _resizeDw);
    final double currentHeight = (isEraser || isMarker) 
        ? ((widget.field.height * widget.scale) + _resizeDh)
        : math.max(20.0, (widget.field.height * widget.scale) + _resizeDh);

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
              final dx = _dragDx;
              final dy = _dragDy;
              setState(() {
                _dragDx = 0;
                _dragDy = 0;
              });
              widget.onUpdatePosition(dx, dy);
            },
            onTap: widget.onEdit, // FIX: Don't use widget.onErase (immediate delete), use onEdit to show confirmation dialog
            child: Container(
              width: isImageOrSign || isEraser || isMarker ? currentWidth : null,
              height: isImageOrSign || isEraser || isMarker ? currentHeight : null,
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: (isImageOrSign && (widget.field.value == null || widget.field.value!.isEmpty))
                    ? Colors.transparent 
                    : (isEraser ? Color(int.parse(widget.field.backgroundColor ?? '0xFFFFFFFF')) : Colors.white.withOpacity(0.05)),
                border: (isImageOrSign && (widget.field.value == null || widget.field.value!.isEmpty))
                    ? null
                    : isEraser 
                      ? Border.all(color: Colors.grey.withOpacity(0.5), width: 1) // subtle border so user can select/see the white box
                      : Border.all(
                          color: Colors.blue.withOpacity(0.8), 
                          width: 1.5, 
                        ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: isEraser ? null : [
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
                    : isEraser
                        ? Container(
                            width: currentWidth,
                            height: currentHeight,
                            // Background color explicitly inherited from BoxDecoration
                          )
                    : isMarker
                        ? Container(
                            width: currentWidth,
                            height: currentHeight,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: buildMarkerWidget(
                                widget.field.value, 
                                widget.field.width, 
                                widget.field.height,
                                color: Color(int.parse(widget.field.textColor)),
                              ),
                            ),
                          )
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
          if (isImageOrSign) // REFINED: Erasers are no longer resizable after being committed (Preview only)
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

Widget buildMarkerWidget(String? type, double width, double height, {Color color = Colors.black}) {
  switch (type) {
    case 'check':
      return Icon(Icons.check, color: color, size: width);
    case 'close':
      return Icon(Icons.close, color: color, size: width);
    case 'square':
      return Container(width: width, height: height, color: color);
    case 'circle':
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    default:
      return Icon(Icons.check, color: color, size: width);
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
  final bool isActive;

  const _ToolbarButton({
    required this.icon, 
    required this.label, 
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.amber.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.amber.withOpacity(0.5) : Colors.transparent,
          )
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isActive ? Colors.amber : Colors.white),
            const SizedBox(height: 4),
            Text(
              label, 
              style: GoogleFonts.inter(
                fontSize: 10, 
                color: isActive ? Colors.amber : Colors.white70
              ),
            ),
          ],
        ),
      ),
    );
  }
}
