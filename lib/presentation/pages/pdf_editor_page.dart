import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../domain/entities/pdf_document_entity.dart';
import '../../domain/entities/pdf_field_entity.dart';
import '../providers/pdf_editor_provider.dart';
import '../providers/repository_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/draft_service.dart';
import '../../data/services/recent_files_service.dart';
import '../../data/services/app_preferences_service.dart';
import '../widgets/pdf_editor_appbar.dart';
import '../widgets/pdf_editor_toolbar.dart';
// _ml_kit_bottom_bar.dart removed entirely
import '../widgets/ai_tools_bottom_bar.dart';
import '../widgets/custom_toast.dart';
import '../widgets/pdf_field_overlay.dart';
import '../widgets/eraser_overlay.dart';
import '../dialogs/text_editor_dialog.dart';
import '../dialogs/marker_selector_dialog.dart';
import '../../common/constants/app_strings.dart';
part 'pdf_editor_page_actions.dart';



enum EditorMode { none, erase, aiTools, sign, text, image, note, marker }

class PdfEditorPage extends ConsumerStatefulWidget {
  const PdfEditorPage({super.key});

  @override
  ConsumerState<PdfEditorPage> createState() => _PdfEditorPageState();
}

class _PdfEditorPageState extends ConsumerState<PdfEditorPage> with WidgetsBindingObserver {
  void _update(VoidCallback fn) => setState(fn);
  
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final _draftService = DraftService();
  final _recentService = RecentFilesService();
  final _prefsService = AppPreferencesService();
  int _currentPage = 1;
  double _scrollX = 0;
  double _scrollY = 0;
  double _zoom = 1.0;
  final TransformationController _transformationController = TransformationController();

