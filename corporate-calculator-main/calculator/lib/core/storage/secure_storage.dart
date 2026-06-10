import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final _storage = const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> saveUserInfo({
    required String role,
    required String userId,
    required String fullName,
  }) async {
    await _storage.write(key: 'user_role', value: role);
    await _storage.write(key: 'user_id', value: userId);
    await _storage.write(key: 'user_name', value: fullName);
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');
  Future<String?> getUserRole() => _storage.read(key: 'user_role');
  Future<String?> getUserId() => _storage.read(key: 'user_id');
  Future<String?> getUserName() => _storage.read(key: 'user_name');

  Future<void> clearTokens() => _storage.deleteAll();
}
