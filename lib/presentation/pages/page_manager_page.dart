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
        title: const Text('Page Manager', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (state.pendingActions.isNotEmpty)
            TextButton.icon(
              onPressed: () => _handleSave(),
              icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
              label: const Text('Apply', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
        : state.error != null
          ? Center(child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.redAccent)))
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
        title: Text('Page ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: const Text('Standard A4', style: TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.rotate_right_rounded, color: Colors.white70),
              onPressed: () => ref.read(pageManagerProvider.notifier).rotatePage(index, 90),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () => _confirmDelete(index),
            ),
            const Icon(Icons.drag_handle_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Page?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete Page ${index + 1}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(pageManagerProvider.notifier).deletePage(index);
              Navigator.pop(ctx);
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent))
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
