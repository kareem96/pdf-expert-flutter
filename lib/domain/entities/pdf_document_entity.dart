import 'package:freezed_annotation/freezed_annotation.dart';
import 'pdf_field_entity.dart';

part 'pdf_document_entity.freezed.dart';

@freezed
class PdfDocumentEntity with _$PdfDocumentEntity {
  const factory PdfDocumentEntity({
    required String filePath,
    required String originalPath, // Jalur file asli untuk identifikasi (Drafts/Recents)
    required String fileName,
    required List<PdfFieldEntity> fields,
    @Default(595.0) double pageWidth,
    @Default(842.0) double pageHeight,
    @Default([]) List<double> pageWidths,
    @Default([]) List<double> pageHeights,
    @Default([]) List<double> pageOffsets,
    @Default(false) bool isModified,
  }) = _PdfDocumentEntity;
}
