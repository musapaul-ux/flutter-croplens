import 'dart:typed_data';
import '../../core/network/api_client.dart';
import '../models/scan_model.dart';

class ScanRepository {
  final ApiClient _client = ApiClient.instance;

  /// Uploads a captured/selected crop image and returns the completed
  /// AI prediction as a saved ScanModel (backend saves it in the same call).
  Future<ScanModel> createScan(Uint8List imageBytes, String fileName) async {
    final res = await _client.upload(
      '/scans',
      fileBytes: imageBytes,
      fileName: fileName,
      fieldName: 'image',
    );
    return ScanModel.fromJson(res['data']['scan']);
  }

  Future<List<ScanModel>> listScans({
    int page = 1,
    int limit = 20,
    String? search,
    String sortBy = 'scannedAt',
    String order = 'desc',
  }) async {
    final res = await _client.get('/scans', query: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      'sortBy': sortBy,
      'order': order,
    });
    final scans = (res['data']['scans'] as List)
        .map((e) => ScanModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return scans;
  }

  Future<ScanModel> getScan(String id) async {
    final res = await _client.get('/scans/$id');
    return ScanModel.fromJson(res['data']['scan']);
  }

  Future<void> deleteScan(String id) async {
    await _client.delete('/scans/$id');
  }
}
