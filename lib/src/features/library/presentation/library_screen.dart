import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gameon/src/data/local/game_library_store.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/features/game/presentation/game_detail_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';

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

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('کتابخانه من')),
      body: FutureBuilder<(List<GameSummary>, List<GameSummary>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
          }
          final followed = snapshot.data?.$1 ?? const <GameSummary>[];
          final wishlist = snapshot.data?.$2 ?? const <GameSummary>[];
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _LibrarySection(title: 'دنبال‌شده‌ها', games: followed, onReturn: _refresh),
                const SizedBox(height: 28),
                _LibrarySection(title: 'Wishlist', games: wishlist, onReturn: _refresh),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LibrarySection extends StatelessWidget {
  const _LibrarySection({required this.title, required this.games, required this.onReturn});
  final String title;
  final List<GameSummary> games;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        if (games.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: GameonColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GameonColors.border),
            ),
            child: const Text('هنوز بازی‌ای اضافه نکردی.', style: TextStyle(color: GameonColors.textSecondary)),
          )
        else
          ...games.map((game) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game)));
                    onReturn();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GameonColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: GameonColors.border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: game.thumbUrl == null
                                ? const ColoredBox(color: GameonColors.background)
                                : CachedNetworkImage(
                                    imageUrl: game.thumbUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const ColoredBox(color: GameonColors.background),
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
              )),
      ],
    );
  }
}
