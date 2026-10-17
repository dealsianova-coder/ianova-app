import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/format/money.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_extras.dart';
import 'seller_models.dart';
import 'seller_panel_ui.dart';
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
  List<SellerProduct> _others = const [];

  @override
  void initState() {
    super.initState();
    _shown = widget.product.image.isEmpty ? null : widget.product.image;
    _extras.addListener(() {
      if (mounted) setState(() {});
    });
    _extras.loadExisting(widget.session.token, widget.product.id);
    _loadOthers();
  }

  Future<void> _loadOthers() async {
    try {
      final c = await widget.service.fetchCatalog(widget.session.token);
      final p = widget.product;
      final list = c.products
          .where((o) =>
              o.id != p.id &&
              o.categoryId == p.categoryId &&
              o.name.trim().toLowerCase() == p.name.trim().toLowerCase())
          .toList();
      if (mounted) setState(() => _others = list);
    } catch (_) {}
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

  Widget _block(Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: IanovaColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F0F12), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  Widget _tile(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: IanovaColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: IanovaColors.muted, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  String _pillKind(SellerProduct p) =>
      p.locked || p.status == 'rejected' || p.status == 'hidden'
          ? 'bad'
          : (p.status == 'approved' ? 'ok' : 'warn');

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
          padding: const EdgeInsets.all(IanovaSpacing.lg),
          children: [
            _block(Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: LayoutBuilder(
                      builder: (context, box) => _shown != null
                          ? Image.network(
                              IanovaApiConfig.imageUrl(_shown!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => SellerThumb(
                                image: '', emoji: p.emoji, bgColor: p.bgColor, size: box.maxWidth),
                            )
                          : SellerThumb(
                              image: '', emoji: p.emoji, bgColor: p.bgColor, size: box.maxWidth),
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
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _shown == images[i] ? IanovaColors.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              IanovaApiConfig.imageUrl(images[i]),
                              width: 60, height: 60, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(width: 60, height: 60),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            )),
            _block(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SPill(_status(p), _pillKind(p)),
                const SizedBox(height: 10),
                Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatKsh(p.price), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    if (p.originalPrice != null && p.originalPrice! > p.price) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(formatKsh(p.originalPrice!),
                            style: const TextStyle(color: IanovaColors.muted, decoration: TextDecoration.lineThrough)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _tile('In stock', '${p.stock}',
                        valueColor: p.stock <= 0 ? const Color(0xFFB00F2F) : null),
                    const SizedBox(width: 10),
                    _tile('Options', '${_others.length + 1}'),
                    const SizedBox(width: 10),
                    _tile('Flash deal', p.isFlashDeal ? 'Yes' : 'No'),
                  ],
                ),
                if (p.stock <= 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Out of stock', style: TextStyle(color: Color(0xFFB00F2F), fontWeight: FontWeight.w700)),
                  ),
              ],
            )),
            _block(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 6),
                if (category.isNotEmpty)
                  _row('Category', p.subcategory.isEmpty ? category : '$category · ${p.subcategory}'),
                if (option.isNotEmpty) _row('Color / size', option),
                _row('Status', _status(p)),
              ],
            )),
            if (p.description.trim().isNotEmpty)
              _block(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(p.description, style: const TextStyle(height: 1.45)),
                ],
              )),
            if (_others.isNotEmpty)
              _block(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Other colors & sizes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 118,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _others.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final o = _others[i];
                        final label = '${o.color} ${o.size}'.trim();
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => SellerProductViewPage(
                                session: widget.session,
                                service: widget.service,
                                categories: widget.categories,
                                onExpired: widget.onExpired,
                                product: o,
                              ),
                            ),
                          ),
                          child: Container(
                            width: 92,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                SellerThumb(image: o.image, emoji: o.emoji, bgColor: o.bgColor, size: 64),
                                const SizedBox(height: 6),
                                Text(
                                  label.isEmpty ? 'Option' : label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )),
            const SizedBox(height: IanovaSpacing.sm),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Edit product', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            const SizedBox(height: IanovaSpacing.lg),
          ],
        ),
      ),
    );
  }
}
