import 'dart:math' as math;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/pdf_document_entity.dart';
import '../../domain/entities/pdf_field_entity.dart';
import '../../domain/usecases/load_pdf_usecase.dart';
import '../../data/services/recent_files_service.dart';
import 'repository_providers.dart';

part 'pdf_editor_provider.g.dart';

@Riverpod(keepAlive: true)
class PdfEditor extends _$PdfEditor {
  final List<PdfDocumentEntity> _history = [];
  int _historyIndex = -1;

  @override
  AsyncValue<PdfDocumentEntity?> build() {
    return const AsyncValue.data(null);
  }

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void _pushHistory(PdfDocumentEntity doc) {
    // Jika kita melakukan aksi baru, hapus semua history 'Redo' yang menggantung
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    
    _history.add(doc);
    _historyIndex = _history.length - 1;
    
    // Batasi history maksimal misal 50 step untuk hemat RAM
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void undo() {
    if (!canUndo) return;
    _historyIndex--;
    state = AsyncValue.data(_history[_historyIndex]);
  }

  void redo() {
    if (!canRedo) return;
    _historyIndex++;
    state = AsyncValue.data(_history[_historyIndex]);
  }

  Future<void> loadPdf(String path, {List<PdfFieldEntity>? draftFields}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(pdfRepositoryProvider);
      final doc = await LoadPdfUseCase(repository).call(path);
      
      PdfDocumentEntity finalDoc = doc;

      if (draftFields != null && draftFields.isNotEmpty) {
        finalDoc = finalDoc.copyWith(
          fields: [...finalDoc.fields, ...draftFields],
          isModified: true,
        );
      }
      
      // Reset history saat load PDF baru
      _history.clear();
      _pushHistory(finalDoc);
      
      return finalDoc;
    });
  }



  void updateField(String identifier, String value) {
    state.whenData((doc) {
      if (doc == null) return;
      PdfFieldEntity? target;
      final otherFields = doc.fields.where((f) {
        // Match by id (internal unique) or name (original PDF name)
        if (f.id == identifier || f.name == identifier) {
          target = f;
          return false;
        }
        return true;
      }).toList();

      if (target != null) {
        final updatedTarget = target!.copyWith(value: value, isModified: true);
        final newState = doc.copyWith(fields: [...otherFields, updatedTarget], isModified: true);
        state = AsyncValue.data(newState);
        _pushHistory(newState);
      }
    });
  }

  void updateFieldPosition(String name, double x, double y) {
    state.whenData((doc) {
      if (doc == null) return;
      PdfFieldEntity? target;
      final otherFields = doc.fields.where((f) {
        if (f.id == name) {
          target = f;
          return false;
        }
        return true;
      }).toList();

      if (target != null) {
        final updatedTarget = target!.copyWith(x: x, y: y, isModified: true);
        final newState = doc.copyWith(fields: [...otherFields, updatedTarget], isModified: true);
        state = AsyncValue.data(newState);
        _pushHistory(newState);
      }
    });
  }

  void removeField(String name) {
    state.whenData((doc) {
      if (doc == null) return;
      final updatedFields = doc.fields.where((f) => f.id != name).toList();
      final newState = doc.copyWith(
        fields: updatedFields,
        isModified: true,
      );
      state = AsyncValue.data(newState);
      _pushHistory(newState);
    });
  }

  void updateFontSize(String name, double size) {
    state.whenData((doc) {
      if (doc == null) return;
      final updatedFields = doc.fields.map((f) {
        if (f.id == name) {
          return f.copyWith(fontSize: size, isModified: true);
        }
        return f;
      }).toList();
      final newState = doc.copyWith(fields: updatedFields, isModified: true);
      state = AsyncValue.data(newState);
      _pushHistory(newState);
    });
  }

  void updateTextColor(String name, String colorString) {
    state.whenData((doc) {
      if (doc == null) return;
      final updatedFields = doc.fields.map((f) {
        if (f.id == name) {
          return f.copyWith(textColor: colorString, isModified: true);
        }
        return f;
      }).toList();
      final newState = doc.copyWith(fields: updatedFields, isModified: true);
      state = AsyncValue.data(newState);
      _pushHistory(newState);
    });
  }

  void updateTextStyle(String name, {bool? isBold, bool? isItalic}) {
    state.whenData((doc) {
      if (doc == null) return;
      final updatedFields = doc.fields.map((f) {
        if (f.id == name) {
          return f.copyWith(
            isBold: isBold ?? f.isBold,
            isItalic: isItalic ?? f.isItalic,
            isModified: true,
          );
        }
        return f;
      }).toList();
      final newState = doc.copyWith(fields: updatedFields, isModified: true);
      state = AsyncValue.data(newState);
      _pushHistory(newState);
    });
  }

  void updateFontFamily(String name, String fontFamily) {
    state.whenData((doc) {
      if (doc == null) return;
      final updatedFields = doc.fields.map((f) {
        if (f.id == name) {
          return f.copyWith(fontFamily: fontFamily, isModified: true);
        }
        return f;
      }).toList();
      final newState = doc.copyWith(fields: updatedFields, isModified: true);
      state = AsyncValue.data(newState);
      _pushHistory(newState);
    });
  }

  void updateFieldSize(String name, double width, double height) {
    state.whenData((doc) {
      if (doc == null) return;
      PdfFieldEntity? target;
      final otherFields = doc.fields.where((f) {
        if (f.id == name) {
          target = f;
          return false;
        }
        return true;
      }).toList();

      if (target != null) {
        final updatedTarget = target!.copyWith(width: width, height: height, isModified: true);
        final newState = doc.copyWith(fields: [...otherFields, updatedTarget], isModified: true);
        state = AsyncValue.data(newState);
        _pushHistory(newState);
      }
    });
  }

  void addFreeText(double x, double y, String text, int pageIndex, {
    double fontSize = 14,
    String textColor = '0xFF000000',
    String? backgroundColor,
    String fontFamily = 'Helvetica',
    bool isBold = false,
    bool isItalic = false,
  }) {
    state.whenData((doc) {
      if (doc == null) return;
      
      final String uniqueId = 'custom_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(999)}';
      final newField = PdfFieldEntity(
        id: uniqueId,
        name: uniqueId,
        type: PdfFieldType.text,
        value: text,
        x: x,
        y: y,
        width: 150, // default width
        height: 30, // default height
        pageIndex: pageIndex,
        fontSize: fontSize,
        textColor: textColor,
        backgroundColor: backgroundColor,
        fontFamily: fontFamily,
        isBold: isBold,
        isItalic: isItalic,
        isModified: true,
        isNewField: true,
      );
      
      final newState = doc.copyWith(
        fields: [...doc.fields, newField],
        isModified: true,
      );
      state = AsyncValue.data(newState);
      _pushHistory(newState);
    });
  }

  void addImage(double x, double y, String imagePath, int pageIndex, {bool isSignature = false}) {
    state.whenData((doc) {
      if (doc == null) return;
      
      final String uniqueId = 'img_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(999)}';
      final newField = PdfFieldEntity(
        id: uniqueId,
        name: uniqueId,
        type: isSignature ? PdfFieldType.signature : PdfFieldType.image,
        value: imagePath, // Menyimpan file path lokal ke dalam value
        x: x,
        y: y,
        width: 150, // default image width
        height: 150, // default image height (can be resized later if needed)
        pageIndex: pageIndex,
        isModified: true,
        isNewField: true,
      );
      
      final newState = doc.copyWith(
        fields: [...doc.fields, newField],
        isModified: true,
      );
      state = AsyncValue.data(newState);
      _pushHistory(newState);
    });
  }

  void clearDocument() {
    _history.clear();
    _historyIndex = -1;
    state = const AsyncValue.data(null);
  }

  Future<void> saveDocument({
    String? customFileName,
    String? customDirectory,
  }) async {
    final doc = state.value;
    if (doc == null) return;

    final repository = ref.read(pdfRepositoryProvider);
    try {
      final fileName = customFileName ?? 'edited_${DateTime.now().millisecondsSinceEpoch}_${doc.fileName}';
      print('PdfEditor: Attempting to save to $fileName');
      final savedFile = await repository.savePdf(
        document: doc,
        customName: fileName,
        customDirectory: customDirectory,
      );
      print('PdfEditor: Save successful at ${savedFile.path}');
      
      // Record this newly generated file in Recents so user can click it from Home!
      final recentService = RecentFilesService();
      await recentService.recordFileOpened(savedFile.path, hasDraft: false, isEdited: true);
      
      // RE-LOAD: Setelah save, kita panggil loadPdf lagi. 
      // File yang baru disimpan akan menjadi state 'originalPath' yang baru pada sesi ini.
      print('PdfEditor: Triggering re-load for flattened view...');
      await loadPdf(savedFile.path);
      print('PdfEditor: Re-load completed.');
      
    } catch (e, st) {
      print('PdfEditor ERROR during save: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> shareDocument() async {
    final doc = state.value;
    if (doc == null) return;

    final repository = ref.read(pdfRepositoryProvider);
    try {
      // First save to a temp or actual physical copy
      final savedFile = await repository.savePdf(
        document: doc,
        customName: 'shared_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      
      await repository.sharePdf(savedFile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

