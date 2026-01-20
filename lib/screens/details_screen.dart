import 'package:cryptowatch/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/crypto_provider.dart';
import '../core/constants.dart';
import '../core/formatters.dart';
import '../widgets/stat_chip.dart';
import '../widgets/stat_card.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.cryptoId});
  final int cryptoId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CryptoProvider>();
    final c = provider.byId(cryptoId);
    if (c == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Crypto not found')),
      );
    }

    final isFav = provider.isFavorite(c.id);
    final cs = Theme.of(context).colorScheme;
    final curr = provider.currency;

    // Range positions
    final price = c.quote.price;
    final low = c.low24h;
    final high = c.high24h;
    double? rangePos;
    if (low != null && high != null && high > low) {
      rangePos = ((price - low) / (high - low)).clamp(0.0, 1.0);
    }

    // Distance to ATH/ATL
    double? pctToAth;
    if (c.ath != null && c.ath! > 0) {
      pctToAth = (price / c.ath! - 1) * 100;
    }
    double? pctFromAtl;
    if (c.atl != null && c.atl! > 0) {
      pctFromAtl = (price / c.atl! - 1) * 100;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 190,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              title: Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 7),
                child: Text(
                  '${c.name} (${c.symbol})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primaryContainer, cs.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 16),
                    child: Hero(
                      tag: 'coin-${c.id}',
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: cs.surfaceContainerHighest,
                        child: ClipOval(
                          child: Image.network(
                            c.iconUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.currency_bitcoin),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav ? Colors.amber : Theme.of(context).iconTheme.color,
                ),
                onPressed: () => provider.toggleFavorite(c.id),
                tooltip: isFav ? 'Unfavorite' : 'Favorite',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and change chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatPrice(price, currencySymbol: curr),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      StatChip(
                        label: '24h',
                        value: c.quote.percentChange24h,
                        isPercent: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatChip(
                        label: '7d',
                        value: c.quote.percentChange7d,
                        isPercent: true,
                      ),
                      const SizedBox(width: 8),
                      StatChip(
                        label: '30d',
                        value: c.quote.percentChange30d,
                        isPercent: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Meta row: Rank, Pairs, Since
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaPill(
                        icon: Icons.verified_rounded,
                        label: 'Rank #${c.cmcRank ?? '-'}',
                      ),
                      if (c.numMarketPairs != null)
                        _MetaPill(
                          icon: Icons.swap_horiz_rounded,
                          label: '${c.numMarketPairs} pairs',
                        ),
                      if (c.dateAdded != null)
                        _MetaPill(
                          icon: Icons.calendar_today_rounded,
                          label: 'Since ${c.dateAdded!.year}',
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 24h range bar
                  if (rangePos != null) ...[
                    Text(
                      '24h Range',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RangeBar(
                      low: low!,
                      high: high!,
                      current: price,
                      currency: curr,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Key stats grid
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    children: [
                      StatCard(
                        title: 'Market Cap',
                        value: c.quote.marketCap == null
                            ? '--'
                            : formatPrice(
                                c.quote.marketCap!,
                                currencySymbol: curr,
                              ),
                      ),
                      StatCard(
                        title: '24h Volume',
                        value: c.quote.volume24h == null
                            ? '--'
                            : formatPrice(
                                c.quote.volume24h!,
                                currencySymbol: curr,
                              ),
                      ),
                      StatCard(
                        title: '7d Volume',
                        value: c.quote.volume7d == null
                            ? '--'
                            : formatPrice(
                                c.quote.volume7d!,
                                currencySymbol: curr,
                              ),
                      ),
                      StatCard(
                        title: '30d Volume',
                        value: c.quote.volume30d == null
                            ? '--'
                            : formatPrice(
                                c.quote.volume30d!,
                                currencySymbol: curr,
                              ),
                      ),
                      StatCard(
                        title: 'ATH',
                        value: c.ath == null ? '--' : formatPrice(c.ath!, currencySymbol: curr),
                      ),
                      StatCard(
                        title: 'ATL',
                        value: c.atl == null ? '--' : formatPrice(c.atl!, currencySymbol: curr),
                      ),
                      StatCard(
                        title: 'High 24h',
                        value: c.high24h == null
                            ? '--'
                            : formatPrice(c.high24h!, currencySymbol: curr),
                      ),
                      StatCard(
                        title: 'Low 24h',
                        value:
                            c.low24h == null ? '--' : formatPrice(c.low24h!, currencySymbol: curr),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Supply gauge
                  if (c.supplyPct != null) ...[
                    Text(
                      'Supply',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SupplyGauge(
                      percent: c.supplyPct!,
                      circulating: c.circulatingSupply,
                      total: c.totalSupply,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Distance to ATH/ATL
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (pctToAth != null)
                        _MetaPill(
                          icon: Icons.trending_up_rounded,
                          label: '${formatPercent(pctToAth)} from ATH',
                          color: isUp(pctToAth)
                              ? kGreenHex
                              : kRedHex, // green if above ATH, red if below
                        ),
                      if (pctFromAtl != null)
                        _MetaPill(
                          icon: Icons.trending_down_rounded,
                          label: '${formatPercent(pctFromAtl)} from ATL',
                          color: isUp(pctFromAtl) ? kGreenHex : kRedHex, // green if above ATL
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            provider.toggleFavorite(c.id);
                            final nowFav = provider.isFavorite(c.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  nowFav ? 'Added to favorites' : 'Removed from favorites',
                                ),
                                duration: const Duration(milliseconds: 900),
                              ),
                            );
                          },
                          icon: Icon(
                            isFav ? Icons.star_rounded : Icons.star_border_rounded,
                          ),
                          label: Text(isFav ? 'Favorited' : 'Add Favorite'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        tooltip: 'Copy symbol',
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: c.symbol),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Symbol copied'),
                              duration: Duration(milliseconds: 800),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Copy CMC URL',
                        onPressed: () async {
                          final slug = c.slug ?? c.name.toLowerCase();
                          final url = 'https://coinmarketcap.com/currencies/$slug/';
                          await Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link copied'),
                              duration: Duration(milliseconds: 800),
                            ),
                          );
                        },
                        icon: const Icon(Icons.link_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final int? color;

  @override
  Widget build(BuildContext context) {
    final c = color != null ? Color(color!) : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: c,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.low,
    required this.high,
    required this.current,
    required this.currency,
  });

  final double low;
  final double high;
  final double current;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = ((current - low) / (high - low)).clamp(0.0, 1.0);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, cts) {
            final w = cts.maxWidth;
            final x = w * pos;
            return Stack(
              children: [
                // Track
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Filled portion
                Container(
                  height: 10,
                  width: x,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Thumb
                Positioned(
                  left: (x - 6).clamp(0.0, w - 12),
                  top: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.25),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Low ${formatPrice(low, currencySymbol: currency)}',
              style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
            ),
            Text(
              'High ${formatPrice(high, currencySymbol: currency)}',
              style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
            ),
          ],
        ),
      ],
    );
  }
}

class _SupplyGauge extends StatelessWidget {
  const _SupplyGauge({
    required this.percent,
    required this.circulating,
    required this.total,
  });

  final double percent;
  final double? circulating;
  final double? total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pctText = '${(percent * 100).toStringAsFixed(2)}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: cs.surfaceContainerHighest.withOpacity(0.6),
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Circulating: ${circulating == null ? '--' : formatNumber(circulating!)}',
              style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
            ),
            const Spacer(),
            Text(
              'Total: ${total == null ? '--' : formatNumber(total!)} ($pctText)',
              style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
            ),
          ],
        ),
      ],
    );
  }
}

