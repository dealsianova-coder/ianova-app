import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'admin_api.dart';
import 'admin_ui.dart';

// ------------------------------------------------------------------ video ad

class AdminVideoAdScreen extends StatefulWidget {
  const AdminVideoAdScreen({super.key});

  @override
  State<AdminVideoAdScreen> createState() => _AdminVideoAdScreenState();
}

class _AdminVideoAdScreenState extends State<AdminVideoAdScreen> with AdminLoad<AdminVideoAdScreen> {
  final TextEditingController _interval = TextEditingController(text: '3');
  final TextEditingController _minSec = TextEditingController(text: '30');
  final TextEditingController _url = TextEditingController();
  bool _enabled = false;
  bool _clear = false;
  bool _saving = false;
  String _src = '';
  String _type = 'none';
  String _product = '0';
  String _category = '0';
  String? _video;

  @override
  Future<Map<String, dynamic>> fetch() async {
    final d = await AdminApi.instance.panel('video_ad_get');
    final s = aMap(d['settings']);

    _enabled = aStr(s['video_ad_enabled']) == '1';
    _src = aStr(s['video_ad_src']);
    _interval.text = aStr(s['video_ad_interval_minutes']).isEmpty ? '3' : aStr(s['video_ad_interval_minutes']);
    _minSec.text = aStr(s['video_ad_min_seconds']).isEmpty ? '30' : aStr(s['video_ad_min_seconds']);
    _type = aStr(s['video_ad_link_type']).isEmpty ? 'none' : aStr(s['video_ad_link_type']);

    final v = aStr(s['video_ad_link_value']);

    _product = _type == 'product' ? v : '0';
    _category = _type == 'category' ? v : '0';
    _url.text = _type == 'url' ? v : '';
    _video = null;
    _clear = false;

    return d;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _interval.dispose();
    _minSec.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await ImagePicker().pickVideo(source: ImageSource.gallery);

    if (f != null) setState(() => _video = f.path);
  }

  Future<void> _save() async {
    String value = '';

    if (_type == 'product') value = _product;
    if (_type == 'category') value = _category;
    if (_type == 'url') value = _url.text.trim();

    setState(() => _saving = true);

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panelUpload(
        'video_ad_save',
        {
          'enabled': _enabled ? '1' : '0',
          'interval': _interval.text.trim(),
          'min_seconds': _minSec.text.trim(),
          'link_type': _type,
          'link_value': value,
          'clear_video': _clear ? '1' : '0',
        },
        {if (_video != null) 'video': _video!},
      ),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) {
      adminSay(context, 'Saved. The website picks this up right away.');
      load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final products = <String, String>{
        '0': '-',
        for (final p in aList(d['products'])) '${aInt(p['id'])}': aStr(p['name']),
      };
      final categories = <String, String>{
        '0': '-',
        for (final c in aList(d['categories'])) '${aInt(c['id'])}': aStr(c['name']),
      };

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Front-store video ad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const AdminMuted(
                  'The video ad plays automatically over the home-page banner carousel, on a timer, then the site returns to rotating your regular banners.',
                ),
                const SizedBox(height: 14),
                AdminSwitch(
                  label: 'Show the video ad on the website',
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
                const Text('Video file (MP4, WebM or MOV, up to 40MB)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (_src.isNotEmpty) AdminMuted('Current: $_src'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    AdminButton('Choose video', kind: 'gray', small: true, onPressed: _pick),
                    const SizedBox(width: 10),
                    if (_video != null) const ATag('New video chosen', kind: 'ok'),
                  ],
                ),
                if (_src.isNotEmpty)
                  AdminSwitch(
                    label: 'Remove current video',
                    value: _clear,
                    onChanged: (v) => setState(() => _clear = v),
                  ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AdminField(label: 'Play every (minutes)', controller: _interval, keyboard: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminField(label: 'Minimum play (seconds)', controller: _minSec, keyboard: TextInputType.number),
                    ),
                  ],
                ),
                AdminPicker(
                  label: 'When tapped (shows a "Shop now" button), open',
                  value: _type,
                  options: const {
                    'none': 'Nothing (no button shown)',
                    'product': 'A product',
                    'category': 'A category',
                    'url': 'A custom link',
                  },
                  onChanged: (v) => setState(() => _type = v),
                ),
                if (_type == 'product')
                  AdminPicker(label: 'Product', value: _product, options: products, onChanged: (v) => setState(() => _product = v)),
                if (_type == 'category')
                  AdminPicker(label: 'Category', value: _category, options: categories, onChanged: (v) => setState(() => _category = v)),
                if (_type == 'url')
                  AdminField(label: 'Custom link (full URL or a path like category.php?slug=electronics)', controller: _url),
                AdminButton('Save video ad settings', busy: _saving, onPressed: _save),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ------------------------------------------------------------------ display control

class AdminDisplayScreen extends StatefulWidget {
  const AdminDisplayScreen({super.key});

  @override
  State<AdminDisplayScreen> createState() => _AdminDisplayScreenState();
}

class _AdminDisplayScreenState extends State<AdminDisplayScreen> with AdminLoad<AdminDisplayScreen> {
  static const _tabs = <String, String>{
    'sections': 'Home sections',
    'banners': 'Banners',
    'categories': 'Categories',
    'products': 'Products',
  };

  final TextEditingController _search = TextEditingController();
  final Map<String, String> _values = <String, String>{};
  final Map<String, String> _prev = <String, String>{};
  String _tab = 'sections';
  String _filter = '';
  int _page = 1;
  bool _saving = false;

