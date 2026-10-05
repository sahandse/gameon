import 'package:flutter/material.dart';
import 'package:gameon/src/core/format/persian_datetime.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/sync/data_sync_service.dart';
import 'package:gameon/src/features/catalog/presentation/catalog_screen.dart';
import 'package:gameon/src/features/game/presentation/game_detail_screen.dart';
import 'package:gameon/src/features/news/presentation/news_screen.dart';
import 'package:gameon/src/features/search/presentation/game_search_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataSyncService _syncService = DataSyncService();
  late Future<DataSyncSnapshot> _future = _syncService.refresh();
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _future = _syncService.refresh();
    });
    try {
      await _future;
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<DataSyncSnapshot>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
            }
            if (snapshot.hasError) {
              return Center(
                child: FilledButton.tonalIcon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('تلاش دوباره'),
                ),
              );
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                children: [
                  Row(
                    children: [
                      Text('GAMEON', textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                      const Spacer(),
                      IconButton.filledTonal(
                        tooltip: 'کاتالوگ',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CatalogScreen())),
                        icon: const Icon(Icons.grid_view_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'اخبار',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NewsScreen())),
                        icon: const Icon(Icons.newspaper_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'جستجو',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GameSearchScreen())),
                        icon: const Icon(Icons.search_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _RefreshCard(
                    updatedAt: data.updatedAt,
                    refreshing: _refreshing,
                    onRefresh: _refresh,
                  ),
                  const SizedBox(height: 24),
                  Text('برای تو', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                    data.platforms.isEmpty ? 'پلتفرمی انتخاب نشده است.' : data.platforms.join(' • '),
                    style: const TextStyle(color: GameonColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CatalogScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: .18),
                            GameonColors.surface,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: .28)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.grid_view_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('کاتالوگ من', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                SizedBox(height: 5),
                                Text('رایگان، اشتراکی، پولی، تخفیف و به‌زودی', style: TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Section(title: 'تخفیف‌های واقعی رایانه', enabled: data.platforms.contains('pc'), deals: data.pcDeals),
                  const SizedBox(height: 28),
                  const _PendingSection(),
                ],
              ),
            );
          },
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameonColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameonColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: refreshing
                ? const Padding(
                    padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.sync_rounded, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('آخرین بروزرسانی', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  PersianDateTime.dateTime(updatedAt),
                  style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: refreshing ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: const Text('بروزرسانی'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.enabled, required this.deals});
  final String title;
  final bool enabled;
  final List<GameSummary> deals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(enabled ? 'داده زنده و واقعی' : 'برای نمایش، رایانه را انتخاب کن', style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 12),
        if (!enabled)
          const _Info(text: 'این بخش فقط برای کاربران رایانه فعال می‌شود.')
        else if (deals.isEmpty)
          const _Info(text: 'در حال حاضر تخفیف قابل نمایش دریافت نشد.')
        else
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: deals.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final game = deals[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game)),
                  ),
                  child: Container(
                    width: 170,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: GameonColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GameonColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(game.title, textDirection: TextDirection.ltr, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Row(
                          children: [
                            if ((game.discountPercent ?? 0) > 0)
                              Text('-${PersianDateTime.digits(game.discountPercent)}٪', style: const TextStyle(color: Color(0xFF56E06E), fontWeight: FontWeight.w900)),
                            const Spacer(),
                            if (game.salePrice != null)
                              Text(game.salePrice == 0 ? 'رایگان' : '\$${game.salePrice!.toStringAsFixed(2)}', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PendingSection extends StatelessWidget {
  const _PendingSection();

  @override
  Widget build(BuildContext context) {
    return const _Info(
      text: 'پلی‌استیشن، ایکس‌باکس و نینتندو تا اتصال منبع رسمی و قابل اتکا هیچ بازی، قیمت یا سرویس آزمایشی نمایش نمی‌دهند.',
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GameonColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameonColors.border),
      ),
      child: Text(text, style: const TextStyle(color: GameonColors.textSecondary, height: 1.65)),
    );
  }
}
