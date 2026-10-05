import 'package:dio/dio.dart';

class TrackerNetworkApi {
  TrackerNetworkApi({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://public-api.tracker.gg/v2'));

  final Dio _dio;

  static const String apiKey = String.fromEnvironment('TRN_API_KEY');

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<PlayerStats> fetchApexProfile({
    required String platform,
    required String playerId,
  }) async {
    if (!isConfigured) {
      throw const TrackerConfigurationException();
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/apex/standard/profile/$platform/${Uri.encodeComponent(playerId)}',
      options: Options(headers: <String, String>{'TRN-Api-Key': apiKey}),
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) throw const TrackerDataException('پروفایل معتبر دریافت نشد.');

    final segments = (data['segments'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    final overview = segments.cast<Map<String, dynamic>?>().firstWhere(
          (segment) => segment?['type'] == 'overview',
          orElse: () => segments.isEmpty ? null : segments.first,
        );
    final stats = overview?['stats'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    return PlayerStats(
      platform: platform,
      playerName: (data['platformInfo'] as Map<String, dynamic>?)?['platformUserHandle'] as String? ?? playerId,
      level: _display(stats['level']),
      rankScore: _display(stats['rankScore']),
      kills: _display(stats['kills']),
      damage: _display(stats['damage']),
      wins: _display(stats['wins']),
    );
  }

  String? _display(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    final display = value['displayValue'];
    return display?.toString();
  }
}

class PlayerStats {
  const PlayerStats({
    required this.platform,
    required this.playerName,
    this.level,
    this.rankScore,
    this.kills,
    this.damage,
    this.wins,
  });

  final String platform;
  final String playerName;
  final String? level;
  final String? rankScore;
  final String? kills;
  final String? damage;
  final String? wins;
}

class TrackerConfigurationException implements Exception {
  const TrackerConfigurationException();
}

class TrackerDataException implements Exception {
  const TrackerDataException(this.message);
  final String message;
}
