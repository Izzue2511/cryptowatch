double? _asDouble(dynamic v) => (v is num) ? v.toDouble() : null;
int? _asInt(dynamic v) => (v is num) ? v.toInt() : null;

class Quote {
  final String name; // quote currency (USD, EUR, etc.)
  final double price;
  final double? percentChange24h;
  final double? percentChange7d;
  final double? percentChange30d;
  final double? marketCap;
  final double? volume24h;
  final double? volume7d;
  final double? volume30d;

  Quote({
    required this.name,
    required this.price,
    this.percentChange24h,
    this.percentChange7d,
    this.percentChange30d,
    this.marketCap,
    this.volume24h,
    this.volume7d,
    this.volume30d,
  });

  factory Quote.fromJson(Map<dynamic, dynamic> json) {
    return Quote(
      name: json['name'] ?? 'USD',
      price: _asDouble(json['price']) ?? 0.0,
      percentChange24h: _asDouble(json['percentChange24h']),
      percentChange7d: _asDouble(json['percentChange7d']),
      percentChange30d: _asDouble(json['percentChange30d']),
      marketCap: _asDouble(json['marketCap']),
      volume24h: _asDouble(json['volume24h']),
      volume7d: _asDouble(json['volume7d']) ?? _asDouble(json['volume_7d']),
      volume30d: _asDouble(json['volume30d']) ?? _asDouble(json['volume_30d']),
    );
  }
}

class Crypto {
  final int id;
  final String name;
  final String symbol;
  final String? slug;
  final int? cmcRank;

  final double? ath;
  final double? atl;
  final double? high24h;
  final double? low24h;

  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;

  final int? numMarketPairs;
  final DateTime? dateAdded;

  final Quote quote;

  Crypto({
    required this.id,
    required this.name,
    required this.symbol,
    required this.quote,
    this.slug,
    this.cmcRank,
    this.ath,
    this.atl,
    this.high24h,
    this.low24h,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.numMarketPairs,
    this.dateAdded,
  });

  String get iconUrl =>
      'https://s2.coinmarketcap.com/static/img/coins/64x64/$id.png';

  double? get supplyPct {
    if (circulatingSupply == null || totalSupply == null || totalSupply == 0) {
      return null;
    }
    return (circulatingSupply! / totalSupply!).clamp(0.0, 1.0);
  }

  factory Crypto.fromJson(Map<String, dynamic> json) {
    final quotes = (json['quotes'] as List?) ?? [];
    final firstQuote = quotes.isNotEmpty
        ? quotes.first as Map<String, dynamic>
        : {};

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    // Handle snake_case and camelCase keys that CMC may use
    final circ =
        _asDouble(json['circulatingSupply']) ??
        _asDouble(json['circulating_supply']);
    final total =
        _asDouble(json['totalSupply']) ?? _asDouble(json['total_supply']);
    final max = _asDouble(json['maxSupply']) ?? _asDouble(json['max_supply']);
    final pairs =
        _asInt(json['numMarketPairs']) ?? _asInt(json['num_market_pairs']);
    final added = parseDate(json['dateAdded'] ?? json['date_added']);

    return Crypto(
      id: json['id'],
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      slug: json['slug'],
      cmcRank: _asInt(json['cmcRank']),
      ath: _asDouble(json['ath']),
      atl: _asDouble(json['atl']),
      high24h: _asDouble(json['high24h']),
      low24h: _asDouble(json['low24h']),
      circulatingSupply: circ,
      totalSupply: total,
      maxSupply: max,
      numMarketPairs: pairs,
      dateAdded: added,
      quote: Quote.fromJson(firstQuote),
    );
  }
}
