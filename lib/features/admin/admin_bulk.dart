import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_api.dart';
import 'admin_ui.dart';

const String _template =
    'name,slug,price,original_price,stock,description,emoji,bg_color,is_flash_deal,image_url\n'
    'Wireless Mouse,wireless-mouse,1500,2000,50,Compact wireless mouse,🖱️,#EFF3EC,0,\n'
    'USB-C Cable,usb-c-cable,300,,200,1 meter fast charging cable,🔌,#EFF3EC,1,https://example.com/cable.jpg\n';

/// Add or update many products at once by pasting CSV rows (same columns as the website).
class AdminBulkPage extends StatefulWidget {
  const AdminBulkPage({super.key});

  @override
  State<AdminBulkPage> createState() => _AdminBulkPageState();
}

class _AdminBulkPageState extends State<AdminBulkPage> {
  final TextEditingController _csv = TextEditingController();
  List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[];
  String _category = '';
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await AdminApi.instance.panel('product_form_data');

      if (!mounted) return;

      setState(() {
        _categories = aList(d['categories']);
        if (_categories.isNotEmpty) _category = '${aInt(_categories.first['id'])}';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = adminErr(e);
        _loading = false;
      });
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;

    if (text != null && text.isNotEmpty) setState(() => _csv.text = text);
  }

  Future<void> _copyTemplate() async {
    await Clipboard.setData(const ClipboardData(text: _template));

    if (mounted) adminSay(context, 'Template copied. Paste it into a notes app and edit it.');
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _result = '';
    });

    String text = '';

    final ok = await adminTry(context, () async {
      final r = await AdminApi.instance.panel('bulk_import', body: {
        'category_id': int.tryParse(_category) ?? 0,
        'csv': _csv.text,
      });
      final errors = (r['errors'] is List) ? (r['errors'] as List).map((e) => '$e').toList() : <String>[];
      text = '${aInt(r['saved'])} product(s) saved.${errors.isEmpty ? '' : '\n\nProblems:\n${errors.join('\n')}'}';
    });

    if (!mounted) return;

    setState(() {
      _busy = false;
      if (ok) _result = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_loading) {
      body = const AdminLoading();
    } else if (_error != null) {
      body = AdminLoading(error: _error, onRetry: _load);
    } else {
      final cats = <String, String>{
        for (final c in _categories) '${aInt(c['id'])}': '${aStr(c['emoji'])} ${aStr(c['name'])}'.trim(),
      };

      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bulk upload products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const AdminMuted(
                  'First line = column names. Required: name, slug, price. Optional: description, original_price, stock, emoji, bg_color, is_flash_deal, image_url. A slug that already exists is updated, not duplicated.',
                ),
                const SizedBox(height: 14),
                AdminPicker(label: 'Category', value: _category, options: cats, onChanged: (v) => setState(() => _category = v)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminButton('Paste from clipboard', kind: 'gray', small: true, onPressed: _paste),
                    AdminButton('Copy template', kind: 'gray', small: true, onPressed: _copyTemplate),
                  ],
                ),
                const SizedBox(height: 12),
                AdminField(label: 'CSV rows', controller: _csv, maxLines: 10, hint: 'Paste your CSV here'),
                AdminButton('Upload products', busy: _busy, onPressed: _send),
              ],
            ),
          ),
          if (_result.isNotEmpty) AdminCard(child: Text(_result)),
        ],
      );
    }

    return AdminSubPage(title: 'Bulk upload', child: body);
  }
}
