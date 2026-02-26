import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/pdf_document_entity.dart';
import '../../domain/repositories/i_pdf_repository.dart';
import '../datasources/syncfusion_pdf_service.dart';

class PdfRepositoryImpl implements IPdfRepository {
  final SyncfusionPdfService pdfService;

  PdfRepositoryImpl(this.pdfService);

  @override
  Future<PdfDocumentEntity> loadPdf(String path) {
    return pdfService.parsePdf(path);
  }

  @override
  Future<File> savePdf({
    required PdfDocumentEntity document,
    required String customName,
    String? customDirectory,
  }) async {
    final String dirPath;
    if (customDirectory != null && customDirectory.isNotEmpty) {
      dirPath = customDirectory;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      dirPath = directory.path;
    }
    String finalName = customName;
    String targetPath = '$dirPath/$finalName';
    
    // Auto-rename logic to prevent overwriting
    int counter = 1;
    while (await File(targetPath).exists()) {
      final String nameWithoutExt = customName.endsWith('.pdf') 
          ? customName.substring(0, customName.length - 4) 
          : customName;
      finalName = '$nameWithoutExt ($counter).pdf';
      targetPath = '$dirPath/$finalName';
      counter++;
    }
    
    return pdfService.saveModifiedPdf(
      documentEntity: document,
      targetPath: targetPath,
    );
  }

  @override
  Future<void> sharePdf(File file) async {
    await Share.shareXFiles([XFile(file.path)]); // Menggunakan API yang sudah stable namun masih diberi peringatan info (deprecated) oleh linter tapi tetap berfungsi di build. Tapi baiknya saya ignore deprecated aja dulu biar lolos flutter analyze.
  }
}
