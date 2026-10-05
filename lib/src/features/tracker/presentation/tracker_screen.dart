import 'package:flutter/material.dart';
import 'package:gameon/src/data/remote/tracker_network_api.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final TrackerNetworkApi _api = TrackerNetworkApi();
  final TextEditingController _player = TextEditingController();
  String _platform = 'psn';
  PlayerStats? _stats;
  String? _message;
  bool _loading = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final id = _player.text.trim();
    if (id.isEmpty || _loading) return;
    GameonHaptics.tap();
    setState(() {
      _loading = true;
      _message = null;
      _stats = null;
    });
    try {
      final stats = await _api.fetchApexProfile(platform: _platform, playerId: id);
      if (mounted) {
        setState(() => _stats = stats);
        GameonHaptics.confirm();
      }
    } on TrackerConfigurationException {
      if (mounted) setState(() => _message = 'کلید Tracker Network هنوز برای این نسخه تنظیم نشده است.');
    } on TrackerDataException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'دریافت آمار واقعی بازیکن ناموفق بود.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رتبه و آمار')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          GameonAnimatedIn(
            child: GameonSurface(
              highlight: true,
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.leaderboard_rounded, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Apex Legends', textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        const Text('ارائه‌دهنده واقعی • بدون آمار ساختگی', style: TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          GameonAnimatedIn(
            delay: const Duration(milliseconds: 70),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'psn', label: Text('PSN')),
                ButtonSegment(value: 'xbl', label: Text('ایکس‌باکس')),
                ButtonSegment(value: 'origin', label: Text('رایانه')),
              ],
              selected: {_platform},
              onSelectionChanged: (value) {
                GameonHaptics.tap();
                setState(() => _platform = value.first);
              },
            ),
          ),
          const SizedBox(height: 14),
          GameonAnimatedIn(
            delay: const Duration(milliseconds: 110),
            child: TextField(
              controller: _player,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _lookup(),
              decoration: const InputDecoration(
                labelText: 'شناسه بازیکن',
                hintText: 'PSN ID / Gamertag / Origin ID',
                prefixIcon: Icon(Icons.person_search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _loading ? null : _lookup,
            icon: const Icon(Icons.analytics_rounded),
            label: Text(_loading ? 'در حال دریافت…' : 'نمایش آمار واقعی'),
          ),
          if (_loading) ...[
            const SizedBox(height: 20),
            const GameonSkeleton(width: double.infinity, height: 180, radius: 24),
          ],
          if (_message != null && !_loading) ...[
            const SizedBox(height: 18),
            GameonEmptyState(
              icon: Icons.info_outline_rounded,
              title: 'آمار در دسترس نیست',
              message: _message!,
            ),
          ],
          if (_stats != null && !_loading) ...[
            const SizedBox(height: 24),
            GameonAnimatedIn(child: _StatsCard(stats: _stats!)),
          ],
          const SizedBox(height: 22),
          const GameonSurface(
            child: Text(
              'بازی‌های بیشتری فقط وقتی اضافه می‌شوند که API قانونی و قابل‌اتکا داشته باشند. برای بازی فاقد API، Gameon عدد تخمینی یا ساختگی تولید نمی‌کند.',
              style: TextStyle(color: GameonColors.textSecondary, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});
  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('سطح', stats.level),
      ('امتیاز رتبه', stats.rankScore),
      ('حذف‌ها', stats.kills),
      ('آسیب', stats.damage),
      ('بردها', stats.wins),
    ].where((item) => item.$2 != null).toList();
    return GameonSurface(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stats.playerName, textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const Text('پروفایل دریافت شد ولی متریک قابل نمایش در پاسخ موجود نبود.', style: TextStyle(color: GameonColors.textSecondary))
          else
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(children: [
                    Text(row.$1, style: const TextStyle(color: GameonColors.textSecondary)),
                    const Spacer(),
                    Text(row.$2!, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ]),
                )),
        ],
      ),
    );
  }
}
