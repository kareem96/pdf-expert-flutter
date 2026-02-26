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

  /// A stable filename key derived from the original PDF path.
  String _draftFileName(String pdfFilePath) {
    // Simple: replace path separators and dots with underscores
    final safe = pdfFilePath
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
        .replaceAll('.', '_');
    return '$safe.draft.json';
  }

  /// Save the current overlay fields as a draft JSON file.
  Future<void> saveDraft(String pdfFilePath, List<PdfFieldEntity> fields) async {
    final dir = await _getDraftsDirectory();
    final file = File('${dir.path}/${_draftFileName(pdfFilePath)}');

    // Only save fields that were added by the user (isNewField = true)
    // We don't want to serialize parsed AcroForm fields.
    final draftFields = fields.where((f) => f.isNewField).toList();
    final jsonList = draftFields.map(_fieldToJson).toList();
    await file.writeAsString(jsonEncode(jsonList));
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
    final file = File('${dir.path}/${_draftFileName(pdfFilePath)}');
    if (await file.exists()) {
      await file.delete();
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
