import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gameon/src/data/models/news_item.dart';
import 'package:xml/xml.dart';

class NewsRssApi {
  NewsRssApi([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
              responseType: ResponseType.plain,
              headers: const <String, String>{
                'User-Agent': 'Gameon/0.2.0 (Flutter; sahandse/gameon)',
                'Accept': 'application/rss+xml, application/atom+xml, application/xml, text/xml, */*',
              },
            ));

  final Dio _dio;

  static const sources = <_NewsSource>[
    _NewsSource('ویجیاتو', 'https://vigiato.net/feed', 'iranian'),
    _NewsSource('دنیای بازی', 'https://feeds.dbazi.com/dbazi', 'iranian'),
    _NewsSource('PlayStation Blog', 'https://blog.playstation.com/feed/', 'international'),
    _NewsSource('Xbox Wire', 'https://news.xbox.com/en-us/feed/', 'international'),
  ];

  Future<List<NewsItem>> fetchAll() async {
    final batches = await Future.wait(
      sources.map((source) async {
        try {
          return await _fetchSource(source);
        } catch (_) {
          return const <NewsItem>[];
        }
      }),
    );

    final merged = <String, NewsItem>{};
    for (final item in batches.expand((e) => e)) {
      merged.putIfAbsent(item.link, () => item);
    }
    final items = merged.values.toList();
    items.sort((a, b) {
      final ad = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return items.take(100).toList();
  }

  Future<List<NewsItem>> _fetchSource(_NewsSource source) async {
    final response = await _dio.get<String>(source.url);
    final raw = response.data ?? '';
    if (raw.trim().isEmpty) return const <NewsItem>[];
    final document = XmlDocument.parse(raw);

    final rssItems = document.findAllElements('item').toList();
    if (rssItems.isNotEmpty) {
      return rssItems.map((node) => _fromRss(node, source)).whereType<NewsItem>().toList();
    }

    return document.findAllElements('entry').map((node) => _fromAtom(node, source)).whereType<NewsItem>().toList();
  }

  NewsItem? _fromRss(XmlElement node, _NewsSource source) {
    final title = _text(node, 'title');
    final link = _text(node, 'link');
    if (title.isEmpty || link.isEmpty) return null;
    final summaryRaw = _text(node, 'description');
    final guid = _text(node, 'guid');
    final pubDate = _text(node, 'pubDate');
    final image = _extractImage(node, summaryRaw);

    return NewsItem(
      id: guid.isNotEmpty ? guid : link,
      title: _decodeEntities(_stripHtml(title)),
      link: link,
      source: source.name,
      sourceType: source.type,
      summary: _cleanSummary(summaryRaw),
      imageUrl: image,
      publishedAt: _parseDate(pubDate),
    );
  }

  NewsItem? _fromAtom(XmlElement node, _NewsSource source) {
    final title = _text(node, 'title');
    final linkNode = node.findElements('link').firstOrNull;
    final link = linkNode?.getAttribute('href') ?? '';
    if (title.isEmpty || link.isEmpty) return null;
    final summaryRaw = _text(node, 'summary').isNotEmpty ? _text(node, 'summary') : _text(node, 'content');
    final dateRaw = _text(node, 'published').isNotEmpty ? _text(node, 'published') : _text(node, 'updated');

    return NewsItem(
      id: _text(node, 'id').isNotEmpty ? _text(node, 'id') : link,
      title: _decodeEntities(_stripHtml(title)),
      link: link,
      source: source.name,
      sourceType: source.type,
      summary: _cleanSummary(summaryRaw),
      imageUrl: _extractImage(node, summaryRaw),
      publishedAt: _parseDate(dateRaw),
    );
  }

  String _text(XmlElement node, String name) => node.findElements(name).firstOrNull?.innerText.trim() ?? '';

  String? _extractImage(XmlElement node, String html) {
    for (final element in node.descendants.whereType<XmlElement>()) {
      final local = element.name.local.toLowerCase();
      if (local == 'content' || local == 'thumbnail' || local == 'enclosure') {
        final url = element.getAttribute('url');
        if (url != null && url.startsWith('http')) return url;
      }
    }
    final match = RegExp(r'<img[^>]+src=["\']([^"\']+)["\']', caseSensitive: false).firstMatch(html);
    return match?.group(1);
  }

  String? _cleanSummary(String value) {
    final cleaned = _decodeEntities(_stripHtml(value)).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return null;
    return cleaned.length <= 260 ? cleaned : '${cleaned.substring(0, 257)}…';
  }

  String _stripHtml(String value) => value.replaceAll(RegExp(r'<[^>]*>'), ' ');

  String _decodeEntities(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    final direct = DateTime.tryParse(value);
    if (direct != null) return direct.toLocal();
    try {
      return HttpDate.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }
}

class _NewsSource {
  const _NewsSource(this.name, this.url, this.type);
  final String name;
  final String url;
  final String type;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
