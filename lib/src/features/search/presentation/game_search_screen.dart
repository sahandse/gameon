import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gameon/src/data/models/game_summary.dart';
import 'package:gameon/src/data/remote/cheapshark_api.dart';
import 'package:gameon/src/features/game/presentation/game_detail_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';

class GameSearchScreen extends StatefulWidget {
  const GameSearchScreen({super.key});

  @override
  State<GameSearchScreen> createState() => _GameSearchScreenState();
}

class _GameSearchScreenState extends State<GameSearchScreen> {
  final CheapSharkApi _api = CheapSharkApi();
  final TextEditingController _controller = TextEditingController();
  List<GameSummary> _results = const <GameSummary>[];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _loading) return;
    GameonHaptics.tap();
    setState(() {
      _loading = true;
      _searched = true;
      _error = null;
    });
    try {
      final results = await _api.searchGames(query);
      if (!mounted) return;
      setState(() => _results = results);
      if (results.isNotEmpty) GameonHaptics.confirm();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'دریافت نتیجه از منبع واقعی ناموفق بود.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جستجوی بازی')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: GameonAnimatedIn(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'نام بازی را بنویس…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'جستجو',
                      onPressed: _search,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    GameonSkeleton(width: double.infinity, height: 96, radius: 20),
                    SizedBox(height: 10),
                    GameonSkeleton(width: double.infinity, height: 96, radius: 20),
                    SizedBox(height: 10),
                    GameonSkeleton(width: double.infinity, height: 96, radius: 20),
                  ],
                ),
              ),
            if (_error != null && !_loading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: GameonEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'اتصال برقرار نشد',
                  message: _error!,
                  actionLabel: 'تلاش دوباره',
                  onAction: _search,
                ),
              ),
            if (!_loading && _error == null)
              Expanded(
                child: _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                        child: GameonEmptyState(
                          icon: _searched ? Icons.search_off_rounded : Icons.sports_esports_rounded,
                          title: _searched ? 'چیزی پیدا نشد' : 'بازی موردنظرت را پیدا کن',
                          message: _searched
                              ? 'برای این عبارت نتیجه‌ای از منبع واقعی پیدا نشد. نام دیگری را امتحان کن.'
                              : 'جستجو از دیتای واقعی انجام می‌شود و هیچ نتیجه آزمایشی نمایش داده نمی‌شود.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final game = _results[index];
                          return GameonAnimatedIn(
                            delay: Duration(milliseconds: 35 * index.clamp(0, 8)),
                            child: GameonSurface(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game)),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: game.thumbUrl == null
                                          ? ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest)
                                          : CachedNetworkImage(
                                              imageUrl: game.thumbUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => const GameonSkeleton(width: 72, height: 72, radius: 14),
                                              errorWidget: (_, __, ___) => ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      game.title,
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_left_rounded, color: GameonColors.textSecondary),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
