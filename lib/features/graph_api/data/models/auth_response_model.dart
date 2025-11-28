/// API authentication response model
class AuthResponseModel {
  final bool success;
  final String message;
  final AuthDataModel data;

  AuthResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: AuthDataModel.fromJson(json['data'] ?? {}),
    );
  }
}

class AuthDataModel {
  final String token;
  final String tokenType;
  final String expiresAt;

  AuthDataModel({
    required this.token,
    required this.tokenType,
    required this.expiresAt,
  });

  factory AuthDataModel.fromJson(Map<String, dynamic> json) {
    return AuthDataModel(
      token: json['token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      expiresAt: json['expires_at'] ?? '',
    );
  }

  bool get isExpired {
    try {
      final expiryDate = DateTime.parse(expiresAt);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }
}
