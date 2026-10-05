import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gameon/src/data/local/game_library_store.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/features/following/presentation/following_center_screen.dart';
import 'package:gameon/src/features/game/presentation/game_detail_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final GameLibraryStore _store = GameLibraryStore();
  late Future<(List<GameSummary>, List<GameSummary>)> _future = _load();

  Future<(List<GameSummary>, List<GameSummary>)> _load() async {
    final followed = await _store.followed();
    final wishlist = await _store.wishlist();
    return (followed, wishlist);
  }

  Future<void> _refresh() async {
    GameonHaptics.tap();
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کتابخانه من'),
        actions: [
          IconButton.filledTonal(
            tooltip: 'مرکز دنبال‌کردن',
            onPressed: () async {
              GameonHaptics.tap();
              await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FollowingCenterScreen()));
              await _refresh();
            },
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder<(List<GameSummary>, List<GameSummary>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const GameonPageSkeleton();
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: GameonEmptyState(
                icon: Icons.folder_off_rounded,
                title: 'کتابخانه باز نشد',
                message: 'اطلاعات ذخیره‌شده قابل خواندن نبود.',
                actionLabel: 'تلاش دوباره',
                onAction: _refresh,
              ),
            );
          }
          final followed = snapshot.data?.$1 ?? const <GameSummary>[];
          final wishlist = snapshot.data?.$2 ?? const <GameSummary>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                GameonAnimatedIn(
                  child: _LibrarySection(
                    title: 'دنبال‌شده‌ها',
                    icon: Icons.notifications_active_rounded,
                    games: followed,
                    emptyTitle: 'هنوز چیزی را دنبال نمی‌کنی',
                    emptyMessage: 'بازی موردعلاقه‌ات را دنبال کن تا تغییرات مهمش در مرکز دنبال‌کردن نمایش داده شود.',
                    onReturn: _refresh,
                  ),
                ),
                const SizedBox(height: 24),
                GameonAnimatedIn(
                  delay: const Duration(milliseconds: 100),
                  child: _LibrarySection(
                    title: 'علاقه‌مندی‌ها',
                    icon: Icons.favorite_rounded,
                    games: wishlist,
                    emptyTitle: 'لیست علاقه‌مندی خالی است',
                    emptyMessage: 'بازی‌هایی که بعداً می‌خواهی بررسی کنی اینجا نگه دار.',
                    onReturn: _refresh,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LibrarySection extends StatelessWidget {
  const _LibrarySection({
    required this.title,
    required this.icon,
    required this.games,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onReturn,
  });

  final String title;
  final IconData icon;
  final List<GameSummary> games;
  final String emptyTitle;
  final String emptyMessage;
  final Future<void> Function() onReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 9),
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 12),
        if (games.isEmpty)
          GameonEmptyState(icon: icon, title: emptyTitle, message: emptyMessage)
        else
          ...games.asMap().entries.map((entry) {
            final game = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GameonAnimatedIn(
                delay: Duration(milliseconds: 30 * entry.key.clamp(0, 8)),
                child: GameonSurface(
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game)));
                    await onReturn();
                  },
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: game.thumbUrl == null
                              ? ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest)
                              : CachedNetworkImage(
                                  imageUrl: game.thumbUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const GameonSkeleton(width: 64, height: 64, radius: 14),
                                  errorWidget: (_, __, ___) => ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(game.title, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800))),
                      const Icon(Icons.chevron_left_rounded, color: GameonColors.textSecondary),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
