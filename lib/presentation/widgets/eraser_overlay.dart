import 'dart:ui' as ui;

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
          // 1. Subtle highlight area
          Positioned(
            left: (pendingEraser!.x * scale) - 2,
            top: topOffset + (pendingEraser!.y * scale) - 2,
            child: Container(
              width: (pendingEraser!.width * scale) + 4,
              height: (pendingEraser!.height * scale) + 4,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1.5),
              ),
            ),
          ),
          // 2. Premium Compact Action Pill
          Positioned(
            left: (pendingEraser!.x * scale) + (pendingEraser!.width * scale / 2) - 60,
            top: topOffset + (pendingEraser!.y * scale) - 50,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 120,
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                          Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPillAction(
                          icon: Icons.close_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                          onTap: onCancel,
                        ),
                        Container(
                          width: 1,
                          height: 18,
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                        ),
                        _buildPillAction(
                          icon: Icons.check_rounded,
                          color: const Color(0xFF6C63FF),
                          onTap: onConfirm,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

}
