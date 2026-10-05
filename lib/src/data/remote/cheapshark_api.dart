import 'package:dio/dio.dart';
import 'package:gameon/src/data/models/game_summary.dart';

class CheapSharkApi {
  CheapSharkApi([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://www.cheapshark.com/api/1.0',
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
              headers: const <String, String>{
                'User-Agent': 'Gameon/0.2.0 (Flutter; sahandse/gameon)',
              },
            ));

  final Dio _dio;

  Future<List<GameSummary>> searchGames(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const <GameSummary>[];

    final response = await _dio.get<List<dynamic>>(
      '/games',
      queryParameters: <String, dynamic>{'title': normalized, 'limit': 30},
    );

    final rows = response.data ?? const <dynamic>[];
    return rows.whereType<Map<String, dynamic>>().map((json) {
      final gameId = (json['gameID'] ?? '').toString();
      return GameSummary(
        id: 'cheapshark:$gameId',
        source: 'cheapshark',
        sourceId: gameId,
        steamAppId: json['steamAppID']?.toString(),
        title: (json['external'] ?? '').toString(),
        thumbUrl: json['thumb']?.toString(),
      );
    }).where((game) => game.sourceId?.isNotEmpty == true && game.title.isNotEmpty).toList();
  }

  Future<List<GameSummary>> fetchDeals({int pageSize = 30}) async {
    final response = await _dio.get<List<dynamic>>(
      '/deals',
      queryParameters: <String, dynamic>{
        'pageSize': pageSize,
        'sortBy': 'Deal Rating',
        'desc': 1,
      },
    );

    final rows = response.data ?? const <dynamic>[];
    return rows.whereType<Map<String, dynamic>>().map((json) {
      final normalPrice = double.tryParse((json['normalPrice'] ?? '').toString());
      final salePrice = double.tryParse((json['salePrice'] ?? '').toString());
      final savings = double.tryParse((json['savings'] ?? '').toString());
      final gameId = (json['gameID'] ?? '').toString();
      final releaseUnix = int.tryParse((json['releaseDate'] ?? '').toString());
      return GameSummary(
        id: 'cheapshark:$gameId',
        source: 'cheapshark',
        sourceId: gameId,
        steamAppId: json['steamAppID']?.toString(),
        title: (json['title'] ?? '').toString(),
        thumbUrl: json['thumb']?.toString(),
        normalPrice: normalPrice,
        salePrice: salePrice,
        discountPercent: savings?.round(),
        storeId: json['storeID']?.toString(),
        releaseDate: releaseUnix == null || releaseUnix <= 0
            ? null
            : DateTime.fromMillisecondsSinceEpoch(releaseUnix * 1000),
      );
    }).where((game) => game.sourceId?.isNotEmpty == true && game.title.isNotEmpty).toList();
  }
}
