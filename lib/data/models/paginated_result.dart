/// Generic container for paginated query results across repositories.
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage; // 1-based index (1, 2, 3...)
  final int pageSize;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  });

  int get totalPages => (totalCount / pageSize).ceil() < 1 ? 1 : (totalCount / pageSize).ceil();
  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < totalPages;

  int get startItem => totalCount == 0 ? 0 : (currentPage - 1) * pageSize + 1;
  int get endItem {
    final computed = currentPage * pageSize;
    return computed > totalCount ? totalCount : computed;
  }

  factory PaginatedResult.empty({int pageSize = 20}) {
    return PaginatedResult(
      items: const [],
      totalCount: 0,
      currentPage: 1,
      pageSize: pageSize,
    );
  }
}
