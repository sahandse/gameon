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
    setState(() { _refreshing = true; _future = _sync.refresh(); });
    try { await _future; if (mounted) GameonHaptics.confirm(); }
    finally { if (mounted) setState(() => _refreshing = false); }
  }

  void _open(Widget page) {
    GameonHaptics.tap();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: FutureBuilder<DataSyncSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const GameonPageSkeleton();
          if (snapshot.hasError || snapshot.data == null) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: GameonEmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'بروزرسانی انجام نشد',
                message: 'دریافت داده واقعی با مشکل روبه‌رو شد و هیچ داده ساختگی جایگزین نمی‌شود.',
                actionLabel: 'تلاش دوباره',
                onAction: _refresh,
              ),
            );
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              children: [
                GameonAnimatedIn(child: _Header(onCatalog: () => _open(const CatalogScreen()), onNews: () => _open(const NewsScreen()), onSearch: () => _open(const GameSearchScreen()))),
                const SizedBox(height: 22),
                GameonAnimatedIn(delay: const Duration(milliseconds: 60), child: _RefreshCard(updatedAt: data.updatedAt, refreshing: _refreshing, onRefresh: _refresh)),
                const SizedBox(height: 24),
                GameonAnimatedIn(
                  delay: const Duration(milliseconds: 110),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('برای تو', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 7),
                    Text(data.platforms.isEmpty ? 'پلتفرمی انتخاب نشده است.' : data.platforms.map(_platformLabel).join(' • '), style: const TextStyle(color: GameonColors.textSecondary)),
                  ]),
                ),
                const SizedBox(height: 18),
                GameonAnimatedIn(
                  delay: const Duration(milliseconds: 160),
                  child: GameonSurface(
                    highlight: true,
                    onTap: () => _open(const CatalogScreen()),
                    child: Row(children: [
                      _AccentIcon(Icons.grid_view_rounded),
                      const SizedBox(width: 14),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('کاتالوگ من', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        SizedBox(height: 5),
                        Text('رایگان، اشتراکی، پولی، تخفیف و به‌زودی', style: TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
                      ])),
                      Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                    ]),
                  ),
                ),
                const SizedBox(height: 28),
                GameonAnimatedIn(delay: const Duration(milliseconds: 210), child: _Deals(enabled: data.platforms.contains('pc'), deals: data.pcDeals)),
                const SizedBox(height: 28),
                const GameonAnimatedIn(
                  delay: Duration(milliseconds: 250),
                  child: GameonEmptyState(
                    icon: Icons.verified_user_outlined,
                    title: 'منبع معتبر، اولویت اول',
                    message: 'پلی‌استیشن، ایکس‌باکس و نینتندو تا اتصال منبع رسمی و قابل‌اتکا هیچ بازی، قیمت یا سرویس آزمایشی نمایش نمی‌دهند.',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  static String _platformLabel(String v) => switch (v) { 'playstation' => 'پلی‌استیشن', 'xbox' => 'ایکس‌باکس', 'pc' => 'رایانه', 'nintendo' => 'نینتندو', _ => v };
}

class _Header extends StatelessWidget {
  const _Header({required this.onCatalog, required this.onNews, required this.onSearch});
  final VoidCallback onCatalog, onNews, onSearch;
  @override
  Widget build(BuildContext context) => Row(children: [
    Text('GAMEON', textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.4)),
    const Spacer(),
    IconButton.filledTonal(tooltip: 'کاتالوگ', onPressed: onCatalog, icon: const Icon(Icons.grid_view_rounded)),
    const SizedBox(width: 7),
    IconButton.filledTonal(tooltip: 'اخبار', onPressed: onNews, icon: const Icon(Icons.newspaper_rounded)),
    const SizedBox(width: 7),
    IconButton.filledTonal(tooltip: 'جستجو', onPressed: onSearch, icon: const Icon(Icons.search_rounded)),
  ]);
}

class _AccentIcon extends StatelessWidget {
  const _AccentIcon(this.icon); final IconData icon;
  @override
  Widget build(BuildContext context) => Container(width: 52, height: 52, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .13), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: Theme.of(context).colorScheme.primary));
}

class _RefreshCard extends StatelessWidget {
  const _RefreshCard({required this.updatedAt, required this.refreshing, required this.onRefresh});
  final DateTime updatedAt; final bool refreshing; final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => GameonSurface(child: Row(children: [
    SizedBox(width: 44, height: 44, child: refreshing ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)) : _AccentIcon(Icons.sync_rounded)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('آخرین بروزرسانی', style: TextStyle(fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text(PersianDateTime.dateTime(updatedAt), style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
    ])),
    TextButton.icon(onPressed: refreshing ? null : onRefresh, icon: const Icon(Icons.refresh_rounded, size: 19), label: const Text('بروزرسانی')),
  ]));
}

class _Deals extends StatelessWidget {
  const _Deals({required this.enabled, required this.deals});
  final bool enabled; final List<GameSummary> deals;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('تخفیف‌های واقعی رایانه', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
    const SizedBox(height: 6),
    Text(enabled ? 'داده زنده و واقعی' : 'برای نمایش، رایانه را انتخاب کن', style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
    const SizedBox(height: 12),
    if (!enabled)
      const GameonEmptyState(icon: Icons.computer_rounded, title: 'رایانه انتخاب نشده', message: 'این بخش فقط برای کاربران رایانه فعال می‌شود.')
    else if (deals.isEmpty)
      const GameonEmptyState(icon: Icons.local_offer_outlined, title: 'تخفیفی دریافت نشد', message: 'در پاسخ فعلی منبع واقعی مورد قابل نمایشی وجود ندارد.')
    else
      SizedBox(height: 160, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: deals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final g = deals[i];
          return SizedBox(width: 178, child: GameonSurface(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: g))),
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.title, textDirection: TextDirection.ltr, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Row(children: [
                if ((g.discountPercent ?? 0) > 0) Text('-${PersianDateTime.digits(g.discountPercent)}٪', style: const TextStyle(color: Color(0xFF56E06E), fontWeight: FontWeight.w900)),
                const Spacer(),
                if (g.salePrice != null) Text(g.salePrice == 0 ? 'رایگان' : '\$${g.salePrice!.toStringAsFixed(2)}', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900)),
              ]),
            ]),
          ));
        },
      )),
  ]);
}
