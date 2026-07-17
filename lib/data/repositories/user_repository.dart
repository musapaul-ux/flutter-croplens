import 'dart:typed_data';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/scan_model.dart';

class UserRepository {
  final ApiClient _client = ApiClient.instance;

  Future<UserModel> getProfile() async {
    final res = await _client.get('/users/profile');
    return UserModel.fromJson(res['data']['user']);
  }

  Future<UserModel> updateProfile({required String fullName}) async {
    final res = await _client.put('/users/profile', data: {'fullName': fullName});
    return UserModel.fromJson(res['data']['user']);
  }

  Future<UserModel> uploadProfilePicture(Uint8List imageBytes, String fileName) async {
    final res = await _client.upload(
      '/users/profile/picture',
      fileBytes: imageBytes,
      fileName: fileName,
      fieldName: 'image',
    );
    return UserModel.fromJson(res['data']['user']);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _client.put('/users/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<DashboardStats> getDashboardStats() async {
    final res = await _client.get('/users/dashboard-stats');
    return DashboardStats.fromJson(res['data']);
  }
}
