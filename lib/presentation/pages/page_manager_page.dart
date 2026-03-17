import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/constants/app_strings.dart';
import '../providers/page_manager_provider.dart';
import '../widgets/custom_toast.dart';

class PageManagerPage extends ConsumerStatefulWidget {
  final String pdfPath;

  const PageManagerPage({super.key, required this.pdfPath});

  @override
  ConsumerState<PageManagerPage> createState() => _PageManagerPageState();
}

class _PageManagerPageState extends ConsumerState<PageManagerPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      ref.read(pageManagerProvider.notifier).loadThumbnails(widget.pdfPath)
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pageManagerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Pages', 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (state.pendingActions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => _handleSave(),
                child: const Text(
                  'Apply', 
                  style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
        : state.error != null
          ? Center(child: Text('${AppStrings.error}: ${state.error}', style: const TextStyle(color: Colors.redAccent)))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.thumbnails.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                ref.read(pageManagerProvider.notifier).reorderPage(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final thumb = state.thumbnails[index];
                return _buildThumbnailItem(index, thumb);
              },
            ),
    );
  }

  Widget _buildThumbnailItem(int index, dynamic thumbData) {
    final state = ref.watch(pageManagerProvider);
    return Container(
      key: ValueKey('page_$index'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 60,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            image: DecorationImage(
              image: MemoryImage(thumbData),
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text('${AppStrings.page} ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(AppStrings.standardA4, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.rotate_right_rounded, color: Colors.white70),
              onPressed: () => ref.read(pageManagerProvider.notifier).rotatePage(index, 90),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded, 
                color: state.thumbnails.length > 1 ? Colors.redAccent : Colors.white24,
              ),
              onPressed: () => _confirmDelete(index),
            ),
            const Icon(Icons.drag_handle_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int index) {
    if (ref.read(pageManagerProvider).thumbnails.length <= 1) {
      CustomToast.show(
        context, 
        message: AppStrings.cannotDeleteLastPage, 
        isError: true,
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(AppStrings.deletePageTitle, style: const TextStyle(color: Colors.white)),
        content: Text(AppStrings.deletePageContent(index + 1), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              ref.read(pageManagerProvider.notifier).deletePage(index);
              Navigator.pop(ctx);
            }, 
            child: Text(AppStrings.delete, style: const TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  void _handleSave() async {
    // Implementation for applying changes will return to PdfEditorPage
    Navigator.pop(context, ref.read(pageManagerProvider).pendingActions);
  }
}
