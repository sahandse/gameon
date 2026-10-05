import 'dart:convert';

import 'package:gameon/src/data/models/game_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameLibraryStore {
  static const _followedKey = 'followed_games_v1';
  static const _wishlistKey = 'wishlist_games_v1';

  Future<List<GameSummary>> followed() => _read(_followedKey);
  Future<List<GameSummary>> wishlist() => _read(_wishlistKey);

  Future<bool> isFollowed(String id) async =>
      (await followed()).any((game) => game.id == id);

  Future<bool> isWishlisted(String id) async =>
      (await wishlist()).any((game) => game.id == id);

  Future<void> setFollowed(GameSummary game, bool value) =>
      _set(_followedKey, game, value);

  Future<void> setWishlisted(GameSummary game, bool value) =>
      _set(_wishlistKey, game, value);

  Future<List<GameSummary>> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key) ?? const <String>[];
    final games = <GameSummary>[];
    for (final item in raw) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        games.add(_fromJson(map));
      } catch (_) {
        // Ignore malformed local entries instead of showing invalid data.
      }
    }
    return games;
  }

  Future<void> _set(String key, GameSummary game, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _read(key);
    current.removeWhere((item) => item.id == game.id);
    if (value) current.insert(0, game);
    await prefs.setStringList(
      key,
      current.map((item) => jsonEncode(_toJson(item))).toList(),
    );
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
        'shortDescription': game.shortDescription,
        'genre': game.genre,
        'platform': game.platform,
        'publisher': game.publisher,
        'developer': game.developer,
        'releaseDate': game.releaseDate?.toIso8601String(),
      };

  GameSummary _fromJson(Map<String, dynamic> json) => GameSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        source: json['source'] as String?,
        sourceId: json['sourceId'] as String?,
        steamAppId: json['steamAppId'] as String?,
        thumbUrl: json['thumbUrl'] as String?,
        normalPrice: (json['normalPrice'] as num?)?.toDouble(),
        salePrice: (json['salePrice'] as num?)?.toDouble(),
        discountPercent: (json['discountPercent'] as num?)?.toInt(),
        storeId: json['storeId'] as String?,
        shortDescription: json['shortDescription'] as String?,
        genre: json['genre'] as String?,
        platform: json['platform'] as String?,
        publisher: json['publisher'] as String?,
        developer: json['developer'] as String?,
        releaseDate: DateTime.tryParse((json['releaseDate'] ?? '').toString()),
      );
}
