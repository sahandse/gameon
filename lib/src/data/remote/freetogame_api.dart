import 'package:dio/dio.dart';
import 'package:gameon/src/data/models/game_details.dart';
import 'package:gameon/src/data/models/game_summary.dart';

class FreeToGameApi {
  FreeToGameApi([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://www.freetogame.com/api',
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
              headers: const <String, String>{
                'User-Agent': 'Gameon/0.2.0 (Flutter; sahandse/gameon)',
              },
            ));

  final Dio _dio;

  Future<List<GameSummary>> fetchGames({
    String platform = 'windows',
    String sortBy = 'popularity',
    String? category,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/games',
      queryParameters: <String, dynamic>{
        'platform': platform,
        'sort-by': sortBy,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );

    final rows = response.data ?? const <dynamic>[];
    return rows.whereType<Map<String, dynamic>>().map(_summaryFromJson).toList();
  }

  Future<List<GameSummary>> searchGames(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const <GameSummary>[];
    final games = await fetchGames(sortBy: 'relevance');
    return games
        .where((game) {
          final title = game.title.toLowerCase();
          final genre = (game.genre ?? '').toLowerCase();
          final publisher = (game.publisher ?? '').toLowerCase();
          final developer = (game.developer ?? '').toLowerCase();
          return title.contains(normalized) ||
              genre.contains(normalized) ||
              publisher.contains(normalized) ||
              developer.contains(normalized);
        })
        .take(40)
        .toList();
  }

  Future<GameDetails> fetchDetails(String sourceId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/game',
      queryParameters: <String, dynamic>{'id': sourceId},
    );
    final json = response.data ?? const <String, dynamic>{};
    final requirements = json['minimum_system_requirements'] is Map<String, dynamic>
        ? json['minimum_system_requirements'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final screenshotsRaw = json['screenshots'];
    final screenshots = screenshotsRaw is List
        ? screenshotsRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => e['image']?.toString())
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .toList()
        : const <String>[];

    return GameDetails(
      id: 'ftg:${json['id'] ?? sourceId}',
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      shortDescription: json['short_description']?.toString(),
      thumbnailUrl: json['thumbnail']?.toString(),
      heroUrl: json['thumbnail']?.toString(),
      genre: json['genre']?.toString(),
      platform: json['platform']?.toString(),
      publisher: json['publisher']?.toString(),
      developer: json['developer']?.toString(),
      releaseDate: DateTime.tryParse((json['release_date'] ?? '').toString()),
      status: json['status']?.toString(),
      officialUrl: json['game_url']?.toString(),
      minimumOs: requirements['os']?.toString(),
      minimumProcessor: requirements['processor']?.toString(),
      minimumMemory: requirements['memory']?.toString(),
      minimumGraphics: requirements['graphics']?.toString(),
      minimumStorage: requirements['storage']?.toString(),
      screenshots: screenshots,
      sourceLabel: 'FreeToGame',
    );
  }

  GameSummary _summaryFromJson(Map<String, dynamic> json) {
    final sourceId = (json['id'] ?? '').toString();
    return GameSummary(
      id: 'ftg:$sourceId',
      source: 'freetogame',
      sourceId: sourceId,
      title: (json['title'] ?? '').toString(),
      thumbUrl: json['thumbnail']?.toString(),
      salePrice: 0,
      shortDescription: json['short_description']?.toString(),
      genre: json['genre']?.toString(),
      platform: json['platform']?.toString(),
      publisher: json['publisher']?.toString(),
      developer: json['developer']?.toString(),
      releaseDate: DateTime.tryParse((json['release_date'] ?? '').toString()),
    );
  }
}
