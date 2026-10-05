class GameSummary {
  const GameSummary({
    required this.id,
    required this.title,
    this.source,
    this.sourceId,
    this.steamAppId,
    this.thumbUrl,
    this.normalPrice,
    this.salePrice,
    this.discountPercent,
    this.storeId,
    this.storeUrl,
    this.shortDescription,
    this.genre,
    this.platform,
    this.publisher,
    this.developer,
    this.releaseDate,
    this.sourceUpdatedAt,
  });

  final String id;
  final String title;
  final String? source;
  final String? sourceId;
  final String? steamAppId;
  final String? thumbUrl;
  final double? normalPrice;
  final double? salePrice;
  final int? discountPercent;
  final String? storeId;
  final String? storeUrl;
  final String? shortDescription;
  final String? genre;
  final String? platform;
  final String? publisher;
  final String? developer;
  final DateTime? releaseDate;
  final DateTime? sourceUpdatedAt;

  bool get isFree => (salePrice ?? normalPrice) == 0;
  bool get isDiscounted =>
      salePrice != null && normalPrice != null && salePrice! < normalPrice!;
}
