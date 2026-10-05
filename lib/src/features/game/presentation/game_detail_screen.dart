import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gameon/src/core/format/persian_datetime.dart';
import 'package:gameon/src/data/local/game_library_store.dart';
import 'package:gameon/src/data/models/game_details.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/remote/freetogame_api.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';
import 'package:url_launcher/url_launcher.dart';

class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({super.key, required this.game});

  final GameSummary game;

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final GameLibraryStore _library = GameLibraryStore();
  final FreeToGameApi _freeToGame = FreeToGameApi();
  bool _following = false;
  bool _wishlisted = false;
  Future<GameDetails?>? _detailsFuture;

  @override
  void initState() {
    super.initState();
    _loadLocalState();
    if (widget.game.source == 'freetogame' && widget.game.sourceId != null) {
      _detailsFuture = _freeToGame.fetchDetails(widget.game.sourceId!);
    }
  }

  Future<void> _loadLocalState() async {
    final followed = await _library.isFollowed(widget.game.id);
    final wishlisted = await _library.isWishlisted(widget.game.id);
    if (!mounted) return;
    setState(() {
      _following = followed;
      _wishlisted = wishlisted;
    });
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

  Future<void> _openStore() async {
    final url = widget.game.storeUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    GameonHaptics.tap();
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                      placeholder: (_, __) => const GameonSkeleton(
                        width: double.infinity,
                        height: 320,
                        radius: 0,
                      ),
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    )
                  else
                    ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          scaffold.withValues(alpha: .58),
                          scaffold,
                        ],
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
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (game.isFree)
                      const _Badge(label: 'رایگان', icon: Icons.bolt_rounded),
                    if (game.genre != null)
                      _Badge(label: game.genre!, icon: Icons.category_outlined),
                    if (game.platform != null)
                      _Badge(label: game.platform!, icon: Icons.devices_rounded),
                    if (game.isDiscounted && game.discountPercent != null)
                      _Badge(
                        label:
                            '${PersianDateTime.digits(game.discountPercent!)}٪ تخفیف',
                        icon: Icons.local_offer_rounded,
                      ),
                    if (game.salePrice != null)
                      _Badge(
                        label: game.salePrice == 0
                            ? 'رایگان'
                            : '\$${game.salePrice!.toStringAsFixed(2)}',
                        icon: Icons.payments_outlined,
                        ltr: true,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _toggleFollow,
                        icon: Icon(
                          _following
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                        ),
                        label: Text(
                          _following ? 'دنبال می‌کنی' : 'دنبال کردن',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'علاقه‌مندی',
                      onPressed: _toggleWishlist,
                      icon: Icon(
                        _wishlisted
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                    ),
                  ],
                ),
                if (game.storeUrl != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openStore,
                      icon: const Icon(Icons.storefront_rounded),
                      label: const Text('مشاهده در فروشگاه رسمی'),
                    ),
                  ),
                ],
                if (game.salePrice != null || game.normalPrice != null) ...[
                  const SizedBox(height: 28),
                  const _SectionTitle(title: 'قیمت'),
                  const SizedBox(height: 10),
                  _PriceCard(game: game),
                ],
                const SizedBox(height: 28),
                _buildDetails(),
                const SizedBox(height: 26),
                _SourceCard(game: game),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    if (_detailsFuture == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'اطلاعات بازی'),
          const SizedBox(height: 10),
          if (widget.game.shortDescription != null) ...[
            Text(
              widget.game.shortDescription!,
              style: const TextStyle(height: 1.7),
            ),
            const SizedBox(height: 12),
          ],
          _MetadataFromSummary(game: widget.game),
        ],
      );
    }

    return FutureBuilder<GameDetails?>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title: 'اطلاعات بازی'),
              SizedBox(height: 12),
              GameonSkeleton(width: double.infinity, height: 110),
              SizedBox(height: 12),
              GameonSkeleton(width: double.infinity, height: 80),
            ],
          );
        }

        final details = snapshot.data;
        if (details == null) {
          return _MetadataFromSummary(game: widget.game);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'درباره بازی'),
            const SizedBox(height: 10),
            if ((details.description ?? details.shortDescription)?.isNotEmpty == true)
              Text(
                details.description ?? details.shortDescription!,
                style: const TextStyle(height: 1.75),
              ),
            const SizedBox(height: 22),
            _InfoGrid(details: details),
            if (details.screenshots.isNotEmpty) ...[
              const SizedBox(height: 28),
              const _SectionTitle(title: 'تصاویر'),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: details.screenshots.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 285,
                        child: CachedNetworkImage(
                          imageUrl: details.screenshots[index],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const GameonSkeleton(
                            width: 285,
                            height: 180,
                            radius: 0,
                          ),
                          errorWidget: (_, __, ___) => ColoredBox(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (_hasRequirements(details)) ...[
              const SizedBox(height: 28),
              const _SectionTitle(title: 'حداقل سیستم مورد نیاز'),
              const SizedBox(height: 12),
              _Requirements(details: details),
            ],
          ],
        );
      },
    );
  }

  bool _hasRequirements(GameDetails d) =>
      d.minimumOs != null ||
      d.minimumProcessor != null ||
      d.minimumMemory != null ||
      d.minimumGraphics != null ||
      d.minimumStorage != null;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w900),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, this.ltr = false});
  final String label;
  final IconData icon;
  final bool ltr;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
          ],
        ),
      );
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.game});
  final GameSummary game;

  @override
  Widget build(BuildContext context) => GameonSurface(
        highlight: game.isDiscounted,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'قیمت فعلی',
                    style: TextStyle(
                      color: GameonColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    game.salePrice == null
                        ? 'نامشخص'
                        : game.salePrice == 0
                            ? 'رایگان'
                            : '\$${game.salePrice!.toStringAsFixed(2)}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (game.normalPrice != null && game.isDiscounted)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'قیمت اصلی',
                    style: TextStyle(
                      color: GameonColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${game.normalPrice!.toStringAsFixed(2)}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: GameonColors.textSecondary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
}

class _MetadataFromSummary extends StatelessWidget {
  const _MetadataFromSummary({required this.game});
  final GameSummary game;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (game.genre != null) ('ژانر', game.genre!),
      if (game.platform != null) ('پلتفرم', game.platform!),
      if (game.developer != null) ('سازنده', game.developer!),
      if (game.publisher != null) ('ناشر', game.publisher!),
      if (game.releaseDate != null)
        ('تاریخ انتشار', PersianDateTime.date(game.releaseDate!)),
      if (game.salePrice != null)
        ('قیمت', game.salePrice == 0 ? 'رایگان' : '\$${game.salePrice!.toStringAsFixed(2)}'),
    ];

    if (rows.isEmpty) {
      return const GameonSurface(
        child: Text(
          'اطلاعات پایه این بازی از کاتالوگ فروشگاه ثبت شده است.',
          style: TextStyle(color: GameonColors.textSecondary),
        ),
      );
    }

    return GameonSurface(
      child: Column(
        children: rows
            .map((row) => _InfoRow(label: row.$1, value: row.$2))
            .toList(),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.game});
  final GameSummary game;

  @override
  Widget build(BuildContext context) {
    final source = switch (game.source) {
      'freetogame' => 'FreeToGame',
      'game-store-catalog' => 'کاتالوگ فروشگاه‌های بازی',
      'cheapshark' => 'CheapShark',
      _ => game.source ?? 'منبع بازی',
    };
    return GameonSurface(
      child: Row(
        children: [
          Icon(Icons.verified_outlined, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('منبع: $source', style: const TextStyle(fontWeight: FontWeight.w800)),
                if (game.sourceUpdatedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'آخرین بروزرسانی منبع: ${PersianDateTime.dateTime(game.sourceUpdatedAt!.toLocal())}',
                    style: const TextStyle(
                      color: GameonColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.details});
  final GameDetails details;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (details.genre != null) ('ژانر', details.genre!),
      if (details.platform != null) ('پلتفرم', details.platform!),
      if (details.developer != null) ('سازنده', details.developer!),
      if (details.publisher != null) ('ناشر', details.publisher!),
      if (details.releaseDate != null)
        ('تاریخ انتشار', PersianDateTime.date(details.releaseDate!)),
      if (details.status != null) ('وضعیت', details.status!),
    ];

    return GameonSurface(
      child: Column(
        children: rows
            .map((row) => _InfoRow(label: row.$1, value: row.$2))
            .toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: const TextStyle(
                  color: GameonColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

class _Requirements extends StatelessWidget {
  const _Requirements({required this.details});
  final GameDetails details;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (details.minimumOs != null) ('سیستم‌عامل', details.minimumOs!),
      if (details.minimumProcessor != null) ('پردازنده', details.minimumProcessor!),
      if (details.minimumMemory != null) ('حافظه', details.minimumMemory!),
      if (details.minimumGraphics != null) ('گرافیک', details.minimumGraphics!),
      if (details.minimumStorage != null) ('فضا', details.minimumStorage!),
    ];
    return GameonSurface(
      child: Column(
        children: rows
            .map((row) => _InfoRow(label: row.$1, value: row.$2))
            .toList(),
      ),
    );
  }
}
