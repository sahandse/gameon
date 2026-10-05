import 'package:flutter/material.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<_ProfileData> _future = _load();

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
            return const GameonPageSkeleton();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: GameonEmptyState(
                icon: Icons.person_off_rounded,
                title: 'پروفایل در دسترس نیست',
                message: 'اطلاعات ذخیره‌شده روی دستگاه قابل خواندن نبود.',
              ),
            );
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              GameonAnimatedIn(child: _ProfileHeader(themeName: data.theme)),
              const SizedBox(height: 18),
              GameonAnimatedIn(
                delay: const Duration(milliseconds: 70),
                child: _Section(
                  icon: Icons.devices_rounded,
                  title: 'پلتفرم‌ها',
                  child: data.platforms.isEmpty
                      ? const _MutedText('پلتفرمی انتخاب نشده است.')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: data.platforms.map((item) => _Chip(_platformLabel(item))).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              GameonAnimatedIn(
                delay: const Duration(milliseconds: 120),
                child: _Section(
                  icon: Icons.workspace_premium_rounded,
                  title: 'سرویس‌ها',
                  child: data.services.isEmpty
                      ? const _MutedText('سرویسی انتخاب نشده است.')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: data.services.map(_Chip.new).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              GameonAnimatedIn(
                delay: const Duration(milliseconds: 170),
                child: _Section(
                  icon: Icons.badge_rounded,
                  title: 'شناسه‌های بازیکن',
                  child: data.ids.isEmpty
                      ? const _MutedText('شناسه‌ای ذخیره نشده است.')
                      : Column(
                          children: data.ids.entries
                              .map((entry) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 7),
                                    child: Row(
                                      children: [
                                        Text(_platformLabel(entry.key), style: const TextStyle(color: GameonColors.textSecondary)),
                                        const Spacer(),
                                        Flexible(
                                          child: Text(
                                            entry.value,
                                            textDirection: TextDirection.ltr,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              const GameonAnimatedIn(
                delay: Duration(milliseconds: 220),
                child: _Section(
                  icon: Icons.shield_outlined,
                  title: 'حریم خصوصی',
                  child: _MutedText('انتخاب‌ها، دنبال‌کردن‌ها، علاقه‌مندی‌ها و شناسه‌های فعلی روی خود دستگاه ذخیره می‌شوند. Gameon برای آمار فقط از API واقعی و مجاز استفاده می‌کند.'),
                ),
              ),
            ],
          );
        },
      ),
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
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [accent.withValues(alpha: .22), Theme.of(context).colorScheme.surface],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              color: accent.withValues(alpha: .14),
              border: Border.all(color: accent.withValues(alpha: .18)),
            ),
            child: Icon(Icons.sports_esports_rounded, color: accent, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GAMEON PLAYER', textDirection: TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .8)),
                const SizedBox(height: 6),
                Text('تم فعال: ${_themeLabel(themeName)}', style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(String value) => switch (value) {
        'playstation' => 'آبی پلی‌استیشن',
        'xbox' => 'سبز ایکس‌باکس',
        'neon' => 'نئون بنفش',
        'oled' => 'OLED مشکی',
        'light' => 'روشن',
        _ => 'نیمه‌شب',
      };
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => GameonSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 9),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: .16)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
      );
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: GameonColors.textSecondary, height: 1.7));
}
