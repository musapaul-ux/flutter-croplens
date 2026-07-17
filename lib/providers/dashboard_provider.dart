import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/scan_model.dart';
import '../data/repositories/user_repository.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

/// Fetches dashboard stats (total/healthy/infected counts + recent scans).
/// autoDispose so it refetches fresh data each time the Dashboard is visited;
/// call ref.refresh(dashboardStatsProvider) after a new scan to update it immediately.
final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getDashboardStats();
});