  @override
  Future<Map<String, dynamic>> fetch() async {
    final d = await AdminApi.instance.panel('display_get', query: {
      'tab': _tab,
      'q': _search.text.trim(),
      'v': _filter,
      'page': '$_page',
    });

    _values.clear();
    _prev.clear();

    if (_tab == 'sections') {
      for (final s in aList(d['sections'])) {
        _values[aStr(s['key'])] = aStr(s['value']);
      }
    } else {
      for (final r in aList(d['rows'])) {
        final id = '${aInt(r['id'])}';

        if (_tab == 'products' && aInt(r['kinds']) > 1) {
          _values[id] = '';
          _prev[id] = '';
        } else {
          _values[id] = kShowOn.containsKey(aStr(r['show_on'])) ? aStr(r['show_on']) : 'both';
          _prev[id] = _values[id]!;
        }
      }
    }

    return d;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _switchTab(String tab) {
    setState(() {
      _tab = tab;
      _page = 1;
      loading = true;
      data = null;
    });
    load();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel('display_save', body: {
        'tab': _tab,
        'values': _values,
        'prev': _prev,
      }),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) {
      adminSay(context, 'Saved. The website and the app use this right away.');
      load();
    }
  }

  Widget _row(String id, String title, String? sub, Map<String, String> options) {
    final value = options.containsKey(_values[id]) ? _values[id]! : options.keys.first;

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          if (sub != null && sub.isNotEmpty) AdminMuted(sub),
          const SizedBox(height: 10),
          AdminPicker(
            label: 'Show it on',
            value: value,
            options: options,
            onChanged: (v) => setState(() => _values[id] = v),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const AdminMuted(
        'Choose where each thing is shown: the website, the app, or both. Anything you do not change stays on both.',
      ),
      const SizedBox(height: 10),
      AdminChipRow(
        children: [
          for (final e in _tabs.entries)
            AdminChip(label: e.value, selected: _tab == e.key, onTap: () => _switchTab(e.key)),
        ],
      ),
    ];

    final d = data;

    if (loading && d == null) {
      children.add(const Padding(padding: EdgeInsets.only(top: 60), child: AdminLoading()));
    } else if (d == null) {
      children.add(AdminLoading(error: error, onRetry: load));
    } else {
      if (_tab == 'sections') {
        for (final s in aList(d['sections'])) {
          final both = aBool(s['both']);
          final options = both
              ? <String, String>{...kShowOn, 'off': 'Hidden everywhere'}
              : <String, String>{'on': 'Shown in the app', 'off': 'Hidden'};

          children.add(_row(aStr(s['key']), aStr(s['label']), aStr(s['note']), options));
        }
      } else if (_tab == 'banners') {
        final rows = aList(d['rows']);

        if (rows.isEmpty) children.add(const AdminCard(child: AdminMuted('No banners yet. Add them under Banners.')));

        for (final r in rows) {
          children.add(_row('${aInt(r['id'])}', aStr(r['title']), '${aStr(r['subtitle'])} · ${aBool(r['is_active']) ? 'Showing' : 'Hidden'}', kShowOn));
        }
      } else if (_tab == 'categories') {
        for (final r in aList(d['rows'])) {
          children.add(_row('${aInt(r['id'])}', '${aStr(r['emoji'])} ${aStr(r['name'])}', aBool(r['is_hidden']) ? 'Hidden' : 'Visible', kShowOn));
        }
      } else {
        children.add(Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  _page = 1;
                  load();
                },
                decoration: AdminField.decoration('Search products'),
              ),
            ),
            const SizedBox(width: 8),
            AdminButton('Filter', kind: 'gray', onPressed: () {
              _page = 1;
              load();
            }),
          ],
        ));
        children.add(const SizedBox(height: 10));
        children.add(AdminChipRow(
          children: [
            AdminChip(label: 'Any', selected: _filter.isEmpty, onTap: () { _filter = ''; _page = 1; load(); }),
            for (final e in kShowOn.entries)
              AdminChip(label: e.value, selected: _filter == e.key, onTap: () { _filter = e.key; _page = 1; load(); }),
          ],
        ));
        children.add(AdminMuted('${aInt(d['total'])} products. A product with several colors or sizes is changed all together.'));
        children.add(const SizedBox(height: 10));

        for (final r in aList(d['rows'])) {
          final mixed = aInt(r['kinds']) > 1;
          final options = mixed ? <String, String>{'': 'Mixed (leave as is)', ...kShowOn} : kShowOn;

          children.add(_row('${aInt(r['id'])}', aStr(r['name']), '${aStr(r['seller_name'])} · ${aMoney(r['price'])}', options));
        }

        if (aInt(d['pages']) > 1) {
          children.add(Row(
            children: [
              if (_page > 1)
                AdminButton('Previous', kind: 'gray', small: true, onPressed: () { _page--; load(); }),
              const Spacer(),
              AdminMuted('Page $_page of ${aInt(d['pages'])}'),
              const Spacer(),
              if (_page < aInt(d['pages']))
                AdminButton('Next', kind: 'gray', small: true, onPressed: () { _page++; load(); }),
            ],
          ));
          children.add(const SizedBox(height: 10));
        }
      }

      children.add(AdminButton('Save', busy: _saving, onPressed: _save));
      children.add(const SizedBox(height: 24));
    }

    return ListView(padding: const EdgeInsets.all(16), children: children);
  }
}
