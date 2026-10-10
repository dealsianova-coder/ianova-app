import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';
import '../../core/format/money.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_models.dart';
import 'seller_service.dart';
import 'seller_ui.dart';

class SellerProductsTab extends StatefulWidget {
  const SellerProductsTab({
    super.key,
    required this.session,
    required this.service,
    required this.onExpired,
  });

  final SellerSession session;
  final SellerService service;
  final VoidCallback onExpired;

  @override
  State<SellerProductsTab> createState() => _SellerProductsTabState();
}

class _SellerProductsTabState extends State<SellerProductsTab> {
  SellerCatalog? _catalog;

  @override
  void initState() {
    super.initState();
    _refresh(() => widget.service.fetchCatalog(widget.session.token));
  }

  Future<void> _refresh(Future<SellerCatalog> Function() action) async {
    final catalog = await runSeller<SellerCatalog>(
      context: context,
      onExpired: widget.onExpired,
      action: action,
    );

    if (!mounted) return;

    setState(() {
      _catalog = catalog ??
          _catalog ??
          const SellerCatalog(products: [], categories: []);
    });
  }

  Future<void> _openForm([SellerProduct? product]) async {
    final catalog = _catalog;

    if (catalog == null) return;

    final result = await Navigator.of(context).push<SellerCatalog>(
      MaterialPageRoute(
        builder: (_) => SellerProductFormPage(
          session: widget.session,
          service: widget.service,
          categories: catalog.categories,
          product: product,
          onExpired: widget.onExpired,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _catalog = result);
    }
  }

  Future<void> _editStock(SellerProduct product) async {
    final controller = TextEditingController(text: '${product.stock}');

    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Stock quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context)
                .pop(int.tryParse(controller.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value == null || value < 0 || !mounted) return;

    await _refresh(
      () => widget.service.setStock(widget.session.token, product.id, value),
    );
  }

  Future<void> _delete(SellerProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${product.name}" will be removed from the store.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _refresh(
      () => widget.service.deleteProduct(widget.session.token, product.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: catalog == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: IanovaColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            ),
      body: RefreshIndicator(
        onRefresh: () =>
            _refresh(() => widget.service.fetchCatalog(widget.session.token)),
        child: catalog == null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : catalog.products.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'No products yet. Tap "Add product".',
                          style: TextStyle(color: IanovaColors.secondary),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      IanovaSpacing.lg,
                      IanovaSpacing.lg,
                      IanovaSpacing.lg,
                      96,
                    ),
                    itemCount: catalog.products.length,
                    itemBuilder: (context, index) {
                      final p = catalog.products[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: IanovaSpacing.md),
                        decoration: sellerCardDecoration(),
                        child: ListTile(
                          onTap: () => _openForm(p),
                          leading: _ProductThumb(product: p),
                          contentPadding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                          title: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(formatKsh(p.price)),
                                Text(
                                  'Stock ${p.stock}',
                                  style: TextStyle(
                                    color: p.stock <= 3
                                        ? IanovaColors.danger
                                        : IanovaColors.secondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SellerPill(
                                  p.status == 'approved'
                                      ? 'Live'
                                      : sellerLabel(p.status),
                                  color: SellerPill.forStatus(p.status),
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _openForm(p);
                              if (value == 'stock') _editStock(p);
                              if (value == 'delete') _delete(p);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'stock',
                                child: Text('Update stock'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

Color _hexColor(String hex, [Color fallback = const Color(0xFFEFF3EC)]) {
  final clean = hex.replaceFirst('#', '');

  if (clean.length != 6) return fallback;

  final value = int.tryParse(clean, radix: 16);

  return value == null ? fallback : Color(0xFF000000 | value);
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product, this.size = 52});

  final SellerProduct product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        product.emoji.isEmpty ? '📦' : product.emoji,
        style: TextStyle(fontSize: size * 0.5),
      ),
    );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _hexColor(product.bgColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: product.image.isEmpty
          ? fallback
          : Image.network(
              IanovaApiConfig.imageUrl(product.image),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

const _swatches = <String>[
  '#EFF3EC',
  '#E6F0FF',
  '#FDE8EF',
  '#FFF1D6',
  '#F3F4F7',
  '#FFF1F4',
];

class SellerProductFormPage extends StatefulWidget {
  const SellerProductFormPage({
    super.key,
    required this.session,
    required this.service,
    required this.categories,
    required this.onExpired,
    this.product,
  });

  final SellerSession session;
  final SellerService service;
  final List<SellerCategory> categories;
  final VoidCallback onExpired;
  final SellerProduct? product;

  @override
  State<SellerProductFormPage> createState() => _SellerProductFormPageState();
}

class _SellerProductFormPageState extends State<SellerProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _original;
  late final TextEditingController _stock;
  late final TextEditingController _description;
  late final TextEditingController _subcategory;
  late final TextEditingController _color;
  late final TextEditingController _size;
  late final TextEditingController _emoji;
  int? _categoryId;
  String _bgColor = _swatches.first;
  bool _flash = false;
  String? _pickedPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final p = widget.product;

    String number(double? v) {
      if (v == null) return '';

      return v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();
    }

    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: number(p?.price));
    _original = TextEditingController(text: number(p?.originalPrice));
    _stock = TextEditingController(text: p == null ? '' : '${p.stock}');
    _description = TextEditingController(text: p?.description ?? '');
    _subcategory = TextEditingController(text: p?.subcategory ?? '');
    _color = TextEditingController(text: p?.color ?? '');
    _size = TextEditingController(text: p?.size ?? '');
    _emoji = TextEditingController(text: p?.emoji ?? '📦');
    _bgColor = (p?.bgColor.isNotEmpty ?? false) ? p!.bgColor : _swatches.first;
    _flash = p?.isFlashDeal ?? false;

    final ids = widget.categories.map((c) => c.id).toSet();

    _categoryId = ids.contains(p?.categoryId) ? p?.categoryId : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _original.dispose();
    _stock.dispose();
    _description.dispose();
    _subcategory.dispose();
    _color.dispose();
    _size.dispose();
    _emoji.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );

      if (file != null && mounted) {
        setState(() => _pickedPath = file.path);
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open your photos.')),
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final catalog = await runSeller<SellerCatalog>(
      context: context,
      onExpired: widget.onExpired,
      action: () => widget.service.saveProduct(
        widget.session.token,
        id: widget.product?.id,
        name: _name.text,
        categoryId: _categoryId!,
        price: double.parse(_price.text.trim()),
        originalPrice: _original.text.trim().isEmpty
            ? null
            : double.tryParse(_original.text.trim()),
        stock: int.tryParse(_stock.text.trim()) ?? 0,
        description: _description.text,
        subcategory: _subcategory.text,
        color: _color.text,
        size: _size.text,
        emoji: _emoji.text,
        bgColor: _bgColor,
        isFlashDeal: _flash,
        imagePath: _pickedPath,
      ),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (catalog != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            catalog.autoApprove
                ? 'Saved. Your listing is live.'
                : 'Saved. Our team will review the listing.',
          ),
        ),
      );
      Navigator.of(context).pop(catalog);
    }
  }

  Widget _photoPreview() {
    final p = widget.product;
    final Widget content;

    if (_pickedPath != null) {
      content = Image.file(File(_pickedPath!), fit: BoxFit.cover);
    } else if (p != null && p.image.isNotEmpty) {
      content = Image.network(
        IanovaApiConfig.imageUrl(p.image),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined),
      );
    } else {
      content = Center(
        child: Text(
          _emoji.text.isEmpty ? '📦' : _emoji.text,
          style: const TextStyle(fontSize: 44),
        ),
      );
    }

    return Container(
      width: 112,
      height: 112,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _hexColor(_bgColor),
        borderRadius: BorderRadius.circular(IanovaSpacing.radiusLarge),
      ),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;

    return Scaffold(
      backgroundColor: IanovaColors.background,
      appBar: AppBar(
        title: Text(
          editing ? 'Edit product' : 'Add product',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(IanovaSpacing.xl),
            children: [
              Row(
                children: [
                  _photoPreview(),
                  const SizedBox(width: IanovaSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickImage,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            _pickedPath != null ||
                                    (widget.product?.image.isNotEmpty ?? false)
                                ? 'Change photo'
                                : 'Add photo',
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'JPG, PNG or WEBP, up to 5MB.',
                          style: TextStyle(
                            fontSize: 12,
                            color: IanovaColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: IanovaSpacing.xl),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a product name.' : null,
              ),
              const SizedBox(height: IanovaSpacing.md),
              DropdownButtonFormField<int>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in widget.categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Choose a category.' : null,
              ),
              const SizedBox(height: IanovaSpacing.md),
              TextFormField(
                controller: _subcategory,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Subcategory',
                  helperText: 'Optional, e.g. Sneakers',
                ),
              ),
              const SizedBox(height: IanovaSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price (KSh)'),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());

                        return n == null || n <= 0 ? 'Enter a price.' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: IanovaSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _original,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Was price',
                        helperText: 'Optional',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: IanovaSpacing.md),
              TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock quantity'),
                validator: (v) => int.tryParse((v ?? '').trim()) == null
                    ? 'Enter how many you have.'
                    : null,
              ),
              const SizedBox(height: IanovaSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _color,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        helperText: 'Optional',
                      ),
                    ),
                  ),
                  const SizedBox(width: IanovaSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _size,
                      decoration: const InputDecoration(
                        labelText: 'Size',
                        helperText: 'Optional',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: IanovaSpacing.md),
              TextFormField(
                controller: _emoji,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Emoji',
                  helperText: 'Shown when the product has no photo',
                ),
              ),
              const SizedBox(height: IanovaSpacing.md),
              const Text(
                'Card background',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  for (final hex in _swatches)
                    GestureDetector(
                      onTap: () => setState(() => _bgColor = hex),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _hexColor(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _bgColor == hex
                                ? IanovaColors.primary
                                : IanovaColors.border,
                            width: _bgColor == hex ? 2.5 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: IanovaSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _flash,
                onChanged: (v) => setState(() => _flash = v),
                title: const Text(
                  'Show in Flash deals',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextFormField(
                controller: _description,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: IanovaSpacing.md),
              const Text(
                'Unless the IANOVA team has marked you as a trusted seller, '
                'new and edited listings are reviewed before they show in '
                'the store.',
                style: TextStyle(fontSize: 12, color: IanovaColors.muted),
              ),
              const SizedBox(height: IanovaSpacing.xl),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: IanovaColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(IanovaSpacing.radiusMedium),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(editing ? 'Save changes' : 'Add product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
