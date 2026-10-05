import 'package:flutter/material.dart';
import 'package:gameon/src/theme/gameon_theme.dart';

enum GamingPlatform { playstation, xbox, pc, nintendo }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Set<GamingPlatform> _selected = <GamingPlatform>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: <Color>[
                          GameonColors.accentBlue,
                          GameonColors.accentCyan,
                        ],
                      ),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'GAMEON',
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'کجا بازی می‌کنی؟',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'فقط پلتفرم‌های خودت را انتخاب کن؛ صفحه اصلی، سرویس‌ها، بازی‌های رایگان، تخفیف‌ها و انتشارهای جدید بر همان اساس ساخته می‌شوند.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: GameonColors.textSecondary,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: GamingPlatform.values
                    .map((platform) => _PlatformCard(
                          platform: platform,
                          selected: _selected.contains(platform),
                          onTap: () {
                            setState(() {
                              if (_selected.contains(platform)) {
                                _selected.remove(platform);
                              } else {
                                _selected.add(platform);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),
              const Spacer(),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _selected.isEmpty ? .45 : 1,
                child: FilledButton(
                  onPressed: _selected.isEmpty ? null : () {},
                  child: const Text('ادامه'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.platform,
    required this.selected,
    required this.onTap,
  });

  final GamingPlatform platform;
  final bool selected;
  final VoidCallback onTap;

  String get label => switch (platform) {
        GamingPlatform.playstation => 'PlayStation',
        GamingPlatform.xbox => 'Xbox',
        GamingPlatform.pc => 'PC',
        GamingPlatform.nintendo => 'Nintendo',
      };

  IconData get fallbackIcon => switch (platform) {
        GamingPlatform.playstation => Icons.sports_esports_rounded,
        GamingPlatform.xbox => Icons.gamepad_rounded,
        GamingPlatform.pc => Icons.computer_rounded,
        GamingPlatform.nintendo => Icons.videogame_asset_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 52) / 2;
    final accent = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: width,
          height: 116,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: .12)
                : GameonColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? accent : GameonColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Icon(
                fallbackIcon,
                size: 26,
                color: selected ? accent : GameonColors.textSecondary,
              ),
              Text(
                label,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
