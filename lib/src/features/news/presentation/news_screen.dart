import 'package:flutter/material.dart';
import 'package:gameon/src/core/format/persian_datetime.dart';
import 'package:gameon/src/data/sync/data_sync_service.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final DataSyncService _syncService = DataSyncService();
  DateTime? _updatedAt;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadLastUpdated();
  }

  Future<void> _loadLastUpdated() async {
    final value = await _syncService.lastUpdated();
    if (mounted) setState(() => _updatedAt = value);
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    GameonHaptics.tap();
    setState(() => _refreshing = true);
    try {
      final snapshot = await _syncService.refresh();
      if (mounted) {
        setState(() => _updatedAt = snapshot.updatedAt);
        GameonHaptics.confirm();
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اخبار')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            GameonAnimatedIn(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('اخبار بازی، کاملاً فارسی', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('منابع رسمی پلتفرم‌ها و سایت‌های ایرانی تأییدشده اینجا تجمیع می‌شوند. هیچ خبر آزمایشی یا ساختگی نمایش داده نمی‌شود.', style: TextStyle(color: GameonColors.textSecondary, height: 1.7)),
              ]),
            ),
            const SizedBox(height: 18),
            GameonAnimatedIn(delay: const Duration(milliseconds: 70), child: _UpdateStatus(updatedAt: _updatedAt, refreshing: _refreshing, onRefresh: _refresh)),
            const SizedBox(height: 22),
            const GameonAnimatedIn(
              delay: Duration(milliseconds: 120),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _NewsFilter('همه'), _NewsFilter('پلی‌استیشن'), _NewsFilter('ایکس‌باکس'), _NewsFilter('رایانه'), _NewsFilter('نینتندو'), _NewsFilter('گیم پس'), _NewsFilter('پلی‌استیشن پلاس'),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const GameonAnimatedIn(
              delay: Duration(milliseconds: 170),
              child: GameonEmptyState(
                icon: Icons.newspaper_rounded,
                title: 'منبع خبر هنوز متصل نشده',
                message: 'پس از اتصال منبع رسمی و سایت ایرانی تأییدشده، عنوان، تصویر، تاریخ و ساعت شمسی انتشار، خلاصه فارسی، منبع و بازی مرتبط اینجا نمایش داده می‌شود.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateStatus extends StatelessWidget {
  const _UpdateStatus({required this.updatedAt, required this.refreshing, required this.onRefresh});
  final DateTime? updatedAt;
  final bool refreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => GameonSurface(
        child: Row(children: [
          Icon(Icons.schedule_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              updatedAt == null ? 'هنوز بروزرسانی موفق ثبت نشده است' : 'آخرین بروزرسانی: ${PersianDateTime.dateTime(updatedAt!)}',
              style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5),
            ),
          ),
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: refreshing ? null : onRefresh,
            icon: refreshing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded),
          ),
        ]),
      );
}

class _NewsFilter extends StatelessWidget {
  const _NewsFilter(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: .15)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
      );
}
