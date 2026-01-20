import 'package:cryptowatch/core/app_theme.dart';
import 'package:cryptowatch/models/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/crypto_provider.dart';
import '../widgets/crypto_list_tile.dart';
import '../widgets/error_view.dart';
import '../core/formatters.dart';
import '../core/constants.dart';
import 'details_screen.dart';
import 'favorites_screen.dart';

enum SortKey { rank, price, change24h, name }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  SortKey _sortKey = SortKey.rank;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _query = '');
    FocusScope.of(context).unfocus();
  }

  List<Crypto> _applySort(List<Crypto> list) {
    final l = [...list];
    switch (_sortKey) {
      case SortKey.rank:
        l.sort(
          (a, b) => (a.cmcRank ?? 1 << 30).compareTo(b.cmcRank ?? 1 << 30),
        );
        break;
      case SortKey.price:
        l.sort((b, a) => a.quote.price.compareTo(b.quote.price));
        break;
      case SortKey.change24h:
        double p(Crypto c) => c.quote.percentChange24h ?? -1e12;
        l.sort((b, a) => p(a).compareTo(p(b)));
        break;
      case SortKey.name:
        l.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CryptoProvider>();
    final q = _query.trim().toLowerCase();

    // Filter top list by name or symbol
    final filtered = provider.cryptos.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.symbol.toLowerCase().contains(q);
    }).toList();

    final shown = _applySort(filtered);

    // Compute movers (only when search is empty)
    final movers = [...provider.cryptos]
      ..removeWhere((c) => c.quote.percentChange24h == null);
    movers.sort(
      (b, a) => (a.quote.percentChange24h ?? 0).compareTo(
        b.quote.percentChange24h ?? 0,
      ),
    );
    final topGainers = movers.take(5).toList();
    final topLosers = movers.reversed.take(5).toList();
    final hasHeader = _query.isEmpty && movers.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Cryptocurrencies'),
        actions: [
          // Currency switcher
          PopupMenuButton<String>(
            initialValue: provider.currency,
            onSelected: (v) => context.read<CryptoProvider>().setCurrency(v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'USD', child: Text('USD \$')),
              PopupMenuItem(value: 'EUR', child: Text('EUR €')),
              PopupMenuItem(value: 'GBP', child: Text('GBP £')),
              PopupMenuItem(value: 'INR', child: Text('INR ₹')),
              PopupMenuItem(value: 'JPY', child: Text('JPY ¥')),
            ],
            icon: const Icon(Icons.attach_money_rounded),
            tooltip: 'Currency',
          ),
          IconButton(
            icon: const Icon(Icons.star_rounded),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _query = val),
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by name or symbol (e.g., bitcoin, BTC)',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: _clearSearch,
                            tooltip: 'Clear',
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Sort chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Rank'),
                        selected: _sortKey == SortKey.rank,
                        onSelected: (_) =>
                            setState(() => _sortKey = SortKey.rank),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Price'),
                        selected: _sortKey == SortKey.price,
                        onSelected: (_) =>
                            setState(() => _sortKey = SortKey.price),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('24h Change'),
                        selected: _sortKey == SortKey.change24h,
                        onSelected: (_) =>
                            setState(() => _sortKey = SortKey.change24h),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Name'),
                        selected: _sortKey == SortKey.name,
                        onSelected: (_) =>
                            setState(() => _sortKey = SortKey.name),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
            ? ErrorView(
                message: provider.error!,
                onRetry: provider.fetchCryptos,
              )
            : RefreshIndicator(
                onRefresh: provider.fetchCryptos,
                child: shown.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              _query.isEmpty
                                  ? 'No data available.'
                                  : 'No results for "$_query".',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: shown.length + (hasHeader ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (hasHeader && i == 0) {
                            return _TopMovers(
                              gainers: topGainers,
                              losers: topLosers,
                              currencySymbol: provider.currencySymbol,
                            );
                          }
                          final index = hasHeader ? i - 1 : i;
                          final c = shown[index];
                          return Dismissible(
                            key: ValueKey('coin-${c.id}'),
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              color: Colors.amber.withOpacity(0.2),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 28,
                              ),
                            ),
                            secondaryBackground: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.amber.withOpacity(0.2),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 28,
                              ),
                            ),
                            confirmDismiss: (dir) async {
                              HapticFeedback.lightImpact();
                              final p = context.read<CryptoProvider>();
                              p.toggleFavorite(c.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    p.isFavorite(c.id)
                                        ? '${c.symbol} added to favorites'
                                        : '${c.symbol} removed from favorites',
                                  ),
                                  duration: const Duration(milliseconds: 900),
                                ),
                              );
                              return false; // don't remove the tile
                            },
                            child: CryptoListTile(
                              crypto: c,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DetailsScreen(cryptoId: c.id),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}

class _TopMovers extends StatelessWidget {
  const _TopMovers({
    required this.gainers,
    required this.losers,
    required this.currencySymbol,
  });

  final List<Crypto> gainers;
  final List<Crypto> losers;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    if (gainers.isEmpty && losers.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Top Movers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final c in gainers)
                _MoverCard(
                  crypto: c,
                  positive: true,
                  currencySymbol: currencySymbol,
                ),
              for (final c in losers)
                _MoverCard(
                  crypto: c,
                  positive: false,
                  currencySymbol: currencySymbol,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoverCard extends StatelessWidget {
  const _MoverCard({
    required this.crypto,
    required this.positive,
    required this.currencySymbol,
  });
  final Crypto crypto;
  final bool positive;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final color = positive ? const Color(kGreenHex) : const Color(kRedHex);
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: cs.surfaceContainerHighest,
                backgroundImage: NetworkImage(crypto.iconUrl),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  crypto.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            crypto.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatPrice(crypto.quote.price, currencySymbol: currencySymbol),
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            '${(crypto.quote.percentChange24h ?? 0).toStringAsFixed(2)}%',
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
