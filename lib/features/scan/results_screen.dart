import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/scan_model.dart';
import '../../core/utils/image_url_resolver.dart';

/// Screen 7 — Results.
/// The scan is already auto-saved to history by the backend at upload time
/// (see ScanController.createScan), so "Save Result" here just confirms/shares.
class ResultsScreen extends StatelessWidget {
  final ScanModel? scan;
  const ResultsScreen({super.key, this.scan});

  @override
  Widget build(BuildContext context) {
    if (scan == null) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.goNamed('dashboard'))),
        body: const Center(child: Text('No scan result to display.')),
      );
    }

    final s = scan!;
    final statusColor = s.isHealthy ? AppColors.healthy : AppColors.infected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.goNamed('dashboard')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: CachedNetworkImage(
                    imageUrl: ImageUrlResolver.resolve(s.imageUrl),
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primary.withOpacity(0.08),
                      child: const Icon(Icons.eco_outlined, size: 48),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.97, 0.97)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.cropName, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(s.diseaseName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: statusColor)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${s.confidence.toStringAsFixed(1)}% confidence',
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Scanned ${DateFormat('MMM d, yyyy · h:mm a').format(s.scannedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              _ResultSection(icon: Icons.medical_information_outlined, title: 'Diagnosis', content: s.diagnosis),
              const SizedBox(height: 16),
              _ResultSection(icon: Icons.medical_services_outlined, title: 'Recommended Treatment', content: s.treatment),
              const SizedBox(height: 16),
              _ResultSection(icon: Icons.shield_outlined, title: 'Prevention Tips', content: s.prevention),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.goNamed('scan'),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Scan Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareResult(context, s),
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Done — Back to Dashboard',
                icon: Icons.check,
                onPressed: () => context.goNamed('dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareResult(BuildContext context, ScanModel s) {
    // Wired to the platform share sheet via share_plus in a full build;
    // kept as a lightweight confirmation here to avoid an extra dependency.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${s.cropName} · ${s.diseaseName} result...')),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  const _ResultSection({required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
