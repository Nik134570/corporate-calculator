import 'package:calculator/core/api/api_client.dart';
import 'package:calculator/core/storage/secure_storage.dart';
import 'package:calculator/features/auth/data/models/auth_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  AuthRepository(this._apiClient, this._storage);

  Future<AuthModel> login(String email, String password) async {
    final response = await _apiClient.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final auth = AuthModel.fromJson(response.data['data']);
    await _storage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    await _storage.saveUserInfo(
      role: auth.user.role,
      userId: auth.user.id,
      fullName: auth.user.fullName,
    );
    return auth;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.dio.post('/auth/logout',
            data: {'refreshToken': refreshToken});
      }
    } catch (_) {}
    await _storage.clearTokens();
  }
}
