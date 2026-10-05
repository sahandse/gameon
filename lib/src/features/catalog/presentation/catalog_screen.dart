import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gameon/src/core/format/persian_datetime.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/remote/cheapshark_api.dart';
import 'package:gameon/src/data/remote/freetogame_api.dart';
import 'package:gameon/src/features/game/presentation/game_detail_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final CheapSharkApi _cheapShark = CheapSharkApi();
  final FreeToGameApi _freeToGame = FreeToGameApi();
  late Future<_CatalogData> _future = _load();
  int _segment = 0;
  String _category = 'همه';

  static const _segments = <String>['رایگان', 'جدیدترین', 'پولی', 'تخفیف', 'اشتراکی'];
  static const _categories = <String>['همه', 'اکشن', 'شوتر', 'MMO', 'استراتژی', 'ورزشی', 'ریسینگ'];

  Future<_CatalogData> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final platforms = prefs.getStringList('platforms') ?? const <String>[];
    final pcEnabled = platforms.contains('pc');
    if (!pcEnabled) {
      return _CatalogData(platforms: platforms, freeGames: const [], newGames: const [], deals: const []);
    }

    final results = await Future.wait<dynamic>([
      _freeToGame.fetchGames(sortBy: 'popularity'),
      _freeToGame.fetchGames(sortBy: 'release-date'),
      _cheapShark.fetchDeals(pageSize: 60),
    ]);

    return _CatalogData(
      platforms: platforms,
      freeGames: results[0] as List<GameSummary>,
      newGames: results[1] as List<GameSummary>,
      deals: results[2] as List<GameSummary>,
    );
  }

  Future<void> _refresh() async {
    GameonHaptics.tap();
    setState(() => _future = _load());
    await _future;
    if (mounted) GameonHaptics.confirm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('کاتالوگ بازی‌ها')),
      body: SafeArea(
        child: FutureBuilder<_CatalogData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const GameonPageSkeleton();
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: GameonEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'کاتالوگ بروزرسانی نشد',
                  message: 'اتصال به منبع واقعی ناموفق بود.',
                  actionLabel: 'تلاش دوباره',
                  onAction: _refresh,
                ),
              );
            }

            final data = snapshot.data!;
            if (!data.platforms.contains('pc')) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  GameonEmptyState(
                    icon: Icons.computer_rounded,
                    title: 'کاتالوگ کامل فعلاً برای PC فعال است',
                    message: 'منابع عمومی قابل‌اعتماد PC متصل شده‌اند. پلتفرم‌های دیگر بدون منبع رسمی پایدار با داده حدسی پر نمی‌شوند.',
                  ),
                ],
              );
            }

            final games = _gamesForSegment(data);
            final filtered = _applyCategory(games);
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
                children: [
                  Text('بازی واقعی، نه دمو', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  const Text('بازی‌های رایگان از FreeToGame و قیمت/تخفیف‌ها از CheapShark دریافت می‌شوند.', style: TextStyle(color: GameonColors.textSecondary, height: 1.55)),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_segments.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(_segments[index]),
                            selected: _segment == index,
                            onSelected: (_) {
                              GameonHaptics.tap();
                              setState(() => _segment = index);
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_segment == 0 || _segment == 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (_) => setState(() => _category = category),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 22),
                  if (_segment == 4)
                    const GameonEmptyState(
                      icon: Icons.workspace_premium_rounded,
                      title: 'سرویس‌های اشتراکی هنوز منبع پایدار ندارند',
                      message: 'Game Pass و PlayStation Plus زمانی فعال می‌شوند که منبع رسمی قابل استفاده داخل اپ داشته باشند؛ فعلاً داده جعلی نمایش داده نمی‌شود.',
                    )
                  else if (filtered.isEmpty)
                    const GameonEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'موردی پیدا نشد',
                      message: 'فیلتر را تغییر بده یا بروزرسانی کن.',
                    )
                  else
                    ...filtered.take(80).map((game) => Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: _GameTile(game: game, showPrice: _segment == 2 || _segment == 3),
                        )),
                  const SizedBox(height: 14),
                  const Text('منابع: FreeToGame و CheapShark', style: TextStyle(color: GameonColors.textSecondary, fontSize: 11.5)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<GameSummary> _gamesForSegment(_CatalogData data) {
    return switch (_segment) {
      0 => data.freeGames,
      1 => data.newGames,
      2 => data.deals.where((g) => (g.salePrice ?? g.normalPrice ?? 0) > 0).toList(),
      3 => data.deals.where((g) => g.isDiscounted).toList(),
      _ => const <GameSummary>[],
    };
  }

  List<GameSummary> _applyCategory(List<GameSummary> games) {
    if (_category == 'همه' || (_segment != 0 && _segment != 1)) return games;
    final needle = switch (_category) {
      'اکشن' => 'action',
      'شوتر' => 'shooter',
      'MMO' => 'mmo',
      'استراتژی' => 'strategy',
      'ورزشی' => 'sports',
      'ریسینگ' => 'racing',
      _ => '',
    };
    if (needle.isEmpty) return games;
    return games.where((g) {
      final genre = (g.genre ?? '').toLowerCase();
      return genre.contains(needle);
    }).toList();
  }
}

class _CatalogData {
  const _CatalogData({required this.platforms, required this.freeGames, required this.newGames, required this.deals});

  final List<String> platforms;
  final List<GameSummary> freeGames;
  final List<GameSummary> newGames;
  final List<GameSummary> deals;
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, required this.showPrice});

  final GameSummary game;
  final bool showPrice;

  @override
  Widget build(BuildContext context) {
    return GameonSurface(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game))),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 82,
              height: 62,
              child: game.thumbUrl == null
                  ? ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest)
                  : CachedNetworkImage(
                      imageUrl: game.thumbUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const GameonSkeleton(width: 82, height: 62, radius: 0),
                      errorWidget: (_, __, ___) => ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.title, textDirection: TextDirection.ltr, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                if (game.genre != null)
                  Text(game.genre!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: GameonColors.textSecondary, fontSize: 11.5)),
                if (game.releaseDate != null) ...[
                  const SizedBox(height: 4),
                  Text(PersianDateTime.date(game.releaseDate!), style: const TextStyle(color: GameonColors.textSecondary, fontSize: 11.5)),
                ],
                if (showPrice && game.salePrice != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(game.salePrice == 0 ? 'رایگان' : '\$${game.salePrice!.toStringAsFixed(2)}', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900)),
                      if ((game.discountPercent ?? 0) > 0) ...[
                        const SizedBox(width: 8),
                        Text('-${PersianDateTime.digits(game.discountPercent ?? 0)}٪', style: const TextStyle(color: Color(0xFF56E06E), fontWeight: FontWeight.w900)),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: GameonColors.textSecondary),
        ],
      ),
    );
  }
}
