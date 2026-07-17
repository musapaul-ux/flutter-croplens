import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/scan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

/// Screen 5 — Dashboard. Shows scan totals, recent scans, and a large
/// floating Scan button that immediately opens the camera.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(dashboardStatsProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back,', style: Theme.of(context).textTheme.bodyMedium),
                          Text(
                            user?.fullName.split(' ').first ?? 'Farmer',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        backgroundImage: user?.profileImage != null ? CachedNetworkImageProvider(user!.profileImage!) : null,
                        child: user?.profileImage == null
                            ? Icon(Icons.person, color: AppColors.primary)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: statsAsync.when(
                    data: (stats) => _StatsRow(stats: stats),
                    loading: () => const _StatsRowSkeleton(),
                    error: (err, st) => Text('Could not load stats', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text('Recent Scans', style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
              statsAsync.when(
                data: (stats) => stats.recentScans.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: EmptyState(
                            icon: Icons.eco_outlined,
                            title: 'No scans yet',
                            message: 'Tap the scan button below to check your first crop.',
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        sliver: SliverList.separated(
                          itemCount: stats.recentScans.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final scan = stats.recentScans[index];
                            return _RecentScanCard(scan: scan)
                                .animate()
                                .fadeIn(delay: (index * 60).ms)
                                .slideX(begin: 0.05, end: 0);
                          },
                        ),
                      ),
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, st) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed('scan'),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Crop'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _StatsRow extends StatelessWidget {
  final DashboardStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Total Scans', value: '${stats.totalScans}', icon: Icons.grid_view_rounded, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Healthy', value: '${stats.healthyCount}', icon: Icons.check_circle_outline, color: AppColors.healthy)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Infected', value: '${stats.infectedCount}', icon: Icons.warning_amber_outlined, color: AppColors.infected)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == 2 ? 0 : 12),
            height: 96,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  final ScanModel scan;
  const _RecentScanCard({required this.scan});

  @override
  Widget build(BuildContext context) {
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
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 60,
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
                  Text(scan.diseaseName, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(DateFormat('MMM d, yyyy · h:mm a').format(scan.scannedAt), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (scan.isHealthy ? AppColors.healthy : AppColors.infected).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${scan.confidence.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: scan.isHealthy ? AppColors.healthy : AppColors.infected,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
