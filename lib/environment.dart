import 'dart:io';

/// Wraps access to Environment variables
/// Allows faking for testing
class Environment {
  static String raygunAppIdKey = 'RAYGUN_APP_ID';
  static String raygunTokenKey = 'RAYGUN_TOKEN';

  final String? raygunAppId;
  final String? raygunToken;

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
  });

  factory Environment._init() {
    final raygunAppId = Platform.environment[raygunAppIdKey];
    final raygunToken = Platform.environment[raygunTokenKey];
    return Environment(
      raygunAppId: raygunAppId,
      raygunToken: raygunToken,
    );
  }
}
