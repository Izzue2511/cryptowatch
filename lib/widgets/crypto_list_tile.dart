import 'package:cryptowatch/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/formatters.dart';
import '../models/crypto.dart';
import '../providers/crypto_provider.dart';

class CryptoListTile extends StatelessWidget {
  const CryptoListTile({super.key, required this.crypto, required this.onTap});

  final Crypto crypto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Listen only to the values this tile cares about

    final isFav = context.select<CryptoProvider, bool>(
      (p) => p.isFavorite(crypto.id),
    );
    final pct = crypto.quote.percentChange24h;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Hero(
                tag: 'coin-${crypto.id}',
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  child: ClipOval(
                    child: Image.network(
                      crypto.iconUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.currency_bitcoin),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${crypto.name} • ${crypto.symbol}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formatPrice(
                            crypto.quote.price,
                            currencySymbol: context
                                .read<CryptoProvider>()
                                .currencySymbol,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(
                              isUp(pct)
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 14,
                              color: isUp(pct)
                                  ? const Color(kGreenHex)
                                  : const Color(kRedHex),
                            ),
                            Text(
                              formatPercent(pct),
                              style: TextStyle(
                                color: isUp(pct)
                                    ? const Color(kGreenHex)
                                    : const Color(kRedHex),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav
                      ? Colors.amber
                      : Theme.of(context).iconTheme.color,
                ),
                onPressed: () =>
                    context.read<CryptoProvider>().toggleFavorite(crypto.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
