import 'package:flutter/material.dart';
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
  static const int _steps = 5;
  int _step = 0;
  GameonThemeChoice _theme = GameonThemeChoice.midnight;
  final Set<GamingPlatform> _platforms = <GamingPlatform>{};
  final Set<String> _services = <String>{};
  final Map<GamingPlatform, TextEditingController> _ids = {
    GamingPlatform.playstation: TextEditingController(),
    GamingPlatform.xbox: TextEditingController(),
    GamingPlatform.pc: TextEditingController(),
    GamingPlatform.nintendo: TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in _ids.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Color get _accent => switch (_theme) {
        GameonThemeChoice.midnight => const Color(0xFF4B7BFF),
        GameonThemeChoice.playstation => const Color(0xFF2F6BFF),
        GameonThemeChoice.xbox => const Color(0xFF39D353),
        GameonThemeChoice.neon => const Color(0xFF9D5CFF),
        GameonThemeChoice.oled => const Color(0xFF19E6C8),
        GameonThemeChoice.light => const Color(0xFF2764E7),
      };

  bool get _canContinue {
    if (_step == 1) return _platforms.isNotEmpty;
    return true;
  }

  List<String> get _availableServices {
    final items = <String>[];
    if (_platforms.contains(GamingPlatform.playstation)) {
      items.addAll(const ['PS Plus Essential', 'PS Plus Extra', 'PS Plus Premium']);
    }
    if (_platforms.contains(GamingPlatform.xbox)) {
      items.addAll(const ['Game Pass Core', 'Game Pass Standard', 'Game Pass Ultimate']);
    }
    if (_platforms.contains(GamingPlatform.pc)) {
      items.add('PC Game Pass');
    }
    if (_platforms.contains(GamingPlatform.nintendo)) {
      items.addAll(const ['Nintendo Switch Online', 'Expansion Pack']);
    }
    return items;
  }

  Future<void> _next() async {
    if (!_canContinue) return;
    if (_step < _steps - 1) {
      setState(() => _step++);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('theme_choice', _theme.name);
    await prefs.setStringList('platforms', _platforms.map((e) => e.name).toList());
    await prefs.setStringList('services', _services.toList());
    for (final entry in _ids.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        await prefs.setString('player_id_${entry.key.name}', value);
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const _OnboardingDoneScreen()),
    );
  }

  void _back() {
    if (_step == 0) return;
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    )
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
                      color: GameonColors.textSecondary,
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
                  backgroundColor: GameonColors.surface,
                  valueColor: AlwaysStoppedAnimation(_accent),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStep(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _canContinue ? _next : null,
                  child: Text(_step == _steps - 1 ? 'ساخت تجربه من' : 'ادامه'),
                ),
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

  Widget _header(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: GameonColors.textSecondary,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 20),
      children: [
        _header(context, 'ظاهر Gameon را خودت انتخاب کن', 'هر زمان خواستی بعداً هم می‌توانی تم را تغییر بدهی.'),
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
            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => setState(() => _theme = item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: .14) : GameonColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: selected ? color : GameonColors.border, width: selected ? 1.5 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [color, color.withValues(alpha: .45)]),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: .25), blurRadius: 16)],
                      ),
                    ),
                    Text(_themeLabel(item), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _platformStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 20),
      children: [
        _header(context, 'کجا بازی می‌کنی؟', 'می‌توانی چند پلتفرم انتخاب کنی. محتوای برنامه فقط براساس انتخاب‌های خودت ساخته می‌شود.'),
        ...GamingPlatform.values.map((platform) {
          final selected = _platforms.contains(platform);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChoiceTile(
              title: _platformLabel(platform),
              subtitle: _platformSubtitle(platform),
              selected: selected,
              accent: _accent,
              icon: _platformIcon(platform),
              onTap: () {
                setState(() {
                  selected ? _platforms.remove(platform) : _platforms.add(platform);
                  _services.removeWhere((service) => !_availableServices.contains(service));
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _serviceStep(BuildContext context) {
    final services = _availableServices;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 20),
      children: [
        _header(context, 'کدام سرویس‌ها را داری؟', 'این مرحله اختیاری است. فقط سرویس‌های مربوط به پلتفرم‌هایی که انتخاب کردی نمایش داده می‌شوند.'),
        if (services.isEmpty)
          const _EmptyCard(text: 'برای پلتفرم انتخاب‌شده سرویس اشتراکی جداگانه‌ای تنظیم نشده است.')
        else
          ...services.map((service) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ChoiceTile(
                  title: service,
                  subtitle: 'برای نمایش بازی‌ها و پیشنهادهای مرتبط',
                  selected: _services.contains(service),
                  accent: _accent,
                  icon: Icons.workspace_premium_rounded,
                  onTap: () => setState(() {
                    _services.contains(service) ? _services.remove(service) : _services.add(service);
                  }),
                ),
              )),
      ],
    );
  }

  Widget _playerIdStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 20),
      children: [
        _header(context, 'شناسه بازیکن تو', 'اختیاری است. Gameon بعداً فقط برای بازی‌ها و سرویس‌هایی که API واقعی دارند از این شناسه استفاده می‌کند.'),
        ..._platforms.map((platform) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(
                controller: _ids[platform],
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: _idLabel(platform),
                  hintText: _idHint(platform),
                  prefixIcon: Icon(_platformIcon(platform)),
                  helperText: 'این مقدار فقط روی دستگاه ذخیره می‌شود.',
                ),
              ),
            )),
        const SizedBox(height: 8),
        const _EmptyCard(
          text: 'فهرست بازی‌ها در این مرحله عمداً دمو نیست. بعد از اتصال دیتابیس واقعی، جستجو و انتخاب بازی‌ها همین‌جا فعال می‌شود.',
        ),
      ],
    );
  }

  Widget _finishStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 20),
      children: [
        _header(context, 'همه‌چیز آماده است', 'از این انتخاب‌ها برای ساخت Home، سرویس‌ها، بازی‌های رایگان، تخفیف‌ها، اخبار و Tracker شخصی استفاده می‌کنیم.'),
        _SummaryCard(
          accent: _accent,
          rows: [
            ('تم', _themeLabel(_theme)),
            ('پلتفرم‌ها', _platforms.map(_platformLabel).join(' • ')),
            ('سرویس‌ها', _services.isEmpty ? 'انتخاب نشده' : _services.join(' • ')),
          ],
        ),
        const SizedBox(height: 14),
        const _EmptyCard(
          text: 'هیچ بازی، قیمت، رتبه یا خبر ساختگی به حساب تو اضافه نمی‌شود. فقط دیتای تأییدشده از منابع واقعی نمایش داده خواهد شد.',
        ),
      ],
    );
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
        GamingPlatform.playstation => 'مثال: YourPSNName',
        GamingPlatform.xbox => 'مثال: YourGamertag',
        GamingPlatform.pc => 'Steam ID یا لینک پروفایل',
        GamingPlatform.nintendo => 'نام نمایشی حساب',
      };
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: .11) : GameonColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? accent : GameonColors.border, width: selected ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? accent.withValues(alpha: .16) : GameonColors.background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: selected ? accent : GameonColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : Colors.transparent,
                border: Border.all(color: selected ? accent : GameonColors.border),
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : null,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GameonColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GameonColors.border),
      ),
      child: Column(
        children: rows.map((row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.$1, style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              Expanded(child: Text(row.$2, textAlign: TextAlign.end)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GameonColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameonColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_rounded, size: 20, color: GameonColors.accentCyan),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: GameonColors.textSecondary, height: 1.6))),
        ],
      ),
    );
  }
}

class _OnboardingDoneScreen extends StatelessWidget {
  const _OnboardingDoneScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [GameonColors.accentBlue, GameonColors.accentCyan]),
                    boxShadow: [BoxShadow(color: GameonColors.accentBlue.withValues(alpha: .25), blurRadius: 28)],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 24),
                Text('Gameon برای تو آماده شد', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                const Text(
                  'مرحله بعد اتصال دیتابیس واقعی بازی‌هاست. تا آن زمان هیچ محتوای دمو نمایش داده نمی‌شود.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GameonColors.textSecondary, height: 1.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
