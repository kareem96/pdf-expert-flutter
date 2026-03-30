import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/services/recent_files_service.dart';
import '../../data/services/draft_service.dart';
import 'repository_providers.dart';

part 'recent_files_provider.g.dart';

@riverpod
class RecentFiles extends _$RecentFiles {
  @override
  Future<List<RecentFileEntry>> build() async {
    final service = ref.watch(recentFilesServiceProvider);
    final files = await service.getRecentFiles();
    
    // Pre-verify existence in parallel to avoid UI jank from sequential I/O
    final checkResults = await Future.wait(files.map((f) async {
      final exists = await File(f.filePath).exists();
      if (!exists) {
        // Schedule cleanup without blocking the UI return
        service.removeFile(f.filePath).catchError((_) {});
        return null;
      }
      
      // Auto-clean draft if older than 7 days
      var validatedFile = f;
      if (f.hasDraft) {
        final daysPassed = DateTime.now().difference(f.lastOpened).inDays;
        if (daysPassed >= 7) {
          DraftService().deleteDraft(f.filePath).catchError((_) {});
          service.updateDraftStatus(f.filePath, hasDraft: false).catchError((_) {});
          validatedFile = f.copyWith(hasDraft: false);
        }
      }
      
      return validatedFile;
    }));
    
    return checkResults.whereType<RecentFileEntry>().toList();
  }

  Future<void> recordFileOpened(String path, {bool? hasDraft, bool? isEdited}) async {
    final service = ref.read(recentFilesServiceProvider);
    await service.recordFileOpened(path, hasDraft: hasDraft, isEdited: isEdited);
    ref.invalidateSelf();
  }

  Future<void> removeFile(String path) async {
    final service = ref.read(recentFilesServiceProvider);
    await service.removeFile(path);
    ref.invalidateSelf();
  }

  Future<void> renameFile(String oldPath, String newName) async {
    final service = ref.read(recentFilesServiceProvider);
    await service.renameFile(oldPath, newName);
    ref.invalidateSelf();
  }

  Future<void> updateDraftStatus(String path, {required bool hasDraft}) async {
    final service = ref.read(recentFilesServiceProvider);
    await service.updateDraftStatus(path, hasDraft: hasDraft);
    ref.invalidateSelf();
  }
}
