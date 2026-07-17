import 'package:equatable/equatable.dart';

class ScanModel extends Equatable {
  final String id;
  final String imageUrl;
  final String cropName;
  final String diseaseName;
  final bool isHealthy;
  final double confidence;
  final String diagnosis;
  final String treatment;
  final String prevention;
  final DateTime scannedAt;

  const ScanModel({
    required this.id,
    required this.imageUrl,
    required this.cropName,
    required this.diseaseName,
    required this.isHealthy,
    required this.confidence,
    required this.diagnosis,
    required this.treatment,
    required this.prevention,
    required this.scannedAt,
  });

  factory ScanModel.fromJson(Map<String, dynamic> json) {
    return ScanModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      cropName: json['cropName']?.toString() ?? 'Unknown crop',
      diseaseName: json['diseaseName']?.toString() ?? 'Unknown',
      isHealthy: json['isHealthy'] == true,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      diagnosis: json['diagnosis']?.toString() ?? '',
      treatment: json['treatment']?.toString() ?? '',
      prevention: json['prevention']?.toString() ?? '',
      scannedAt: DateTime.tryParse(json['scannedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, imageUrl, cropName, diseaseName, isHealthy, confidence, scannedAt];
}

class DashboardStats extends Equatable {
  final int totalScans;
  final int healthyCount;
  final int infectedCount;
  final List<ScanModel> recentScans;

  const DashboardStats({
    required this.totalScans,
    required this.healthyCount,
    required this.infectedCount,
    required this.recentScans,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalScans: json['totalScans'] ?? 0,
      healthyCount: json['healthyCount'] ?? 0,
      infectedCount: json['infectedCount'] ?? 0,
      recentScans: (json['recentScans'] as List? ?? [])
          .map((e) => ScanModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory DashboardStats.empty() =>
      const DashboardStats(totalScans: 0, healthyCount: 0, infectedCount: 0, recentScans: []);

  @override
  List<Object?> get props => [totalScans, healthyCount, infectedCount, recentScans];
}
