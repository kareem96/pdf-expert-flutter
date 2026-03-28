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
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isEdit ? 'Edit Text' : 'Add Text',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: textController,
              autofocus: true,
              maxLines: null,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Type your text here...',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppStrings.dialogSize} ${currentFontSize.toInt()}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      Slider(
                        value: currentFontSize,
                        min: 8,
                        max: 72,
                        onChanged: (val) => setState(() => currentFontSize = val),
                      ),
                    ],
                  ),
                ),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(currentColor)),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.format_bold, color: isBold ? Colors.deepPurpleAccent : Colors.white),
                  onPressed: () => setState(() => isBold = !isBold),
                ),
                IconButton(
                  icon: Icon(Icons.format_italic, color: isItalic ? Colors.deepPurpleAccent : Colors.white),
                  onPressed: () => setState(() => isItalic = !isItalic),
                ),
                DropdownButton<String>(
                  value: currentFontFamily,
                  dropdownColor: const Color(0xFF2A2A3E),
                  style: const TextStyle(color: Colors.white),
                  items: fontFamilies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => currentFontFamily = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.isEdit)
                   TextButton(
                     onPressed: () => Navigator.pop(context, {'action': 'delete'}),
                     child: Text(AppStrings.delete, style: const TextStyle(color: Colors.red)),
                   ),
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: Text(AppStrings.cancel)
                ),
                ElevatedButton(
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
                  child: Text(widget.isEdit ? 'OK' : 'Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
