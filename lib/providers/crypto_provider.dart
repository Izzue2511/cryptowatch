import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/crypto.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class CryptoProvider extends ChangeNotifier {
  CryptoProvider(this._prefs);

  final SharedPreferences _prefs;

  final List<Crypto> _all = [];
  bool _loading = false;
  String? _error;

  final Set<int> _favorites = {};

  // Currency state
  String _currency = 'USD';

  bool get isLoading => _loading;
  String? get error => _error;
  String get currency => _currency;
  String get currencySymbol => currencySymbolFor(_currency);

  List<Crypto> get cryptos => _all.take(kTopCount).toList();
  List<Crypto> get favorites =>
      _all.where((c) => _favorites.contains(c.id)).toList();

  Future<void> init() async {
    await _loadFavorites();
    await fetchCryptos();
  }

  Future<void> fetchCryptos() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final items = await ApiService.fetchCryptos(convert: _currency);
      _all
        ..clear()
        ..addAll(items);
    } catch (e) {
      _error = 'Failed to load data. ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setCurrency(String newCurrency) {
    if (newCurrency == _currency) return;
    _currency = newCurrency.toUpperCase();
    fetchCryptos();
  }

  Crypto? byId(int id) {
    try {
      return _all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isFavorite(int id) => _favorites.contains(id);

  void toggleFavorite(int id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    _persistFavorites();
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    final ids = _prefs.getStringList('favorites') ?? [];
    _favorites
      ..clear()
      ..addAll(ids.map(int.parse));
  }

  Future<void> _persistFavorites() async {
    await _prefs.setStringList(
      'favorites',
      _favorites.map((e) => e.toString()).toList(),
    );
  }
}
