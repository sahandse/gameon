import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gameon/src/core/format/persian_datetime.dart';
import 'package:gameon/src/data/models/news_item.dart';
import 'package:gameon/src/data/remote/news_rss_api.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsRssApi _api = NewsRssApi();
  late Future<List<NewsItem>> _future = _api.fetchAll();
  String _filter = 'همه';
  DateTime? _updatedAt;

  static const _filters = <String>['همه', 'ایرانی', 'خارجی', 'پلی‌استیشن', 'ایکس‌باکس'];

  Future<void> _refresh() async {
    GameonHaptics.tap();
    final next = _api.fetchAll();
    setState(() => _future = next);
    await next;
    if (!mounted) return;
    setState(() => _updatedAt = DateTime.now());
    GameonHaptics.confirm();
  }

  List<NewsItem> _filtered(List<NewsItem> items) {
    return switch (_filter) {
      'ایرانی' => items.where((e) => e.isIranian).toList(),
      'خارجی' => items.where((e) => !e.isIranian).toList(),
      'پلی‌استیشن' => items.where((e) => e.source == 'PlayStation Blog').toList(),
      'ایکس‌باکس' => items.where((e) => e.source == 'Xbox Wire').toList(),
      _ => items,
    };
  }

  Future<void> _openSource(NewsItem item) async {
    final uri = Uri.tryParse(item.link);
    if (uri == null) return;
    GameonHaptics.tap();
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اخبار بازی'),
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: FutureBuilder<List<NewsItem>>(
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
                title: 'اخبار دریافت نشد',
                message: 'اتصال به فیدهای خبری واقعی برقرار نشد.',
                actionLabel: 'تلاش دوباره',
                onAction: _refresh,
              ),
            );
          }

          final all = snapshot.data ?? const <NewsItem>[];
          final items = _filtered(all);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
              children: [
                GameonAnimatedIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ایران + منابع رسمی خارجی', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 7),
                      const Text(
                        'ویجیاتو و دنیای بازی در کنار PlayStation Blog و Xbox Wire. تاریخ و ساعت داخل Gameon به‌صورت شمسی و با اعداد فارسی نمایش داده می‌شود.',
                        style: TextStyle(color: GameonColors.textSecondary, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GameonSurface(
                  child: Row(
                    children: [
                      Icon(Icons.sync_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _updatedAt == null ? 'فیدها هنگام ورود دریافت شدند' : 'آخرین بروزرسانی: ${PersianDateTime.dateTime(_updatedAt!)}',
                          style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5),
                        ),
                      ),
                      TextButton(onPressed: _refresh, child: const Text('بروزرسانی')),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _filter == filter,
                          onSelected: (_) {
                            GameonHaptics.tap();
                            setState(() => _filter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                if (items.isEmpty)
                  const GameonEmptyState(
                    icon: Icons.newspaper_rounded,
                    title: 'خبری در این فیلتر نیست',
                    message: 'یک فیلتر دیگر انتخاب کن یا فیدها را بروزرسانی کن.',
                  )
                else
                  ...items.take(60).toList().asMap().entries.map((entry) {
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GameonAnimatedIn(
                        delay: Duration(milliseconds: 20 * entry.key.clamp(0, 8)),
                        child: _NewsCard(item: item, onTap: () => _openSource(item)),
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                const Text(
                  'برای حفظ دقت، خبر خارجی با متن اصلی منبع نمایش داده می‌شود؛ ترجمه ساختگی به آن اضافه نمی‌شود.',
                  style: TextStyle(color: GameonColors.textSecondary, fontSize: 11.5, height: 1.6),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GameonSurface(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null)
              SizedBox(
                width: double.infinity,
                height: 170,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const GameonSkeleton(width: double.infinity, height: 170, radius: 0),
                  errorWidget: (_, __, ___) => ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(item.source, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                      ),
                      const Spacer(),
                      if (item.publishedAt != null)
                        Text(PersianDateTime.dateTime(item.publishedAt!), style: const TextStyle(color: GameonColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    item.title,
                    textDirection: item.isIranian ? TextDirection.rtl : TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, height: 1.4),
                  ),
                  if (item.summary != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.summary!,
                      textDirection: item.isIranian ? TextDirection.rtl : TextDirection.ltr,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: GameonColors.textSecondary, height: 1.55),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 17, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('مشاهده خبر در منبع', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
