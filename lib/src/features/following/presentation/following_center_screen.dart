import 'package:flutter/material.dart';
import 'package:gameon/src/core/format/persian_datetime.dart';
import 'package:gameon/src/data/local/game_library_store.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/sync/data_sync_service.dart';
import 'package:gameon/src/features/game/presentation/game_detail_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FollowingCenterScreen extends StatefulWidget {
  const FollowingCenterScreen({super.key});
  @override
  State<FollowingCenterScreen> createState() => _FollowingCenterScreenState();
}

class _FollowingCenterScreenState extends State<FollowingCenterScreen> {
  final GameLibraryStore _store = GameLibraryStore();
  final DataSyncService _syncService = DataSyncService();
  late Future<_FollowingState> _future = _load();
  bool _refreshing = false;

  Future<_FollowingState> _load() async {
    final games = await _store.followed();
    final prefs = await SharedPreferences.getInstance();
    final lastUpdated = await _syncService.lastUpdated();
    return _FollowingState(
      games: games,
      lastUpdated: lastUpdated,
      releaseAlerts: prefs.getBool('alert_release') ?? true,
      priceAlerts: prefs.getBool('alert_price') ?? true,
      serviceAlerts: prefs.getBool('alert_service') ?? true,
      updateAlerts: prefs.getBool('alert_update') ?? true,
    );
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    GameonHaptics.tap();
    setState(() => _refreshing = true);
    try {
      await _syncService.refresh();
      if (mounted) {
        setState(() => _future = _load());
        GameonHaptics.confirm();
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _setAlert(String key, bool value) async {
    GameonHaptics.tap();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دنبال‌شده‌ها')),
      body: FutureBuilder<_FollowingState>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const GameonPageSkeleton();
          final state = snapshot.data ?? const _FollowingState(games: []);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                GameonAnimatedIn(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('مرکز دنبال‌کردن', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('هشدار فقط برای تغییر واقعی از منبع معتبر فعال می‌شود.', style: TextStyle(color: GameonColors.textSecondary, height: 1.6)),
                ])),
                const SizedBox(height: 16),
                GameonAnimatedIn(delay: const Duration(milliseconds: 60), child: _UpdateStatus(lastUpdated: state.lastUpdated, refreshing: _refreshing, onRefresh: _refresh)),
                const SizedBox(height: 20),
                GameonAnimatedIn(delay: const Duration(milliseconds: 100), child: _AlertTile(title: 'انتشار بازی', icon: Icons.event_available_rounded, value: state.releaseAlerts, onChanged: (v) => _setAlert('alert_release', v))),
                GameonAnimatedIn(delay: const Duration(milliseconds: 130), child: _AlertTile(title: 'تغییر قیمت و تخفیف', icon: Icons.local_offer_rounded, value: state.priceAlerts, onChanged: (v) => _setAlert('alert_price', v))),
                GameonAnimatedIn(delay: const Duration(milliseconds: 160), child: _AlertTile(title: 'ورود یا خروج از سرویس اشتراکی', icon: Icons.subscriptions_rounded, value: state.serviceAlerts, onChanged: (v) => _setAlert('alert_service', v))),
                GameonAnimatedIn(delay: const Duration(milliseconds: 190), child: _AlertTile(title: 'بروزرسانی مهم بازی', icon: Icons.system_update_alt_rounded, value: state.updateAlerts, onChanged: (v) => _setAlert('alert_update', v))),
                const SizedBox(height: 24),
                Text('بازی‌های دنبال‌شده', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                if (state.games.isEmpty)
                  const GameonEmptyState(icon: Icons.notifications_none_rounded, title: 'هنوز بازی‌ای را دنبال نکردی', message: 'از صفحه هر بازی دکمه دنبال‌کردن را بزن تا اینجا نمایش داده شود.')
                else
                  ...state.games.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GameonAnimatedIn(delay: Duration(milliseconds: 25 * entry.key.clamp(0, 8)), child: _GameTile(game: entry.value)),
                  )),
                const SizedBox(height: 24),
                Text('تقویم انتشار', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                const GameonEmptyState(
                  icon: Icons.calendar_month_rounded,
                  title: 'تقویم آماده اتصال داده است',
                  message: 'فقط تاریخ‌های انتشار تأییدشده نمایش داده می‌شوند. همه تاریخ‌ها شمسی، با نام ماه و اعداد فارسی خواهند بود و هیچ تاریخ حدسی اضافه نمی‌شود.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FollowingState {
  const _FollowingState({required this.games, this.lastUpdated, this.releaseAlerts = true, this.priceAlerts = true, this.serviceAlerts = true, this.updateAlerts = true});
  final List<GameSummary> games;
  final DateTime? lastUpdated;
  final bool releaseAlerts, priceAlerts, serviceAlerts, updateAlerts;
}

class _UpdateStatus extends StatelessWidget {
  const _UpdateStatus({required this.lastUpdated, required this.refreshing, required this.onRefresh});
  final DateTime? lastUpdated; final bool refreshing; final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => GameonSurface(child: Row(children: [
    Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary),
    const SizedBox(width: 10),
    Expanded(child: Text(lastUpdated == null ? 'هنوز بروزرسانی موفق ثبت نشده است' : 'آخرین بروزرسانی: ${PersianDateTime.dateTime(lastUpdated!)}', style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5))),
    IconButton(tooltip: 'بروزرسانی', onPressed: refreshing ? null : onRefresh, icon: refreshing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded)),
  ]));
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.title, required this.icon, required this.value, required this.onChanged});
  final String title; final IconData icon; final bool value; final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GameonSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        value: value,
        onChanged: onChanged,
      ),
    ),
  );
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game}); final GameSummary game;
  @override
  Widget build(BuildContext context) => GameonSurface(
    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game))),
    padding: const EdgeInsets.all(16),
    child: Row(children: [
      Icon(Icons.notifications_active_rounded, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 12),
      Expanded(child: Text(game.title, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800))),
      const Icon(Icons.chevron_left_rounded, color: GameonColors.textSecondary),
    ]),
  );
}
