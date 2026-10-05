import 'package:gameon/src/data/local/home_data_cache.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/remote/cheapshark_api.dart';
import 'package:gameon/src/data/remote/freetogame_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataSyncSnapshot {
  const DataSyncSnapshot({
    required this.platforms,
    required this.pcDeals,
    required this.popularFreeGames,
    required this.newFreeGames,
    required this.updatedAt,
    required this.usingCachedData,
  });

  final List<String> platforms;
  final List<GameSummary> pcDeals;
  final List<GameSummary> popularFreeGames;
  final List<GameSummary> newFreeGames;
  final DateTime updatedAt;
  final bool usingCachedData;
}

class DataSyncService {
  DataSyncService({
    CheapSharkApi? cheapSharkApi,
    FreeToGameApi? freeToGameApi,
    HomeDataCache? cache,
  })  : _cheapSharkApi = cheapSharkApi ?? CheapSharkApi(),
        _freeToGameApi = freeToGameApi ?? FreeToGameApi(),
        _cache = cache ?? HomeDataCache();

  static const _lastRefreshKey = 'last_successful_data_refresh_ms';
  final CheapSharkApi _cheapSharkApi;
  final FreeToGameApi _freeToGameApi;
  final HomeDataCache _cache;

  Future<DataSyncSnapshot> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final platforms = prefs.getStringList('platforms') ?? const <String>[];
    final cached = await _cache.read();

    final results = await Future.wait<_FetchResult>([
      _safeFetch(
        () => _freeToGameApi.fetchGames(sortBy: 'popularity'),
        cached.popular,
      ),
      _safeFetch(
        () => _freeToGameApi.fetchGames(sortBy: 'release-date'),
        cached.newest,
      ),
      _safeFetch(
        () => _cheapSharkApi.fetchDeals(pageSize: 40),
        cached.deals,
      ),
    ]);

    final popular = results[0].games.take(24).toList();
    final newest = results[1].games.take(24).toList();
    final deals = results[2].games.take(40).toList();
    final allFromCache = results.every((result) => result.fromCache);
    final anyFresh = results.any((result) => !result.fromCache && result.games.isNotEmpty);

    final updatedAt = anyFresh
        ? DateTime.now()
        : cached.updatedAt ?? DateTime.now();

    if (anyFresh) {
      await _cache.save(
        popular: popular,
        newest: newest,
        deals: deals,
        updatedAt: updatedAt,
      );
      await prefs.setInt(_lastRefreshKey, updatedAt.millisecondsSinceEpoch);
    }

    return DataSyncSnapshot(
      platforms: platforms,
      pcDeals: deals,
      popularFreeGames: popular,
      newFreeGames: newest,
      updatedAt: updatedAt,
      usingCachedData: allFromCache,
    );
  }

  Future<DateTime?> lastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_lastRefreshKey);
    if (value != null) return DateTime.fromMillisecondsSinceEpoch(value);
    return (await _cache.read()).updatedAt;
  }

  Future<_FetchResult> _safeFetch(
    Future<List<GameSummary>> Function() fetch,
    List<GameSummary> fallback,
  ) async {
    try {
      final result = await fetch();
      if (result.isNotEmpty) {
        return _FetchResult(games: result, fromCache: false);
      }
    } catch (_) {
      // Fall back to the last successful real response.
    }
    return _FetchResult(games: fallback, fromCache: true);
  }
}

class _FetchResult {
  const _FetchResult({required this.games, required this.fromCache});
  final List<GameSummary> games;
  final bool fromCache;
}
