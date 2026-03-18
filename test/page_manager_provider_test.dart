import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_expert/domain/entities/page_action.dart';
import 'package:pdf_expert/presentation/providers/page_manager_provider.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('rotatePage updates rotations and pendingActions', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(pageManagerProvider.notifier);

    notifier.state = PageManagerState(
      thumbnails: [Uint8List(0), Uint8List(0)],
      rotations: [0, 0],
      pendingActions: const [],
    );

    notifier.rotatePage(1, 90);

    final state = container.read(pageManagerProvider);
    expect(state.rotations, [0, 90]);
    expect(state.pendingActions.length, 1);
    expect(state.pendingActions.first.type, PageActionType.rotate);
    expect(state.pendingActions.first.pageIndex, 1);
    expect(state.pendingActions.first.value, 90);
  });

  test('reorderPage keeps rotations aligned and adds reorder action', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(pageManagerProvider.notifier);

    final t0 = Uint8List.fromList([0]);
    final t1 = Uint8List.fromList([1]);
    final t2 = Uint8List.fromList([2]);

    notifier.state = PageManagerState(
      thumbnails: [t0, t1, t2],
      rotations: [0, 90, 180],
      pendingActions: const [],
    );

    notifier.reorderPage(0, 2);

    final state = container.read(pageManagerProvider);
    expect(state.thumbnails, [t1, t2, t0]);
    expect(state.rotations, [90, 180, 0]);
    expect(state.pendingActions.length, 1);
    expect(state.pendingActions.first.type, PageActionType.reorder);
    expect(state.pendingActions.first.pageIndex, 0);
    expect(state.pendingActions.first.value, 2);
  });

  test('deletePage removes thumbnail/rotation and adds delete action', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(pageManagerProvider.notifier);

    final t0 = Uint8List.fromList([0]);
    final t1 = Uint8List.fromList([1]);

    notifier.state = PageManagerState(
      thumbnails: [t0, t1],
      rotations: [0, 90],
      pendingActions: const [],
    );

    notifier.deletePage(0);

    final state = container.read(pageManagerProvider);
    expect(state.thumbnails, [t1]);
    expect(state.rotations, [90]);
    expect(state.pendingActions.length, 1);
    expect(state.pendingActions.first.type, PageActionType.delete);
    expect(state.pendingActions.first.pageIndex, 0);
  });

  test('rotateAllPages updates all rotations and adds action per page', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(pageManagerProvider.notifier);

    notifier.state = PageManagerState(
      thumbnails: [Uint8List(0), Uint8List(0), Uint8List(0)],
      rotations: [0, 90, 180],
      pendingActions: const [],
    );

    notifier.rotateAllPages(90);

    final state = container.read(pageManagerProvider);
    expect(state.rotations, [90, 180, 270]);
    expect(state.pendingActions.length, 3);
    for (int i = 0; i < 3; i++) {
      expect(state.pendingActions[i].type, PageActionType.rotate);
      expect(state.pendingActions[i].pageIndex, i);
      expect(state.pendingActions[i].value, 90);
    }
  });
}
