import 'package:flutter/material.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/remote/cheapshark_api.dart';
import 'package:gameon/src/features/game/presentation/game_detail_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final CheapSharkApi _api = CheapSharkApi();
  late Future<_CatalogData> _future = _load();
  String? _activePlatform;
  int _segment = 0;

  static const _segments = <String>[
    'رایگان',
    'اشتراکی',
    'پولی',
    'تخفیف',
    'بزودی',
  ];

  Future<_CatalogData> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final platforms = prefs.getStringList('platforms') ?? const <String>[];
    final pcDeals = platforms.contains('pc')
        ? await _api.fetchDeals(pageSize: 40)
        : const <GameSummary>[];
    return _CatalogData(platforms: platforms, pcDeals: pcDeals);
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
            final selected = _activePlatform ?? (data.platforms.isNotEmpty ? data.platforms.first : null);
            final deals = selected == 'pc' ? data.pcDeals : const <GameSummary>[];
            final filteredDeals = switch (_segment) {
              0 => deals.where((g) => g.isFree).toList(),
              3 => deals.where((g) => g.isDiscounted).toList(),
              _ => const <GameSummary>[],
            };

            return RefreshIndicator(
              onRefresh: () async => setState(() => _future = _load()),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    'همه چیز براساس پلتفرم تو',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gameon فقط داده‌ای را نشان می‌دهد که از منبع واقعی دریافت شده باشد.',
                    style: TextStyle(color: GameonColors.textSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  if (data.platforms.isEmpty)
                    const _SourceState(text: 'در تنظیمات هنوز پلتفرمی انتخاب نشده است.')
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: data.platforms.map((platform) {
                          final isSelected = selected == platform;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text(_platformLabel(platform)),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _activePlatform = platform),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 18),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_segments.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(_segments[index]),
                            selected: _segment == index,
                            onSelected: (_) => setState(() => _segment = index),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildContent(selected, filteredDeals),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(String? platform, List<GameSummary> deals) {
    if (platform == null) {
      return const _SourceState(text: 'یک پلتفرم انتخاب کن.');
    }

    if (platform == 'pc' && (_segment == 0 || _segment == 3)) {
      if (deals.isEmpty) {
        return _SourceState(
          text: _segment == 0
              ? 'در پاسخ فعلی CheapShark بازی رایگان قابل نمایش پیدا نشد.'
              : 'در پاسخ فعلی CheapShark تخفیف قابل نمایش پیدا نشد.',
        );
      }
      return Column(
        children: deals.map((game) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _GameTile(game: game),
        )).toList(),
      );
    }

    final sourceText = switch (platform) {
      'playstation' => _segment == 1
          ? 'PS Plus از منبع رسمی PlayStation نمایش داده خواهد شد.'
          : 'کاتالوگ PlayStation فقط بعد از اتصال پایدار به منبع رسمی فروشگاه نمایش داده می‌شود.',
      'xbox' => _segment == 1
          ? 'Game Pass از منبع رسمی Xbox با دسته‌های Recently Added، Coming و Leaving Soon نمایش داده خواهد شد.'
          : 'کاتالوگ Xbox فقط بعد از اتصال پایدار به منبع رسمی نمایش داده می‌شود.',
      'nintendo' => _segment == 1
          ? 'Nintendo Switch Online، Classics و Game Trials از منبع رسمی Nintendo نمایش داده خواهند شد.'
          : 'کاتالوگ Nintendo فقط بعد از اتصال پایدار به منبع رسمی نمایش داده می‌شود.',
      'pc' => 'این دسته هنوز منبع عمومی واقعی متصل ندارد.',
      _ => 'برای این بخش هنوز منبع معتبر متصل نشده است.',
    };

    return _SourceState(text: sourceText);
  }

  String _platformLabel(String value) => switch (value) {
    'playstation' => 'PlayStation',
    'xbox' => 'Xbox',
    'pc' => 'PC',
    'nintendo' => 'Nintendo',
    _ => value,
  };
}

class _CatalogData {
  const _CatalogData({required this.platforms, required this.pcDeals});
  final List<String> platforms;
  final List<GameSummary> pcDeals;
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game});
  final GameSummary game;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GameonColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GameonColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.title, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (game.discountPercent != null && game.discountPercent! > 0)
                        Text('-${game.discountPercent}%', style: const TextStyle(color: Color(0xFF56E06E), fontWeight: FontWeight.w900)),
                      if (game.discountPercent != null && game.discountPercent! > 0) const SizedBox(width: 10),
                      if (game.salePrice != null)
                        Text(game.salePrice == 0 ? 'رایگان' : '\$${game.salePrice!.toStringAsFixed(2)}', textDirection: TextDirection.ltr),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: GameonColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SourceState extends StatelessWidget {
  const _SourceState({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GameonColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GameonColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined, color: GameonColors.accentCyan),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: GameonColors.textSecondary, height: 1.7))),
        ],
      ),
    );
  }
}
