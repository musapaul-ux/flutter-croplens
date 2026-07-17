import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../core/network/api_exception.dart';
import '../data/models/scan_model.dart';
import '../data/repositories/scan_repository.dart';

final scanRepositoryProvider = Provider((ref) => ScanRepository());

enum ScanUploadStatus { idle, uploading, success, error }

class ScanUploadState {
  final ScanUploadStatus status;
  final ScanModel? result;
  final String? errorMessage;

  const ScanUploadState({this.status = ScanUploadStatus.idle, this.result, this.errorMessage});

  ScanUploadState copyWith({ScanUploadStatus? status, ScanModel? result, String? errorMessage}) {
    return ScanUploadState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }
}

/// Drives the "capture -> upload -> AI prediction -> results" flow.
/// The Scan screen calls uploadImage(); the Results screen watches this
/// provider to display the returned prediction.
class ScanUploadNotifier extends StateNotifier<ScanUploadState> {
  final ScanRepository _repo;
  ScanUploadNotifier(this._repo) : super(const ScanUploadState());

  Future<bool> uploadImage(Uint8List imageBytes, String fileName) async {
    state = state.copyWith(status: ScanUploadStatus.uploading);
    try {
      final scan = await _repo.createScan(imageBytes, fileName);
      state = state.copyWith(status: ScanUploadStatus.success, result: scan);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(status: ScanUploadStatus.error, errorMessage: e.message);
      return false;
    } catch (e) {
      // Catch-all so any unexpected error (plugin issue, unsupported platform
      // operation, etc.) still clears the loading state instead of leaving
      // the "Analyzing..." spinner stuck forever.
      state = state.copyWith(status: ScanUploadStatus.error, errorMessage: 'Something went wrong while uploading: $e');
      return false;
    }
  }

  void reset() => state = const ScanUploadState();
}

final scanUploadProvider = StateNotifierProvider<ScanUploadNotifier, ScanUploadState>((ref) {
  return ScanUploadNotifier(ref.watch(scanRepositoryProvider));
});
