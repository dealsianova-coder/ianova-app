import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';
import 'admin_api.dart';
import 'admin_bulk.dart';
import 'admin_dark.dart';
import 'admin_ui.dart';

const Map<String, String> _statusLabels = {
  '': 'All',
  'pending': 'Pending',
  'approved': 'Approved',
  'rejected': 'Rejected',
  'hidden': 'Hidden',
  'low': '⚠️ Low stock',
};

String _opt(Map<String, dynamic> p) {
  return '${aStr(p['color'])} ${aStr(p['size'])}'.trim();
}

String _subtitle(Map<String, dynamic> p) {
  final option = _opt(p);
  final base = '${aStr(p['category'])} · ${aStr(p['seller'])}';

  return option.isEmpty ? base : '$base · $option';
}

Color _statusColor(String status) {
  if (status == 'approved') return AC.okFg;
  if (status == 'pending') return AC.warnFg;

  return AC.red;
}

/// Products list: search, filter, approve, reject, hide, edit, delete.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({
    super.key,
    this.initialStatus = '',
    this.initialCategory = 0,
  });

  final String initialStatus;
  final int initialCategory;

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController _search = TextEditingController();

  late String _status;
  late int _category;
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  int _limit = 40;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _category = widget.initialCategory;
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await AdminApi.instance.panel(
        'products_list',
        query: {
          'q': _search.text.trim(),
          'status': _status,
          'category': '$_category',
          'limit': '$_limit',
        },
      );

      if (!mounted) return;

      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = adminErr(error);
        _loading = false;
      });
    }
  }

  void _more() {
    setState(() {
      _limit += 40;
      _loading = true;
    });
    _load();
  }

  void _reload({String? status, int? category}) {
    setState(() {
      _limit = 40;
      if (status != null) _status = status;
      if (category != null) _category = category;
      _loading = true;
    });
    _load();
  }

  Future<void> _act(Map<String, dynamic> p, String action) async {
    if (action == 'delete' &&
        !await adminConfirm(context, 'Delete "${aStr(p['name'])}"? This cannot be undone.')) {
      return;
    }

    if (action == 'hide' &&
        !await adminConfirm(context, 'Hide this product from the storefront?')) {
      return;
    }

    if (!mounted) return;

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel(
        'product_action',
        body: {'id': aInt(p['id']), 'do': action},
      ),
    );

    if (!mounted) return;

    if (ok) adminSay(context, 'Done.');
    _load();
  }

  Future<void> _edit(int id) async {
    await adminPush(context, AdminProductEditPage(id: id));
    _load();
  }

  Future<void> _view(int id) async {
    await adminPush(context, AdminProductViewPage(id: id));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    if (_loading && data == null) return const AdminLoading();
    if (data == null) return AdminLoading(error: _error, onRetry: _load);

    final counts = aMap(data['counts']);
    final products = aList(data['products']);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminButton('+ Add product', onPressed: () => _edit(0)),
              AdminButton('📤 Bulk upload', kind: 'gray', onPressed: () async {
                await adminPush(context, const AdminBulkPage());
                _load();
              }),
              if (_category > 0)
                AdminButton(
                  'Clear category filter',
                  kind: 'gray',
                  onPressed: () => _reload(category: 0),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AdminChipRow(
            children: [
              for (final entry in _statusLabels.entries)
                AdminChip(
                  label: entry.value,
                  count: aInt(counts[entry.key.isEmpty ? 'all' : entry.key]),
                  selected: _status == entry.key,
                  onTap: () => _reload(status: entry.key),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _reload(),
                  decoration: AdminField.decoration('Search products...'),
                ),
              ),
              const SizedBox(width: 8),
              AdminButton('Search', onPressed: () => _reload()),
            ],
          ),
          const SizedBox(height: 14),
          if (products.isEmpty) const AdminCard(child: AdminMuted('No products found.')),
          for (final p in products)
            AdminCard(
              onTap: () => _view(aInt(p['id'])),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminThumb(
                        image: aStr(p['image']),
                        emoji: aStr(p['emoji']),
                        bg: aStr(p['bg_color']),
                        size: 64,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              aStr(p['name']),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            Text(
                              _subtitle(p),
                              style: const TextStyle(color: AC.muted, fontSize: 12.5),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  aMoney(p['price']),
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'stock ${aInt(p['stock'])}',
                                  style: const TextStyle(color: AC.muted, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        aStr(p['status']).isEmpty
                            ? 'Approved'
                            : '${aStr(p['status'])[0].toUpperCase()}${aStr(p['status']).substring(1)}',
                        style: TextStyle(
                          color: _statusColor(aStr(p['status'])),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (aBool(p['is_flash_deal'])) const ATag('⚡ Flash', kind: 'wait'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (aStr(p['status']) == 'pending') ...[
                        AdminButton('Approve', small: true, onPressed: () => _act(p, 'approve')),
                        AdminButton('Reject', small: true, kind: 'red', onPressed: () => _act(p, 'reject')),
                      ],
                      AdminButton('Edit', small: true, kind: 'gray', onPressed: () => _edit(aInt(p['id']))),
                      if (aStr(p['status']) == 'hidden')
                        AdminButton('Unhide', small: true, onPressed: () => _act(p, 'unhide'))
                      else
                        AdminButton('Hide', small: true, kind: 'gold', onPressed: () => _act(p, 'hide')),
                      AdminButton('Delete', small: true, kind: 'red', onPressed: () => _act(p, 'delete')),
                    ],
                  ),
                ],
              ),
            ),
          if (aBool(data['more']))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: AdminButton('Show more products', kind: 'gray', busy: _loading, onPressed: _more),
            ),
          if (_loading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

/// One product: photos, price, stock, status, other colors.
class AdminProductViewPage extends StatefulWidget {
  const AdminProductViewPage({super.key, required this.id});

  final int id;

  @override
  State<AdminProductViewPage> createState() => _AdminProductViewPageState();
}

class _AdminProductViewPageState extends State<AdminProductViewPage> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  String? _shown;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AdminApi.instance.panel(
        'product_view',
        query: {'id': '${widget.id}'},
      );

      if (!mounted) return;

      final images = (data['images'] is List) ? (data['images'] as List) : const [];

      setState(() {
        _data = data;
        _shown = images.isEmpty ? null : '${images.first}';
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = adminErr(error);
        _loading = false;
      });
    }
  }

  Future<void> _edit() async {
    await adminPush(context, AdminProductEditPage(id: widget.id));
    _load();
  }

  Widget _row(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AC.muted, fontSize: 13)),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    Widget body;

    if (_loading) {
      body = const AdminLoading();
    } else if (data == null) {
      body = AdminLoading(error: _error, onRetry: _load);
    } else {
      final p = aMap(data['product']);
      final images = (data['images'] is List)
          ? (data['images'] as List).map((e) => '$e').toList()
          : <String>[];
      final others = aList(data['others']);
      final option = '${aStr(p['color'])} ${aStr(p['size'])}'.trim();
      final original = aNum(p['original_price']);
      final price = aNum(p['price']);

      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _shown == null
                        ? Container(
                            color: aHex(aStr(p['bg_color']), const Color(0xFFEFF3EC)),
                            alignment: Alignment.center,
                            child: Text(
                              aStr(p['emoji']).isEmpty ? '📦' : aStr(p['emoji']),
                              style: const TextStyle(fontSize: 72),
                            ),
                          )
                        : AdminKeepColors(
                            child: Image.network(
                              IanovaApiConfig.imageUrl(_shown!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(color: AC.soft),
                            ),
                          ),
                  ),
                ),
                if (images.length > 1) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 64,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final img in images)
                          GestureDetector(
                            onTap: () => setState(() => _shown = img),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: img == _shown ? AC.green : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: AdminKeepColors(
                                  child: Image.network(
                                    IanovaApiConfig.imageUrl(img),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const SizedBox(width: 60, height: 60),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  aStr(p['name']),
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(aMoney(price), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                    if (original > price) ...[
                      const SizedBox(width: 8),
                      Text(
                        aMoney(original),
                        style: const TextStyle(
                          color: AC.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                _row('Seller', Text(aStr(p['seller']), style: const TextStyle(fontWeight: FontWeight.w700))),
                _row('Status', Align(alignment: Alignment.centerLeft, child: ATag(aStr(p['status'])))),
                _row(
                  'Stock',
                  Text(
                    '${aInt(p['stock'])}${aInt(p['stock']) <= 0 ? ' · out of stock' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _row(
                  'Category',
                  Text(
                    '${aStr(p['category'])}${aStr(p['subcategory']).isEmpty ? '' : ' · ${aStr(p['subcategory'])}'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (option.isNotEmpty)
                  _row('Color / size', Text(option, style: const TextStyle(fontWeight: FontWeight.w700))),
                _row('Flash deal', Text(aBool(p['is_flash_deal']) ? 'Yes' : 'No', style: const TextStyle(fontWeight: FontWeight.w700))),
                if (aStr(p['description']).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(aStr(p['description'])),
                ],
                const SizedBox(height: 14),
                AdminButton('Edit product', onPressed: _edit),
              ],
            ),
          ),
          if (others.isNotEmpty)
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Other colors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final o in others)
                          GestureDetector(
                            onTap: () => adminPush(context, AdminProductViewPage(id: aInt(o['id']))),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  AdminThumb(image: aStr(o['image']), size: 64),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_opt(o)} · ${aInt(o['stock'])}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return AdminSubPage(title: 'Product', child: body);
  }
}

class _ColorOption {
  final TextEditingController color = TextEditingController();
  final TextEditingController stock = TextEditingController(text: '0');
  final TextEditingController price = TextEditingController();
  String? image;
  List<String> more = <String>[];

  void dispose() {
    color.dispose();
    stock.dispose();
    price.dispose();
  }
}

/// Add or edit a product with every option the website editor has.
class AdminProductEditPage extends StatefulWidget {
  const AdminProductEditPage({super.key, this.id = 0});

  final int id;

  @override
  State<AdminProductEditPage> createState() => _AdminProductEditPageState();
}

class _AdminProductEditPageState extends State<AdminProductEditPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _slug = TextEditingController();
  final TextEditingController _seller = TextEditingController(text: 'IANOVA Direct');
  final TextEditingController _sub = TextEditingController();
  final TextEditingController _color = TextEditingController();
  final TextEditingController _size = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _orig = TextEditingController();
  final TextEditingController _stock = TextEditingController(text: '0');
  final TextEditingController _rating = TextEditingController(text: '4.5');
  final TextEditingController _reviews = TextEditingController(text: '0');
  final TextEditingController _emoji = TextEditingController(text: '📦');
  final TextEditingController _bg = TextEditingController(text: '#EFF3EC');
  final TextEditingController _desc = TextEditingController();

  final List<_ColorOption> _options = <_ColorOption>[];
  final List<String> _newGallery = <String>[];
  final Set<int> _removeImages = <int>{};

  List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[];
  List<String> _subs = <String>[];
  List<Map<String, dynamic>> _gallery = <Map<String, dynamic>>[];
  String _category = '';
  String _mainImage = '';
  String? _newMain;
  bool _flash = false;
  String _showOn = 'both';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name, _slug, _seller, _sub, _color, _size, _price, _orig,
      _stock, _rating, _reviews, _emoji, _bg, _desc,
    ]) {
      c.dispose();
    }
    for (final o in _options) {
      o.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final form = await AdminApi.instance.panel('product_form_data');
      Map<String, dynamic>? view;

      if (widget.id > 0) {
        view = await AdminApi.instance.panel(
          'product_view',
          query: {'id': '${widget.id}'},
        );
      }

      if (!mounted) return;

      setState(() {
        _categories = aList(form['categories']);
        _subs = (form['subcategories'] is List)
            ? (form['subcategories'] as List).map((e) => '$e').toList()
            : <String>[];

        if (_categories.isNotEmpty) _category = '${aInt(_categories.first['id'])}';

        if (view != null) {
          final p = aMap(view['product']);
          _name.text = aStr(p['name']);
          _slug.text = aStr(p['slug']);
          _seller.text = aStr(p['seller_name']);
          _sub.text = aStr(p['subcategory']);
          _color.text = aStr(p['color']);
          _size.text = aStr(p['size']);
          _price.text = aStr(p['price']);
          _orig.text = p['original_price'] == null ? '' : aStr(p['original_price']);
          _stock.text = aStr(p['stock']);
          _rating.text = aStr(p['rating']);
          _reviews.text = aStr(p['review_count']);
          _emoji.text = aStr(p['emoji']);
          _bg.text = aStr(p['bg_color']);
          _desc.text = aStr(p['description']);
          _flash = aBool(p['is_flash_deal']);
          _showOn = kShowOn.containsKey(aStr(p['show_on'])) ? aStr(p['show_on']) : 'both';
          _category = '${aInt(p['category_id'])}';
          _mainImage = aStr(p['image']);
          _gallery = aList(view['gallery']);
        }

        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = adminErr(error);
        _loading = false;
      });
    }
  }

  Future<void> _pickMain() async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (f != null) setState(() => _newMain = f.path);
  }

  Future<void> _pickGallery() async {
    final files = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (files.isEmpty) return;

    setState(() {
      for (final f in files) {
        if (_newGallery.length < 10) _newGallery.add(f.path);
      }
    });
  }

  Future<void> _pickOptionImage(_ColorOption o) async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (f != null) setState(() => o.image = f.path);
  }

  Future<void> _pickOptionMore(_ColorOption o) async {
    final files = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (files.isEmpty) return;

    setState(() {
      o.more = files.take(10).map((f) => f.path).toList();
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      adminSay(context, 'Enter the product name.');
      return;
    }

    if (_category.isEmpty) {
      adminSay(context, 'Pick a category.');
      return;
    }

    final hasOptions = _options.any((o) => o.color.text.trim().isNotEmpty);

    if (hasOptions && _color.text.trim().isEmpty) {
      adminSay(context, 'Enter a Color for the main product before adding more colors.');
      return;
    }

    final fields = <String, String>{
      'id': '${widget.id}',
      'name': _name.text.trim(),
      'slug': _slug.text.trim(),
      'category_id': _category,
      'seller_name': _seller.text.trim(),
      'subcategory': _sub.text.trim(),
      'color': _color.text.trim(),
      'size': _size.text.trim(),
      'price': _price.text.trim(),
      'original_price': _orig.text.trim(),
      'stock': _stock.text.trim(),
      'rating': _rating.text.trim(),
      'review_count': _reviews.text.trim(),
      'emoji': _emoji.text.trim(),
      'bg_color': _bg.text.trim(),
      'description': _desc.text.trim(),
      'is_flash_deal': _flash ? '1' : '0',
      'show_on': _showOn,
      'del_img': _removeImages.join(','),
    };
    final files = <String, String>{};

    if (_newMain != null) files['image'] = _newMain!;

    for (var i = 0; i < _newGallery.length; i++) {
      files['gallery_$i'] = _newGallery[i];
    }

    for (var i = 0; i < _options.length && i < 20; i++) {
      final o = _options[i];

      if (o.color.text.trim().isEmpty) continue;

      fields['opt_color_$i'] = o.color.text.trim();
      fields['opt_stock_$i'] = o.stock.text.trim();
      fields['opt_price_$i'] = o.price.text.trim();

      if (o.image != null) files['opt_image_$i'] = o.image!;

      for (var j = 0; j < o.more.length; j++) {
        files['opt_more_${i}_$j'] = o.more[j];
      }
    }

    setState(() => _saving = true);

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panelUpload('product_save', fields, files),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) {
      adminSay(context, 'Product saved.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_loading) {
      body = const AdminLoading();
    } else if (_error != null) {
      body = AdminLoading(error: _error, onRetry: _load);
    } else {
      final catOptions = <String, String>{
        for (final c in _categories) '${aInt(c['id'])}': '${aStr(c['emoji'])} ${aStr(c['name'])}'.trim(),
      };

      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminField(label: 'Name', controller: _name),
                AdminField(label: 'Slug (made from the name if empty)', controller: _slug),
                AdminPicker(
                  label: 'Category',
                  value: _category,
                  options: catOptions,
                  onChanged: (v) => setState(() => _category = v),
                ),
                AdminField(label: 'Seller', controller: _seller),
                AdminField(
                  label: 'Subcategory (e.g. Men, Women)',
                  controller: _sub,
                  hint: _subs.isEmpty ? null : 'Used: ${_subs.take(6).join(', ')}',
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: AdminField(label: 'Color (optional)', controller: _color)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminField(label: 'Size (optional)', controller: _size, hint: 'e.g. 42, M'),
                    ),
                  ],
                ),
                const AdminMuted(
                  'Tip: add the same product name again with a different color or size, and customers can choose between them.',
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AdminField(
                        label: 'Price',
                        controller: _price,
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminField(
                        label: 'Original price',
                        controller: _orig,
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AdminField(label: 'Stock', controller: _stock, keyboard: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminField(
                        label: 'Rating (0-5)',
                        controller: _rating,
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminField(label: 'Reviews', controller: _reviews, keyboard: TextInputType.number),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: AdminField(label: 'Emoji fallback', controller: _emoji)),
                    const SizedBox(width: 12),
                    Expanded(child: AdminField(label: 'Background color', controller: _bg)),
                  ],
                ),
                AdminField(label: 'Description', controller: _desc, maxLines: 5),
                const Text('Main photo (max 5MB)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_newMain != null)
                      const ATag('New photo chosen', kind: 'ok')
                    else if (_mainImage.isNotEmpty)
                      AdminThumb(image: _mainImage, size: 56),
                    const SizedBox(width: 10),
                    AdminButton('Choose photo', kind: 'gray', small: true, onPressed: _pickMain),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'More photos - front, back, sides',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (_gallery.isNotEmpty) ...[
                  const AdminMuted('Tap a photo to remove it when you save.'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final g in _gallery)
                        GestureDetector(
                          onTap: () => setState(() {
                            final id = aInt(g['id']);
                            if (!_removeImages.add(id)) _removeImages.remove(id);
                          }),
                          child: Opacity(
                            opacity: _removeImages.contains(aInt(g['id'])) ? 0.35 : 1,
                            child: Stack(
                              children: [
                                AdminThumb(image: aStr(g['image']), size: 64),
                                if (_removeImages.contains(aInt(g['id'])))
                                  const Positioned.fill(
                                    child: Icon(Icons.delete_outline_rounded, color: AC.red),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    AdminButton('Add photos', kind: 'gray', small: true, onPressed: _pickGallery),
                    const SizedBox(width: 10),
                    if (_newGallery.isNotEmpty) ATag('${_newGallery.length} new', kind: 'ok'),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'More colors of this product',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const AdminMuted('Each color gets its own photo and stock. Leave price empty to use the main price.'),
                const SizedBox(height: 10),
                for (var i = 0; i < _options.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AC.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: AdminField(label: 'Color', controller: _options[i].color)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AdminField(
                                label: 'Stock',
                                controller: _options[i].stock,
                                keyboard: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        AdminField(
                          label: 'Price (optional)',
                          controller: _options[i].price,
                          keyboard: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AdminButton(
                              _options[i].image == null ? 'Main photo' : 'Main photo ✓',
                              kind: 'gray',
                              small: true,
                              onPressed: () => _pickOptionImage(_options[i]),
                            ),
                            AdminButton(
                              _options[i].more.isEmpty ? 'More photos' : 'More photos (${_options[i].more.length})',
                              kind: 'gray',
                              small: true,
                              onPressed: () => _pickOptionMore(_options[i]),
                            ),
                            AdminButton(
                              'Remove',
                              kind: 'red',
                              small: true,
                              onPressed: () => setState(() {
                                _options[i].dispose();
                                _options.removeAt(i);
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                AdminButton(
                  '+ Add another color',
                  kind: 'gray',
                  onPressed: () => setState(() => _options.add(_ColorOption())),
                ),
                const SizedBox(height: 16),
                AdminPicker(
                  label: 'Show this product on',
                  value: _showOn,
                  options: kShowOn,
                  onChanged: (v) => setState(() => _showOn = v),
                ),
                AdminSwitch(
                  label: 'Show as flash deal',
                  value: _flash,
                  onChanged: (v) => setState(() => _flash = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    AdminButton('Save product', busy: _saving, onPressed: _save),
                    const SizedBox(width: 10),
                    AdminButton('Cancel', kind: 'gray', onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return AdminSubPage(
      title: widget.id > 0 ? 'Edit product' : 'Add product',
      child: body,
    );
  }
}
