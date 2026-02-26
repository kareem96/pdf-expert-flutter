import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/services/draft_service.dart';
import '../../data/services/recent_files_service.dart';
import '../providers/pdf_editor_provider.dart';
import '../providers/pdf_thumbnail_provider.dart';
import '../widgets/custom_toast.dart';
import 'pdf_editor_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _recentService = RecentFilesService();
  final _draftService = DraftService();

  List<RecentFileEntry> _recentFiles = [];
  bool _loading = true;
  bool _isOpening = false;
  int _activeTab = 0; // 0: All, 1: Originals, 2: Edited
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final files = await _recentService.getRecentFiles();
    // Filter out files that no longer exist on disk
    final valid = <RecentFileEntry>[];
    for (final f in files) {
      if (await File(f.filePath).exists()) {
        valid.add(f);
      } else {
        await _recentService.removeFile(f.filePath);
      }
    }
    if (mounted) setState(() { _recentFiles = valid; _loading = false; });
  }

  Future<void> _pickNewFile() async {
    if (_isOpening) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      await _openFile(path);
    }
  }

  Future<void> _openFile(String path, {bool restoreDraft = false}) async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    
    try {
      await _recentService.recordFileOpened(path);
      if (!mounted) return;

      if (restoreDraft) {
        final draftFields = await _draftService.loadDraft(path);
        if (mounted) {
          await ref.read(pdfEditorProvider.notifier).loadPdf(path, draftFields: draftFields);
        }
      } else {
        await ref.read(pdfEditorProvider.notifier).loadPdf(path);
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PdfEditorPage()),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
        _loadRecents();
      }
    }
  }

  Future<void> _onTapRecentFile(RecentFileEntry entry) async {
    if (entry.hasDraft) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Resume Editing?'),
          content: Text(
            '"${entry.fileName}" has unsaved draft edits.\nWould you like to continue editing or open fresh?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'fresh'),
              child: const Text('Open Fresh'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'resume'),
              child: const Text('Resume Draft'),
            ),
          ],
        ),
      );
      if (choice == null) return;
      if (choice == 'fresh') {
        await _draftService.deleteDraft(entry.filePath);
        await _recentService.updateDraftStatus(entry.filePath, hasDraft: false);
        await _openFile(entry.filePath, restoreDraft: false);
      } else {
        await _openFile(entry.filePath, restoreDraft: true);
      }
    } else {
      await _openFile(entry.filePath, restoreDraft: false);
    }
  }

  Future<void> _removeRecentFile(RecentFileEntry entry) async {
    await _recentService.removeFile(entry.filePath);
    await _draftService.deleteDraft(entry.filePath);
    _loadRecents();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Primary Filter (Global Search)
    final searchedFiles = _recentFiles.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.fileName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // 2. Secondary Filter (Tab Category)
    final filteredFiles = searchedFiles.where((f) {
      if (_activeTab == 1) return !f.isEdited;
      if (_activeTab == 2) return f.isEdited;
      return true;
    }).toList();

    final latestDraft = _recentFiles.where((f) => f.hasDraft).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F1A), Color(0xFF16162A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1E2E), Color(0xFF252540)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.picture_as_pdf, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PDF Expert',
                            style: GoogleFonts.inter(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: -0.5,
                            ),
                          ),
                          Text('Edit, annotate & sign your PDFs',
                            style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF8888AA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: -0.1, end: 0),

              Expanded(
                child: _loading || _isOpening
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFF6C63FF)),
                            if (_isOpening) ...[
                              const SizedBox(height: 16),
                              Text('Preparing Document...', 
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                            ]
                          ],
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          // ── Continue banner ───────────────────────────────
                          if (latestDraft != null) SliverToBoxAdapter(
                            child: _ContinueBanner(
                              entry: latestDraft,
                              onTap: () => _onTapRecentFile(latestDraft),
                            ),
                          ),

                          // ── Open New PDF button ───────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                              child: GestureDetector(
                                onTap: _pickNewFile,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6C63FF).withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Text('Open New PDF',
                                        style: GoogleFonts.inter(
                                          fontSize: 15, fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate(delay: 150.ms).fade().scale(),
                            ),
                          ),

                          // ── Sticky Header (Search & Tabs) ───────────────────────
                          if (_recentFiles.isNotEmpty)
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _StickyHeaderDelegate(
                                searchController: _searchController,
                                searchQuery: _searchQuery,
                                activeTab: _activeTab,
                                onSearchChanged: (val) => setState(() => _searchQuery = val),
                                onSearchCleared: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  FocusScope.of(context).unfocus();
                                },
                                onTabChanged: (idx) => setState(() => _activeTab = idx),
                              ),
                            ),

                          // ── Recent list ───────────────────────────────────
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => AnimationConfiguration.staggeredList(
                                position: i,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _RecentFileTile(
                                      entry: filteredFiles[i],
                                      onTap: () => _onTapRecentFile(filteredFiles[i]),
                                      onDismiss: () => _removeRecentFile(filteredFiles[i]),
                                    ),
                                  ),
                                ),
                              ),
                              childCount: filteredFiles.length,
                            ),
                          ),

                          // ── Empty recent ─────────────────────────────────
                          if (_recentFiles.isNotEmpty && filteredFiles.isEmpty) SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Column(
                                  children: [
                                    const Icon(Icons.search_off_rounded,
                                        size: 48, color: Color(0xFF44445A)),
                                    const SizedBox(height: 12),
                                    Text(
                                      _searchQuery.isNotEmpty 
                                          ? 'No matches found in this tab' 
                                          : 'No files in this category',
                                      style: GoogleFonts.inter(
                                        fontSize: 14, color: const Color(0xFF66667A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fade().scale(),
                          ),
                          if (_recentFiles.isEmpty) SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Column(
                                  children: [
                                    const Icon(Icons.folder_open_outlined,
                                      size: 56, color: Color(0xFF44445A)),
                                    const SizedBox(height: 12),
                                    Text('No recent files',
                                      style: GoogleFonts.inter(
                                        fontSize: 14, color: const Color(0xFF66667A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fade().scale(),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 32)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final String searchQuery;
  final int activeTab;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<int> onTabChanged;

  _StickyHeaderDelegate({
    required this.searchController,
    required this.searchQuery,
    required this.activeTab,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onTabChanged,
  });

  @override
  double get minExtent => 135.0; // Min Height of Sticky box

  @override
  double get maxExtent => 135.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      // Soft blur background when scrolling past
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A).withValues(alpha: 0.95),
        border: overlapsContent ? const Border(bottom: BorderSide(color: Color(0xFF2E2E4A), width: 1)) : null,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2E2E4A)),
            ),
            child: TextField(
              controller: searchController,
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: onSearchChanged,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search files...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF66667A)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF66667A), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF8888AA), size: 18),
                        onPressed: onSearchCleared,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tabs Horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabButtonWrapper(0, 'All'),
                const SizedBox(width: 8),
                _buildTabButtonWrapper(1, 'Originals'),
                const SizedBox(width: 8),
                _buildTabButtonWrapper(2, 'Edited by Me'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtonWrapper(int index, String title) {
    final bool isActive = activeTab == index;
    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6C63FF) : const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF8B80FF) : const Color(0xFF2E2E4A),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF8888AA),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.searchQuery != searchQuery || oldDelegate.activeTab != activeTab;
  }
}


