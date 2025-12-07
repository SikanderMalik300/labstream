class AppConfig {
  // Token Server Configuration
  static const String tokenServerUrl = String.fromEnvironment(
    'TOKEN_SERVER_URL',
    defaultValue: 'http://localhost:3000',
  );

  // LiveKit Server Configuration
  static const String liveKitUrl = String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: 'ws://localhost:7880',
  );

  // App Settings
  static const int maxParticipants = 150;
  static const int participantsPerPage = 60;

  // Block Durations (in minutes)
  static const int blockDuration10Min = 10;
  static const int blockDuration30Min = 30;
  static const int blockDurationPermanent = -1; // -1 represents permanent

  // Evaluation Settings
  static const double minScore = 0.0;
  static const double maxScore = 10.0;

  // Audio/Video Settings
  static const int defaultVideoWidth = 1280;
  static const int defaultVideoHeight = 720;
  static const int defaultFrameRate = 30;
  static const int defaultAudioBitrate = 48000;

  // Chat Settings
  static const int maxChatMessageLength = 500;

  // API Endpoints
  static String get loginEndpoint => '$tokenServerUrl/api/auth/login';
  static String get tokenEndpoint => '$tokenServerUrl/api/auth/token';
  static String get blockEndpoint => '$tokenServerUrl/api/blocks';
  static String get evaluationEndpoint => '$tokenServerUrl/api/evaluations';
}
