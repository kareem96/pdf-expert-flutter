import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import '../../data/services/ml_kit_model_service.dart';
import '../../domain/entities/page_action.dart';
import 'page_manager_page.dart';
import '../widgets/pdf_editor_appbar.dart';
import '../widgets/pdf_editor_toolbar.dart';
// _ml_kit_bottom_bar.dart removed entirely
import '../widgets/ai_tools_bottom_bar.dart';
import '../widgets/custom_toast.dart';
import '../widgets/pdf_field_overlay.dart';
import '../widgets/eraser_overlay.dart';
import '../widgets/toolbar_button.dart';
import '../dialogs/text_editor_dialog.dart';
import '../dialogs/marker_selector_dialog.dart';
import '../../common/constants/app_strings.dart';
part 'pdf_editor_page_actions.dart';



enum EditorMode { none, aiTools, sign, text, image, note, marker }

class PdfEditorPage extends ConsumerStatefulWidget {
  const PdfEditorPage({super.key});

  @override
  ConsumerState<PdfEditorPage> createState() => _PdfEditorPageState();
}

class _PdfEditorPageState extends ConsumerState<PdfEditorPage> with WidgetsBindingObserver {
  void _update(VoidCallback fn) {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      Future.microtask(() => setState(fn));
    } else {
      setState(fn);
    }
  }
  
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final _draftService = DraftService();
  final _recentService = RecentFilesService();
  final _prefsService = AppPreferencesService();
  final _mlKitModelService = MlKitModelService();
  int _currentPage = 1;
  double _scrollX = 0;
  double _scrollY = 0;
  double _zoom = 1.0;
  final TransformationController _transformationController = TransformationController();

  // Toolbar Modes
  EditorMode _activeMode = EditorMode.none;
  // _useMlKit boolean removed, because logic is now inside aiTools mode
  String _activeAiTool = 'erase';
  bool _isAiScanDownloading = false;
  bool _isModelDownloaded = false;
  PdfFieldEntity? _pendingEraser; // Temporary field for previewing eraser
  String _selectedMarkerType = 'check'; // 'check', 'close', 'square', 'circle'
  bool _isToolbarExpanded = false;


  @override
  void initState() {
    super.initState();
    _pdfViewerController.addListener(_onControllerChange);
    WidgetsBinding.instance.addObserver(this);
    _checkInitialModelStatus();
  }

  Future<void> _checkInitialModelStatus() async {
    final status = await _mlKitModelService.isModelDownloaded();
    _update(() => _isModelDownloaded = status);
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
        _update(() {
          _currentPage = _pdfViewerController.pageNumber;
          _zoom = _pdfViewerController.zoomLevel;
          _scrollX = _pdfViewerController.scrollOffset.dx;
          _scrollY = _pdfViewerController.scrollOffset.dy;
        });
      }
    } catch (e) {
      // Viewer controller might not be ready yet, log error if needed.
      // debugPrint('Error in _onControllerChange: $e');
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
              body: const Center(child: Text('Document not found', style: TextStyle(color: Colors.white))),
            );
          }
         
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                   PdfEditorAppBar(
                    docName: doc.fileName,
                    isEditing: _activeMode != EditorMode.none,
                    onPageManagerTap: () => _onPageManagerTap(doc.originalPath),
                  ),
                  PdfEditorToolbar(
                    activeMode: _activeMode,
                    onModeChanged: (mode) async {
                      if (mode == EditorMode.aiTools) {
                        final isDownloaded = await _mlKitModelService.isModelDownloaded();
                        if (!isDownloaded) {
                          if (mounted) _showAiScanDownloadPopup();
                          return;
                        }
                      }
                      
                      _update(() {
                        _activeMode = mode;
                        if (mode == EditorMode.aiTools) _activeAiTool = 'erase'; 
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
                    isExpanded: _isToolbarExpanded,
                    onToggleExpand: () => _update(() => _isToolbarExpanded = !_isToolbarExpanded),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double totalDocHeight = 0;
                        final List<double> pagePixelOffsets = [];
                        final List<double> pageScales = [];

                        for (int i = 0; i < doc.pageWidths.length; i++) {
                          final double pWidth = doc.pageWidths[i];
                          final double pHeight = doc.pageHeights[i];
                          if (pWidth <= 0 || pHeight <= 0) continue; 
                          
                          double s = (constraints.maxWidth / pWidth);
                          if (s <= 0 || s.isInfinite || s.isNaN) s = 1.0; 
                          
                          pageScales.add(s);
                          pagePixelOffsets.add(totalDocHeight);
                          totalDocHeight += pHeight * s;
                        }

                        if (totalDocHeight <= 0) {
                          totalDocHeight = constraints.maxHeight > 0 ? constraints.maxHeight : 500;
                        }

                        return Stack(
                          children: [
                            _buildMainContent(context, doc, constraints, pagePixelOffsets, pageScales, totalDocHeight),
                            _buildSecondaryToolbarOverlay(doc),
                          ],
                        );
                      },
                    ),
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

  Widget _buildSecondaryToolbarOverlay(PdfDocumentEntity doc) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      top: _isToolbarExpanded ? 10 : -100,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isToolbarExpanded ? 1.0 : 0.0,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ToolbarButton(
                          icon: Icons.image_outlined,
                          label: AppStrings.modeImage,
                          isActive: _activeMode == EditorMode.image,
                          onTap: () {
                            _update(() => _activeMode = EditorMode.image);
                            _onAddImage(doc);
                          },
                        ),
                        ToolbarButton(
                          icon: Icons.sticky_note_2_outlined,
                          label: AppStrings.modeNote,
                          isActive: _activeMode == EditorMode.note,
                          onTap: () {
                            _update(() => _activeMode = EditorMode.note);
                            _onAddStickyNote(doc);
                          },
                        ),
                        ToolbarButton(
                          icon: Icons.save_outlined,
                          label: AppStrings.modeSave,
                          onTap: () {
                            _update(() => _activeMode = EditorMode.none);
                            _onSave(doc);
                          },
                        ),
                        ToolbarButton(
                          icon: Icons.share_outlined,
                          label: AppStrings.modeShare,
                          onTap: () {
                            _update(() => _activeMode = EditorMode.none);
                            _onShare(doc);
                          },
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
    );
  }

  Widget _buildMainContent(BuildContext context, PdfDocumentEntity doc, BoxConstraints constraints, List<double> pagePixelOffsets, List<double> pageScales, double totalDocHeight) {
    return Stack(
      children: [
        // 1. A. PDF & FIXED OVERLAYS (ZOOMABLE)
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

                          if (_activeMode == EditorMode.aiTools && _activeAiTool == 'erase') {
                            _onEraseText(pageRelativePos, tappedPageIdx, _zoom, isAiScan: _isModelDownloaded);
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
                  ...doc.fields.where((PdfFieldEntity f) => f.isNewField).map((field) {
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
                      isEraserMode: _activeMode == EditorMode.aiTools && _activeAiTool == 'erase',
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

        // 2. B. SCREEN-STATIC OVERLAYS (NOT ZOOMABLE)
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
  }

}
