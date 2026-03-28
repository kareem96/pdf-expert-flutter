import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/constants/app_strings.dart';

class MarkerSelectorDialog extends StatefulWidget {
  final String initialType;
  final String initialColor;
  final bool isEdit;

  const MarkerSelectorDialog({
    super.key,
    this.initialType = 'check',
    this.initialColor = '0xFF000000',
    this.isEdit = false,
  });

  @override
  State<MarkerSelectorDialog> createState() => _MarkerSelectorDialogState();
}

class _MarkerSelectorDialogState extends State<MarkerSelectorDialog> {
  late String selectedType;
  late Color selectedColor;

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

  @override
  void initState() {
    super.initState();
    selectedType = widget.initialType;
    selectedColor = Color(int.parse(widget.initialColor));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      surfaceTintColor: Colors.transparent,
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      title: Text(
        widget.isEdit ? 'Edit Marker' : 'Select Marker',
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
                onTap: () => setState(() => selectedType = 'check'),
              ),
              _MarkerOption(
                icon: Icons.close,
                isSelected: selectedType == 'close',
                onTap: () => setState(() => selectedType = 'close'),
              ),
              _MarkerOption(
                icon: Icons.square,
                isSelected: selectedType == 'square',
                onTap: () => setState(() => selectedType = 'square'),
              ),
              _MarkerOption(
                icon: Icons.circle,
                isSelected: selectedType == 'circle',
                onTap: () => setState(() => selectedType = 'circle'),
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
              final bool isColorSelected = selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => selectedColor = color),
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
                      BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 4),
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
        if (widget.isEdit)
          TextButton(
            onPressed: () => Navigator.pop(context, {'action': 'delete'}),
            child: Text(AppStrings.delete, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.cancel, style: const TextStyle(color: Colors.white60, fontSize: 13)),
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
            'color': '0x${selectedColor.toARGB32().toRadixString(16).toUpperCase()}',
          }),
          child: Text(widget.isEdit ? 'Update' : 'Add', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
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
          color: isSelected ? Colors.amber.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
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
