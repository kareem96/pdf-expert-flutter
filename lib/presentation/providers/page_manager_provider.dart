import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/page_action.dart';
import 'repository_providers.dart';

part 'page_manager_provider.g.dart';

class PageManagerState {
  final List<Uint8List> thumbnails;
  final List<int> rotations; // Track visual rotation for each thumbnail
  final List<PageAction> pendingActions;
  final bool isLoading;
  final String? error;

  PageManagerState({
    this.thumbnails = const [],
    this.rotations = const [],
    this.pendingActions = const [],
    this.isLoading = false,
    this.error,
  });

  PageManagerState copyWith({
    List<Uint8List>? thumbnails,
    List<int>? rotations,
    List<PageAction>? pendingActions,
    bool? isLoading,
    String? error,
  }) {
    return PageManagerState(
      thumbnails: thumbnails ?? this.thumbnails,
      rotations: rotations ?? this.rotations,
      pendingActions: pendingActions ?? this.pendingActions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@riverpod
class PageManager extends _$PageManager {
  @override
  PageManagerState build() {
    return PageManagerState();
  }

  Future<void> loadThumbnails(String path) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(pdfRepositoryProvider);
      final thumbnails = await repo.getThumbnails(path);
      state = state.copyWith(
        thumbnails: thumbnails, 
        rotations: List.generate(thumbnails.length, (_) => 0),
        isLoading: false
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reorderPage(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    
    final thumbnails = List<Uint8List>.from(state.thumbnails);
    final page = thumbnails.removeAt(oldIndex);
    thumbnails.insert(newIndex, page);

    final rotations = List<int>.from(state.rotations);
    final rot = rotations.removeAt(oldIndex);
    rotations.insert(newIndex, rot);
    
    final actions = List<PageAction>.from(state.pendingActions);
    actions.add(PageAction(
      pageIndex: oldIndex,
      type: PageActionType.reorder,
      value: newIndex,
    ));
    
    state = state.copyWith(thumbnails: thumbnails, rotations: rotations, pendingActions: actions);
  }

  void rotatePage(int index, int angleDelta) {
    // 1. Update visual rotation
    final rotations = List<int>.from(state.rotations);
    rotations[index] = (rotations[index] + angleDelta) % 360;

    // 2. Track action
    final actions = List<PageAction>.from(state.pendingActions);
    actions.add(PageAction(
      pageIndex: index,
      type: PageActionType.rotate,
      value: angleDelta,
    ));
    state = state.copyWith(rotations: rotations, pendingActions: actions);
  }

  void deletePage(int index) {
    if (state.thumbnails.length <= 1) return;
    
    final thumbnails = List<Uint8List>.from(state.thumbnails);
    thumbnails.removeAt(index);

    final rotations = List<int>.from(state.rotations);
    rotations.removeAt(index);
    
    final actions = List<PageAction>.from(state.pendingActions);
    actions.add(PageAction(
      pageIndex: index,
      type: PageActionType.delete,
    ));
    
    state = state.copyWith(thumbnails: thumbnails, rotations: rotations, pendingActions: actions);
  }
}
