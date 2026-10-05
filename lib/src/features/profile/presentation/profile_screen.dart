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
  late Future<_ProfileData> _future = _load();
  static const _allPlatforms = <String>['playstation', 'xbox', 'pc', 'nintendo'];

  Future<_ProfileData> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final platforms = prefs.getStringList('platforms') ?? const <String>[];
    final services = prefs.getStringList('services') ?? const <String>[];
    final ids = <String, String>{};
    for (final platform in _allPlatforms) {
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

  Future<void> _togglePlatform(_ProfileData data, String platform) async {
    final selected = data.platforms.toSet();
    if (selected.contains(platform)) {
      if (selected.length == 1) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حداقل یک پلتفرم باید انتخاب بماند.')));
        return;
      }
      selected.remove(platform);
    } else {
      selected.add(platform);
    }

    final allowedServices = _servicesForPlatforms(selected);
    final services = data.services.where(allowedServices.contains).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('platforms', selected.toList());
    await prefs.setStringList('services', services);
    GameonHaptics.confirm();
    if (!mounted) return;
    setState(() => _future = _load());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پلتفرم‌ها ذخیره شدند؛ صفحه اصلی با بروزرسانی بعدی هماهنگ می‌شود.')));
  }

  Future<void> _toggleService(_ProfileData data, String service) async {
    final selected = data.services.toSet();
    selected.contains(service) ? selected.remove(service) : selected.add(service);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('services', selected.toList());
    GameonHaptics.confirm();
    if (mounted) setState(() => _future = _load());
  }

  Set<String> _servicesForPlatforms(Set<String> platforms) {
    final result = <String>{};
    if (platforms.contains('playstation')) {
      result.addAll(const ['PS Plus Essential', 'PS Plus Extra', 'PS Plus Premium']);
    }
    if (platforms.contains('xbox')) {
      result.addAll(const ['Game Pass Core', 'Game Pass Standard', 'Game Pass Ultimate']);
    }
    if (platforms.contains('pc')) result.add('PC Game Pass');
    if (platforms.contains('nintendo')) {
      result.addAll(const ['Nintendo Switch Online', 'Expansion Pack']);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('من')),
      body: FutureBuilder<_ProfileData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const GameonPageSkeleton();
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
          final selectedPlatforms = data.platforms.toSet();
          final availableServices = _servicesForPlatforms(selectedPlatforms);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              GameonAnimatedIn(child: _ProfileHeader(themeName: data.theme)),
              const SizedBox(height: 18),
              GameonAnimatedIn(
                delay: const Duration(milliseconds: 60),
                child: _Section(
                  icon: Icons.devices_rounded,
                  title: 'پلتفرم‌ها',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _MutedText('هر زمان خواستی می‌توانی کنسول یا PC دیگری اضافه کنی.'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allPlatforms.map((platform) {
                          final selected = selectedPlatforms.contains(platform);
                          return FilterChip(
                            label: Text(_platformLabel(platform)),
                            selected: selected,
                            onSelected: (_) => _togglePlatform(data, platform),
                            avatar: Icon(_platformIcon(platform), size: 18),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GameonAnimatedIn(
                delay: const Duration(milliseconds: 110),
                child: _Section(
                  icon: Icons.workspace_premium_rounded,
                  title: 'سرویس‌ها',
                  child: availableServices.isEmpty
                      ? const _MutedText('برای پلتفرم‌های فعلی سرویس قابل انتخابی وجود ندارد.')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableServices.map((service) {
                            return FilterChip(
                              label: Text(service),
                              selected: data.services.contains(service),
                              onSelected: (_) => _toggleService(data, service),
                            );
                          }).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              GameonAnimatedIn(
                delay: const Duration(milliseconds: 160),
                child: _Section(
                  icon: Icons.badge_rounded,
                  title: 'شناسه‌های بازیکن',
                  child: data.ids.isEmpty
                      ? const _MutedText('شناسه‌ای ذخیره نشده است.')
                      : Column(
                          children: data.ids.entries.map((entry) {
                            return Padding(
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
                            );
                          }).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              const GameonAnimatedIn(
                delay: Duration(milliseconds: 210),
                child: _Section(
                  icon: Icons.shield_outlined,
                  title: 'حریم خصوصی',
                  child: _MutedText('انتخاب‌ها، دنبال‌کردن‌ها، علاقه‌مندی‌ها و شناسه‌ها روی خود دستگاه ذخیره می‌شوند.'),
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

  IconData _platformIcon(String value) => switch (value) {
        'playstation' => Icons.sports_esports_rounded,
        'xbox' => Icons.gamepad_rounded,
        'pc' => Icons.computer_rounded,
        'nintendo' => Icons.videogame_asset_rounded,
        _ => Icons.devices_rounded,
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
  Widget build(BuildContext context) {
    return GameonSurface(
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
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: GameonColors.textSecondary, height: 1.7));
}
