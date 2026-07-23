import '../../core/network/api_client.dart';
import '../../core/network/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _client = ApiClient.instance;

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final res = await _client.post('/auth/register', data: {
      'fullName': fullName,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
    });

    final data = res['data'] as Map<String, dynamic>;
    await SecureStorage.instance.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );
    return UserModel.fromJson(data['user']);
  }

  Future<UserModel> login({
    required String emailOrUsername,
    required String password,
    bool rememberMe = true,
  }) async {
    final res = await _client.post('/auth/login', data: {
      'emailOrUsername': emailOrUsername,
      'password': password,
      'rememberMe': rememberMe,
    });

    final data = res['data'] as Map<String, dynamic>;
    await SecureStorage.instance.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );
    return UserModel.fromJson(data['user']);
  }

  Future<void> logout() async {
    final refreshToken = await SecureStorage.instance.getRefreshToken();
    try {
      await _client.post('/auth/logout', data: {'refreshToken': refreshToken});
    } finally {
      await SecureStorage.instance.clearTokens();
    }
  }

  Future<void> forgotPassword(String email) async {
    await _client.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.post('/auth/reset-password', data: {
      'code': code,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }
}
