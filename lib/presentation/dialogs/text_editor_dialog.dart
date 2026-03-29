import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../common/constants/app_strings.dart';
import '../widgets/custom_toast.dart';

class TextEditorDialog extends StatefulWidget {
  final String initialText;
  final double initialFontSize;
  final bool initialIsBold;
  final bool initialIsItalic;
  final String initialColor;
  final String initialFontFamily;
  final bool isEdit;

  const TextEditorDialog({
    super.key,
    this.initialText = '',
    this.initialFontSize = 14,
    this.initialIsBold = false,
    this.initialIsItalic = false,
    this.initialColor = '0xFF000000',
    this.initialFontFamily = 'Helvetica',
    this.isEdit = false,
  });

  @override
  State<TextEditorDialog> createState() => _TextEditorDialogState();
}

class _TextEditorDialogState extends State<TextEditorDialog> {
  late TextEditingController textController;
  late double currentFontSize;
  late bool isBold;
  late bool isItalic;
  late String currentColor;
  late String currentFontFamily;

  final List<String> fontFamilies = [
    'Helvetica',
    'Roboto',
    'Merriweather',
    'Courier Prime',
    'Playfair Display',
    'Dancing Script',
  ];

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.initialText);
    currentFontSize = widget.initialFontSize;
    isBold = widget.initialIsBold;
    isItalic = widget.initialIsItalic;
    currentColor = widget.initialColor;
    currentFontFamily = widget.initialFontFamily;
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isEdit ? AppStrings.dialogEditText : AppStrings.dialogAddText,
              style: GoogleFonts.inter(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark 
                    ? colorScheme.onSurface.withValues(alpha: 0.05) 
                    : colorScheme.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: textController,
                autofocus: true,
                maxLines: null,
                style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Type your text here...',
                  hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppStrings.dialogSize} ${currentFontSize.toInt()}', 
                        style: GoogleFonts.inter(
                          fontSize: 12, 
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        )
                      ),
                      Slider(
                        value: currentFontSize,
                        min: 8,
                        max: 72,
                        activeColor: colorScheme.primary,
                        inactiveColor: colorScheme.primary.withValues(alpha: 0.1),
                        onChanged: (val) => setState(() => currentFontSize = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(AppStrings.selectColor),
                        content: SingleChildScrollView(
                          child: BlockPicker(
                            pickerColor: Color(int.parse(currentColor)),
                            onColorChanged: (color) {
                              setState(() => currentColor = '0x${color.toARGB32().toRadixString(16).toUpperCase()}');
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(int.parse(currentColor)),
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Color(int.parse(currentColor)).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStyleToggle(
                  icon: Icons.format_bold, 
                  isActive: isBold, 
                  onTap: () => setState(() => isBold = !isBold),
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 12),
                _buildStyleToggle(
                  icon: Icons.format_italic, 
                  isActive: isItalic, 
                  onTap: () => setState(() => isItalic = !isItalic),
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentFontFamily,
                        dropdownColor: colorScheme.surface,
                        style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                        items: fontFamilies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => currentFontFamily = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                if (widget.isEdit)
                   IconButton(
                     onPressed: () => Navigator.pop(context, {'action': 'delete'}),
                     icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
                     style: IconButton.styleFrom(
                       backgroundColor: colorScheme.error.withValues(alpha: 0.1),
                       padding: const EdgeInsets.all(12),
                     ),
                   ),
                if (widget.isEdit) const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context), 
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppStrings.cancel, style: TextStyle(color: colorScheme.onSurfaceVariant))
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (textController.text.trim().isEmpty) {
                         CustomToast.show(context, message: AppStrings.toastTextEmpty, isError: true);
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(widget.isEdit ? AppStrings.ok : AppStrings.add),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleToggle({
    required IconData icon, 
    required bool isActive, 
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon, 
          color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
          size: 20,
        ),
      ),
    );
  }
}
