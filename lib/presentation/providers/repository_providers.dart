import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/syncfusion_pdf_service.dart';
import '../../data/repositories/pdf_repository_impl.dart';
import '../../domain/repositories/i_pdf_repository.dart';

import '../../data/datasources/ml_kit_ocr_service.dart';

part 'repository_providers.g.dart';

@riverpod
SyncfusionPdfService pdfService(Ref ref) {
  return SyncfusionPdfService();
}

@riverpod
MlKitOcrService mlKitOcrService(Ref ref) {
  final service = MlKitOcrService();
  ref.onDispose(() => service.dispose());
  return service;
}

@riverpod
IPdfRepository pdfRepository(Ref ref) {
  final pdfService = ref.watch(pdfServiceProvider);
  final mlKitService = ref.watch(mlKitOcrServiceProvider);
  return PdfRepositoryImpl(pdfService, mlKitService);
}
