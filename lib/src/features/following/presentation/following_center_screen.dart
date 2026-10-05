import 'package:flutter/material.dart';
import 'package:gameon/src/data/local/game_library_store.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/features/game/presentation/game_detail_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FollowingCenterScreen extends StatefulWidget {
  const FollowingCenterScreen({super.key});

  @override
  State<FollowingCenterScreen> createState() => _FollowingCenterScreenState();
}

class _FollowingCenterScreenState extends State<FollowingCenterScreen> {
  final GameLibraryStore _store = GameLibraryStore();
  late Future<_FollowingState> _future = _load();

  Future<_FollowingState> _load() async {
    final games = await _store.followed();
    final prefs = await SharedPreferences.getInstance();
    return _FollowingState(
      games: games,
      releaseAlerts: prefs.getBool('alert_release') ?? true,
      priceAlerts: prefs.getBool('alert_price') ?? true,
      serviceAlerts: prefs.getBool('alert_service') ?? true,
      updateAlerts: prefs.getBool('alert_update') ?? true,
    );
  }

  Future<void> _setAlert(String key, bool value) async {
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
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
          }
          final state = snapshot.data ?? const _FollowingState(games: []);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text('مرکز دنبال‌کردن', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('هشدارها فقط زمانی فعال می‌شوند که تغییر واقعی از منبع معتبر دریافت شود.', style: TextStyle(color: GameonColors.textSecondary, height: 1.6)),
              const SizedBox(height: 22),
              _AlertTile(title: 'انتشار بازی', value: state.releaseAlerts, onChanged: (v) => _setAlert('alert_release', v)),
              _AlertTile(title: 'تغییر قیمت و تخفیف', value: state.priceAlerts, onChanged: (v) => _setAlert('alert_price', v)),
              _AlertTile(title: 'ورود یا خروج از سرویس اشتراکی', value: state.serviceAlerts, onChanged: (v) => _setAlert('alert_service', v)),
              _AlertTile(title: 'آپدیت مهم بازی', value: state.updateAlerts, onChanged: (v) => _setAlert('alert_update', v)),
              const SizedBox(height: 26),
              Text('بازی‌های دنبال‌شده', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              if (state.games.isEmpty)
                const _InfoCard(text: 'هنوز بازی‌ای را دنبال نکردی.')
              else
                ...state.games.map((game) => _GameTile(game: game)),
              const SizedBox(height: 26),
              Text('تقویم انتشار', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const _InfoCard(text: 'تقویم فقط تاریخ‌های انتشار تأییدشده را نمایش می‌دهد. تا اتصال منبع کامل انتشار، هیچ تاریخ دمو یا حدسی اضافه نمی‌شود.'),
            ],
          );
        },
      ),
    );
  }
}

class _FollowingState {
  const _FollowingState({
    required this.games,
    this.releaseAlerts = true,
    this.priceAlerts = true,
    this.serviceAlerts = true,
    this.updateAlerts = true,
  });

  final List<GameSummary> games;
  final bool releaseAlerts;
  final bool priceAlerts;
  final bool serviceAlerts;
  final bool updateAlerts;
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.title, required this.value, required this.onChanged});
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: GameonColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GameonColors.border),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game});
  final GameSummary game;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game))),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GameonColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GameonColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: GameonColors.accentCyan),
              const SizedBox(width: 12),
              Expanded(child: Text(game.title, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800))),
              const Icon(Icons.chevron_left_rounded, color: GameonColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
