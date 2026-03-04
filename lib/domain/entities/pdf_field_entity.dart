import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdf_field_entity.freezed.dart';

enum PdfFieldType {
  text,
  checkBox,
  signature,
  image,
  eraser,
  marker,
  unknown,
}

@freezed
class PdfFieldEntity with _$PdfFieldEntity {
  const factory PdfFieldEntity({
    required String id, // ID Unik (internal app)
    required String name, // Nama asli (dari PDF)
    required PdfFieldType type,
    String? value,
    required double x,
    required double y,
    required double width,
    required double height,
    @Default(0) int pageIndex,
    @Default(12) double fontSize,
    @Default('0xFF000000') String textColor, // Warna teks (default: hitam)
    String? backgroundColor, 
    @Default('Helvetica') String fontFamily,
    @Default(false) bool isBold, 
    @Default(false) bool isItalic,
    @Default(false) bool isModified,
    @Default(false) bool isNewField, // True if added via "Free Text Insertion"
    int? originalIndex, // Index asli di PdfForm.fields (untuk AcroForms)
  }) = _PdfFieldEntity;
}
