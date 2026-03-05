import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../common/constants/app_strings.dart';
import '../widgets/toolbar_button.dart';
import '../widgets/custom_toast.dart';
// Note: We need a way to pass EditorMode, so we will expect the parent to define it 
// or import it if it's extracted. Since EditorMode is in pdf_editor_page.dart, 
// it's better to extract the enum or just import it.
import '../pages/pdf_editor_page.dart' show EditorMode;

class PdfEditorToolbar extends StatefulWidget {
  final EditorMode activeMode;
  final ValueChanged<EditorMode> onModeChanged;
  final VoidCallback onAddSignature;
  final VoidCallback onAddImage;
  final VoidCallback onAddText;
  final VoidCallback onAddNote;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final String selectedMarkerType;

  const PdfEditorToolbar({
    super.key,
    required this.activeMode,
    required this.onModeChanged,
    required this.onAddSignature,
    required this.onAddImage,
    required this.onAddText,
    required this.onAddNote,
    required this.onSave,
    required this.onShare,
    required this.selectedMarkerType,
  });

  @override
  State<PdfEditorToolbar> createState() => _PdfEditorToolbarState();
}

class _PdfEditorToolbarState extends State<PdfEditorToolbar> {
  final ScrollController _toolbarScrollController = ScrollController();
  bool _showLeftIndicator = false;
  bool _showRightIndicator = true;

  @override
  void initState() {
    super.initState();
    _toolbarScrollController.addListener(_updateToolbarIndicators);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateToolbarIndicators());
  }

  @override
  void dispose() {
    _toolbarScrollController.removeListener(_updateToolbarIndicators);
    _toolbarScrollController.dispose();
    super.dispose();
  }

  void _updateToolbarIndicators() {
    if (!mounted) return;
    final maxScroll = _toolbarScrollController.position.maxScrollExtent;
    final currentScroll = _toolbarScrollController.offset;
    
    setState(() {
      _showLeftIndicator = currentScroll > 0;
      _showRightIndicator = currentScroll < maxScroll;
    });
  }

  IconData _getMarkerIcon(String type) {
    switch (type) {
      case 'check': return Icons.check;
      case 'close': return Icons.close;
      case 'square': return Icons.crop_square;
      case 'circle': return Icons.radio_button_unchecked;
      default: return Icons.check;
    }
  }

  void _toggleMode(EditorMode mode) {
    final newMode = widget.activeMode == mode ? EditorMode.none : mode;
    widget.onModeChanged(newMode);
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF252540).withOpacity(0.6)
                  : Colors.white.withOpacity(0.8),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3E3E5A)
                      : Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _toolbarScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      ToolbarButton(
                        icon: Icons.draw_outlined,  
                        label: AppStrings.modeSign,  
                        isActive: widget.activeMode == EditorMode.sign,
                        onTap: () {
                          _toggleMode(EditorMode.sign);
                          widget.onAddSignature();
                        }
                      ),
                      ToolbarButton(
                        icon: Icons.image_outlined, 
                        label: AppStrings.modeImage, 
                        isActive: widget.activeMode == EditorMode.image,
                        onTap: () {
                          _toggleMode(EditorMode.image);
                          widget.onAddImage();
                        }
                      ),
                      ToolbarButton(
                        icon: Icons.title_rounded,  
                        label: AppStrings.modeText,  
                        isActive: widget.activeMode == EditorMode.text,
                        onTap: () {
                          _toggleMode(EditorMode.text);
                          widget.onAddText();
                        }
                      ),
                      ToolbarButton(
                        icon: Icons.cleaning_services_rounded, 
                        label: AppStrings.modeErase, 
                        isActive: widget.activeMode == EditorMode.erase,
                        onTap: () {
                          _toggleMode(EditorMode.erase);
                          if (widget.activeMode != EditorMode.erase) {
                            CustomToast.show(context, message: AppStrings.toastEraserActive);
                          }
                        }
                      ),
                      ToolbarButton(
                        icon: _getMarkerIcon(widget.selectedMarkerType),
                        label: AppStrings.modeMarker,
                        isActive: widget.activeMode == EditorMode.marker,
                        onTap: () {
                          _toggleMode(EditorMode.marker);
                          if (widget.activeMode != EditorMode.marker) {
                            CustomToast.show(context, message: AppStrings.toastMarkerActive);
                          }
                        }
                      ),
                      ToolbarButton(
                        icon: Icons.sticky_note_2_outlined, 
                        label: AppStrings.modeNote, 
                        isActive: widget.activeMode == EditorMode.note,
                        onTap: () {
                          _toggleMode(EditorMode.note);
                          widget.onAddNote();
                        }
                      ),
                      ToolbarButton(
                        icon: Icons.save_outlined,  
                        label: AppStrings.modeSave,  
                        onTap: () {
                          widget.onModeChanged(EditorMode.none);
                          widget.onSave();
                        }
                      ),
                      ToolbarButton(
                        icon: Icons.share_outlined, 
                        label: AppStrings.modeShare, 
                        onTap: () {
                          widget.onModeChanged(EditorMode.none);
                          widget.onShare();
                        }
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
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
                            Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252540) : Colors.white,
                            (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252540) : Colors.white).withOpacity(0),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded, 
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black26, 
                        size: 20,
                      ),
                    ),
                  ),
                ),
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
                            Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252540) : Colors.white,
                            (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252540) : Colors.white).withOpacity(0),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded, 
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black26, 
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
