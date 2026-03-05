import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact toolbar button used in the secondary action bar row.
class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const ToolbarButton({
    super.key,
    required this.icon, 
    required this.label, 
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.amber.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.amber.withOpacity(0.5) : Colors.transparent,
          )
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isActive ? Colors.amber : Colors.white),
            const SizedBox(height: 4),
            Text(
              label, 
              style: GoogleFonts.inter(
                fontSize: 10, 
                color: isActive ? Colors.amber : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
