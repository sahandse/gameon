import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/remote/cheapshark_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataSyncSnapshot {
  const DataSyncSnapshot({
    required this.platforms,
    required this.pcDeals,
    required this.updatedAt,
  });

  final List<String> platforms;
  final List<GameSummary> pcDeals;
  final DateTime updatedAt;
}

class DataSyncService {
  DataSyncService({CheapSharkApi? cheapSharkApi})
      : _cheapSharkApi = cheapSharkApi ?? CheapSharkApi();

  static const _lastRefreshKey = 'last_successful_data_refresh_ms';
  final CheapSharkApi _cheapSharkApi;

  Future<DataSyncSnapshot> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final platforms = prefs.getStringList('platforms') ?? const <String>[];

    final deals = platforms.contains('pc')
        ? await _cheapSharkApi.fetchDeals(pageSize: 20)
        : const <GameSummary>[];

    final updatedAt = DateTime.now();
    await prefs.setInt(_lastRefreshKey, updatedAt.millisecondsSinceEpoch);

    return DataSyncSnapshot(
      platforms: platforms,
      pcDeals: deals,
      updatedAt: updatedAt,
    );
  }

  Future<DateTime?> lastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_lastRefreshKey);
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
  }
}
