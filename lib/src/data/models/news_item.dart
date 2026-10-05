class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.link,
    required this.source,
    required this.sourceType,
    this.summary,
    this.imageUrl,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String link;
  final String source;
  final String sourceType;
  final String? summary;
  final String? imageUrl;
  final DateTime? publishedAt;

  bool get isIranian => sourceType == 'iranian';
}
