import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/constants/app_strings.dart';
import '../providers/app_language_provider.dart';
import '../providers/pdf_editor_provider.dart';

class PdfEditorAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String docName;
  final bool isEditing;

  const PdfEditorAppBar({
    super.key,
    required this.docName,
    required this.isEditing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appStringsProvider);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E2E).withOpacity(0.7)
                  : Colors.white.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3E3E5A)
                      : Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.appName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                if (docName.isNotEmpty)
                  Text(
                    docName,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF8888BB) : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.undo_rounded,
            size: 20,
            color: ref.watch(pdfEditorProvider.notifier).canUndo 
                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)
                : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300),
          ),
          onPressed: ref.watch(pdfEditorProvider.notifier).canUndo 
              ? () => ref.read(pdfEditorProvider.notifier).undo() 
              : null,
        ),
        IconButton(
          icon: Icon(
            Icons.redo_rounded,
            size: 20,
            color: ref.watch(pdfEditorProvider.notifier).canRedo 
                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)
                : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300),
          ),
          onPressed: ref.watch(pdfEditorProvider.notifier).canRedo 
              ? () => ref.read(pdfEditorProvider.notifier).redo() 
              : null,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
