import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/scan_model.dart';
import '../../providers/history_provider.dart';

/// Screen 8 — History.
/// Every completed scan, with search, filter/sort, and delete.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(historyProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSortSheet() {
    final notifier = ref.read(historyProvider.notifier);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text('Sort by', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Newest first'),
                onTap: () {
                  notifier.setSort('scannedAt', 'desc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Oldest first'),
                onTap: () {
                  notifier.setSort('scannedAt', 'asc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.percent),
                title: const Text('Highest confidence'),
                onTap: () {
                  notifier.setSort('confidence', 'desc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Crop name (A–Z)'),
                onTap: () {
                  notifier.setSort('cropName', 'asc');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(ScanModel scan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete scan?'),
        content: Text('This will permanently remove the ${scan.cropName} scan from your history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyProvider.notifier).deleteScan(scan.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (v) => ref.read(historyProvider.notifier).setSearch(v),
                      decoration: InputDecoration(
                        hintText: 'Search by crop or disease',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(historyProvider.notifier).setSearch('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(onPressed: _showSortSheet, icon: const Icon(Icons.tune)),
                ],
              ),
            ),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(HistoryState state) {
    if (state.isLoading && state.scans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.scans.isEmpty) {
      return Center(child: Text(state.errorMessage!));
    }

    if (state.scans.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'No scans found',
        message: 'Your scan history will show up here once you check a crop.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(historyProvider.notifier).loadInitial(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: state.scans.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.scans.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final scan = state.scans[index];
          return Dismissible(
            key: ValueKey(scan.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              await _confirmDelete(scan);
              return false; // deletion is handled via provider state, not the dismiss animation
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(color: AppColors.infected.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.delete_outline, color: AppColors.infected),
            ),
            child: _HistoryCard(scan: scan),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ScanModel scan;
  const _HistoryCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    final statusColor = scan.isHealthy ? AppColors.healthy : AppColors.infected;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.pushNamed('results', extra: scan),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: scan.imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 64,
                  height: 64,
                  color: AppColors.primary.withOpacity(0.08),
                  child: const Icon(Icons.eco_outlined),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scan.cropName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(scan.diseaseName, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(DateFormat('MMM d, yyyy').format(scan.scannedAt), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text('${scan.confidence.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
