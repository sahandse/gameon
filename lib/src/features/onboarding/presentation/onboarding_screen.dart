import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/src/features/shell/presentation/app_shell.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GamingPlatform { playstation, xbox, pc, nintendo }
enum GameonThemeChoice { midnight, playstation, xbox, neon, oled, light }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _steps = 5;
  int _step = 0;
  bool _saving = false;
  GameonThemeChoice _theme = GameonThemeChoice.midnight;
  final Set<GamingPlatform> _platforms = <GamingPlatform>{};
  final Set<String> _services = <String>{};
  final Map<GamingPlatform, TextEditingController> _ids = {
    for (final platform in GamingPlatform.values) platform: TextEditingController(),
  };

  Color get _accent => switch (_theme) {
        GameonThemeChoice.midnight => const Color(0xFF4B7BFF),
        GameonThemeChoice.playstation => const Color(0xFF2F6BFF),
        GameonThemeChoice.xbox => const Color(0xFF39D353),
        GameonThemeChoice.neon => const Color(0xFF9D5CFF),
        GameonThemeChoice.oled => const Color(0xFF19E6C8),
        GameonThemeChoice.light => const Color(0xFF2764E7),
      };

  bool get _canContinue => _step != 1 || _platforms.isNotEmpty;

  List<String> get _availableServices {
    final items = <String>[];
    if (_platforms.contains(GamingPlatform.playstation)) {
      items.addAll(const ['PS Plus Essential', 'PS Plus Extra', 'PS Plus Premium']);
    }
    if (_platforms.contains(GamingPlatform.xbox)) {
      items.addAll(const ['Game Pass Core', 'Game Pass Standard', 'Game Pass Ultimate']);
    }
    if (_platforms.contains(GamingPlatform.pc)) items.add('PC Game Pass');
    if (_platforms.contains(GamingPlatform.nintendo)) {
      items.addAll(const ['Nintendo Switch Online', 'Expansion Pack']);
    }
    return items;
  }

  @override
  void dispose() {
    for (final controller in _ids.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    if (!_canContinue || _saving) return;
    HapticFeedback.selectionClick();

    if (_step < _steps - 1) {
      setState(() => _step++);
      return;
    }

    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('theme_choice', _theme.name);
    await prefs.setStringList('platforms', _platforms.map((e) => e.name).toList());
    await prefs.setStringList('services', _services.toList());

    for (final entry in _ids.entries) {
      final value = entry.value.text.trim();
      final key = 'player_id_${entry.key.name}';
      if (value.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    }

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
      (_) => false,
    );
  }

  void _back() {
    if (_step == 0 || _saving) return;
    HapticFeedback.selectionClick();
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(onPressed: _back, icon: const Icon(Icons.arrow_forward_rounded))
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  Text(
                    'GAMEON',
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_step + 1}/$_steps',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: (_step + 1) / _steps,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(_accent),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(_step), child: _buildStep(context)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: FilledButton(
                onPressed: _canContinue && !_saving ? _next : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_step == _steps - 1 ? 'ورود به Gameon' : 'ادامه'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) => switch (_step) {
        0 => _themeStep(context),
        1 => _platformStep(context),
        2 => _serviceStep(context),
        3 => _playerIdStep(context),
        _ => _finishStep(context),
      };

  Widget _page(String title, String subtitle, List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.65),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }

  Widget _themeStep(BuildContext context) {
    return _page('ظاهر Gameon را انتخاب کن', 'تمی را انتخاب کن که بازی‌کردن با آن حس بهتری بهت می‌دهد.', [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: GameonThemeChoice.values.map((item) {
          final selected = item == _theme;
          final color = _themeColor(item);
          return _SelectCard(
            title: _themeLabel(item),
            selected: selected,
            accent: color,
            icon: Icons.palette_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _theme = item);
            },
          );
        }).toList(),
      ),
    ]);
  }

  Widget _platformStep(BuildContext context) {
    return _page('کجا بازی می‌کنی؟', 'یک یا چند پلتفرم انتخاب کن تا محتوای صفحه اصلی برای خودت مرتب شود.', [
      ...GamingPlatform.values.map((platform) {
        final selected = _platforms.contains(platform);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SelectCard(
            title: _platformLabel(platform),
            subtitle: _platformSubtitle(platform),
            selected: selected,
            accent: _accent,
            icon: _platformIcon(platform),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                selected ? _platforms.remove(platform) : _platforms.add(platform);
                _services.removeWhere((service) => !_availableServices.contains(service));
              });
            },
          ),
        );
      }),
    ]);
  }

  Widget _serviceStep(BuildContext context) {
    final services = _availableServices;
    return _page('سرویس‌های بازی', 'این مرحله اختیاری است و برای شخصی‌سازی Game Pass، PS Plus و Nintendo Switch Online استفاده می‌شود.', [
      if (services.isEmpty)
        const _InfoCard('برای پلتفرم‌های انتخاب‌شده سرویس جداگانه‌ای وجود ندارد.')
      else
        ...services.map((service) {
          final selected = _services.contains(service);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectCard(
              title: service,
              selected: selected,
              accent: _accent,
              icon: Icons.workspace_premium_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => selected ? _services.remove(service) : _services.add(service));
              },
            ),
          );
        }),
    ]);
  }

  Widget _playerIdStep(BuildContext context) {
    return _page('شناسه بازیکن', 'اختیاری است. فقط برای Providerهایی استفاده می‌شود که API واقعی و مجاز دارند.', [
      ..._platforms.map((platform) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: TextField(
              controller: _ids[platform],
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: _idLabel(platform),
                hintText: _idHint(platform),
                prefixIcon: Icon(_platformIcon(platform)),
              ),
            ),
          )),
      const _InfoCard('اگر شناسه‌ای وارد نکنی، بعداً هم می‌توانی از بخش Tracker جستجو کنی.'),
    ]);
  }

  Widget _finishStep(BuildContext context) {
    return _page('آماده‌ای 🎮', 'بعد از این صفحه مستقیم وارد برنامه اصلی می‌شوی.', [
      _SummaryCard(
        accent: _accent,
        rows: [
          ('تم', _themeLabel(_theme)),
          ('پلتفرم‌ها', _platforms.map(_platformLabel).join(' • ')),
          ('سرویس‌ها', _services.isEmpty ? 'انتخاب نشده' : _services.join(' • ')),
        ],
      ),
      const SizedBox(height: 14),
      const _InfoCard('هیچ بازی، قیمت، خبر یا رتبه ساختگی نمایش داده نمی‌شود؛ فقط داده واقعی و قابل‌تأیید.'),
    ]);
  }

  Color _themeColor(GameonThemeChoice value) => switch (value) {
        GameonThemeChoice.midnight => const Color(0xFF4B7BFF),
        GameonThemeChoice.playstation => const Color(0xFF2F6BFF),
        GameonThemeChoice.xbox => const Color(0xFF39D353),
        GameonThemeChoice.neon => const Color(0xFF9D5CFF),
        GameonThemeChoice.oled => const Color(0xFF19E6C8),
        GameonThemeChoice.light => const Color(0xFF72A0FF),
      };

  String _themeLabel(GameonThemeChoice value) => switch (value) {
        GameonThemeChoice.midnight => 'Midnight',
        GameonThemeChoice.playstation => 'PlayStation Blue',
        GameonThemeChoice.xbox => 'Xbox Green',
        GameonThemeChoice.neon => 'Neon Purple',
        GameonThemeChoice.oled => 'OLED Black',
        GameonThemeChoice.light => 'Light',
      };

  String _platformLabel(GamingPlatform value) => switch (value) {
        GamingPlatform.playstation => 'PlayStation',
        GamingPlatform.xbox => 'Xbox',
        GamingPlatform.pc => 'PC',
        GamingPlatform.nintendo => 'Nintendo',
      };

  String _platformSubtitle(GamingPlatform value) => switch (value) {
        GamingPlatform.playstation => 'PS5 و PS4 • PS Plus',
        GamingPlatform.xbox => 'Series X|S و Xbox One • Game Pass',
        GamingPlatform.pc => 'Steam، Epic و PC Game Pass',
        GamingPlatform.nintendo => 'Nintendo Switch • Switch Online',
      };

  IconData _platformIcon(GamingPlatform value) => switch (value) {
        GamingPlatform.playstation => Icons.sports_esports_rounded,
        GamingPlatform.xbox => Icons.gamepad_rounded,
        GamingPlatform.pc => Icons.computer_rounded,
        GamingPlatform.nintendo => Icons.videogame_asset_rounded,
      };

  String _idLabel(GamingPlatform value) => switch (value) {
        GamingPlatform.playstation => 'PSN Online ID',
        GamingPlatform.xbox => 'Xbox Gamertag',
        GamingPlatform.pc => 'Steam ID / Profile',
        GamingPlatform.nintendo => 'Nintendo nickname',
      };

  String _idHint(GamingPlatform value) => switch (value) {
        GamingPlatform.playstation => 'YourPSNName',
        GamingPlatform.xbox => 'YourGamertag',
        GamingPlatform.pc => 'Steam ID یا لینک پروفایل',
        GamingPlatform.nintendo => 'نام نمایشی حساب',
      };
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.title,
    required this.selected,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: .12) : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? accent : scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? accent.withValues(alpha: .15) : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: selected ? accent : scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                  ],
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: selected
                  ? Icon(Icons.check_circle_rounded, key: const ValueKey(true), color: accent)
                  : Icon(Icons.circle_outlined, key: const ValueKey(false), color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.accent, required this.rows});
  final Color accent;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: rows
            .map((row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.$1, style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(row.$2, textAlign: TextAlign.end)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6))),
        ],
      ),
    );
  }
}
