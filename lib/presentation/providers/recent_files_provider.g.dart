// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_files_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recentFilesHash() => r'db0c3b80ad85dd182eb913d20594385b6b94f436';

/// See also [RecentFiles].
@ProviderFor(RecentFiles)
final recentFilesProvider =
    AutoDisposeAsyncNotifierProvider<
      RecentFiles,
      List<RecentFileEntry>
    >.internal(
      RecentFiles.new,
      name: r'recentFilesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recentFilesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RecentFiles = AutoDisposeAsyncNotifier<List<RecentFileEntry>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
