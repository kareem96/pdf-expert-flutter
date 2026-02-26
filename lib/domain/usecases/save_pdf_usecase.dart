import 'dart:io';
import '../entities/pdf_document_entity.dart';
import '../repositories/i_pdf_repository.dart';

class SavePdfUseCase {
  final IPdfRepository repository;

  SavePdfUseCase(this.repository);

  Future<File> call({
    required PdfDocumentEntity document,
    required String customName,
  }) {
    return repository.savePdf(
      document: document,
      customName: customName,
    );
  }
}
