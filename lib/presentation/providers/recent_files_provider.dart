import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/services/recent_files_service.dart';
import 'repository_providers.dart';

part 'recent_files_provider.g.dart';

@riverpod
class RecentFiles extends _$RecentFiles {
  @override
  Future<List<RecentFileEntry>> build() async {
    final service = ref.watch(recentFilesServiceProvider);
    final files = await service.getRecentFiles();
    
    // Verify each file still exists on disk
    final valid = <RecentFileEntry>[];
    for (final f in files) {
      if (await File(f.filePath).exists()) {
        valid.add(f);
      } else {
        await service.removeFile(f.filePath);
      }
    }
    return valid;
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
