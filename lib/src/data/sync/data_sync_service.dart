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
  });

  final List<String> platforms;
  final List<GameSummary> pcDeals;
  final List<GameSummary> popularFreeGames;
  final List<GameSummary> newFreeGames;
  final DateTime updatedAt;
}

class DataSyncService {
  DataSyncService({
    CheapSharkApi? cheapSharkApi,
    FreeToGameApi? freeToGameApi,
  })  : _cheapSharkApi = cheapSharkApi ?? CheapSharkApi(),
        _freeToGameApi = freeToGameApi ?? FreeToGameApi();

  static const _lastRefreshKey = 'last_successful_data_refresh_ms';
  final CheapSharkApi _cheapSharkApi;
  final FreeToGameApi _freeToGameApi;

  Future<DataSyncSnapshot> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final platforms = prefs.getStringList('platforms') ?? const <String>[];

    final shouldLoadPc = platforms.contains('pc');
    final results = await Future.wait<dynamic>([
      if (shouldLoadPc) _cheapSharkApi.fetchDeals(pageSize: 30) else Future.value(const <GameSummary>[]),
      if (shouldLoadPc) _freeToGameApi.fetchGames(sortBy: 'popularity') else Future.value(const <GameSummary>[]),
      if (shouldLoadPc) _freeToGameApi.fetchGames(sortBy: 'release-date') else Future.value(const <GameSummary>[]),
    ]);

    final deals = results[0] as List<GameSummary>;
    final popularFree = (results[1] as List<GameSummary>).take(20).toList();
    final newFree = (results[2] as List<GameSummary>).take(20).toList();

    final updatedAt = DateTime.now();
    await prefs.setInt(_lastRefreshKey, updatedAt.millisecondsSinceEpoch);

    return DataSyncSnapshot(
      platforms: platforms,
      pcDeals: deals,
      popularFreeGames: popularFree,
      newFreeGames: newFree,
      updatedAt: updatedAt,
    );
  }

  Future<DateTime?> lastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_lastRefreshKey);
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
  }
}
