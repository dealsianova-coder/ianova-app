import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/format/money.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_extras.dart';
import 'seller_models.dart';
import 'seller_products_tab.dart';
import 'seller_service.dart';
import 'seller_ui.dart';

/// Read-only product page, like the website's product view. "Edit product" opens the form.
class SellerProductViewPage extends StatefulWidget {
  const SellerProductViewPage({
    super.key,
    required this.session,
    required this.service,
    required this.categories,
    required this.onExpired,
    required this.product,
  });

  final SellerSession session;
  final SellerService service;
  final List<SellerCategory> categories;
  final VoidCallback onExpired;
  final SellerProduct product;

  @override
  State<SellerProductViewPage> createState() => _SellerProductViewPageState();
}

class _SellerProductViewPageState extends State<SellerProductViewPage> {
  final _extras = SellerExtrasController();
  String? _shown;

  @override
  void initState() {
    super.initState();
    _shown = widget.product.image.isEmpty ? null : widget.product.image;
    _extras.addListener(() {
      if (mounted) setState(() {});
    });
    _extras.loadExisting(widget.session.token, widget.product.id);
  }

  @override
  void dispose() {
    _extras.dispose();
    super.dispose();
  }

  String _status(SellerProduct p) {
    if (p.locked) return 'Locked by admin';
    switch (p.status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Waiting for review';
      case 'rejected':
        return 'Rejected';
      case 'hidden':
        return 'Hidden by admin';
    }
    return p.status;
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: IanovaColors.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit() async {
    final result = await Navigator.of(context).push<SellerCatalog>(
      MaterialPageRoute(
        builder: (_) => SellerProductFormPage(
          session: widget.session,
          service: widget.service,
          categories: widget.categories,
          product: widget.product,
          onExpired: widget.onExpired,
        ),
      ),
    );

    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final images = <String>[
      if (p.image.isNotEmpty) p.image,
      for (final g in _extras.existing)
        if ('${g['image']}'.isNotEmpty && '${g['image']}' != p.image)
          '${g['image']}',
    ];
    final cats = widget.categories.where((c) => c.id == p.categoryId);
    final category = cats.isEmpty ? '' : cats.first.name;
    final option = '${p.color} ${p.size}'.trim();

    return Scaffold(
      backgroundColor: IanovaColors.background,
      appBar: AppBar(
        title: const Text(
          'Product',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(IanovaSpacing.xl),
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(IanovaSpacing.radiusLarge),
                child: LayoutBuilder(
                  builder: (context, box) => _shown != null
                      ? Image.network(
                          IanovaApiConfig.imageUrl(_shown!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => SellerThumb(
                            image: '',
                            emoji: p.emoji,
                            bgColor: p.bgColor,
                            size: box.maxWidth,
                          ),
                        )
                      : SellerThumb(
                          image: '',
                          emoji: p.emoji,
                          bgColor: p.bgColor,
                          size: box.maxWidth,
                        ),
                ),
              ),
            ),
            if (images.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _shown = images[i]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        IanovaApiConfig.imageUrl(images[i]),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(width: 64, height: 64),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: IanovaSpacing.lg),
            Text(
              p.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  formatKsh(p.price),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (p.originalPrice != null && p.originalPrice! > p.price) ...[
                  const SizedBox(width: 8),
                  Text(
                    formatKsh(p.originalPrice!),
                    style: const TextStyle(
                      color: IanovaColors.muted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: IanovaSpacing.md),
            _row('Status', _status(p)),
            _row('Stock', p.stock <= 0 ? '${p.stock} · out of stock' : '${p.stock}'),
            if (category.isNotEmpty)
              _row(
                'Category',
                p.subcategory.isEmpty ? category : '$category · ${p.subcategory}',
              ),
            if (option.isNotEmpty) _row('Color / size', option),
            _row('Flash deal', p.isFlashDeal ? 'Yes' : 'No'),
            if (p.description.trim().isNotEmpty) ...[
              const SizedBox(height: IanovaSpacing.md),
              Text(p.description),
            ],
            const SizedBox(height: IanovaSpacing.xl),
            if (p.locked)
              const Text(
                'This product is locked by the admin. Use Request review in Products.',
                style: TextStyle(color: IanovaColors.muted, fontSize: 13),
              )
            else
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _edit,
                  style: FilledButton.styleFrom(
                    backgroundColor: IanovaColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(IanovaSpacing.radiusMedium),
                    ),
                  ),
                  child: const Text('Edit product'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
