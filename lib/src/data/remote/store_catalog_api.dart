import 'package:dio/dio.dart';
import 'package:gameon/src/data/models/game_summary.dart';

class StoreCatalogSnapshot {
  const StoreCatalogSnapshot({
    required this.platform,
    required this.games,
    required this.updatedAt,
    required this.total,
  });

  final String platform;
  final List<GameSummary> games;
  final DateTime? updatedAt;
  final int total;
}

class StoreCatalogApi {
  StoreCatalogApi([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl:
                  'https://raw.githubusercontent.com/Ephellon/game-store-catalog/main',
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 45),
              headers: const <String, String>{
                'User-Agent': 'Gameon/0.2.0 (Flutter; sahandse/gameon)',
                'Accept': 'application/json',
              },
            ));

  final Dio _dio;
  final Map<String, StoreCatalogSnapshot> _memoryCache = {};

  static const _folderByPlatform = <String, String>{
    'playstation': 'psn',
    'xbox': 'xbox-console',
    'nintendo': 'nintendo',
  };

  Future<StoreCatalogSnapshot> fetchPlatform(String platform) async {
    final cached = _memoryCache[platform];
    if (cached != null) return cached;

    final folder = _folderByPlatform[platform];
    if (folder == null) {
      return StoreCatalogSnapshot(
        platform: platform,
        games: const <GameSummary>[],
        updatedAt: null,
        total: 0,
      );
    }

    final responses = await Future.wait<Response<dynamic>>([
      _dio.get<dynamic>('/$folder/%21.json'),
      _dio.get<dynamic>('/$folder/%24.json'),
    ]);

    final metadata = responses[1].data is Map<String, dynamic>
        ? responses[1].data as Map<String, dynamic>
        : const <String, dynamic>{};
    final updatedAt = DateTime.tryParse((metadata['date'] ?? '').toString());
    final rows = responses[0].data is List
        ? responses[0].data as List<dynamic>
        : const <dynamic>[];

    final games = <GameSummary>[];
    for (final row in rows) {
      Map<String, dynamic>? json;
      String? fallbackName;
      if (row is List && row.length >= 2) {
        fallbackName = row.first?.toString();
        if (row[1] is Map) {
          json = Map<String, dynamic>.from(row[1] as Map);
        }
      } else if (row is Map) {
        json = Map<String, dynamic>.from(row);
      }
      if (json == null) continue;

      final title = (json['name'] ?? fallbackName ?? '').toString().trim();
      if (title.isEmpty) continue;
      final uuid = (json['uuid'] ?? title).toString();
      final price = _parsePrice(json['price']?.toString());
      final platformNames = json['platforms'] is List
          ? (json['platforms'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .join(' • ')
          : _label(platform);

      games.add(GameSummary(
        id: 'catalog:$platform:$uuid',
        source: 'game-store-catalog',
        sourceId: uuid,
        title: title,
        thumbUrl: _httpOrNull(json['image']?.toString()),
        normalPrice: price,
        salePrice: price,
        storeUrl: _httpOrNull(json['href']?.toString()),
        platform: platformNames,
        sourceUpdatedAt: updatedAt,
      ));
    }

    games.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    final snapshot = StoreCatalogSnapshot(
      platform: platform,
      games: games,
      updatedAt: updatedAt,
      total: (metadata['size'] as num?)?.toInt() ?? games.length,
    );
    _memoryCache[platform] = snapshot;
    return snapshot;
  }

  double? _parsePrice(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    if (normalized.toLowerCase() == 'free') return 0;
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(normalized);
    return match == null ? null : double.tryParse(match.group(1)!);
  }

  String? _httpOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.startsWith('http') ? trimmed : null;
  }

  String _label(String value) => switch (value) {
        'playstation' => 'PlayStation',
        'xbox' => 'Xbox',
        'nintendo' => 'Nintendo',
        _ => value,
      };
}
