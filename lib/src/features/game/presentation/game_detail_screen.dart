import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({super.key, required this.game});

  final GameSummary game;

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  bool _following = false;
  bool _wishlisted = false;

  String get _followKey => 'follow_game_${widget.game.id}';
  String get _wishlistKey => 'wishlist_game_${widget.game.id}';

  @override
  void initState() {
    super.initState();
    _loadLocalState();
  }

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _following = prefs.getBool(_followKey) ?? false;
      _wishlisted = prefs.getBool(_wishlistKey) ?? false;
    });
  }

  Future<void> _toggleFollow() async {
    final prefs = await SharedPreferences.getInstance();
    final value = !_following;
    await prefs.setBool(_followKey, value);
    if (mounted) setState(() => _following = value);
  }

  Future<void> _toggleWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final value = !_wishlisted;
    await prefs.setBool(_wishlistKey, value);
    if (mounted) setState(() => _wishlisted = value);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            expandedHeight: 320,
            backgroundColor: GameonColors.background,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (game.thumbUrl != null)
                    CachedNetworkImage(
                      imageUrl: game.thumbUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(color: GameonColors.surface),
                      errorWidget: (_, __, ___) => const ColoredBox(color: GameonColors.surface),
                    )
                  else
                    const ColoredBox(color: GameonColors.surface),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC07090D), GameonColors.background],
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
                Text(
                  game.title,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.15),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (game.isFree) const _Badge(label: 'رایگان', icon: Icons.bolt_rounded),
                    if (game.isDiscounted && game.discountPercent != null)
                      _Badge(label: '${game.discountPercent}% تخفیف', icon: Icons.local_offer_rounded),
                    if (game.salePrice != null)
                      _Badge(
                        label: game.salePrice == 0 ? 'Free' : '\$${game.salePrice!.toStringAsFixed(2)}',
                        icon: Icons.payments_outlined,
                        ltr: true,
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _toggleFollow,
                        icon: Icon(_following ? Icons.notifications_active_rounded : Icons.notifications_none_rounded),
                        label: Text(_following ? 'دنبال می‌کنی' : 'دنبال کردن'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Wishlist',
                      onPressed: _toggleWishlist,
                      icon: Icon(_wishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _SectionTitle(title: 'اطلاعات قیمت'),
                const SizedBox(height: 12),
                _PriceCard(game: game),
                const SizedBox(height: 28),
                _SectionTitle(title: 'درباره بازی'),
                const SizedBox(height: 12),
                const _InfoCard(
                  text: 'توضیحات کامل، سازنده، ناشر، ژانر، تاریخ انتشار، پلتفرم‌ها، تصاویر، DLC و بازی‌های مشابه فقط زمانی نمایش داده می‌شوند که منبع معتبر واقعی برای این بازی متصل باشد.',
                ),
                const SizedBox(height: 28),
                _SectionTitle(title: 'سرویس‌ها'),
                const SizedBox(height: 12),
                const _InfoCard(
                  text: 'وضعیت PS Plus، Game Pass و Nintendo Switch Online بدون منبع قابل‌تأیید نمایش داده نمی‌شود.',
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, this.ltr = false});
  final String label;
  final IconData icon;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GameonColors.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: GameonColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: GameonColors.accentCyan),
          const SizedBox(width: 6),
          Text(label, textDirection: ltr ? TextDirection.ltr : TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.game});
  final GameSummary game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GameonColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GameonColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('قیمت فعلی', style: TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 6),
                Text(
                  game.salePrice == null ? 'نامشخص' : game.salePrice == 0 ? 'رایگان' : '\$${game.salePrice!.toStringAsFixed(2)}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          if (game.normalPrice != null && game.isDiscounted)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('قیمت اصلی', style: TextStyle(color: GameonColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 6),
                Text(
                  '\$${game.normalPrice!.toStringAsFixed(2)}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(decoration: TextDecoration.lineThrough, color: GameonColors.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GameonColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GameonColors.border),
      ),
      child: Text(text, style: const TextStyle(color: GameonColors.textSecondary, height: 1.7)),
    );
  }
}