  // Toolbar Modes
  EditorMode _activeMode = EditorMode.none;
  // _useMlKit boolean removed, because logic is now inside aiTools mode
  String _activeAiTool = 'erase'; // Sub-mode active on AI tools (erase, edit, copy)
  PdfFieldEntity? _pendingEraser; // Temporary field for previewing eraser
  String _selectedMarkerType = 'check'; // 'check', 'close', 'square', 'circle'


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
    _transformationController.dispose();
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
            title: Text(AppStrings.leaveEditorTitle),
            content: Text(AppStrings.leaveEditorBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: Text(AppStrings.stay),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'draft'),
                child: Text(AppStrings.saveDraft),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'discard'),
                child: Text(AppStrings.discard, style: const TextStyle(color: Colors.red)),
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
      child: pdfState.when(
        data: (doc) {
          if (doc == null) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Center(child: Text('Document not found', style: TextStyle(color: Colors.white))),
            );
          }
          
          final docName = doc.fileName;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(
                kToolbarHeight + 80.0
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PdfEditorAppBar(
                    docName: docName,
                    isEditing: true,
                  ),
                  PdfEditorToolbar(
                    activeMode: _activeMode,
                    onModeChanged: (mode) {
                      _update(() {
                        _activeMode = mode;
                        _pendingEraser = null;
                      });
                    },
                    onAddSignature: () => _onAddSignature(doc),
                    onAddImage: () => _onAddImage(doc),
                    onAddText: () => _onAddTextFromToolbar(doc),
                    onAddNote: () => _onAddStickyNote(doc),
                    onSave: () => _onSave(doc),
                    onShare: () => _onShare(doc),
                    selectedMarkerType: _selectedMarkerType,
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _activeMode == EditorMode.aiTools 
                ? AiToolsBottomBar(
                    activeTool: _activeAiTool,
                    onToolChanged: (val) => _update(() => _activeAiTool = val),
                  )
                : null,
            body: LayoutBuilder(
              builder: (context, constraints) {
                // 1. Calculate document dimensions at current zoom
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
                    // A. PDF & FIXED OVERLAYS (ZOOMABLE)
                    InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 6.0,
                      panEnabled: true,
                      scaleEnabled: true,
                      constrained: false,
                      onInteractionUpdate: (details) {
                        _update(() {
                          _zoom = _transformationController.value.getMaxScaleOnAxis();
                          _scrollX = -_transformationController.value.getTranslation().x;
                          _scrollY = -_transformationController.value.getTranslation().y;
                        });
                      },
                      child: GestureDetector(
                        onDoubleTap: _resetView,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: totalDocHeight,
                          child: Stack(
                            children: [
                              // 1. The PDF Renderer
                              AbsorbPointer(
                                absorbing: true,
                                child: SfPdfViewer.file(
                                  File(doc.filePath),
                                  controller: _pdfViewerController,
                                  enableDoubleTapZooming: false,
                                  onDocumentLoaded: (details) {},
                                ),
                              ),
                              
                              // 2. Gesture Detector Layer (Screen Relative)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapUp: (details) {
                                    if (_pendingEraser != null) return;
                                    final Offset localPos = details.localPosition;

                                    int tappedPageIdx = -1;
                                    for (int i = 0; i < pagePixelOffsets.length; i++) {
                                      final double startY = pagePixelOffsets[i];
                                      final double endY = (i + 1 < pagePixelOffsets.length) 
                                          ? pagePixelOffsets[i+1] 
                                          : totalDocHeight;
                                      
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
                                        _onEraseText(pageRelativePos, tappedPageIdx, _zoom, isAiScan: false);
                                      } else if (_activeMode == EditorMode.aiTools && _activeAiTool == 'erase') {
                                        _onEraseText(pageRelativePos, tappedPageIdx, _zoom, isAiScan: true);
                                      } else if (_activeMode == EditorMode.marker) {
                                        _onAddMarker(pageRelativePos, tappedPageIdx);
                                      } else if (_activeMode == EditorMode.none) {
                                        // Do nothing
                                      } else if (_activeMode == EditorMode.text) {
                                        _onAddCustomText(pageRelativePos, tappedPageIdx);
                                      }
                                    }
                                  },
                                  child: Container(color: Colors.transparent),
                                ),
                              ),

                              // 3. Document Fields Overlays
                              ...doc.fields.where((f) => f.isNewField).map((field) {
                                final int pIdx = field.pageIndex;
                                if (pIdx >= pageScales.length) return const SizedBox.shrink();

                                final double pageScale = pageScales[pIdx];
                                final double pageTopPixel = pagePixelOffsets[pIdx];
                                
                                final double screenX = field.x * pageScale;
                                final double screenY = pageTopPixel + (field.y * pageScale);

                                return PdfFieldOverlay(
                                  key: ValueKey(field.id),
                                  field: field,
                                  scale: pageScale,
                                  offset: Offset(screenX, screenY),
                                  onUpdatePosition: (dx, dy) {
                                    ref.read(pdfEditorProvider.notifier).updateFieldPosition(
                                          field.id,
                                          field.x + (dx / pageScale),
                                          field.y + (dy / pageScale),
                                        );
                                  },
                                  onResize: (dw, dh) {
                                    final double newW = field.width + (dw / pageScale);
                                    final double newH = field.height + (dh / pageScale);
                                    ref.read(pdfEditorProvider.notifier).updateFieldSize(
                                      field.id,
                                      newW > 10 ? newW : 10,
                                      newH > 10 ? newH : 10,
                                    );
                                  },
                                  onEdit: () => _onEditField(field),
                                  isEraserMode: _activeMode == EditorMode.erase,
                                  onErase: () => ref.read(pdfEditorProvider.notifier).removeField(field.id),
                                );
                              }),

                              // 4. Pending Eraser Preview
                              EraserOverlay(
                                pageScales: pageScales,
                                pagePixelOffsets: pagePixelOffsets,
                                pendingEraser: _pendingEraser,
                                onCancel: () => _update(() => _pendingEraser = null),
                                onConfirm: () {
                                   if (_pendingEraser != null) {
                                      ref.read(pdfEditorProvider.notifier).addEraser(
                                        _pendingEraser!.x,
                                        _pendingEraser!.y,
                                        _pendingEraser!.width,
                                        _pendingEraser!.height,
                                        _pendingEraser!.pageIndex,
                                      );
                                      _update(() => _pendingEraser = null);
                                      CustomToast.show(context, message: AppStrings.toastTextErased);
                                   }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // B. SCREEN-STATIC OVERLAYS (NOT ZOOMABLE)
                    if (_zoom > 1.05)
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _resetView,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF8B80FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
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
                                    AppStrings.resetView,
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
                  ],
                );
              },
            ),
          );
        },
        loading: () => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
        ),
        error: (err, stack) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Text('Error: $err', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ),
      ),
    );
  }



}
