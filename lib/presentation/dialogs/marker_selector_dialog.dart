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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.isEdit ? 'Edit Marker' : 'Select Marker',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: colorScheme.onSurface, 
          fontWeight: FontWeight.bold, 
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MarkerOption(
                icon: Icons.check_rounded,
                isSelected: selectedType == 'check',
                onTap: () => setState(() => selectedType = 'check'),
                colorScheme: colorScheme,
              ),
              _MarkerOption(
                icon: Icons.close_rounded,
                isSelected: selectedType == 'close',
                onTap: () => setState(() => selectedType = 'close'),
                colorScheme: colorScheme,
              ),
              _MarkerOption(
                icon: Icons.square_rounded,
                isSelected: selectedType == 'square',
                onTap: () => setState(() => selectedType = 'square'),
                colorScheme: colorScheme,
              ),
              _MarkerOption(
                icon: Icons.circle_rounded,
                isSelected: selectedType == 'circle',
                onTap: () => setState(() => selectedType = 'circle'),
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Select Color',
            style: GoogleFonts.inter(
              color: colorScheme.onSurfaceVariant, 
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: availableColors.map((color) {
              final bool isColorSelected = selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => selectedColor = color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isColorSelected ? colorScheme.primary : Colors.white24,
                      width: isColorSelected ? 3 : 1,
                    ),
                    boxShadow: isColorSelected ? [
                      BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                    ] : null,
                  ),
                  child: isColorSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        if (widget.isEdit)
          IconButton(
            onPressed: () => Navigator.pop(context, {'action': 'delete'}),
            icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.error.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
        if (widget.isEdit) const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(AppStrings.cancel, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
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
  final ColorScheme colorScheme;

  const _MarkerOption({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [
            BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ] : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          size: 24,
        ),
      ),
    );
  }
}
