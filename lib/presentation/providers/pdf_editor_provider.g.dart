// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_editor_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pdfEditorHash() => r'92a11e15020af5e85c7cf9f30f064445cee73423';

/// See also [PdfEditor].
@ProviderFor(PdfEditor)
final pdfEditorProvider =
    NotifierProvider<PdfEditor, AsyncValue<PdfDocumentEntity?>>.internal(
      PdfEditor.new,
      name: r'pdfEditorProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pdfEditorHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PdfEditor = Notifier<AsyncValue<PdfDocumentEntity?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
