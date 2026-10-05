import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gameon/src/data/local/game_library_store.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';

class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({super.key, required this.game});
  final GameSummary game;
  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final GameLibraryStore _library = GameLibraryStore();
  bool _following = false;
  bool _wishlisted = false;

  @override
  void initState() {
    super.initState();
    _loadLocalState();
  }

  Future<void> _loadLocalState() async {
    final followed = await _library.isFollowed(widget.game.id);
    final wishlisted = await _library.isWishlisted(widget.game.id);
    if (!mounted) return;
    setState(() { _following = followed; _wishlisted = wishlisted; });
  }

  Future<void> _toggleFollow() async {
    final value = !_following;
    await _library.setFollowed(widget.game, value);
    GameonHaptics.confirm();
    if (mounted) setState(() => _following = value);
  }

  Future<void> _toggleWishlist() async {
    final value = !_wishlisted;
    await _library.setWishlisted(widget.game, value);
    GameonHaptics.confirm();
    if (mounted) setState(() => _wishlisted = value);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final theme = Theme.of(context);
    final scaffold = theme.scaffoldBackgroundColor;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            expandedHeight: 320,
            backgroundColor: scaffold,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (game.thumbUrl != null)
                    CachedNetworkImage(
                      imageUrl: game.thumbUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const GameonSkeleton(width: double.infinity, height: 320, radius: 0),
                      errorWidget: (_, __, ___) => ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                    )
                  else
                    ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, scaffold.withValues(alpha: .68), scaffold],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                GameonAnimatedIn(child: Text(game.title, textDirection: TextDirection.ltr, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.15))),
                const SizedBox(height: 14),
                GameonAnimatedIn(
                  delay: const Duration(milliseconds: 60),
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    if (game.isFree) const _Badge(label: 'رایگان', icon: Icons.bolt_rounded),
                    if (game.isDiscounted && game.discountPercent != null) _Badge(label: '${game.discountPercent}٪ تخفیف', icon: Icons.local_offer_rounded),
                    if (game.salePrice != null) _Badge(label: game.salePrice == 0 ? 'رایگان' : '\$${game.salePrice!.toStringAsFixed(2)}', icon: Icons.payments_outlined, ltr: true),
                  ]),
                ),
                const SizedBox(height: 22),
                GameonAnimatedIn(
                  delay: const Duration(milliseconds: 110),
                  child: Row(children: [
                    Expanded(child: FilledButton.icon(onPressed: _toggleFollow, icon: Icon(_following ? Icons.notifications_active_rounded : Icons.notifications_none_rounded), label: Text(_following ? 'دنبال می‌کنی' : 'دنبال کردن'))),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(tooltip: 'علاقه‌مندی', onPressed: _toggleWishlist, icon: Icon(_wishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded)),
                  ]),
                ),
                const SizedBox(height: 30),
                const _SectionTitle(title: 'اطلاعات قیمت'),
                const SizedBox(height: 12),
                GameonAnimatedIn(delay: const Duration(milliseconds: 150), child: _PriceCard(game: game)),
                const SizedBox(height: 28),
                const _SectionTitle(title: 'درباره بازی'),
                const SizedBox(height: 12),
                const GameonAnimatedIn(delay: Duration(milliseconds: 190), child: GameonEmptyState(icon: Icons.info_outline_rounded, title: 'اطلاعات تکمیلی هنوز متصل نیست', message: 'توضیحات کامل، سازنده، ناشر، ژانر، تاریخ انتشار، پلتفرم‌ها، تصاویر، DLC و بازی‌های مشابه فقط از منبع واقعی نمایش داده می‌شوند.')),
                const SizedBox(height: 28),
                const _SectionTitle(title: 'سرویس‌ها'),
                const SizedBox(height: 12),
                const GameonAnimatedIn(delay: Duration(milliseconds: 230), child: GameonEmptyState(icon: Icons.subscriptions_rounded, title: 'وضعیت سرویس نامشخص است', message: 'وضعیت پلی‌استیشن پلاس، گیم پس و Nintendo Switch Online بدون منبع قابل‌تأیید نمایش داده نمی‌شود.')),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title}); final String title;
  @override
  Widget build(BuildContext context) => Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900));
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, this.ltr = false});
  final String label; final IconData icon; final bool ltr;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(100), border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: .15))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 6),
      Text(label, textDirection: ltr ? TextDirection.ltr : TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
    ]),
  );
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.game}); final GameSummary game;
  @override
  Widget build(BuildContext context) => GameonSurface(
    highlight: game.isDiscounted,
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('قیمت فعلی', style: TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 6),
        Text(game.salePrice == null ? 'نامشخص' : game.salePrice == 0 ? 'رایگان' : '\$${game.salePrice!.toStringAsFixed(2)}', textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      ])),
      if (game.normalPrice != null && game.isDiscounted)
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('قیمت اصلی', style: TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
          const SizedBox(height: 6),
          Text('\$${game.normalPrice!.toStringAsFixed(2)}', textDirection: TextDirection.ltr, style: const TextStyle(decoration: TextDecoration.lineThrough, color: GameonColors.textSecondary)),
        ]),
    ]),
  );
}
