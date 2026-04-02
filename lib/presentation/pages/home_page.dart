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
import '../providers/recent_files_provider.dart';
import '../widgets/custom_toast.dart';
import '../../common/constants/app_strings.dart';
import '../widgets/adaptive_layout_wrapper.dart';
import 'pdf_editor_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _draftService = DraftService();

  bool _isOpening = false;
  int _activeTab = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  RecentFileEntry? _selectedFile;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      await ref.read(recentFilesProvider.notifier).recordFileOpened(path);
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
      }
    }
  }

  Future<void> _onTapRecentFile(RecentFileEntry entry) async {
    if (AdaptiveLayoutWrapper.isTablet(context)) {
      setState(() => _selectedFile = entry);
      return;
    }

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
        await ref.read(recentFilesProvider.notifier).updateDraftStatus(entry.filePath, hasDraft: false);
        await _openFile(entry.filePath, restoreDraft: false);
      } else {
        await _openFile(entry.filePath, restoreDraft: true);
      }
    } else {
      await _openFile(entry.filePath, restoreDraft: false);
    }
  }

  void _removeRecentFile(RecentFileEntry entry) {
    // Provider sekarang melakukan update optimistic, jadi UI langsung refresh
    ref.read(recentFilesProvider.notifier).removeFile(entry.filePath);
    _draftService.deleteDraft(entry.filePath);
    if (_selectedFile?.filePath == entry.filePath) {
      setState(() => _selectedFile = null);
    }
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
        await ref.read(recentFilesProvider.notifier).renameFile(entry.filePath, newName);
        if (mounted) CustomToast.show(context, message: AppStrings.toastRenameSuccess);
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
          ref.watch(appStringsProvider);

          return AlertDialog(
            title: Text(AppStrings.settings),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(AppStrings.theme),
                  subtitle: Text(Theme.of(context).brightness == Brightness.dark ? AppStrings.themeDark : AppStrings.themeLight),
                  trailing: Switch(
                    value: Theme.of(context).brightness == Brightness.dark,
                    onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(Theme.of(context).brightness == Brightness.dark),
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
              ), // Removed .animate() for instant first paint to avoid black gap

              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final recentFilesAsync = ref.watch(recentFilesProvider);
                    
                    return recentFilesAsync.when(
                      data: (recentFiles) {
                        final searchedFiles = recentFiles.where((f) {
                          if (_searchQuery.isEmpty) return true;
                          return f.fileName.toLowerCase().contains(_searchQuery.toLowerCase());
                        }).toList();

                        final filteredFiles = searchedFiles.where((f) {
                          if (_activeTab == 1) return !f.isEdited;
                          if (_activeTab == 2) return f.isEdited;
                          return true;
                        }).toList();

                        final latestDraft = recentFiles.where((f) => f.hasDraft).firstOrNull;
                        final bool isTablet = AdaptiveLayoutWrapper.isTablet(context);

                    Widget mainList = CustomScrollView(
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
                            ),
                          ),
                        ),

                        if (recentFiles.isNotEmpty)
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

                        if (filteredFiles.isNotEmpty && !isTablet) SliverToBoxAdapter(
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

                        if (recentFiles.isNotEmpty && filteredFiles.isEmpty) SliverToBoxAdapter(
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
                        if (recentFiles.isEmpty) SliverToBoxAdapter(
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
                    );

                    if (!isTablet) return mainList;

                    return Row(
                      children: [
                        Expanded(flex: screenWidth > 900 ? 5 : 6, child: mainList),
                        VerticalDivider(width: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                        Expanded(flex: screenWidth > 900 ? 7 : 8, child: _buildDetailPanel(_selectedFile, screenWidth)),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => Center(child: Text('Error: $e')),
                );
              },
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(RecentFileEntry? entry, double screenWidth) {
    if (entry == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              AppStrings.searchHint.replaceAll('...', ''), 
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
          ],
        ),
      );
    }

    final thumbAsync = ref.watch(pdfThumbnailProvider(entry.filePath));

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Card
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: thumbAsync.when(
                data: (data) => data != null
                    ? Container(color: Colors.white, child: Image.memory(data, fit: BoxFit.contain, alignment: Alignment.topCenter))
                    : const Center(child: Icon(Icons.picture_as_pdf, size: 80, color: Colors.red)),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const Center(child: Icon(Icons.error_outline)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Metadata
          Text(
            entry.fileName,
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Last opened: ${DateFormat('d MMM y, HH:mm').format(entry.lastOpened)}',
            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 48),
          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isOpening ? null : () => _openFile(entry.filePath, restoreDraft: entry.hasDraft),
              icon: _isOpening 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Icon(entry.hasDraft ? Icons.edit_note_rounded : Icons.menu_book_rounded),
              label: Text(
                _isOpening ? AppStrings.preparingDocument : (entry.hasDraft ? AppStrings.continueEditing : AppStrings.openPdf),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
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
              isSelected: _selectedFile?.filePath == files[i].filePath,
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
                isSelected: _selectedFile?.filePath == files[i].filePath,
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
                        child: Container(color: Colors.white, child: Image.memory(data, fit: BoxFit.cover, alignment: Alignment.topCenter)),
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
  final bool isSelected;

  const _RecentFileTile({
    required this.entry,
    required this.onTap,
    required this.onDismiss,
    required this.onRename,
    required this.isGrid,
    this.isSelected = false,
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

    final int daysPassed = DateTime.now().difference(entry.lastOpened).inDays;
    final int daysLeft = (7 - daysPassed).clamp(0, 7);

    Widget content;
    if (isGrid) {
      content = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2E2E4A).withValues(alpha: 0.3)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: thumbAsync.when(
                        data: (data) => data != null
                            ? Container(
                                color: Colors.white, 
                                child: Image.memory(
                                  data, 
                                  fit: BoxFit.cover, 
                                  alignment: Alignment.topCenter,
                                  cacheHeight: 250, // Optimize GPU memory for Grid
                                ),
                              )
                            : Center(child: Icon(Icons.picture_as_pdf_outlined, color: Colors.red.withValues(alpha: 0.5), size: 40)),
                        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (e, s) => const Center(child: Icon(Icons.error_outline)),
                      ),
                    ),
                    if (entry.hasDraft)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit, size: 10, color: Colors.black),
                              const SizedBox(width: 4),
                              Text('${daysLeft}d', style: const TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.fileName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13, 
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF6C63FF) : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(_formatDate(entry.lastOpened),
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8888AA)),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF8888AA)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showOptions(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      content = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF6C63FF).withValues(alpha: 0.1)
              : (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E2E).withValues(alpha: 0.5)
                  : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF6C63FF) 
                : (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2E2E4A).withValues(alpha: 0.3)
                    : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 65,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.hardEdge,
              child: thumbAsync.when(
                data: (data) => data != null
                    ? Container(
                        color: Colors.white, 
                        child: Image.memory(
                          data, 
                          fit: BoxFit.cover, 
                          alignment: Alignment.topCenter,
                          cacheHeight: 150, // Optimize GPU memory for List
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, s) => const Icon(Icons.error_outline),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(entry.fileName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (entry.hasDraft)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${AppStrings.labelDraft} • ${daysLeft}d', style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: const Color(0xFF8888AA).withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(_formatDate(entry.lastOpened),
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8888AA)),
                      ),
                      const SizedBox(width: 12),
                      if (entry.isEdited) ...[
                        Icon(Icons.check_circle_outline, size: 12, color: Colors.green.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(AppStrings.labelEdited, style: GoogleFonts.inter(fontSize: 12, color: Colors.green.withValues(alpha: 0.8))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF8888AA)),
              onPressed: () => _showOptions(context),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: isGrid ? content : Dismissible(
            key: Key(entry.filePath),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
            confirmDismiss: (_) => _showDeleteDialog(context),
            onDismissed: (_) => onDismiss(),
            child: content,
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false, // Hanya butuh padding bawah
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(AppStrings.actionRename),
                onTap: () { Navigator.pop(ctx); onRename(); },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(AppStrings.modeShare),
                onTap: () { Navigator.pop(ctx); Share.share(entry.filePath); },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(AppStrings.actionDelete, style: const TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await _showDeleteDialog(context);
                  if (confirmed) onDismiss();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
