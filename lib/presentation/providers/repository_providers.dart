import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/syncfusion_pdf_service.dart';
import '../../data/repositories/pdf_repository_impl.dart';
import '../../domain/repositories/i_pdf_repository.dart';

part 'repository_providers.g.dart';

@riverpod
SyncfusionPdfService pdfService(Ref ref) {
  return SyncfusionPdfService();
}

@riverpod
IPdfRepository pdfRepository(Ref ref) {
  final service = ref.watch(pdfServiceProvider);
  return PdfRepositoryImpl(service);
}