// ── Continue Banner ────────────────────────────────────────────────────────────
class _ContinueBanner extends ConsumerWidget {
  final RecentFileEntry entry;
  final VoidCallback onTap;

  const _ContinueBanner({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbAsync = ref.watch(pdfThumbnailProvider(entry.filePath));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C63FF).withOpacity(0.2),
              const Color(0xFF9B59B6).withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.hardEdge,
              child: thumbAsync.when(
                data: (data) => data != null 
                    ? Container(
                        color: Colors.white,
                        width: double.infinity,
                        height: double.infinity,
                        child: Image.memory(
                          data, 
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      )
                    : const Icon(Icons.edit_note_rounded, color: Color(0xFF6C63FF), size: 20),
                loading: () => const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF))),
                error: (_, __) => const Icon(Icons.edit_note_rounded, color: Color(0xFF6C63FF), size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Continue Editing',
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                    ),
                  ),
                  Text(entry.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF8888AA),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF6C63FF)),
          ],
        ),
      ),
    );
  }
}

// ── Recent File Tile ───────────────────────────────────────────────────────────
class _RecentFileTile extends ConsumerWidget {
  final RecentFileEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _RecentFileTile({
    required this.entry,
    required this.onTap,
    required this.onDismiss,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM y').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbAsync = ref.watch(pdfThumbnailProvider(entry.filePath));

    return Dismissible(
      key: ValueKey(entry.filePath),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withOpacity(0.2),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (_) async {
        FocusManager.instance.primaryFocus?.unfocus();

        final action = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove File?'),
            content: Text('What would you like to do with "${entry.fileName}"?\n\nThis will also clear any saved draft states.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'history'),
                child: const Text('Remove from History'),
              ),
              if (entry.isEdited) // Only allow physical deletion for exported files natively
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'delete'),
                  child: const Text('Delete File from Device', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        );

        if (action == 'delete') {
          try {
            final file = File(entry.filePath);
            if (await file.exists()) {
              await file.delete();
            }
            if (context.mounted) {
              CustomToast.show(context, message: 'File deleted from device');
            }
            return true;
          } catch (e) {
            CustomToast.show(context, message: 'Could not delete file: $e', isError: true);
            return false;
          }
        }
        
        final isHistory = (action == 'history');
        if (isHistory && context.mounted) {
          CustomToast.show(context, message: 'Removed from history');
        }
        return isHistory;
      },
      onDismissed: (_) => onDismiss(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E2E4A), width: 0.5),
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6C63FF).withOpacity(0.2), const Color(0xFF9B59B6).withOpacity(0.2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.hardEdge,
            child: thumbAsync.when(
              data: (data) => data != null 
                  ? Container(
                      color: Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.memory(
                        data, 
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    )
                  : const Icon(Icons.description_rounded, color: Color(0xFF8B80FF), size: 24),
              loading: () => const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B80FF))),
              error: (_, __) => const Icon(Icons.description_rounded, color: Color(0xFF8B80FF), size: 24),
            ),
          ),
          title: Text(entry.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          subtitle: Text(_formatDate(entry.lastOpened),
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8888AA)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Color(0xFF8888AA), size: 20),
                onPressed: () async {
                  try {
                    final file = File(entry.filePath);
                    if (await file.exists()) {
                      await Share.shareXFiles([XFile(entry.filePath)], text: 'Here is my document: ${entry.fileName}');
                    } else {
                      if (context.mounted) {
                        CustomToast.show(context, message: 'File not found or moved.', isError: true);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      CustomToast.show(context, message: 'Could not share file: $e', isError: true);
                    }
                  }
                },
              ),
              const SizedBox(width: 4),
              if (entry.hasDraft)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 4),
                    ],
                  ),
                  child: Text('Draft',
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF44445A), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
