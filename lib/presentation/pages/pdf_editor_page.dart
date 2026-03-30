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
import '../providers/recent_files_provider.dart';
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
import '../providers/pdf_thumbnail_provider.dart';
import 'page_manager_page.dart';
import '../widgets/pdf_editor_appbar.dart';
import '../widgets/pdf_editor_toolbar.dart';
import '../widgets/adaptive_layout_wrapper.dart';
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
  late final ValueNotifier<int> _currentPageNotifier = ValueNotifier(1);
  late final ValueNotifier<double> _zoomNotifier = ValueNotifier(1.0);
  double _scrollX = 0;
  double _scrollY = 0;
  final TransformationController _transformationController = TransformationController();

  List<double> _cachedPagePixelOffsets = [];
  List<double> _cachedPageScales = [];
  double _cachedTotalDocHeight = 0;
  Size? _lastConstraintsSize;
  String? _lastDocFilePath;

  EditorMode _activeMode = EditorMode.none;
  String _activeAiTool = 'erase';
  bool _isAiScanDownloading = false;
  bool _isModelDownloaded = false;
  PdfFieldEntity? _pendingEraser; 
  String _selectedMarkerType = 'check'; 
  bool _isToolbarExpanded = false;
  bool _isProcessingPages = false;

  bool _showViewer = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController.addListener(_onControllerChange);
    WidgetsBinding.instance.addObserver(this);
    _checkInitialModelStatus();
    
    // DELAY: Tunggu transisi navigasi selesai sebelum render PDF berat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showViewer = true);
      });
    });
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
    _currentPageNotifier.dispose();
    _zoomNotifier.dispose();
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
      await _draftService.saveDraft(doc.originalPath, doc.fields, currentPdfPath: doc.filePath);
      await _recentService.updateDraftStatus(doc.originalPath, hasDraft: true);
    }
  }

  void _onControllerChange() {
    if (!mounted) return;
    try {
      if (_currentPageNotifier.value != _pdfViewerController.pageNumber) {
        _currentPageNotifier.value = _pdfViewerController.pageNumber;
      }
      if (_zoomNotifier.value != _pdfViewerController.zoomLevel) {
        _zoomNotifier.value = _pdfViewerController.zoomLevel;
      }
      _scrollX = _pdfViewerController.scrollOffset.dx;
      _scrollY = _pdfViewerController.scrollOffset.dy;
    } catch (e) {
      // Ignore
    }
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
    _zoomNotifier.value = 1.0;
    _currentPageNotifier.value = 1;
    _update(() {
      _scrollX = 0;
      _scrollY = 0;
      _activeMode = EditorMode.none; 
      _pendingEraser = null; 
    });
    CustomToast.show(context, message: 'View Reset');
  }

  @override
  Widget build(BuildContext context) {
    // Optimize: Only watch essential metadata to avoid full page rebuilds
    final docAsData = ref.watch(pdfEditorProvider.select((s) => s.asData));
    final doc = docAsData?.value;

    final isEditing = doc != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!isEditing) {
          if (context.mounted) Navigator.of(context).pop();
          return;
        }
        
        if (!doc.isModified) {
          ref.read(pdfEditorProvider.notifier).clearDocument();
          if (context.mounted) Navigator.of(context).pop();
          return;
        }
        
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
          final doc = ref.read(pdfEditorProvider).asData?.value;
          if (doc != null) {
            await _draftService.deleteDraft(doc.originalPath);
            await _recentService.updateDraftStatus(doc.originalPath, hasDraft: false);
            ref.invalidate(pdfThumbnailProvider(doc.originalPath));
            // Force refresh recent files list for Home synchronization
            ref.invalidate(recentFilesProvider);
          }
          ref.read(pdfEditorProvider.notifier).clearDocument();
          if (context.mounted) Navigator.of(context).pop();
        } else if (result == 'draft') {
          await _autoSaveDraft();
          final doc = ref.read(pdfEditorProvider).asData?.value;
          if (doc != null) {
            ref.invalidate(pdfThumbnailProvider(doc.originalPath));
          }
          // Force refresh recent files list for Home synchronization
          ref.invalidate(recentFilesProvider);
          ref.read(pdfEditorProvider.notifier).clearDocument();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: docAsData == null || docAsData.isLoading
        ? Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
          )
        : docAsData.hasError ? 
          Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Text('${AppStrings.error}: ${docAsData.error}', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          )
        : (() {
          final doc = docAsData.value;


          if (doc == null) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Center(child: Text(AppStrings.docNotFound, style: const TextStyle(color: Colors.white))),
            );
          }
         
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: AdaptiveLayoutWrapper(
              mobile: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: PdfEditorAppBar(
                        docName: doc.fileName,
                        isEditing: _activeMode != EditorMode.none,
                        onPageManagerTap: () => _onPageManagerTap(doc.filePath),
                      ),
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: PdfEditorToolbar(
                        activeMode: _activeMode,
                        onModeChanged: (mode) => _handleModeChange(mode),
                        onAddSignature: () => _onAddSignature(doc),
                        onAddImage: () => _onAddImage(doc),
                        onAddText: () => _onAddTextFromToolbar(doc),
                        onAddNote: () => _onAddStickyNote(doc),
                        onSave: () => _onSave(doc),
                        onShare: () => _onShare(doc),
                        selectedMarkerType: _selectedMarkerType,
                        isExpanded: _isToolbarExpanded,
                        onToggleExpand: () => _update(() => _isToolbarExpanded = !_isToolbarExpanded),
                        isVertical: false,
                      ),
                    ),
                  ),
                  Expanded(child: _buildPdfContent(doc)),
                ],
              ),
              tablet: Row(
                children: [
                  PdfEditorToolbar(
                    activeMode: _activeMode,
                    onModeChanged: (mode) => _handleModeChange(mode),
                    onAddSignature: () => _onAddSignature(doc),
                    onAddImage: () => _onAddImage(doc),
                    onAddText: () => _onAddTextFromToolbar(doc),
                    onAddNote: () => _onAddStickyNote(doc),
                    onSave: () => _onSave(doc),
                    onShare: () => _onShare(doc),
                    selectedMarkerType: _selectedMarkerType,
                    isExpanded: _isToolbarExpanded,
                    onToggleExpand: () => _update(() => _isToolbarExpanded = !_isToolbarExpanded),
                    isVertical: true,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        PdfEditorAppBar(
                          docName: doc.fileName,
                          isEditing: _activeMode != EditorMode.none,
                          onPageManagerTap: () => _onPageManagerTap(doc.filePath),
                        ),
                        Expanded(child: _buildPdfContent(doc)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
                if (_isProcessingPages)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                    ),
                  ),
                Positioned(
                  bottom: 80,
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
            ),
            bottomNavigationBar: _activeMode == EditorMode.aiTools 
                ? AiToolsBottomBar(
                    activeTool: _activeAiTool,
                    onToolChanged: (val) => _update(() => _activeAiTool = val),
                  )
                : null,
          );
        }()),
    );
  }


  Future<void> _handleModeChange(EditorMode mode) async {
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

    if (mode == EditorMode.text) {
      if (context.mounted) CustomToast.show(context, message: AppStrings.toastTextActive);
    } else if (mode == EditorMode.marker) {
      if (context.mounted) CustomToast.show(context, message: AppStrings.toastMarkerActive);
    } else if (mode == EditorMode.sign) {
      if (context.mounted) CustomToast.show(context, message: AppStrings.toastSignActive);
    }
  }

  Widget _buildPdfContent(PdfDocumentEntity doc) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        if (_lastConstraintsSize != size || _cachedPagePixelOffsets.isEmpty || _lastDocFilePath != doc.filePath) {
          _lastConstraintsSize = size;
          _lastDocFilePath = doc.filePath;
          _cachedPagePixelOffsets = [];
          _cachedPageScales = [];
          _cachedTotalDocHeight = 0;
          const double pageSpacing = 4.0;

          for (int i = 0; i < doc.pageWidths.length; i++) {
            final double pWidth = doc.pageWidths[i];
            final double pHeight = doc.pageHeights[i];
            if (pWidth <= 0 || pHeight <= 0) continue; 
            
            double s = (constraints.maxWidth / pWidth);
            if (s <= 0 || s.isInfinite || s.isNaN) s = 1.0; 
            
            _cachedPageScales.add(s);
            _cachedPagePixelOffsets.add(_cachedTotalDocHeight);
            _cachedTotalDocHeight += (pHeight * s) + pageSpacing;
          }
          if (_cachedTotalDocHeight <= 0) {
            _cachedTotalDocHeight = constraints.maxHeight > 0 ? constraints.maxHeight : 500;
          }
        }

        return Stack(
          children: [
            _buildMainContent(context, doc, constraints),
            _buildSecondaryToolbarOverlay(doc),
          ],
        );
      },
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
                filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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

  Widget _buildMainContent(BuildContext context, PdfDocumentEntity doc, BoxConstraints constraints) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 6.0,
          panEnabled: true,
          scaleEnabled: true,
          constrained: false,
          onInteractionUpdate: (details) {
            final double zoom = _transformationController.value.getMaxScaleOnAxis();
            final double sy = -_transformationController.value.getTranslation().y;
            final double sx = -_transformationController.value.getTranslation().x;
            
            _scrollX = sx;
            _scrollY = sy;
            if (_zoomNotifier.value != zoom) {
              _zoomNotifier.value = zoom;
            }

            int newPage = 1;
            final double detectionY = sy + (constraints.maxHeight * 0.2); 
            for (int i = 0; i < _cachedPagePixelOffsets.length; i++) {
              final double start = _cachedPagePixelOffsets[i] * zoom;
              final double end = (i + 1 < _cachedPagePixelOffsets.length) 
                ? _cachedPagePixelOffsets[i+1] * zoom 
                : _cachedTotalDocHeight * zoom;
              if (detectionY >= start && detectionY <= end) {
                newPage = i + 1;
                break;
              }
            }

            if (_currentPageNotifier.value != newPage) {
              _currentPageNotifier.value = newPage;
            }
          },
          child: RepaintBoundary(
            child: GestureDetector(
              onDoubleTap: _resetView,
              child: SizedBox(
                width: constraints.maxWidth,
                height: _cachedTotalDocHeight,
                child: Stack(
                  children: [
                    AbsorbPointer(
                      absorbing: true,
                      child: RepaintBoundary(
                        child: _showViewer 
                          ? SfPdfViewer.file(
                              File(doc.filePath),
                              key: ValueKey(doc.filePath),
                              controller: _pdfViewerController,
                              enableDoubleTapZooming: false,
                              canShowPaginationDialog: false,
                              canShowScrollHead: false, 
                              canShowScrollStatus: false,
                            )
                          : Container(color: Theme.of(context).scaffoldBackgroundColor),
                      ),
                    ),

                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (details) {
                        if (_pendingEraser != null) return;
                        final Offset localPos = details.localPosition;

                        int tappedPageIdx = -1;
                        for (int i = 0; i < _cachedPagePixelOffsets.length; i++) {
                          final double startY = _cachedPagePixelOffsets[i];
                          final double endY = (i + 1 < _cachedPagePixelOffsets.length) 
                              ? _cachedPagePixelOffsets[i+1] 
                              : _cachedTotalDocHeight;

                          if (localPos.dy >= startY && localPos.dy < endY) {
                            tappedPageIdx = i;
                            break;
                          }
                        }

                        if (tappedPageIdx != -1) {
                          final double scale = _cachedPageScales[tappedPageIdx];
                          final Offset pageRelativePos = Offset(
                            localPos.dx / scale, 
                            (localPos.dy - _cachedPagePixelOffsets[tappedPageIdx]) / scale
                          );

                          if (_activeMode == EditorMode.aiTools && _activeAiTool == 'erase') {
                            _onEraseText(pageRelativePos, tappedPageIdx, _zoomNotifier.value, isAiScan: _isModelDownloaded);
                          } else if (_activeMode == EditorMode.marker) {
                            _onAddMarker(pageRelativePos, tappedPageIdx);
                          } else if (_activeMode == EditorMode.text) {
                            _onAddCustomText(pageRelativePos, tappedPageIdx);
                          } else if (_activeMode == EditorMode.sign) {
                            _onAddSignature(doc, position: pageRelativePos, pageIndex: tappedPageIdx);
                          }
                        }
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  ...List.generate(doc.pageWidths.length, (index) {
                    final double top = _cachedPagePixelOffsets[index];
                    return Positioned(
                      top: top + 15,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 5, 2, 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          '${index + 1} / ${doc.pageWidths.length}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),

                  // Optimize: Use Consumer to isolate field rebuilds
                  Consumer(
                    builder: (context, ref, _) {
                      final fields = ref.watch(pdfEditorProvider.select((s) => s.value?.fields ?? []));
                      final newFields = fields.where((f) => f.isNewField).toList();
                      
                      return Stack(
                        children: newFields.map((field) {
                          final int pIdx = field.pageIndex;
                          if (pIdx >= _cachedPageScales.length) return const SizedBox.shrink();

                          final double pageScale = _cachedPageScales[pIdx];
                          final double pageTopPixel = _cachedPagePixelOffsets[pIdx];

                          final double screenX = field.x * pageScale;
                          final double screenY = pageTopPixel + (field.y * pageScale);

                          return Positioned(
                            left: screenX,
                            top: screenY,
                            child: RepaintBoundary( // Isolation layer for EACH field
                              key: ValueKey(field.id),
                              child: PdfFieldOverlay(
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
                                onEdit: () => _onEditField(field),
                                isEraserMode: _activeMode == EditorMode.aiTools && _activeAiTool == 'erase',
                                onErase: () => ref.read(pdfEditorProvider.notifier).removeField(field.id),
                                onResize: (dw, dh) {
                                  final double newW = field.width + (dw / pageScale);
                                  final double newH = field.height + (dh / pageScale);
                                  ref.read(pdfEditorProvider.notifier).updateFieldSize(
                                        field.id,
                                        newW > 10 ? newW : 10,
                                        newH > 10 ? newH : 10,
                                      );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),


                  EraserOverlay(
                    pageScales: _cachedPageScales,
                    pagePixelOffsets: _cachedPagePixelOffsets,
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
      ),
    ],
  );
}
}
