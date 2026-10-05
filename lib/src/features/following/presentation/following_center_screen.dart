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
    DataSyncSnapshot? sync;
    try {
      sync = await _syncService.refresh();
    } catch (_) {
      sync = null;
    }

    final dated = <String, GameSummary>{};
    for (final game in <GameSummary>[
      ...games,
      ...?sync?.newFreeGames,
    ]) {
      if (game.releaseDate != null) dated[game.id] = game;
    }
    final calendar = dated.values.toList()
      ..sort((a, b) => b.releaseDate!.compareTo(a.releaseDate!));

    return _FollowingState(
      games: games,
      calendarGames: calendar.take(30).toList(),
      lastUpdated: sync?.updatedAt ?? await _syncService.lastUpdated(),
      usingCachedData: sync?.usingCachedData ?? false,
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
      setState(() => _future = _load());
      await _future;
      if (mounted) GameonHaptics.confirm();
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
      appBar: AppBar(title: const Text('دنبال‌شده‌ها و تقویم')),
      body: FutureBuilder<_FollowingState>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const GameonPageSkeleton();
          }
          final state = snapshot.data ?? const _FollowingState(games: []);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                GameonAnimatedIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرکز دنبال‌کردن',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'تاریخ‌ها و تغییرات فقط از داده واقعی نمایش داده می‌شوند.',
                        style: TextStyle(
                          color: GameonColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _UpdateStatus(
                  lastUpdated: state.lastUpdated,
                  refreshing: _refreshing,
                  cached: state.usingCachedData,
                  onRefresh: _refresh,
                ),
                const SizedBox(height: 20),
                _AlertTile(
                  title: 'انتشار بازی',
                  icon: Icons.event_available_rounded,
                  value: state.releaseAlerts,
                  onChanged: (v) => _setAlert('alert_release', v),
                ),
                _AlertTile(
                  title: 'تغییر قیمت و تخفیف',
                  icon: Icons.local_offer_rounded,
                  value: state.priceAlerts,
                  onChanged: (v) => _setAlert('alert_price', v),
                ),
                _AlertTile(
                  title: 'ورود یا خروج از سرویس اشتراکی',
                  icon: Icons.subscriptions_rounded,
                  value: state.serviceAlerts,
                  onChanged: (v) => _setAlert('alert_service', v),
                ),
                _AlertTile(
                  title: 'بروزرسانی مهم بازی',
                  icon: Icons.system_update_alt_rounded,
                  value: state.updateAlerts,
                  onChanged: (v) => _setAlert('alert_update', v),
                ),
                const SizedBox(height: 24),
                Text(
                  'بازی‌های دنبال‌شده',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (state.games.isEmpty)
                  const GameonSurface(
                    child: Text(
                      'بازی‌ای را دنبال نکرده‌ای؛ از صفحه هر بازی می‌توانی Follow را فعال کنی.',
                      style: TextStyle(
                        color: GameonColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  )
                else
                  ...state.games.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GameonAnimatedIn(
                            delay: Duration(
                              milliseconds: 25 * entry.key.clamp(0, 8),
                            ),
                            child: _GameTile(game: entry.value),
                          ),
                        ),
                      ),
                const SizedBox(height: 26),
                Text(
                  'تقویم انتشار',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'تاریخ‌های تأییدشده موجود در منابع بازی؛ همه تاریخ‌ها شمسی نمایش داده می‌شوند.',
                  style: TextStyle(
                    color: GameonColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.calendarGames.isEmpty)
                  const GameonSurface(
                    child: Text(
                      'در داده ذخیره‌شده فعلی تاریخ انتشار معتبری وجود ندارد. با بروزرسانی بعدی دوباره بررسی می‌شود.',
                      style: TextStyle(
                        color: GameonColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  )
                else
                  ...state.calendarGames.map(
                    (game) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CalendarTile(game: game),
                    ),
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
  const _FollowingState({
    required this.games,
    this.calendarGames = const <GameSummary>[],
    this.lastUpdated,
    this.usingCachedData = false,
    this.releaseAlerts = true,
    this.priceAlerts = true,
    this.serviceAlerts = true,
    this.updateAlerts = true,
  });

  final List<GameSummary> games;
  final List<GameSummary> calendarGames;
  final DateTime? lastUpdated;
  final bool usingCachedData;
  final bool releaseAlerts;
  final bool priceAlerts;
  final bool serviceAlerts;
  final bool updateAlerts;
}

class _UpdateStatus extends StatelessWidget {
  const _UpdateStatus({
    required this.lastUpdated,
    required this.refreshing,
    required this.cached,
    required this.onRefresh,
  });

  final DateTime? lastUpdated;
  final bool refreshing;
  final bool cached;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => GameonSurface(
        child: Row(
          children: [
            Icon(
              cached ? Icons.inventory_2_outlined : Icons.calendar_month_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lastUpdated == null
                    ? 'هنوز بروزرسانی موفق ثبت نشده است'
                    : '${cached ? 'داده کش‌شده' : 'آخرین بروزرسانی'}: ${PersianDateTime.dateTime(lastUpdated!)}',
                style: const TextStyle(
                  color: GameonColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ),
            IconButton(
              tooltip: 'بروزرسانی',
              onPressed: refreshing ? null : onRefresh,
              icon: refreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      );
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GameonSurface(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            value: value,
            onChanged: onChanged,
          ),
        ),
      );
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game});
  final GameSummary game;

  @override
  Widget build(BuildContext context) => GameonSurface(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.notifications_active_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                game.title,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: GameonColors.textSecondary,
            ),
          ],
        ),
      );
}

class _CalendarTile extends StatelessWidget {
  const _CalendarTile({required this.game});
  final GameSummary game;

  @override
  Widget build(BuildContext context) {
    final date = game.releaseDate!;
    final isFuture = date.isAfter(DateTime.now());
    return GameonSurface(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  PersianDateTime.digits(date.day),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  PersianDateTime.date(date),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GameonColors.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  textDirection: TextDirection.ltr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  '${PersianDateTime.date(date)} • ${isFuture ? 'در راه' : 'منتشر شده'}',
                  style: TextStyle(
                    color: isFuture
                        ? Theme.of(context).colorScheme.primary
                        : GameonColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left_rounded),
        ],
      ),
    );
  }
}
