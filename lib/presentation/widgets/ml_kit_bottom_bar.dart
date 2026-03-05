import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_toast.dart';

class MlKitBottomBar extends StatelessWidget {
  final bool useMlKit;
  final ValueChanged<bool> onChanged;

  const MlKitBottomBar({
    super.key,
    required this.useMlKit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E1E2E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'AI Scan (ML Kit) for Scanned PDFs', 
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12)
              ),
            ],
          ),
          Switch(
            value: useMlKit,
            activeColor: Colors.amber,
            onChanged: (val) {
              onChanged(val);
              if (val) {
                CustomToast.show(
                  context, 
                  message: 'AI ML Kit Engine Enabled. Scanned documents will now be analyzed.'
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
