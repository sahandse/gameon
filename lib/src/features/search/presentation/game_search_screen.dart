import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/remote/cheapshark_api.dart';
import 'package:gameon/src/data/remote/freetogame_api.dart';
import 'package:gameon/src/data/remote/store_catalog_api.dart';
import 'package:gameon/src/features/game/presentation/game_detail_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameSearchScreen extends StatefulWidget {
  const GameSearchScreen({super.key});

  @override
  State<GameSearchScreen> createState() => _GameSearchScreenState();
}

class _GameSearchScreenState extends State<GameSearchScreen> {
  final CheapSharkApi _cheapShark = CheapSharkApi();
  final FreeToGameApi _freeToGame = FreeToGameApi();
  final StoreCatalogApi _storeCatalog = StoreCatalogApi();
  final TextEditingController _controller = TextEditingController();
  List<GameSummary> _results = const <GameSummary>[];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _loading) return;
    GameonHaptics.tap();
    setState(() {
      _loading = true;
      _searched = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final selected = prefs.getStringList('platforms') ?? const <String>[];
      final consolePlatforms = selected
          .where((p) => p == 'playstation' || p == 'xbox' || p == 'nintendo')
          .toList();

      final futures = <Future<List<GameSummary>>>[
        _safe(() => _freeToGame.searchGames(query)),
        _safe(() => _cheapShark.searchGames(query)),
        ...consolePlatforms.map(
          (platform) => _safe(() => _storeCatalog.searchPlatform(platform, query)),
        ),
      ];

      final sources = await Future.wait(futures);
      final merged = <String, GameSummary>{};
      for (final game in sources.expand((items) => items)) {
        final platform = (game.platform ?? '').toLowerCase();
        final key = '${game.title.trim().toLowerCase()}|$platform';
        merged.putIfAbsent(key, () => game);
      }

      final results = merged.values.toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      if (!mounted) return;
      setState(() => _results = results.take(160).toList());
      if (results.isNotEmpty) GameonHaptics.confirm();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'دریافت نتیجه از منابع واقعی ناموفق بود.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<GameSummary>> _safe(
    Future<List<GameSummary>> Function() fetch,
  ) async {
    try {
      return await fetch();
    } catch (_) {
      return const <GameSummary>[];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جستجوی بازی')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: GameonAnimatedIn(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'نام بازی، ژانر یا سازنده…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'جستجو',
                      onPressed: _search,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'منابع: FreeToGame + CheapShark + کاتالوگ کنسول‌های انتخاب‌شده',
                  style: TextStyle(
                    color: GameonColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  children: [
                    GameonSkeleton(
                      width: double.infinity,
                      height: 96,
                      radius: 20,
                    ),
                    SizedBox(height: 10),
                    GameonSkeleton(
                      width: double.infinity,
                      height: 96,
                      radius: 20,
                    ),
                    SizedBox(height: 10),
                    GameonSkeleton(
                      width: double.infinity,
                      height: 96,
                      radius: 20,
                    ),
                  ],
                ),
              ),
            if (_error != null && !_loading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: GameonEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'اتصال برقرار نشد',
                  message: _error!,
                  actionLabel: 'تلاش دوباره',
                  onAction: _search,
                ),
              ),
            if (!_loading && _error == null)
              Expanded(
                child: _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                        child: GameonEmptyState(
                          icon: _searched
                              ? Icons.search_off_rounded
                              : Icons.sports_esports_rounded,
                          title: _searched
                              ? 'چیزی پیدا نشد'
                              : 'بازی موردنظرت را پیدا کن',
                          message: _searched
                              ? 'برای این عبارت نتیجه‌ای از منابع واقعی پیدا نشد.'
                              : 'جستجو PC و کنسول‌های انتخاب‌شده را هم‌زمان پوشش می‌دهد.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final game = _results[index];
                          return GameonAnimatedIn(
                            delay: Duration(
                              milliseconds: 30 * index.clamp(0, 8),
                            ),
                            child: GameonSurface(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => GameDetailScreen(game: game),
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: SizedBox(
                                      width: 82,
                                      height: 66,
                                      child: game.thumbUrl == null
                                          ? ColoredBox(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: game.thumbUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) =>
                                                  const GameonSkeleton(
                                                width: 82,
                                                height: 66,
                                                radius: 0,
                                              ),
                                              errorWidget: (_, __, ___) =>
                                                  ColoredBox(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          game.title,
                                          textDirection: TextDirection.ltr,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        if (game.platform != null) ...[
                                          const SizedBox(height: 5),
                                          Text(
                                            game.platform!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: GameonColors.textSecondary,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 5),
                                        Text(
                                          _sourceLabel(game),
                                          style: const TextStyle(
                                            color: GameonColors.textSecondary,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_left_rounded,
                                    color: GameonColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  String _sourceLabel(GameSummary game) => switch (game.source) {
        'freetogame' => 'رایگان • FreeToGame',
        'game-store-catalog' => 'فروشگاه کنسول • کاتالوگ واقعی',
        _ => 'قیمت و فروشگاه • CheapShark',
      };
}
