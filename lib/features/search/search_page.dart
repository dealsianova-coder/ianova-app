import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/product.dart';
import '../../widgets/ianova_product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    this.onProductTap,
    this.onCartChanged,
    this.initialQuery = '',
  });

  final String initialQuery;
  final ValueChanged<Product>? onProductTap;
  final VoidCallback? onCartChanged;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();

  List<Product> _all = const [];
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
    _query = widget.initialQuery.trim();
    _loadProducts();
  }

  @override
  void dispose() {
    _controller.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final products = await _api.getProducts();

      if (!mounted) return;

      setState(() {
        _all = products;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to connect to IANOVA.';
        _loading = false;
      });
    }
  }

  List<Product> get _results {
    final terms = _query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();

    if (terms.isEmpty) {
      return const [];
    }

    final matches = _all.where((product) {
      final haystack =
          '${product.name} ${product.description} ${product.sellerName}'
              .toLowerCase();

      return terms.every((term) => haystack.contains(term));
    }).toList();

    // Products whose name matches come first.
    final nameMatches = matches
        .where(
          (product) => product.name.toLowerCase().contains(terms.first),
        )
        .toList();
    final others = matches
        .where((product) => !nameMatches.contains(product))
        .toList();

    return [...nameMatches, ...others];
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              IanovaSpacing.xl,
              IanovaSpacing.sm,
              IanovaSpacing.xl,
              IanovaSpacing.md,
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _query = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(IanovaSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48),
              const SizedBox(height: IanovaSpacing.md),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: IanovaSpacing.lg),
              FilledButton(
                onPressed: _loadProducts,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_query.isEmpty) {
      return const _Hint(
        icon: Icons.search_rounded,
        title: 'Search IANOVA',
        message: 'Find products by name or description.',
      );
    }

    final results = _results;

    if (results.isEmpty) {
      return _Hint(
        icon: Icons.search_off_rounded,
        title: 'No results',
        message: 'Nothing matched "$_query". Try a different word.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        IanovaSpacing.xl,
        IanovaSpacing.sm,
        IanovaSpacing.xl,
        IanovaSpacing.xxxl,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 14,
        childAspectRatio: 0.66,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];

        return IanovaProductCard(
          product: product,
          onTap: () => widget.onProductTap?.call(product),
          onCartChanged: widget.onCartChanged,
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(IanovaSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: IanovaColors.muted),
            const SizedBox(height: IanovaSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: IanovaSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: IanovaColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
