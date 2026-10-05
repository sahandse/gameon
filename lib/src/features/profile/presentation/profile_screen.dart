import 'package:flutter/material.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _future = _load();

  Future<_ProfileData> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final platforms = prefs.getStringList('platforms') ?? const <String>[];
    final services = prefs.getStringList('services') ?? const <String>[];
    final ids = <String, String>{};
    for (final platform in platforms) {
      final value = prefs.getString('player_id_$platform');
      if (value != null && value.trim().isNotEmpty) ids[platform] = value.trim();
    }
    return _ProfileData(
      theme: prefs.getString('theme_choice') ?? 'midnight',
      platforms: platforms,
      services: services,
      ids: ids,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('من')),
      body: FutureBuilder<_ProfileData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              _ProfileHeader(themeName: data.theme),
              const SizedBox(height: 22),
              _Section(
                title: 'پلتفرم‌ها',
                child: data.platforms.isEmpty
                    ? const _MutedText('پلتفرمی انتخاب نشده است.')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: data.platforms.map((item) => _Chip(_platformLabel(item))).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'سرویس‌ها',
                child: data.services.isEmpty
                    ? const _MutedText('سرویسی انتخاب نشده است.')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: data.services.map(_Chip.new).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'شناسه‌های بازیکن',
                child: data.ids.isEmpty
                    ? const _MutedText('شناسه‌ای ذخیره نشده است.')
                    : Column(
                        children: data.ids.entries
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Text(_platformLabel(entry.key), style: const TextStyle(color: GameonColors.textSecondary)),
                                      const Spacer(),
                                      Flexible(child: Text(entry.value, textDirection: TextDirection.ltr, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              const _Section(
                title: 'حریم خصوصی',
                child: _MutedText('انتخاب‌ها، Follow، Wishlist و شناسه‌های فعلی روی خود دستگاه ذخیره می‌شوند. Gameon برای نمایش آمار فقط از API واقعی و مجاز استفاده خواهد کرد.'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _platformLabel(String value) => switch (value) {
        'playstation' => 'PlayStation',
        'xbox' => 'Xbox',
        'pc' => 'PC',
        'nintendo' => 'Nintendo',
        _ => value,
      };
}

class _ProfileData {
  const _ProfileData({required this.theme, required this.platforms, required this.services, required this.ids});
  final String theme;
  final List<String> platforms;
  final List<String> services;
  final Map<String, String> ids;
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.themeName});
  final String themeName;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withValues(alpha: .20), GameonColors.surface]),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: GameonColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: .16)),
            child: Icon(Icons.sports_esports_rounded, color: accent),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GAMEON PLAYER', textDirection: TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text('تم: $themeName', style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: GameonColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: GameonColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: GameonColors.background, borderRadius: BorderRadius.circular(100), border: Border.all(color: GameonColors.border)),
        child: Text(label, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
      );
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: GameonColors.textSecondary, height: 1.7));
}
