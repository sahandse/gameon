class GameSummary {
  const GameSummary({
    required this.id,
    required this.title,
    this.thumbUrl,
    this.normalPrice,
    this.salePrice,
    this.discountPercent,
    this.storeId,
  });

  final String id;
  final String title;
  final String? thumbUrl;
  final double? normalPrice;
  final double? salePrice;
  final int? discountPercent;
  final String? storeId;

  bool get isFree => (salePrice ?? normalPrice) == 0;
  bool get isDiscounted =>
      salePrice != null && normalPrice != null && salePrice! < normalPrice!;
}
