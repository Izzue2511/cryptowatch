import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/crypto.dart';

class ApiService {
  static Future<List<Crypto>> fetchCryptos({String convert = 'USD'}) async {
    final uri = Uri.https(kApiHost, kApiPath, {
      ...kBaseQuery,
      'convert': convert,
    });

    final res = await http
        .get(
          uri,
          headers: {
            'User-Agent': 'Mozilla/5.0',
            'Accept': 'application/json, text/plain, */*',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final jsonBody = json.decode(res.body) as Map<String, dynamic>;
    final data =
        (jsonBody['data'] as Map<String, dynamic>)['cryptoCurrencyList']
            as List<dynamic>;
    final list = data
        .map((e) => Crypto.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }
}
