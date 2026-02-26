import '../entities/pdf_document_entity.dart';
import '../repositories/i_pdf_repository.dart';

class LoadPdfUseCase {
  final IPdfRepository repository;

  LoadPdfUseCase(this.repository);

  Future<PdfDocumentEntity> call(String path) {
    return repository.loadPdf(path);
  }
}
