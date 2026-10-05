import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/src/theme/gameon_theme.dart';

abstract final class GameonHaptics {
  static Future<void> tap() => HapticFeedback.selectionClick();
  static Future<void> confirm() => HapticFeedback.lightImpact();
  static Future<void> important() => HapticFeedback.mediumImpact();
}

class GameonSurface extends StatelessWidget {
  const GameonSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight
              ? accent.withValues(alpha: .26)
              : Theme.of(context).dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        GameonHaptics.tap();
        onTap!();
      },
      child: content,
    );
  }
}

class GameonEmptyState extends StatelessWidget {
  const GameonEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GameonSurface(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  accent.withValues(alpha: .24),
                  accent.withValues(alpha: .06),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent.withValues(alpha: .18)),
            ),
            child: Icon(icon, size: 31, color: accent),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GameonColors.textSecondary,
              height: 1.75,
              fontSize: 13,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: () {
                GameonHaptics.tap();
                onAction!();
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class GameonAnimatedIn extends StatefulWidget {
  const GameonAnimatedIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, .045),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<GameonAnimatedIn> createState() => _GameonAnimatedInState();
}

class _GameonAnimatedInState extends State<GameonAnimatedIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : widget.offset,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOut,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class GameonSkeleton extends StatefulWidget {
  const GameonSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 16,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<GameonSkeleton> createState() => _GameonSkeletonState();
}

class _GameonSkeletonState extends State<GameonSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.4 + (t * 2.8), 0),
              end: Alignment(-.4 + (t * 2.8), 0),
              colors: [
                GameonColors.surfaceRaised.withValues(alpha: .72),
                Theme.of(context).colorScheme.primary.withValues(alpha: .10),
                GameonColors.surfaceRaised.withValues(alpha: .72),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GameonPageSkeleton extends StatelessWidget {
  const GameonPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: const [
        Row(
          children: [
            GameonSkeleton(width: 126, height: 28, radius: 10),
            Spacer(),
            GameonSkeleton(width: 46, height: 46, radius: 15),
            SizedBox(width: 8),
            GameonSkeleton(width: 46, height: 46, radius: 15),
          ],
        ),
        SizedBox(height: 28),
        GameonSkeleton(width: double.infinity, height: 84, radius: 22),
        SizedBox(height: 30),
        GameonSkeleton(width: 120, height: 25, radius: 9),
        SizedBox(height: 14),
        GameonSkeleton(width: double.infinity, height: 150, radius: 24),
        SizedBox(height: 14),
        GameonSkeleton(width: double.infinity, height: 110, radius: 24),
      ],
    );
  }
}
