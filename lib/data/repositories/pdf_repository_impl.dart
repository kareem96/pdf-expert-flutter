import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/pdf_document_entity.dart';
import '../../domain/repositories/i_pdf_repository.dart';
import '../datasources/syncfusion_pdf_service.dart';
import '../datasources/ml_kit_ocr_service.dart';
import '../datasources/pdf_page_service.dart';
import '../../domain/entities/page_action.dart';

class PdfRepositoryImpl implements IPdfRepository {
  final SyncfusionPdfService pdfService;
  final MlKitOcrService mlKitOcrService;
  final PdfPageService pageService;

  PdfRepositoryImpl(this.pdfService, this.mlKitOcrService, this.pageService);

  @override
  Future<PdfDocumentEntity> loadPdf(String path) {
    // TUNING: Pindah parsing PDF ke Isolate agar tidak memblokir Main Thread (UI Jank)
    return compute(_loadPdfIsolate, path);
  }

  @override
  Future<Rect?> extractWordBounds(
    String path, 
    int pageIndex, 
    double x, 
    double y, {
    double pad = 10.0,
    bool useAiScan = false,
  }) async {
    if (kDebugMode) {
      print('PdfRepository: Extracting bounds at ($x, $y). AI Scan Mode: $useAiScan');
    }
    
    // 1. Jika mode "AI Scan" aktif, prioritas menggunakan ML Kit OCR dahulu
    if (useAiScan) {
      final rect = await mlKitOcrService.extractWordBoundsFromImage(path, pageIndex, x, y, pad: pad);
      if (rect != null) return rect;
      
      // Jika AI Scan gagal, _fall-back_ ke Syncfusion (sebagai safety-net)
      if (kDebugMode) print('PdfRepository: AI Scan yielded null, falling back to Syncfusion.');
    }
    
    // 2. Default: Menggunakan TextExtractor bawaan Syncfusion Cepat 
    return pdfService.extractWordBoundsAt(path, pageIndex, x, y, pad: pad);
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
    
    // Auto-rename logic to prevent overwriting
    String finalName = customName;
    String targetPath = '$dirPath/$finalName';
    int counter = 1;
    while (await File(targetPath).exists()) {
      final String nameWithoutExt = customName.endsWith('.pdf') 
          ? customName.substring(0, customName.length - 4) 
          : customName;
      finalName = '$nameWithoutExt ($counter).pdf';
      targetPath = '$dirPath/$finalName';
      counter++;
    }

    // TUNING: Gunakan compute untuk pindahkan pemrosesan berat ke Isolate
    return compute(_savePdfIsolate, {
      'document': document,
      'targetPath': targetPath,
    });
  }

  @override
  Future<void> sharePdf(File file) async {
    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Future<List<Uint8List>> getThumbnails(String path, {double dpi = 72.0}) {
    return pageService.generateThumbnails(path, dpi: dpi);
  }

  @override
  Future<File> applyPageChanges({
    required String sourcePath,
    required List<PageAction> actions,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final String fileName = sourcePath.split('/').last;
    final String targetPath = '${tempDir.path}/modified_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    // TUNING: Gunakan compute untuk pindahkan pemrosesan berat ke Isolate
    return compute(_applyPageChangesIsolate, {
      'sourcePath': sourcePath,
      'actions': actions,
      'targetPath': targetPath,
    });
  }
}

/// Helper function (Top-level) for Save PDF Isolate
Future<File> _savePdfIsolate(Map<String, dynamic> args) async {
  final SyncfusionPdfService service = SyncfusionPdfService();
  final PdfDocumentEntity document = args['document'];
  final String targetPath = args['targetPath'];
  
  return service.saveModifiedPdf(
    documentEntity: document,
    targetPath: targetPath,
  );
}

/// Helper function (Top-level) for Page Changes Isolate
Future<File> _applyPageChangesIsolate(Map<String, dynamic> args) async {
  final PdfPageService service = PdfPageService();
  final String sourcePath = args['sourcePath'];
  final List<PageAction> actions = args['actions'];
  final String targetPath = args['targetPath'];
  
  return service.processPageChanges(
    sourcePath: sourcePath,
    actions: actions,
    targetPath: targetPath,
  );
}

/// Helper function (Top-level) for Load PDF Isolate
Future<PdfDocumentEntity> _loadPdfIsolate(String path) async {
  final SyncfusionPdfService service = SyncfusionPdfService();
  return service.parsePdf(path);
}
