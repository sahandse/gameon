class GameDetails {
  const GameDetails({
    required this.id,
    required this.title,
    this.description,
    this.shortDescription,
    this.thumbnailUrl,
    this.heroUrl,
    this.genre,
    this.platform,
    this.publisher,
    this.developer,
    this.releaseDate,
    this.status,
    this.officialUrl,
    this.minimumOs,
    this.minimumProcessor,
    this.minimumMemory,
    this.minimumGraphics,
    this.minimumStorage,
    this.screenshots = const <String>[],
    this.sourceLabel,
  });

  final String id;
  final String title;
  final String? description;
  final String? shortDescription;
  final String? thumbnailUrl;
  final String? heroUrl;
  final String? genre;
  final String? platform;
  final String? publisher;
  final String? developer;
  final DateTime? releaseDate;
  final String? status;
  final String? officialUrl;
  final String? minimumOs;
  final String? minimumProcessor;
  final String? minimumMemory;
  final String? minimumGraphics;
  final String? minimumStorage;
  final List<String> screenshots;
  final String? sourceLabel;
}
