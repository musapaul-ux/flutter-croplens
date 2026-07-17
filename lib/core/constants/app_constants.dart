class AppConstants {
  AppConstants._();

  static const String appName = 'CropLens';
  static const String appSlogan = 'Scan. Diagnose. Grow healthier crops.';

  // SecureStorage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String rememberMeKey = 'remember_me';

  // Pagination
  static const int defaultPageSize = 20;

  // Animation durations
  static const Duration shortAnim = Duration(milliseconds: 220);
  static const Duration mediumAnim = Duration(milliseconds: 400);
  static const Duration longAnim = Duration(milliseconds: 650);
}
