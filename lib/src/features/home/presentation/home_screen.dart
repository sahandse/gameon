import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gameon/src/core/format/persian_datetime.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/sync/data_sync_service.dart';
import 'package:gameon/src/features/catalog/presentation/catalog_screen.dart';
import 'package:gameon/src/features/game/presentation/game_detail_screen.dart';
import 'package:gameon/src/features/news/presentation/news_screen.dart';
import 'package:gameon/src/features/search/presentation/game_search_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataSyncService _sync = DataSyncService();
  late Future<DataSyncSnapshot> _future = _sync.refresh();
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    GameonHaptics.tap();
    setState(() {
      _refreshing = true;
      _future = _sync.refresh();
    });
    try {
      await _future;
      if (mounted) GameonHaptics.confirm();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _open(Widget page) {
    GameonHaptics.tap();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<DataSyncSnapshot>(
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
                  title: 'بروزرسانی انجام نشد',
                  message: 'اتصال به منابع واقعی بازی‌ها برقرار نشد. داده ساختگی نمایش داده نمی‌شود.',
                  actionLabel: 'تلاش دوباره',
                  onAction: _refresh,
                ),
              );
            }

            final data = snapshot.data!;
            final pcEnabled = data.platforms.contains('pc');
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
                children: [
                  GameonAnimatedIn(
                    child: _Header(
                      onCatalog: () => _open(const CatalogScreen()),
                      onNews: () => _open(const NewsScreen()),
                      onSearch: () => _open(const GameSearchScreen()),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GameonAnimatedIn(
                    delay: const Duration(milliseconds: 50),
                    child: _RefreshCard(
                      updatedAt: data.updatedAt,
                      refreshing: _refreshing,
                      onRefresh: _refresh,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'برای تو',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.platforms.isEmpty
                        ? 'پلتفرمی انتخاب نشده است.'
                        : data.platforms.map(_platformLabel).join(' • '),
                    style: const TextStyle(color: GameonColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  _QuickActions(
                    onCatalog: () => _open(const CatalogScreen()),
                    onSearch: () => _open(const GameSearchScreen()),
                    onNews: () => _open(const NewsScreen()),
                  ),
                  const SizedBox(height: 28),
                  if (!pcEnabled)
                    const GameonEmptyState(
                      icon: Icons.computer_rounded,
                      title: 'برای محتوای زنده PC، رایانه را هم انتخاب کن',
                      message: 'از بخش «من» می‌توانی هر زمان خواستی پلتفرم دیگری اضافه کنی.',
                    )
                  else ...[
                    _HorizontalGames(
                      title: 'محبوب‌ترین بازی‌های رایگان',
                      subtitle: 'داده واقعی از FreeToGame',
                      games: data.popularFreeGames,
                    ),
                    const SizedBox(height: 30),
                    _HorizontalGames(
                      title: 'جدیدترین بازی‌های رایگان',
                      subtitle: 'مرتب‌شده بر اساس تاریخ انتشار',
                      games: data.newFreeGames,
                    ),
                    const SizedBox(height: 30),
                    _HorizontalGames(
                      title: 'تخفیف‌های واقعی PC',
                      subtitle: 'قیمت‌های زنده از فروشگاه‌های مختلف',
                      games: data.pcDeals,
                      showPrice: true,
                    ),
                  ],
                  const SizedBox(height: 30),
                  GameonSurface(
                    highlight: true,
                    onTap: () => _open(const NewsScreen()),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.newspaper_rounded, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('اخبار بازی', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              SizedBox(height: 4),
                              Text('ویجیاتو، دنیای بازی، PlayStation Blog و Xbox Wire', style: TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'داده‌های بازی از FreeToGame و CheapShark و خبرها از فیدهای واقعی رسانه‌ها دریافت می‌شوند.',
                    style: TextStyle(color: GameonColors.textSecondary, fontSize: 11.5, height: 1.6),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _platformLabel(String value) => switch (value) {
        'playstation' => 'پلی‌استیشن',
        'xbox' => 'ایکس‌باکس',
        'pc' => 'رایانه',
        'nintendo' => 'نینتندو',
        _ => value,
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.onCatalog, required this.onNews, required this.onSearch});

  final VoidCallback onCatalog;
  final VoidCallback onNews;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'GAMEON',
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.4),
        ),
        const Spacer(),
        IconButton.filledTonal(tooltip: 'کاتالوگ', onPressed: onCatalog, icon: const Icon(Icons.grid_view_rounded)),
        const SizedBox(width: 7),
        IconButton.filledTonal(tooltip: 'اخبار', onPressed: onNews, icon: const Icon(Icons.newspaper_rounded)),
        const SizedBox(width: 7),
        IconButton.filledTonal(tooltip: 'جستجو', onPressed: onSearch, icon: const Icon(Icons.search_rounded)),
      ],
    );
  }
}

class _RefreshCard extends StatelessWidget {
  const _RefreshCard({required this.updatedAt, required this.refreshing, required this.onRefresh});

  final DateTime updatedAt;
  final bool refreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return GameonSurface(
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: refreshing
                ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.sync_rounded, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('آخرین بروزرسانی', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(PersianDateTime.dateTime(updatedAt), style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: refreshing ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('بروزرسانی'),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onCatalog, required this.onSearch, required this.onNews});

  final VoidCallback onCatalog;
  final VoidCallback onSearch;
  final VoidCallback onNews;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, VoidCallback)>[
      (Icons.grid_view_rounded, 'کاتالوگ', onCatalog),
      (Icons.search_rounded, 'جستجو', onSearch),
      (Icons.newspaper_rounded, 'اخبار', onNews),
    ];
    return Row(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: entry.key == items.length - 1 ? 0 : 8),
            child: GameonSurface(
              onTap: item.$3,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Column(
                children: [
                  Icon(item.$1, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 7),
                  Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HorizontalGames extends StatelessWidget {
  const _HorizontalGames({
    required this.title,
    required this.subtitle,
    required this.games,
    this.showPrice = false,
  });

  final String title;
  final String subtitle;
  final List<GameSummary> games;
  final bool showPrice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 12),
        if (games.isEmpty)
          const GameonEmptyState(
            icon: Icons.hourglass_empty_rounded,
            title: 'موردی دریافت نشد',
            message: 'منبع واقعی در این بروزرسانی داده‌ای برنگرداند.',
          )
        else
          SizedBox(
            height: 232,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: games.take(12).length,
              separatorBuilder: (_, __) => const SizedBox(width: 11),
              itemBuilder: (context, index) => _GameCard(game: games[index], showPrice: showPrice),
            ),
          ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.showPrice});

  final GameSummary game;
  final bool showPrice;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: GameonSurface(
        padding: EdgeInsets.zero,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 108,
                width: double.infinity,
                child: game.thumbUrl == null
                    ? ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest)
                    : CachedNetworkImage(
                        imageUrl: game.thumbUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const GameonSkeleton(width: double.infinity, height: 108, radius: 0),
                        errorWidget: (_, __, ___) => ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        textDirection: TextDirection.ltr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                      ),
                      const Spacer(),
                      if (game.genre != null)
                        Text(game.genre!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: GameonColors.textSecondary, fontSize: 11.5)),
                      if (showPrice && game.salePrice != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              game.salePrice == 0 ? 'رایگان' : '\$${game.salePrice!.toStringAsFixed(2)}',
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                            ),
                            const Spacer(),
                            if ((game.discountPercent ?? 0) > 0)
                              Text('-${PersianDateTime.digits(game.discountPercent ?? 0)}٪', style: const TextStyle(color: Color(0xFF56E06E), fontWeight: FontWeight.w900, fontSize: 11.5)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
