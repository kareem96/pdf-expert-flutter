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
import '../providers/app_theme_provider.dart';
import '../providers/app_language_provider.dart';
import '../widgets/custom_toast.dart';
import '../../common/constants/app_strings.dart';
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
  int _activeTab = 0;
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
      await _openFile(result.files.single.path!);
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
        final draftPdfPath = await _draftService.getDraftPdfPath(path);
        if (mounted) {
          await ref.read(pdfEditorProvider.notifier).loadPdf(
            draftPdfPath ?? path, 
            originalPath: path,
            draftFields: draftFields
          );
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
          title: Text(AppStrings.resumeEditing),
          content: Text(AppStrings.resumeEditingBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'fresh'),
              child: Text(AppStrings.openFresh),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'resume'),
              child: Text(AppStrings.resumeDraft),
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

  Future<void> _renameRecentFile(RecentFileEntry entry) async {
    String nameWithoutExt = entry.fileName;
    if (nameWithoutExt.toLowerCase().endsWith('.pdf')) {
      nameWithoutExt = nameWithoutExt.substring(0, nameWithoutExt.length - 4);
    }
    final controller = TextEditingController(text: nameWithoutExt);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.dialogRenameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppStrings.dialogRenameHint,
            suffixText: '.pdf',
            prefixIcon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppStrings.ok),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != nameWithoutExt) {
      try {
        await _recentService.renameFile(entry.filePath, newName);
        if (mounted) CustomToast.show(context, message: AppStrings.toastRenameSuccess);
        _loadRecents();
      } catch (e) {
        if (mounted) CustomToast.show(context, message: e.toString(), isError: true);
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final themeMode = ref.watch(themeProvider);
          ref.watch(appStringsProvider);

          return AlertDialog(
            title: Text(AppStrings.settings),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(AppStrings.theme),
                  subtitle: Text(themeMode == ThemeMode.dark ? AppStrings.themeDark : AppStrings.themeLight),
                  trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                  ),
                ),
                const Divider(),
                ListTile(
                  title: Text(AppStrings.language),
                  subtitle: Text(AppStrings.currentLanguage == 'id' ? 'Bahasa Indonesia' : 'English'),
                  trailing: DropdownButton<String>(
                    value: AppStrings.currentLanguage,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'id', child: Text(AppStrings.langIndo)),
                      DropdownMenuItem(value: 'en', child: Text(AppStrings.langEnglish)),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(languageProvider.notifier).setLanguage(val);
                      }
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.ok),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appStringsProvider);
    final double screenWidth = MediaQuery.of(context).size.width;

    final searchedFiles = _recentFiles.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.fileName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredFiles = searchedFiles.where((f) {
      if (_activeTab == 1) return !f.isEdited;
      if (_activeTab == 2) return f.isEdited;
      return true;
    }).toList();

    final latestDraft = _recentFiles.where((f) => f.hasDraft).firstOrNull;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF0F0F1A), const Color(0xFF16162A)]
              : [const Color(0xFFF0F2F9), const Color(0xFFF8F9FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF1E1E2E), const Color(0xFF252540)]
                      : [const Color(0xFFFFFFFF), const Color(0xFFF0F2F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: Theme.of(context).brightness == Brightness.light
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))]
                    : null,
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
                          Text(AppStrings.appName,
                            style: GoogleFonts.inter(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(AppStrings.appSubtitle,
                            style: GoogleFonts.inter(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      onPressed: _showSettingsDialog,
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
                              Text(AppStrings.preparingDocument,
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                            ]
                          ],
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          if (latestDraft != null) SliverToBoxAdapter(
                            child: _ContinueBanner(
                              entry: latestDraft,
                              onTap: () => _onTapRecentFile(latestDraft),
                            ),
                          ),

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
                                        color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
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
                                      Text(AppStrings.openNewPdf,
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

                          if (filteredFiles.isNotEmpty && screenWidth < 600) SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: Center(
                                child: Text(
                                  AppStrings.hintSwipeDelete,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF8888AA).withValues(alpha: 0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          _buildRecentContent(context, filteredFiles, screenWidth),

                          if (_recentFiles.isNotEmpty && filteredFiles.isEmpty) SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Column(
                                  children: [
                                    const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF44445A)),
                                    const SizedBox(height: 12),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? AppStrings.noMatchesInTab
                                          : AppStrings.noFilesInCategory,
                                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF66667A)),
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
                                    const Icon(Icons.folder_open_outlined, size: 56, color: Color(0xFF44445A)),
                                    const SizedBox(height: 12),
                                    Text(AppStrings.noRecentFiles,
                                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF66667A)),
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

  Widget _buildRecentContent(BuildContext context, List<RecentFileEntry> files, double screenWidth) {
    final bool useGrid = screenWidth >= 600;
    
    if (useGrid) {
      final int crossAxisCount = screenWidth > 900 ? 3 : 2;
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.9,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _RecentFileTile(
              entry: files[i],
              onTap: () => _onTapRecentFile(files[i]),
              onDismiss: () => _removeRecentFile(files[i]),
              onRename: () => _renameRecentFile(files[i]),
              isGrid: true,
            ),
            childCount: files.length,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => AnimationConfiguration.staggeredList(
          position: i,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _RecentFileTile(
                entry: files[i],
                onTap: () => _onTapRecentFile(files[i]),
                onDismiss: () => _removeRecentFile(files[i]),
                onRename: () => _renameRecentFile(files[i]),
                isGrid: false,
              ),
            ),
          ),
        ),
        childCount: files.length,
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
  double get minExtent => 135.0;
  @override
  double get maxExtent => 135.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Consumer(
      builder: (context, ref, _) {
        ref.watch(appStringsProvider);
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F0F1A).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            border: overlapsContent
                ? Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1))
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E1E2E)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2E2E4A)
                        : Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  controller: searchController,
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  onChanged: onSearchChanged,
                  style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: AppStrings.searchHint,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF8888AA)
                          : Colors.black38,
                    ),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton(context, 0, AppStrings.tabAll),
                    const SizedBox(width: 8),
                    _buildTabButton(context, 1, AppStrings.tabRecent),
                    const SizedBox(width: 8),
                    _buildTabButton(context, 2, AppStrings.tabDrafts),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(BuildContext context, int index, String title) {
    final bool isActive = activeTab == index;
    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6C63FF)
              : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E2E) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF8B80FF)
                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2E2E4A) : Colors.grey.shade300),
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

