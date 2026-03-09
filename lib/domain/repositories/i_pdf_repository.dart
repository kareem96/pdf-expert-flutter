import 'dart:io';
import 'dart:ui';
import '../entities/pdf_document_entity.dart';

abstract class IPdfRepository {
  /// Extracts the boundaries of a single word at coordinates (x,y)
  /// If [useAiScan] is true, it overrides the default engine and forces an ML Kit OCR evaluation.
  Future<Rect?> extractWordBounds(
    String path, 
    int pageIndex, 
    double x, 
    double y, {
    double pad = 10.0,
    bool useAiScan = false,
  });

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
