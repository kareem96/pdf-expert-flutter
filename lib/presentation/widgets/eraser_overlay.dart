import 'package:flutter/material.dart';
import '../../domain/entities/pdf_field_entity.dart';

class EraserOverlay extends StatelessWidget {
  final List<double> pageScales;
  final List<double> pagePixelOffsets;
  final PdfFieldEntity? pendingEraser;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const EraserOverlay({
    Key? key,
    required this.pageScales,
    required this.pagePixelOffsets,
    this.pendingEraser,
    required this.onCancel,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pendingEraser == null || pendingEraser!.pageIndex >= pageScales.length) {
      return const SizedBox.shrink();
    }

    final double scale = pageScales[pendingEraser!.pageIndex];
    final double topOffset = pagePixelOffsets[pendingEraser!.pageIndex];

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Stack(
        children: [
          // The highlight of what will be erased
          Positioned(
            left: pendingEraser!.x * scale,
            top: topOffset + (pendingEraser!.y * scale),
            child: Container(
              width: pendingEraser!.width * scale,
              height: pendingEraser!.height * scale,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.35),
                border: Border.all(color: Colors.red, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 10),
                ],
              ),
              child: const Center(
                child: Icon(Icons.auto_fix_high, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Actions bar floating near the area
          Positioned(
            left: pendingEraser!.x * scale,
            top: topOffset + (pendingEraser!.y * scale) - 60,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade400, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Erase this?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onCancel,
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.greenAccent, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onConfirm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
