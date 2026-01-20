import 'package:intl/intl.dart';

String formatPrice(double value, {String currencySymbol = '\$'}) {
  if (value >= 100000) {
    return NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: currencySymbol,
    ).format(value);
  }
  if (value >= 1) {
    final noSymbol = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: 2,
    );
    return '$currencySymbol${noSymbol.format(value)}';
  }
  return '$currencySymbol${value.toStringAsFixed(6)}';
}

String formatNumber(double value) {
  if (value >= 100000) {
    return NumberFormat.compact(locale: 'en_US').format(value);
  }
  return NumberFormat("#,##0.##", "en_US").format(value);
}

String formatPercent(double? value) {
  if (value == null) return '--';
  final fmt = NumberFormat("+#,##0.00;-#,##0.00", "en_US");
  return '${fmt.format(value)}%';
}

bool isUp(double? p) => (p ?? 0) >= 0;
