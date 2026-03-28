import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/constants/app_strings.dart';
import '../providers/app_language_provider.dart';
import '../providers/pdf_editor_provider.dart';

class PdfEditorAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String docName;
  final bool isEditing;
  final VoidCallback? onPageManagerTap;

  const PdfEditorAppBar({
    super.key,
    required this.docName,
    required this.isEditing,
    this.onPageManagerTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appStringsProvider);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Theme.of(context).brightness,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
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
          color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).colorScheme.onSurface,
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
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
            Icons.grid_view_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => onPageManagerTap?.call(),
        ),
        IconButton(
          icon: Icon(
            Icons.undo_rounded,
            size: 20,
            color: ref.watch(pdfEditorProvider.notifier).canUndo 
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
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
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
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
