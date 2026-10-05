import 'package:flutter/material.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/remote/cheapshark_api.dart';
import 'package:gameon/src/features/catalog/presentation/catalog_screen.dart';
import 'package:gameon/src/features/game/presentation/game_detail_screen.dart';
import 'package:gameon/src/features/news/presentation/news_screen.dart';
import 'package:gameon/src/features/search/presentation/game_search_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CheapSharkApi _api = CheapSharkApi();
  late Future<_HomeData> _future = _load();

  Future<_HomeData> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final platforms = prefs.getStringList('platforms') ?? const <String>[];
    final deals = platforms.contains('pc')
        ? await _api.fetchDeals(pageSize: 20)
        : const <GameSummary>[];
    return _HomeData(platforms, deals);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
            }
            if (snapshot.hasError) {
              return Center(
                child: FilledButton.tonal(
                  onPressed: () => setState(() => _future = _load()),
                  child: const Text('تلاش دوباره'),
                ),
              );
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => setState(() => _future = _load()),
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
                  const SizedBox(height: 26),
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
                                Text('رایگان، اشتراکی، پولی، تخفیف و بزودی', style: TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Section(title: 'تخفیف‌های واقعی PC', enabled: data.platforms.contains('pc'), deals: data.deals),
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

class _HomeData {
  const _HomeData(this.platforms, this.deals);
  final List<String> platforms;
  final List<GameSummary> deals;
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
        Text(enabled ? 'داده زنده از CheapShark' : 'برای نمایش، PC را انتخاب کن', style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 12),
        if (!enabled)
          const _Info(text: 'این بخش فقط برای کاربران PC فعال می‌شود.')
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
                              Text('-${game.discountPercent}%', style: const TextStyle(color: Color(0xFF56E06E), fontWeight: FontWeight.w900)),
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
      text: 'PlayStation، Xbox و Nintendo تا اتصال منبع رسمی و قابل اتکا هیچ بازی، قیمت یا سرویس دمو نمایش نمی‌دهند.',
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
