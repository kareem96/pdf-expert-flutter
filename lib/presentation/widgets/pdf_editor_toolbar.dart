import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/constants/app_strings.dart';
import '../providers/app_language_provider.dart';
import '../widgets/toolbar_button.dart';
import '../widgets/custom_toast.dart';
import '../pages/pdf_editor_page.dart' show EditorMode;

class PdfEditorToolbar extends ConsumerStatefulWidget {
  final EditorMode activeMode;
  final ValueChanged<EditorMode> onModeChanged;
  final VoidCallback onAddSignature;
  final VoidCallback onAddImage;
  final VoidCallback onAddText;
  final VoidCallback onAddNote;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final String selectedMarkerType;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

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
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  ConsumerState<PdfEditorToolbar> createState() => _PdfEditorToolbarState();
}

class _PdfEditorToolbarState extends ConsumerState<PdfEditorToolbar> {
  // Removed scroll controller and indicators logic for new Expand/Collapse UX

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
    ref.watch(appStringsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildPrimaryActions(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildExpandToggleButton(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolbarButton(
          icon: Icons.draw_outlined,
          label: AppStrings.modeSign,
          isActive: widget.activeMode == EditorMode.sign,
          onTap: () {
            _toggleMode(EditorMode.sign);
            widget.onAddSignature();
          },
        ),
        ToolbarButton(
          icon: Icons.title_rounded,
          label: AppStrings.modeText,
          isActive: widget.activeMode == EditorMode.text,
          onTap: () => _toggleMode(EditorMode.text),
        ),
        ToolbarButton(
          icon: Icons.auto_awesome_rounded,
          label: AppStrings.modeAiTools,
          isActive: widget.activeMode == EditorMode.aiTools,
          onTap: () {
            _toggleMode(EditorMode.aiTools);
          },
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
          },
        ),
      ],
    );
  }

  Widget _buildExpandToggleButton(ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onToggleExpand,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.isExpanded ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: AnimatedRotation(
            turns: widget.isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: widget.isExpanded ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
