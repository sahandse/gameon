import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gameon/src/core/format/persian_datetime.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/remote/cheapshark_api.dart';
import 'package:gameon/src/data/remote/freetogame_api.dart';
import 'package:gameon/src/data/remote/store_catalog_api.dart';
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
  final StoreCatalogApi _storeCatalog = StoreCatalogApi();
  final TextEditingController _search = TextEditingController();

  late Future<_CatalogData> _future = _load();
  String? _activePlatform;
  int _segment = 0;
  String _category = 'همه';

  static const _pcSegments = <String>['رایگان', 'جدیدترین', 'پولی', 'تخفیف'];
  static const _consoleSegments = <String>['همه', 'رایگان', 'پولی'];
  static const _categories = <String>[
    'همه',
    'اکشن',
    'شوتر',
    'MMO',
    'استراتژی',
    'ورزشی',
    'ریسینگ',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<_CatalogData> _load([String? requestedPlatform]) async {
    final prefs = await SharedPreferences.getInstance();
    final platforms = prefs.getStringList('platforms') ?? const <String>[];
    final platform = requestedPlatform ??
        _activePlatform ??
        (platforms.isNotEmpty ? platforms.first : 'pc');

    if (platform == 'pc') {
      final results = await Future.wait<dynamic>([
        _freeToGame.fetchGames(sortBy: 'popularity'),
        _freeToGame.fetchGames(sortBy: 'release-date'),
        _cheapShark.fetchDeals(pageSize: 100),
      ]);
      return _CatalogData(
        platforms: platforms,
        platform: platform,
        freeGames: results[0] as List<GameSummary>,
        newGames: results[1] as List<GameSummary>,
        deals: results[2] as List<GameSummary>,
      );
    }

    final snapshot = await _storeCatalog.fetchPlatform(platform);
    return _CatalogData(
      platforms: platforms,
      platform: platform,
      consoleCatalog: snapshot,
    );
  }

  Future<void> _selectPlatform(String platform) async {
    if (_activePlatform == platform) return;
    GameonHaptics.tap();
    setState(() {
      _activePlatform = platform;
      _segment = 0;
      _category = 'همه';
      _search.clear();
      _future = _load(platform);
    });
    await _future;
  }

  Future<void> _refresh() async {
    GameonHaptics.tap();
    setState(() => _future = _load(_activePlatform));
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
            _activePlatform ??= data.platform;
            final segments = data.platform == 'pc'
                ? _pcSegments
                : _consoleSegments;
            final games = _filteredGames(data);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
                children: [
                  Text(
                    'کاتالوگ کامل ${_platformLabel(data.platform)}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _sourceDescription(data),
                    style: const TextStyle(
                      color: GameonColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  if (data.consoleCatalog?.updatedAt != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      'آخرین بروزرسانی منبع: ${PersianDateTime.dateTime(data.consoleCatalog!.updatedAt!.toLocal())}',
                      style: const TextStyle(
                        color: GameonColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _PlatformSelector(
                    platforms: data.platforms,
                    selected: data.platform,
                    onSelected: _selectPlatform,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'جستجو در کاتالوگ ${_platformLabel(data.platform)}…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'پاک کردن',
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(segments.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(segments[index]),
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
                  if (data.platform == 'pc' && (_segment == 0 || _segment == 1)) ...[
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (_) {
                                GameonHaptics.tap();
                                setState(() => _category = category);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        '${PersianDateTime.digits(games.length)} بازی',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      if (data.consoleCatalog != null)
                        Text(
                          'کل منبع: ${PersianDateTime.digits(data.consoleCatalog!.total)}',
                          style: const TextStyle(
                            color: GameonColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (games.isEmpty)
                    const GameonEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'موردی پیدا نشد',
                      message: 'عبارت جستجو یا فیلتر را تغییر بده.',
                    )
                  else
                    ...games.take(250).map(
                          (game) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _GameTile(game: game),
                          ),
                        ),
                  if (games.length > 250) ...[
                    const SizedBox(height: 8),
                    GameonSurface(
                      child: Text(
                        'برای سبک نگه‌داشتن صفحه، ۲۵۰ نتیجه اول نمایش داده شده. با جستجو می‌توانی بین کل ${PersianDateTime.digits(games.length)} مورد نتیجه دقیق پیدا کنی.',
                        style: const TextStyle(
                          color: GameonColors.textSecondary,
                          height: 1.6,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    _sourceFooter(data),
                    style: const TextStyle(
                      color: GameonColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<GameSummary> _filteredGames(_CatalogData data) {
    List<GameSummary> games;
    if (data.platform == 'pc') {
      games = switch (_segment) {
        0 => data.freeGames,
        1 => data.newGames,
        2 => data.deals
            .where((g) => (g.salePrice ?? g.normalPrice ?? 0) > 0)
            .toList(),
        3 => data.deals.where((g) => g.isDiscounted).toList(),
        _ => const <GameSummary>[],
      };
      games = _applyCategory(games);
    } else {
      final all = data.consoleCatalog?.games ?? const <GameSummary>[];
      games = switch (_segment) {
        1 => all.where((g) => g.isFree).toList(),
        2 => all.where((g) => (g.salePrice ?? g.normalPrice ?? 0) > 0).toList(),
        _ => all,
      };
    }

    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return games;
    return games.where((game) {
      final haystack = [
        game.title,
        game.genre ?? '',
        game.platform ?? '',
        game.publisher ?? '',
        game.developer ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
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
    return games.where((g) => (g.genre ?? '').toLowerCase().contains(needle)).toList();
  }

  String _sourceDescription(_CatalogData data) {
    if (data.platform == 'pc') {
      return 'بازی‌های رایگان از FreeToGame و قیمت/تخفیف‌ها از CheapShark دریافت می‌شوند.';
    }
    return 'نام، قیمت، کاور، لینک فروشگاه و پلتفرم از کاتالوگ واقعی فروشگاه‌ها دریافت می‌شود؛ این منبع کش‌شده است و تاریخ بروزرسانی آن شفاف نمایش داده می‌شود.';
  }

  String _sourceFooter(_CatalogData data) => data.platform == 'pc'
      ? 'منابع: FreeToGame و CheapShark'
      : 'منبع کاتالوگ: Ephellon/game-store-catalog (داده جمع‌آوری‌شده از فروشگاه رسمی)';

  String _platformLabel(String value) => switch (value) {
        'playstation' => 'پلی‌استیشن',
        'xbox' => 'ایکس‌باکس',
        'pc' => 'رایانه',
        'nintendo' => 'نینتندو',
        _ => value,
      };
}

class _CatalogData {
  const _CatalogData({
    required this.platforms,
    required this.platform,
    this.freeGames = const <GameSummary>[],
    this.newGames = const <GameSummary>[],
    this.deals = const <GameSummary>[],
    this.consoleCatalog,
  });

  final List<String> platforms;
  final String platform;
  final List<GameSummary> freeGames;
  final List<GameSummary> newGames;
  final List<GameSummary> deals;
  final StoreCatalogSnapshot? consoleCatalog;
}

class _PlatformSelector extends StatelessWidget {
  const _PlatformSelector({
    required this.platforms,
    required this.selected,
    required this.onSelected,
  });

  final List<String> platforms;
  final String selected;
  final Future<void> Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    final items = platforms.isEmpty
        ? const <String>['pc']
        : platforms;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((platform) {
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(_label(platform)),
              selected: selected == platform,
              onSelected: (_) => onSelected(platform),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(String value) => switch (value) {
        'playstation' => 'پلی‌استیشن',
        'xbox' => 'ایکس‌باکس',
        'pc' => 'رایانه',
        'nintendo' => 'نینتندو',
        _ => value,
      };
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game});

  final GameSummary game;

  @override
  Widget build(BuildContext context) {
    return GameonSurface(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 82,
              height: 68,
              child: game.thumbUrl == null
                  ? ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    )
                  : CachedNetworkImage(
                      imageUrl: game.thumbUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const GameonSkeleton(
                        width: 82,
                        height: 68,
                        radius: 0,
                      ),
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  textDirection: TextDirection.ltr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                if (game.platform != null)
                  Text(
                    game.platform!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GameonColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                if (game.releaseDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    PersianDateTime.date(game.releaseDate!),
                    style: const TextStyle(
                      color: GameonColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
                if (game.salePrice != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        game.salePrice == 0
                            ? 'رایگان'
                            : '\$${game.salePrice!.toStringAsFixed(2)}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      if ((game.discountPercent ?? 0) > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '-${PersianDateTime.digits(game.discountPercent ?? 0)}٪',
                          style: const TextStyle(
                            color: Color(0xFF56E06E),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 15,
            color: GameonColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
