import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isVertical;

  const ToolbarButton({
    super.key,
    required this.icon, 
    required this.label, 
    required this.onTap,
    this.isActive = false,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: isVertical ? 72 : 68,
        margin: isVertical 
            ? const EdgeInsets.symmetric(vertical: 4, horizontal: 4)
            : const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isActive 
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              )
            : null,
          boxShadow: isActive ? [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 8, offset: const Offset(0, 4),
            )
          ] : null,
        ),
        // USING CONSTRAINEDBOX TO ENSURE IT NEVER GOES BELOW A CERTAIN HEIGHT WITHOUT SCALING
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50, maxHeight: 72),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon, size: 20, 
                    color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label, 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10, 
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? Colors.white : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
