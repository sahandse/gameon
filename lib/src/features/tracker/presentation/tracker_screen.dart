import 'package:flutter/material.dart';
import 'package:gameon/src/data/remote/tracker_network_api.dart';
import 'package:gameon/src/theme/gameon_theme.dart';

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
    if (id.isEmpty) return;
    setState(() {
      _loading = true;
      _message = null;
      _stats = null;
    });
    try {
      final stats = await _api.fetchApexProfile(platform: _platform, playerId: id);
      if (mounted) setState(() => _stats = stats);
    } on TrackerConfigurationException {
      if (mounted) setState(() => _message = 'کلید Tracker Network هنوز برای این Build تنظیم نشده است.');
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
      appBar: AppBar(title: const Text('Tracker')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          Text('Apex Legends', textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('اولین Provider واقعی Gameon • بدون آمار دمو', style: TextStyle(color: GameonColors.textSecondary)),
          const SizedBox(height: 22),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'psn', label: Text('PSN')),
              ButtonSegment(value: 'xbl', label: Text('Xbox')),
              ButtonSegment(value: 'origin', label: Text('PC')),
            ],
            selected: {_platform},
            onSelectionChanged: (value) => setState(() => _platform = value.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _player,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _lookup(),
            decoration: const InputDecoration(
              labelText: 'Player ID',
              hintText: 'PSN ID / Gamertag / Origin ID',
              prefixIcon: Icon(Icons.person_search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _loading ? null : _lookup,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.analytics_rounded),
            label: const Text('نمایش آمار واقعی'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 18),
            _Info(text: _message!),
          ],
          if (_stats != null) ...[
            const SizedBox(height: 24),
            _StatsCard(stats: _stats!),
          ],
          const SizedBox(height: 22),
          const _Info(text: 'بازی‌های بیشتری فقط وقتی اضافه می‌شوند که API قانونی و قابل‌اتکا داشته باشند. برای بازی فاقد API، Gameon عدد تخمینی یا ساختگی تولید نمی‌کند.'),
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
      ('Level', stats.level),
      ('Rank Score', stats.rankScore),
      ('Kills', stats.kills),
      ('Damage', stats.damage),
      ('Wins', stats.wins),
    ].where((item) => item.$2 != null).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GameonColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GameonColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stats.playerName, textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const Text('پروفایل دریافت شد ولی متریک قابل نمایش در پاسخ موجود نبود.', style: TextStyle(color: GameonColors.textSecondary))
          else
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Text(row.$1, textDirection: TextDirection.ltr, style: const TextStyle(color: GameonColors.textSecondary)),
                    const Spacer(),
                    Text(row.$2!, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ]),
                )),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: GameonColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: GameonColors.border)),
        child: Text(text, style: const TextStyle(color: GameonColors.textSecondary, height: 1.7)),
      );
}
