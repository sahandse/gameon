import 'package:flutter/material.dart';
import 'package:gameon/src/core/format/persian_datetime.dart';
import 'package:gameon/src/data/sync/data_sync_service.dart';
import 'package:gameon/src/theme/gameon_theme.dart';

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
    setState(() => _refreshing = true);
    try {
      final snapshot = await _syncService.refresh();
      if (mounted) setState(() => _updatedAt = snapshot.updatedAt);
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
            Text('اخبار بازی، کاملاً فارسی', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'منابع رسمی پلتفرم‌ها و سایت‌های ایرانی تأییدشده اینجا تجمیع می‌شوند. هیچ خبر آزمایشی یا ساختگی نمایش داده نمی‌شود.',
              style: TextStyle(color: GameonColors.textSecondary, height: 1.7),
            ),
            const SizedBox(height: 18),
            _UpdateStatus(updatedAt: _updatedAt, refreshing: _refreshing, onRefresh: _refresh),
            const SizedBox(height: 22),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _NewsFilter('همه'),
                _NewsFilter('پلی‌استیشن'),
                _NewsFilter('ایکس‌باکس'),
                _NewsFilter('رایانه'),
                _NewsFilter('نینتندو'),
                _NewsFilter('گیم پس'),
                _NewsFilter('پلی‌استیشن پلاس'),
              ],
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: GameonColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: GameonColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.newspaper_rounded, size: 34, color: GameonColors.accentCyan),
                  SizedBox(height: 14),
                  Text('منبع خبر هنوز متصل نشده', style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 8),
                  Text(
                    'پس از اتصال منبع رسمی و سایت ایرانی تأییدشده، عنوان، تصویر، تاریخ و ساعت شمسی انتشار، خلاصه فارسی، منبع و بازی مرتبط اینجا نمایش داده می‌شود.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: GameonColors.textSecondary, height: 1.7),
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

class _UpdateStatus extends StatelessWidget {
  const _UpdateStatus({required this.updatedAt, required this.refreshing, required this.onRefresh});
  final DateTime? updatedAt;
  final bool refreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameonColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GameonColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              updatedAt == null
                  ? 'هنوز بروزرسانی موفق ثبت نشده است'
                  : 'آخرین بروزرسانی: ${PersianDateTime.dateTime(updatedAt!)}',
              style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5),
            ),
          ),
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: refreshing ? null : onRefresh,
            icon: refreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _NewsFilter extends StatelessWidget {
  const _NewsFilter(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: GameonColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: GameonColors.border),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
      );
}
