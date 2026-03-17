import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Represents a recently opened PDF file entry.
class RecentFileEntry {
  final String filePath;
  final String fileName;
  final DateTime lastOpened;
  final bool hasDraft;
  final bool isEdited;

  const RecentFileEntry({
    required this.filePath,
    required this.fileName,
    required this.lastOpened,
    this.hasDraft = false,
    this.isEdited = false,
  });

  RecentFileEntry copyWith({bool? hasDraft, bool? isEdited}) => RecentFileEntry(
    filePath: filePath,
    fileName: fileName,
    lastOpened: lastOpened,
    hasDraft: hasDraft ?? this.hasDraft,
    isEdited: isEdited ?? this.isEdited,
  );

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'fileName': fileName,
    'lastOpened': lastOpened.toIso8601String(),
    'hasDraft': hasDraft,
    'isEdited': isEdited,
  };

  factory RecentFileEntry.fromJson(Map<String, dynamic> j) => RecentFileEntry(
    filePath: j['filePath'] as String,
    fileName: j['fileName'] as String,
    lastOpened: DateTime.parse(j['lastOpened'] as String),
    hasDraft: j['hasDraft'] as bool? ?? false,
    isEdited: j['isEdited'] as bool? ?? false,
  );
}

/// Maintains a list of recently opened PDF files in shared_preferences.
/// Max 20 entries, sorted by most recent.
class RecentFilesService {
  static const _key = 'pdf_expert_recent_files';
  static const _maxEntries = 50;

  Future<List<RecentFileEntry>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entries = raw.map((s) {
      try {
        return RecentFileEntry.fromJson(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<RecentFileEntry>().toList();
    // Sorted newest first
    entries.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    return entries;
  }

  /// Add or update a file entry (called when a file is opened).
  Future<void> recordFileOpened(String filePath, {bool? hasDraft, bool? isEdited}) async {
    final files = await getRecentFiles();
    
    // Preserve existing flags if not explicitly provided
    final existingIdx = files.indexWhere((f) => f.filePath == filePath);
    bool finalHasDraft = hasDraft ?? false;
    bool finalIsEdited = isEdited ?? false;
    
    if (existingIdx != -1) {
      final existing = files[existingIdx];
      if (hasDraft == null) finalHasDraft = existing.hasDraft;
      if (isEdited == null) finalIsEdited = existing.isEdited;
      files.removeAt(existingIdx);
    }

    // Insert at front
    files.insert(
      0,
      RecentFileEntry(
        filePath: filePath,
        fileName: filePath.split('/').last,
        lastOpened: DateTime.now(),
        hasDraft: finalHasDraft,
        isEdited: finalIsEdited,
      ),
    );
    // Trim to max
    final trimmed = files.take(_maxEntries).toList();
    await _save(trimmed);
  }

  /// Update the hasDraft flag for a specific file.
  Future<void> updateDraftStatus(String filePath, {required bool hasDraft}) async {
    final files = await getRecentFiles();
    final idx = files.indexWhere((f) => f.filePath == filePath);
    if (idx != -1) {
      files[idx] = files[idx].copyWith(hasDraft: hasDraft);
      await _save(files);
    }
  }

  /// Remove a file from recents (e.g. file deleted or user clears it).
  Future<void> removeFile(String filePath) async {
    final files = await getRecentFiles();
    files.removeWhere((f) => f.filePath == filePath);
    await _save(files);
  }

  /// Renames a file physically and updates the recent entries.
  Future<String> renameFile(String oldPath, String newName) async {
    final file = File(oldPath);
    if (!await file.exists()) throw Exception('File not found');

    final String dir = file.parent.path;
    String finalNewName = newName;
    if (!finalNewName.toLowerCase().endsWith('.pdf')) {
      finalNewName = '$finalNewName.pdf';
    }

    final String newPath = '$dir/$finalNewName';
    if (await File(newPath).exists()) {
      throw Exception('File with this name already exists');
    }

    await file.rename(newPath);

    final files = await getRecentFiles();
    final idx = files.indexWhere((f) => f.filePath == oldPath);
    if (idx != -1) {
      files[idx] = RecentFileEntry(
        filePath: newPath,
        fileName: finalNewName,
        lastOpened: files[idx].lastOpened,
        hasDraft: files[idx].hasDraft,
        isEdited: files[idx].isEdited,
      );
      await _save(files);
    }
    return newPath;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _save(List<RecentFileEntry> files) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = files.map((f) => jsonEncode(f.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }
}
