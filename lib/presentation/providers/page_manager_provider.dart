import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/page_action.dart';
import 'repository_providers.dart';

part 'page_manager_provider.g.dart';

class PageManagerState {
  final List<Uint8List> thumbnails;
  final List<PageAction> pendingActions;
  final bool isLoading;
  final String? error;

  PageManagerState({
    this.thumbnails = const [],
    this.pendingActions = const [],
    this.isLoading = false,
    this.error,
  });

  PageManagerState copyWith({
    List<Uint8List>? thumbnails,
    List<PageAction>? pendingActions,
    bool? isLoading,
    String? error,
  }) {
    return PageManagerState(
      thumbnails: thumbnails ?? this.thumbnails,
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
      state = state.copyWith(thumbnails: thumbnails, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reorderPage(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    
    final thumbnails = List<Uint8List>.from(state.thumbnails);
    final page = thumbnails.removeAt(oldIndex);
    thumbnails.insert(newIndex, page);
    
    final actions = List<PageAction>.from(state.pendingActions);
    actions.add(PageAction(
      pageIndex: oldIndex,
      type: PageActionType.reorder,
      value: newIndex,
    ));
    
    state = state.copyWith(thumbnails: thumbnails, pendingActions: actions);
  }

  void rotatePage(int index, int angleDelta) {
    // Note: We don't visually rotate thumbnails here for simplicity (though we could)
    // We just track the action.
    final actions = List<PageAction>.from(state.pendingActions);
    actions.add(PageAction(
      pageIndex: index,
      type: PageActionType.rotate,
      value: angleDelta,
    ));
    state = state.copyWith(pendingActions: actions);
  }

  void deletePage(int index) {
    if (state.thumbnails.length <= 1) return;
    
    final thumbnails = List<Uint8List>.from(state.thumbnails);
    thumbnails.removeAt(index);
    
    final actions = List<PageAction>.from(state.pendingActions);
    actions.add(PageAction(
      pageIndex: index,
      type: PageActionType.delete,
    ));
    
    state = state.copyWith(thumbnails: thumbnails, pendingActions: actions);
  }
}
