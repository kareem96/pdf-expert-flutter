enum PageActionType { reorder, delete }

class PageAction {
  final int pageIndex;
  final PageActionType type;
  final dynamic value; // Target index for reorder, angle for rotate

  PageAction({
    required this.pageIndex,
    required this.type,
    this.value,
  });
}
