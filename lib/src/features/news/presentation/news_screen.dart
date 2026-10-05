import 'package:flutter/material.dart';
import 'package:gameon/src/theme/gameon_theme.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اخبار')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text('اخبار بازی، کاملاً فارسی', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'منابع رسمی پلتفرم‌ها و سایت‌های ایرانی تأییدشده اینجا تجمیع می‌شوند. هیچ خبر آزمایشی یا ساختگی نمایش داده نمی‌شود.',
            style: TextStyle(color: GameonColors.textSecondary, height: 1.7),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _NewsFilter('همه'),
              _NewsFilter('PlayStation'),
              _NewsFilter('Xbox'),
              _NewsFilter('PC'),
              _NewsFilter('Nintendo'),
              _NewsFilter('Game Pass'),
              _NewsFilter('PS Plus'),
            ],
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GameonColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GameonColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.newspaper_rounded, size: 34, color: GameonColors.accentCyan),
                SizedBox(height: 14),
                Text('منبع خبر هنوز متصل نشده', style: TextStyle(fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text(
                  'به‌محض اتصال منبع رسمی و سایت ایرانی که انتخاب می‌کنی، خبرها با عنوان، تصویر، زمان انتشار، خلاصه فارسی، منبع و بازی مرتبط اینجا نمایش داده می‌شوند.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GameonColors.textSecondary, height: 1.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsFilter extends StatelessWidget {
  const _NewsFilter(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: GameonColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: GameonColors.border),
        ),
        child: Text(label, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
      );
}