class _ContinueBanner extends ConsumerWidget {
  final RecentFileEntry entry;
  final VoidCallback onTap;

  const _ContinueBanner({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appStringsProvider);
    final thumbAsync = ref.watch(pdfThumbnailProvider(entry.filePath));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C63FF).withValues(alpha: 0.2),
              const Color(0xFF9B59B6).withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: thumbAsync.when(
                data: (data) => data != null
                    ? Container(
                        color: Colors.white,
                        width: double.infinity,
                        height: double.infinity,
                        child: Image.memory(data, fit: BoxFit.cover, alignment: Alignment.topCenter),
                      )
                    : const Icon(Icons.edit_note_rounded, color: Color(0xFF6C63FF), size: 20),
                loading: () => const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF))),
                error: (context, error) => const Icon(Icons.edit_note_rounded, color: Color(0xFF6C63FF), size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.continueEditing,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  Text(entry.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8888AA)),
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

class _RecentFileTile extends ConsumerWidget {
  final RecentFileEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback onRename;
  final bool isGrid;

  const _RecentFileTile({
    required this.entry,
    required this.onTap,
    required this.onDismiss,
    required this.onRename,
    required this.isGrid,
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

  Future<bool> _showDeleteDialog(BuildContext context) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.removeFile),
        content: Text(AppStrings.removeFileBody(entry.fileName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'history'),
            child: Text(AppStrings.removeFromHistory),
          ),
          if (entry.isEdited)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: Text(AppStrings.deleteFromDevice, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
    return action == 'history' || action == 'delete';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appStringsProvider);
    final thumbAsync = ref.watch(pdfThumbnailProvider(entry.filePath));

    Widget content;
    if (isGrid) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2E2E4A).withValues(alpha: 0.3)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: thumbAsync.when(
                      data: (data) => data != null
                          ? Image.memory(data, fit: BoxFit.cover, alignment: Alignment.topCenter)
                          : const Icon(Icons.description_rounded, color: Color(0xFF8B80FF), size: 40),
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (context, error) => const Icon(Icons.description_rounded, color: Color(0xFF8B80FF), size: 40),
                    ),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: _buildPopMenu(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(entry.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Text(_formatDate(entry.lastOpened),
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8888AA)),
          ),
        ],
      );
    } else {
      content = ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6C63FF).withValues(alpha: 0.2), const Color(0xFF9B59B6).withValues(alpha: 0.2)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
          ),
          clipBehavior: Clip.hardEdge,
          child: thumbAsync.when(
            data: (data) => data != null
                ? Image.memory(data, fit: BoxFit.cover, alignment: Alignment.topCenter)
                : const Icon(Icons.description_rounded, color: Color(0xFF8B80FF), size: 24),
            loading: () => const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)),
            error: (context, error) => const Icon(Icons.description_rounded, color: Color(0xFF8B80FF), size: 24),
          ),
        ),
        title: Text(entry.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_formatDate(entry.lastOpened),
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8888AA)),
        ),
        trailing: _buildPopMenu(context),
      );
    }

    final tile = Container(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? (isGrid ? Colors.transparent : const Color(0xFF1E1E2E).withValues(alpha: 0.5))
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isGrid ? null : Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2E2E4A)
              : Colors.grey.shade200,
        ),
        boxShadow: !isGrid && Theme.of(context).brightness == Brightness.light
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: isGrid ? GestureDetector(onTap: onTap, child: content) : content,
    );

    if (isGrid) return tile;

    return Dismissible(
      key: ValueKey(entry.filePath),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withValues(alpha: 0.2),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (_) => _showDeleteDialog(context),
      onDismissed: (_) => onDismiss(),
      child: tile,
    );
  }

  Widget _buildPopMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: const Color(0xFF8888AA), size: isGrid ? 18 : 22),
      padding: EdgeInsets.zero,
      onSelected: (val) async {
        if (val == 'rename') onRename();
        if (val == 'delete') {
          final confirmed = await _showDeleteDialog(context);
          if (confirmed) onDismiss();
        }
        if (val == 'share') {
          try {
            await Share.shareXFiles([XFile(entry.filePath)], text: 'PDF Expert: ${entry.fileName}'); // ignore: deprecated_member_use
          } catch (e) {
            if (context.mounted) CustomToast.show(context, message: 'Share failed: $e', isError: true);
          }
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 10),
              Text(AppStrings.actionRename, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              const Icon(Icons.share_outlined, size: 18),
              const SizedBox(width: 10),
              Text(AppStrings.modeShare, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
              const SizedBox(width: 10),
              Text(AppStrings.actionDelete, style: const TextStyle(fontSize: 13, color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }
}
