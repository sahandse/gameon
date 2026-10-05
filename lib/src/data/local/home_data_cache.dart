import 'dart:convert';

import 'package:gameon/src/data/models/game_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeDataCache {
  static const _popularKey = 'home_cache_popular_v1';
  static const _newKey = 'home_cache_new_v1';
  static const _dealsKey = 'home_cache_deals_v1';
  static const _updatedKey = 'home_cache_updated_ms';

  Future<void> save({
    required List<GameSummary> popular,
    required List<GameSummary> newest,
    required List<GameSummary> deals,
    required DateTime updatedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_popularKey, jsonEncode(popular.map(_toJson).toList())),
      prefs.setString(_newKey, jsonEncode(newest.map(_toJson).toList())),
      prefs.setString(_dealsKey, jsonEncode(deals.map(_toJson).toList())),
      prefs.setInt(_updatedKey, updatedAt.millisecondsSinceEpoch),
    ]);
  }

  Future<({
    List<GameSummary> popular,
    List<GameSummary> newest,
    List<GameSummary> deals,
    DateTime? updatedAt,
  })> read() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      popular: _decodeList(prefs.getString(_popularKey)),
      newest: _decodeList(prefs.getString(_newKey)),
      deals: _decodeList(prefs.getString(_dealsKey)),
      updatedAt: switch (prefs.getInt(_updatedKey)) {
        final int value => DateTime.fromMillisecondsSinceEpoch(value),
        _ => null,
      },
    );
  }

  List<GameSummary> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const <GameSummary>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <GameSummary>[];
      return decoded
          .whereType<Map>()
          .map((e) => _fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const <GameSummary>[];
    }
  }

  Map<String, dynamic> _toJson(GameSummary game) => <String, dynamic>{
        'id': game.id,
        'title': game.title,
        'source': game.source,
        'sourceId': game.sourceId,
        'steamAppId': game.steamAppId,
        'thumbUrl': game.thumbUrl,
        'normalPrice': game.normalPrice,
        'salePrice': game.salePrice,
        'discountPercent': game.discountPercent,
        'storeId': game.storeId,
        'storeUrl': game.storeUrl,
        'shortDescription': game.shortDescription,
        'genre': game.genre,
        'platform': game.platform,
        'publisher': game.publisher,
        'developer': game.developer,
        'releaseDate': game.releaseDate?.toIso8601String(),
        'sourceUpdatedAt': game.sourceUpdatedAt?.toIso8601String(),
      };

  GameSummary _fromJson(Map<String, dynamic> json) => GameSummary(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        source: json['source']?.toString(),
        sourceId: json['sourceId']?.toString(),
        steamAppId: json['steamAppId']?.toString(),
        thumbUrl: json['thumbUrl']?.toString(),
        normalPrice: (json['normalPrice'] as num?)?.toDouble(),
        salePrice: (json['salePrice'] as num?)?.toDouble(),
        discountPercent: (json['discountPercent'] as num?)?.toInt(),
        storeId: json['storeId']?.toString(),
        storeUrl: json['storeUrl']?.toString(),
        shortDescription: json['shortDescription']?.toString(),
        genre: json['genre']?.toString(),
        platform: json['platform']?.toString(),
        publisher: json['publisher']?.toString(),
        developer: json['developer']?.toString(),
        releaseDate: DateTime.tryParse((json['releaseDate'] ?? '').toString()),
        sourceUpdatedAt:
            DateTime.tryParse((json['sourceUpdatedAt'] ?? '').toString()),
      );
}
