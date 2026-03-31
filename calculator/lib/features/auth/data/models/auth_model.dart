class AuthModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  AuthModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: UserModel.fromJson(json['user']),
    );
  }
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      role: json['role'],
    );
  }
}
