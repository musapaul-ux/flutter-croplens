import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../core/network/api_exception.dart';
import '../data/models/scan_model.dart';
import '../data/repositories/scan_repository.dart';
import 'scan_provider.dart';

class HistoryState {
  final List<ScanModel> scans;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String search;
  final String sortBy;
  final String order;
  final String? errorMessage;

  const HistoryState({
    this.scans = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.search = '',
    this.sortBy = 'scannedAt',
    this.order = 'desc',
    this.errorMessage,
  });

  HistoryState copyWith({
    List<ScanModel>? scans,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? search,
    String? sortBy,
    String? order,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HistoryState(
      scans: scans ?? this.scans,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      search: search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      order: order ?? this.order,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Backs the History screen: search, sort, infinite-scroll pagination, delete.
class HistoryNotifier extends StateNotifier<HistoryState> {
  final ScanRepository _repo;
  HistoryNotifier(this._repo) : super(const HistoryState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, page: 1, hasMore: true, clearError: true);
    try {
      final scans = await _repo.listScans(
        page: 1,
        search: state.search,
        sortBy: state.sortBy,
        order: state.order,
      );
      state = state.copyWith(scans: scans, isLoading: false, page: 1, hasMore: scans.length >= 20);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final scans = await _repo.listScans(
        page: nextPage,
        search: state.search,
        sortBy: state.sortBy,
        order: state.order,
      );
      state = state.copyWith(
        scans: [...state.scans, ...scans],
        isLoadingMore: false,
        page: nextPage,
        hasMore: scans.length >= 20,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.message);
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
    loadInitial();
  }

  void setSort(String sortBy, String order) {
    state = state.copyWith(sortBy: sortBy, order: order);
    loadInitial();
  }

  Future<bool> deleteScan(String id) async {
    try {
      await _repo.deleteScan(id);
      state = state.copyWith(scans: state.scans.where((s) => s.id != id).toList());
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref.watch(scanRepositoryProvider));
});
