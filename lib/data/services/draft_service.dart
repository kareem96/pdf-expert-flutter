import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/pdf_field_entity.dart';

/// Handles saving and restoring draft edit state (overlay fields) as JSON.
/// Draft files are stored in: app_documents/drafts/filename.json
class DraftService {
  static const _draftsDir = 'pdf_expert_drafts';

  // Get the drafts directory, creating it if needed.
  Future<Directory> _getDraftsDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_draftsDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _draftFileName(String pdfFilePath) {
    final safe = pdfFilePath
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
        .replaceAll('.', '_');
    return '$safe.draft.json';
  }

  String _draftPdfName(String pdfFilePath) {
    final safe = pdfFilePath
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
        .replaceAll('.', '_');
    return '$safe.draft.pdf';
  }

  /// Save the current overlay fields as a draft JSON file.
  Future<void> saveDraft(String originalPdfPath, List<PdfFieldEntity> fields, {String? currentPdfPath}) async {
    final dir = await _getDraftsDirectory();
    final jsonFile = File('${dir.path}/${_draftFileName(originalPdfPath)}');

    final draftFields = fields.where((f) => f.isNewField).toList();
    final jsonList = draftFields.map(_fieldToJson).toList();
    await jsonFile.writeAsString(jsonEncode(jsonList));

    // If currentPdfPath is different from original (meaning page reorder/structural change),
    // save a copy of the modified PDF as part of the draft.
    if (currentPdfPath != null && currentPdfPath != originalPdfPath) {
      final draftPdfFile = File('${dir.path}/${_draftPdfName(originalPdfPath)}');
      await File(currentPdfPath).copy(draftPdfFile.path);
    }
  }

  /// Returns the path to the draft PDF file if it exists, otherwise null.
  Future<String?> getDraftPdfPath(String originalPdfPath) async {
    final dir = await _getDraftsDirectory();
    final file = File('${dir.path}/${_draftPdfName(originalPdfPath)}');
    if (await file.exists()) return file.path;
    return null;
  }

  /// Load a previously saved draft for the given PDF file.
  /// Returns null if no draft exists.
  Future<List<PdfFieldEntity>?> loadDraft(String pdfFilePath) async {
    final dir = await _getDraftsDirectory();
    final file = File('${dir.path}/${_draftFileName(pdfFilePath)}');

    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
      return jsonList.map((e) => _fieldFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Corrupted draft — treat as no draft
      await file.delete();
      return null;
    }
  }

  /// Check whether a draft exists for the given PDF.
  Future<bool> hasDraft(String pdfFilePath) async {
    final dir = await _getDraftsDirectory();
    final file = File('${dir.path}/${_draftFileName(pdfFilePath)}');
    return file.exists();
  }

  /// Delete the draft for the given PDF (e.g. after final save/discard).
  Future<void> deleteDraft(String pdfFilePath) async {
    final dir = await _getDraftsDirectory();
    final jsonFile = File('${dir.path}/${_draftFileName(pdfFilePath)}');
    if (await jsonFile.exists()) {
      await jsonFile.delete();
    }
    final pdfFile = File('${dir.path}/${_draftPdfName(pdfFilePath)}');
    if (await pdfFile.exists()) {
      await pdfFile.delete();
    }
  }

  // ── Manual JSON serialization ─────────────────────────────────────────────

  Map<String, dynamic> _fieldToJson(PdfFieldEntity f) => {
    'id': f.id,
    'name': f.name,
    'type': f.type.name,
    'value': f.value,
    'x': f.x,
    'y': f.y,
    'width': f.width,
    'height': f.height,
    'pageIndex': f.pageIndex,
    'fontSize': f.fontSize,
    'textColor': f.textColor,
    'fontFamily': f.fontFamily,
    'isBold': f.isBold,
    'isItalic': f.isItalic,
    'isModified': f.isModified,
    'isNewField': true,
  };

  PdfFieldEntity _fieldFromJson(Map<String, dynamic> j) => PdfFieldEntity(
    id: j['id'] as String? ?? j['name'] as String,
    name: j['name'] as String,
    type: PdfFieldType.values.firstWhere(
      (e) => e.name == j['type'],
      orElse: () => PdfFieldType.text,
    ),
    value: j['value'] as String?,
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    width: (j['width'] as num).toDouble(),
    height: (j['height'] as num).toDouble(),
    pageIndex: (j['pageIndex'] as num).toInt(),
    fontSize: (j['fontSize'] as num).toDouble(),
    textColor: j['textColor'] as String? ?? '0xFF000000',
    fontFamily: j['fontFamily'] as String? ?? 'Helvetica',
    isBold: j['isBold'] as bool? ?? false,
    isItalic: j['isItalic'] as bool? ?? false,
    isModified: j['isModified'] as bool? ?? false,
    isNewField: true,
  );
}
