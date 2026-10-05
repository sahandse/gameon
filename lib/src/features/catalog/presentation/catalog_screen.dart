import 'package:flutter/material.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/remote/cheapshark_api.dart';
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
  final CheapSharkApi _api = CheapSharkApi();
  late Future<_CatalogData> _future = _load();
  String? _activePlatform;
  int _segment = 0;

  static const _segments = <String>['رایگان', 'اشتراکی', 'پولی', 'تخفیف', 'به‌زودی'];

  Future<_CatalogData> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final platforms = prefs.getStringList('platforms') ?? const <String>[];
    final pcDeals = platforms.contains('pc')
        ? await _api.fetchDeals(pageSize: 40)
        : const <GameSummary>[];
    return _CatalogData(platforms: platforms, pcDeals: pcDeals);
  }

  Future<void> _refresh() async {
    GameonHaptics.tap();
    setState(() => _future = _load());
    await _future;
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
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: GameonEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'کاتالوگ بروزرسانی نشد',
                  message: 'دریافت داده واقعی ناموفق بود.',
                  actionLabel: 'تلاش دوباره',
                  onAction: _refresh,
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
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  GameonAnimatedIn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('همه‌چیز براساس پلتفرم تو', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        const Text('فقط داده واقعی نمایش داده می‌شود؛ بخش‌های بدون منبع معتبر با وضعیت شفاف مشخص هستند.', style: TextStyle(color: GameonColors.textSecondary, height: 1.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (data.platforms.isEmpty)
                    const GameonEmptyState(
                      icon: Icons.devices_other_rounded,
                      title: 'پلتفرمی انتخاب نشده',
                      message: 'برای ساخت کاتالوگ شخصی، ابتدا یک پلتفرم انتخاب کن.',
                    )
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
                              onSelected: (_) {
                                GameonHaptics.tap();
                                setState(() => _activePlatform = platform);
                              },
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
                            onSelected: (_) {
                              GameonHaptics.tap();
                              setState(() => _segment = index);
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GameonAnimatedIn(
                    key: ValueKey('$selected-$_segment'),
                    child: _buildContent(selected, filteredDeals),
                  ),
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
      return const GameonEmptyState(icon: Icons.touch_app_rounded, title: 'پلتفرم را انتخاب کن', message: 'یکی از پلتفرم‌ها را برای دیدن کاتالوگ انتخاب کن.');
    }

    if (platform == 'pc' && (_segment == 0 || _segment == 3)) {
      if (deals.isEmpty) {
        return GameonEmptyState(
          icon: _segment == 0 ? Icons.bolt_rounded : Icons.local_offer_outlined,
          title: _segment == 0 ? 'بازی رایگانی پیدا نشد' : 'تخفیفی پیدا نشد',
          message: 'در پاسخ فعلی منبع واقعی، مورد قابل نمایشی وجود ندارد.',
        );
      }
      return Column(
        children: deals.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GameonAnimatedIn(
                delay: Duration(milliseconds: 30 * entry.key.clamp(0, 8)),
                child: _GameTile(game: entry.value),
              ),
            )).toList(),
      );
    }

    final sourceText = switch (platform) {
      'playstation' => _segment == 1
          ? 'پلی‌استیشن پلاس فقط بعد از اتصال پایدار به منبع رسمی نمایش داده می‌شود.'
          : 'کاتالوگ پلی‌استیشن فقط بعد از اتصال پایدار به منبع رسمی فروشگاه نمایش داده می‌شود.',
      'xbox' => _segment == 1
          ? 'گیم پس از منبع رسمی ایکس‌باکس با دسته‌های افزوده‌شده، در راه و خروج نزدیک نمایش داده خواهد شد.'
          : 'کاتالوگ ایکس‌باکس فقط بعد از اتصال پایدار به منبع رسمی نمایش داده می‌شود.',
      'nintendo' => _segment == 1
          ? 'Nintendo Switch Online، Classics و Game Trials از منبع رسمی نینتندو نمایش داده خواهند شد.'
          : 'کاتالوگ نینتندو فقط بعد از اتصال پایدار به منبع رسمی نمایش داده می‌شود.',
      'pc' => 'این دسته هنوز منبع عمومی واقعی متصل ندارد.',
      _ => 'برای این بخش هنوز منبع معتبر متصل نشده است.',
    };

    return GameonEmptyState(
      icon: Icons.verified_outlined,
      title: 'منتظر منبع معتبر',
      message: sourceText,
    );
  }

  String _platformLabel(String value) => switch (value) {
    'playstation' => 'پلی‌استیشن',
    'xbox' => 'ایکس‌باکس',
    'pc' => 'رایانه',
    'nintendo' => 'نینتندو',
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
    return GameonSurface(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.title, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 9),
                Row(
                  children: [
                    if (game.discountPercent != null && game.discountPercent! > 0)
                      Text('-${game.discountPercent}٪', style: const TextStyle(color: Color(0xFF56E06E), fontWeight: FontWeight.w900)),
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
    );
  }
}
