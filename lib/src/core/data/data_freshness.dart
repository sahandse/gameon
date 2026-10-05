enum DataFreshness { live, cached, stale, unavailable }

class DataEnvelope<T> {
  const DataEnvelope({
    required this.data,
    required this.freshness,
    required this.fetchedAt,
    this.source,
  });

  final T? data;
  final DataFreshness freshness;
  final DateTime? fetchedAt;
  final String? source;

  bool get hasRealData => data != null && freshness != DataFreshness.unavailable;
}

/// Production repositories must never substitute fabricated values when a
/// provider fails. Return an unavailable/stale envelope and let the UI explain
/// the state clearly to the user.
abstract interface class RealDataRepository<T> {
  Future<DataEnvelope<T>> fetch();
}
