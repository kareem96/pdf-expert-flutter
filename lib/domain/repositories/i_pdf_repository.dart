import 'dart:io';
import '../entities/pdf_document_entity.dart';

abstract class IPdfRepository {
  /// Loads a PDF from a file path and parses its fields
  Future<PdfDocumentEntity> loadPdf(String path);

  /// Saves the modified fields back to a PDF file
  /// If [customName] is provided, saves to that name
  Future<File> savePdf({
    required PdfDocumentEntity document,
    required String customName,
    String? customDirectory,
  });

  /// Shares a PDF file
  Future<void> sharePdf(File file);
}
