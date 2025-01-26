import 'dart:io';

/// Wraps access to Environment variables
/// Allows faking for testing
class Environment {
  static const String raygunAppIdKey = 'RAYGUN_APP_ID';
  static const String raygunTokenKey = 'RAYGUN_TOKEN';
  static const String raygunApiKeyKey = 'RAYGUN_API_KEY';

  final String? raygunAppId;
  final String? raygunToken;
  final String? raygunApiKey;

  static Environment? _instance;

  /// Singleton instance access
  /// Will init if not already
  static Environment get instance {
    _instance ??= Environment._init();
    return _instance!;
  }

  /// For testing purposes
  static void setInstance(Environment instance) {
    _instance = instance;
  }

  /// Create custom instance
  Environment({
    required this.raygunAppId,
    required this.raygunToken,
    required this.raygunApiKey,
  });

  String? operator [](String key) {
    switch (key) {
      case raygunAppIdKey:
        return raygunAppId;
      case raygunTokenKey:
        return raygunToken;
      case raygunApiKeyKey:
        return raygunApiKey;
      default:
        return null;
    }
  }

  factory Environment._init() {
    final raygunAppId = Platform.environment[raygunAppIdKey];
    final raygunToken = Platform.environment[raygunTokenKey];
    final raygunApiKey = Platform.environment[raygunApiKeyKey];
    return Environment(
        raygunAppId: raygunAppId,
        raygunToken: raygunToken,
        raygunApiKey: raygunApiKey);
  }
}
