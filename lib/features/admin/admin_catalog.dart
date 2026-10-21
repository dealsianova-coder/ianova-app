import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'admin_api.dart';
import 'admin_ui.dart';

// ------------------------------------------------------------------ categories

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> with AdminLoad<AdminCategoriesScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _slug = TextEditingController();
  final TextEditingController _emoji = TextEditingController(text: '🛍️');
  final TextEditingController _sort = TextEditingController(text: '0');
  int _editId = 0;
  String _showOn = 'both';
  String _currentImage = '';
  String? _newImage;
  bool _removeImage = false;
  bool _saving = false;

  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('categories_list');

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _emoji.dispose();
    _sort.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _editId = 0;
      _name.clear();
      _slug.clear();
      _emoji.text = '🛍️';
      _sort.text = '0';
      _showOn = 'both';
      _currentImage = '';
      _newImage = null;
      _removeImage = false;
    });
  }

  Future<void> _pick() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);

    if (f != null) {
      setState(() {
        _newImage = f.path;
        _removeImage = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panelUpload(
        'category_save',
        {
          'id': '$_editId',
          'name': _name.text.trim(),
          'slug': _slug.text.trim(),
          'emoji': _emoji.text.trim(),
          'sort_order': _sort.text.trim(),
          'show_on': _showOn,
          'remove_image': _removeImage ? '1' : '0',
        },
        {if (_newImage != null) 'image': _newImage!},
      ),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) {
      adminSay(context, 'Category saved.');
      _clear();
      load();
    }
  }

  Future<void> _call(String action, int id, [String? confirm]) async {
    if (confirm != null && !await adminConfirm(context, confirm)) return;
    if (!mounted) return;

    await adminTry(context, () => AdminApi.instance.panel(action, body: {'id': id}));
    load();
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final cats = aList(d['categories']);

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editId > 0 ? 'Edit category' : 'Add category',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  AdminField(label: 'Name', controller: _name),
                  AdminField(label: 'Slug (made from the name if empty)', controller: _slug),
                  const Text('Picture (replaces the emoji)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_newImage != null)
                        const ATag('New picture chosen', kind: 'ok')
                      else if (_currentImage.isNotEmpty && !_removeImage)
                        AdminThumb(image: _currentImage, size: 56),
                      const SizedBox(width: 10),
                      AdminButton('Choose picture', kind: 'gray', small: true, onPressed: _pick),
                      if (_currentImage.isNotEmpty || _newImage != null) ...[
                        const SizedBox(width: 8),
                        AdminButton('Remove', kind: 'red', small: true, onPressed: () {
                          setState(() {
                            _newImage = null;
                            _removeImage = true;
                          });
                        }),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  AdminField(label: 'Emoji (used only if there is no picture)', controller: _emoji),
                  AdminPicker(
                    label: 'Show this category on',
                    value: _showOn,
                    options: kShowOn,
                    onChanged: (v) => setState(() => _showOn = v),
                  ),
                  AdminField(label: 'Sort order', controller: _sort, keyboard: TextInputType.number),
                  Row(
                    children: [
                      AdminButton('Save', busy: _saving, onPressed: _save),
                      const SizedBox(width: 10),
                      if (_editId > 0) AdminButton('Cancel', kind: 'gray', onPressed: _clear),
                    ],
                  ),
                ],
              ),
            ),
            const AdminHeading('All categories'),
            for (final c in cats)
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AdminThumb(image: aStr(c['image']), emoji: aStr(c['emoji']), size: 44),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            aStr(c['name']),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          aBool(c['is_hidden']) ? 'Hidden' : 'Visible',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: aBool(c['is_hidden']) ? AC.red : AC.okFg,
                          ),
                        ),
                      ],
                    ),
                    AdminMuted('${aInt(c['products'])} products · ${kShowOn[aStr(c['show_on'])] ?? kShowOn['both']}'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AdminButton('Edit', small: true, onPressed: () {
                          setState(() {
                            _editId = aInt(c['id']);
                            _name.text = aStr(c['name']);
                            _slug.text = aStr(c['slug']);
                            _emoji.text = aStr(c['emoji']);
                            _sort.text = aStr(c['sort_order']);
                            _showOn = kShowOn.containsKey(aStr(c['show_on'])) ? aStr(c['show_on']) : 'both';
                            _currentImage = aStr(c['image']);
                            _newImage = null;
                            _removeImage = false;
                          });
                        }),
                        AdminButton(
                          aBool(c['is_hidden']) ? 'Show' : 'Hide',
                          small: true,
                          kind: 'gray',
                          onPressed: () => _call('category_toggle', aInt(c['id'])),
                        ),
                        AdminButton(
                          'Delete',
                          small: true,
                          kind: 'red',
                          onPressed: () => _call('category_delete', aInt(c['id']), 'Delete this category and its products?'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ------------------------------------------------------------------ users

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, this.onGo, this.initialRole = 'all'});

  final String initialRole;

  /// Opens another admin section (used by "Open in Sellers").
  final void Function(String page)? onGo;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with AdminLoad<AdminUsersScreen> {
  final TextEditingController _search = TextEditingController();
  String _role = 'all';

  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('users_list');

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
    load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _hit(List<String> values) {
    final q = _search.text.trim().toLowerCase();

    if (q.isEmpty) return true;

    for (final v in values) {
      if (v.toLowerCase().contains(q)) return true;
    }

    return false;
  }

  Future<bool> _editDialog(String title, Map<String, dynamic> u, String action) async {
    final name = TextEditingController(text: aStr(u['name']));
    final email = TextEditingController(text: aStr(u['email']));

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminField(label: 'Name', controller: name),
            AdminField(label: 'Email', controller: email, keyboard: TextInputType.emailAddress),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
        ],
      ),
    );

    final newName = name.text.trim();
    final newEmail = email.text.trim();
    name.dispose();
    email.dispose();

    if (save != true || !mounted) return false;

    return adminTry(
      context,
      () => AdminApi.instance.panel(action, body: {'id': aInt(u['id']), 'name': newName, 'email': newEmail}),
    );
  }

  Future<void> _editUser(Map<String, dynamic> u) async {
    if (await _editDialog('Edit customer', u, 'user_save')) load();
  }

  Future<void> _editAdmin(Map<String, dynamic> a) async {
    final name = TextEditingController(text: aStr(a['name']));
    final email = TextEditingController(text: aStr(a['email']));
    final newPw = TextEditingController();
    final curPw = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminField(label: 'Name', controller: name),
              AdminField(label: 'Email', controller: email, keyboard: TextInputType.emailAddress),
              AdminField(label: 'New password (optional)', controller: newPw, obscure: true),
              AdminField(label: '🔒 Current password (required)', controller: curPw, obscure: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
        ],
      ),
    );

    final body = <String, dynamic>{
      'id': aInt(a['id']),
      'name': name.text.trim(),
      'email': email.text.trim(),
      'new_password': newPw.text,
      'current_password': curPw.text,
    };

    name.dispose();
    email.dispose();
    newPw.dispose();
    curPw.dispose();

    if (save != true || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('admin_account_save', body: body));

    if (ok) load();
  }

  Future<void> _delete(Map<String, dynamic> u) async {
    if (!await adminConfirm(context, 'Delete ${aStr(u['name'])}?')) return;
    if (!mounted) return;

    await adminTry(context, () => AdminApi.instance.panel('user_delete', body: {'id': aInt(u['id'])}));
    load();
  }

  Widget _section(String icon, String title, String note, ATag tag) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$icon $title', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              tag,
            ],
          ),
          if (note.isNotEmpty) AdminMuted(note),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final me = aInt(d['me']);
      final admins = aList(d['admins']).where((r) => _hit([aStr(r['name']), aStr(r['email'])])).toList();
      final sellers = aList(d['sellers']).where((r) => _hit([aStr(r['business_name']), aStr(r['email'])])).toList();
      final users = aList(d['users']).where((r) => _hit([aStr(r['name']), aStr(r['email'])])).toList();
      final total = admins.length + sellers.length + users.length;

      final children = <Widget>[
        TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          decoration: AdminField.decoration('Search name or email'),
        ),
        const SizedBox(height: 10),
        AdminChipRow(
          children: [
            AdminChip(label: 'All', selected: _role == 'all', count: total, onTap: () => setState(() => _role = 'all')),
            AdminChip(label: '👑 Admin', selected: _role == 'admin', count: admins.length, onTap: () => setState(() => _role = 'admin')),
            AdminChip(label: '🏪 Sellers', selected: _role == 'seller', count: sellers.length, onTap: () => setState(() => _role = 'seller')),
            AdminChip(label: '🛍️ Customers', selected: _role == 'customer', count: users.length, onTap: () => setState(() => _role = 'customer')),
          ],
        ),
        const SizedBox(height: 14),
      ];

      if (_role == 'all' || _role == 'admin') {
        children.add(_section('👑', 'Admin', 'The store owner accounts. Only these can sign in to the admin and the Admin app.', const ATag('FULL CONTROL', kind: 'wait')));

        for (final a in admins) {
          children.add(
            AdminCard(
              accent: AC.goldLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(aStr(a['name']), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                      if (aInt(a['id']) == me) const ATag('YOU', kind: 'ok'),
                    ],
                  ),
                  Text(aStr(a['email'])),
                  AdminMuted('Last sign-in: ${aStr(a['last_login']).isEmpty ? 'never' : aStr(a['last_login'])}'),
                  const SizedBox(height: 10),
                  if (aInt(a['id']) == me)
                    AdminButton('🔒 Edit (needs password)', small: true, onPressed: () => _editAdmin(a))
                  else
                    const AdminMuted('🔒 Protected: only this admin can edit this account.'),
                ],
              ),
            ),
          );
        }

        if (admins.isEmpty) children.add(const AdminCard(child: AdminMuted('No admin accounts found.')));
      }

      if (_role == 'all' || _role == 'seller') {
        children.add(_section('🏪', 'Sellers', '', const ATag('SELLER', kind: 'ok')));

        for (final s in sellers) {
          children.add(
            AdminCard(
              accent: AC.green,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(aStr(s['business_name']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
                      ATag(aStr(s['status']), kind: aStr(s['status']) == 'approved' ? 'ok' : 'wait'),
                    ],
                  ),
                  Text(aStr(s['email'])),
                  AdminMuted('${aInt(s['products'])} products · joined ${aStr(s['created_at'])}'),
                  if (widget.onGo != null) ...[
                    const SizedBox(height: 10),
                    AdminButton('Open in Sellers', small: true, kind: 'gray', onPressed: () => widget.onGo!('sellers')),
                  ],
                ],
              ),
            ),
          );
        }

        if (sellers.isEmpty) children.add(const AdminCard(child: AdminMuted('No sellers.')));
      }

      if (_role == 'all' || _role == 'customer') {
        children.add(_section('🛍️', 'Customers', '', const ATag('CUSTOMER')));

        for (final u in users) {
          children.add(
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(aStr(u['name']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(aStr(u['email'])),
                  AdminMuted('${aInt(u['orders'])} orders · joined ${aStr(u['created_at'])}'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      AdminButton('Edit', small: true, onPressed: () => _editUser(u)),
                      AdminButton('Delete', small: true, kind: 'red', onPressed: () => _delete(u)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        if (users.isEmpty) children.add(const AdminCard(child: AdminMuted('No customers.')));
      }

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(padding: const EdgeInsets.all(16), children: children),
      );
    });
  }
}

// ------------------------------------------------------------------ subscribers

class AdminSubscribersScreen extends StatefulWidget {
  const AdminSubscribersScreen({super.key});

  @override
  State<AdminSubscribersScreen> createState() => _AdminSubscribersScreenState();
}

class _AdminSubscribersScreenState extends State<AdminSubscribersScreen> with AdminLoad<AdminSubscribersScreen> {
  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('subscribers_list');

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final rows = aList(d['subscribers']);

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminMuted('${rows.length} subscribers'),
            const SizedBox(height: 10),
            for (final r in rows)
              AdminCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(aStr(r['email']), style: const TextStyle(fontWeight: FontWeight.w800)),
                          AdminMuted(aStr(r['subscribed_at'])),
                        ],
                      ),
                    ),
                    AdminButton('Delete', small: true, kind: 'red', onPressed: () async {
                      if (!await adminConfirm(context, 'Delete subscriber?')) return;
                      if (!context.mounted) return;
                      await adminTry(
                        context,
                        () => AdminApi.instance.panel('subscriber_delete', body: {'id': aInt(r['id'])}),
                      );
                      load();
                    }),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ------------------------------------------------------------------ suggestions

class AdminSuggestionsScreen extends StatefulWidget {
  const AdminSuggestionsScreen({super.key});

  @override
  State<AdminSuggestionsScreen> createState() => _AdminSuggestionsScreenState();
}

class _AdminSuggestionsScreenState extends State<AdminSuggestionsScreen> with AdminLoad<AdminSuggestionsScreen> {
  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('suggestions_list');

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final rows = aList(d['suggestions']);

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (rows.isEmpty) const AdminCard(child: AdminMuted('No suggestions yet.')),
            for (final r in rows)
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(aStr(r['name']), style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        ATag(aStr(r['status']) == 'new' ? 'New' : 'Reviewed', kind: aStr(r['status']) == 'new' ? 'wait' : 'na'),
                      ],
                    ),
                    AdminMuted(aStr(r['email'])),
                    const SizedBox(height: 8),
                    Text(aStr(r['message'])),
                    const SizedBox(height: 6),
                    AdminMuted(aStr(r['created_at'])),
                    if (aStr(r['status']) == 'new') ...[
                      const SizedBox(height: 10),
                      AdminButton('Mark reviewed', small: true, onPressed: () async {
                        await adminTry(
                          context,
                          () => AdminApi.instance.panel('suggestion_reviewed', body: {'id': aInt(r['id'])}),
                        );
                        load();
                      }),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ------------------------------------------------------------------ banners

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> with AdminLoad<AdminBannersScreen> {
  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('banners_list');

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> _edit(Map<String, dynamic>? banner) async {
    final d = data;

    if (d == null) return;

    await adminPush(
      context,
      _BannerEditPage(
        banner: banner,
        products: aList(d['products']),
        categories: aList(d['categories']),
      ),
    );
    load();
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final banners = aList(d['banners']);

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AdminMuted(
              'Banners slide across the top of the app and the website home page. With no banners, the app shows your flash-deal products instead.',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: AdminButton('+ Add banner', onPressed: () => _edit(null)),
            ),
            const SizedBox(height: 12),
            if (banners.isEmpty) const AdminCard(child: AdminMuted('No banners yet.')),
            for (final b in banners)
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (aStr(b['image']).isNotEmpty) ...[
                          AdminThumb(image: aStr(b['image']), size: 56),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(aStr(b['title']), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              AdminMuted(aStr(b['subtitle'])),
                              AdminMuted('Order ${aInt(b['sort_order'])} · opens ${aStr(b['link_type'])} · ${kShowOn[aStr(b['show_on'])] ?? kShowOn['both']}'),
                            ],
                          ),
                        ),
                        ATag(aBool(b['is_active']) ? 'Showing' : 'Hidden', kind: aBool(b['is_active']) ? 'ok' : 'na'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AdminButton('Edit', small: true, kind: 'gray', onPressed: () => _edit(b)),
                        AdminButton(aBool(b['is_active']) ? 'Hide' : 'Show', small: true, kind: 'gray', onPressed: () async {
                          await adminTry(
                            context,
                            () => AdminApi.instance.panel('banner_toggle', body: {'id': aInt(b['id'])}),
                          );
                          load();
                        }),
                        AdminButton('Delete', small: true, kind: 'red', onPressed: () async {
                          if (!await adminConfirm(context, 'Delete this banner?')) return;
                          if (!context.mounted) return;
                          await adminTry(
                            context,
                            () => AdminApi.instance.panel('banner_delete', body: {'id': aInt(b['id'])}),
                          );
                          load();
                        }),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _BannerEditPage extends StatefulWidget {
  const _BannerEditPage({this.banner, required this.products, required this.categories});

  final Map<String, dynamic>? banner;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> categories;

  @override
  State<_BannerEditPage> createState() => _BannerEditPageState();
}

class _BannerEditPageState extends State<_BannerEditPage> {
  late final TextEditingController _title;
  late final TextEditingController _sub;
  late final TextEditingController _label;
  late final TextEditingController _search;
  late final TextEditingController _sort;
  late String _color;
  late String _type;
  late String _product;
  late String _category;
  late bool _active;
  late String _showOn;
  String? _image;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.banner ?? <String, dynamic>{};
    _title = TextEditingController(text: aStr(b['title']));
    _sub = TextEditingController(text: aStr(b['subtitle']));
    _label = TextEditingController(text: b['button_label'] == null ? 'Shop now' : aStr(b['button_label']));
    _sort = TextEditingController(text: aStr(b['sort_order']).isEmpty ? '0' : aStr(b['sort_order']));
    _color = aStr(b['color']).isEmpty ? 'blush' : aStr(b['color']);
    _type = aStr(b['link_type']).isEmpty ? 'none' : aStr(b['link_type']);
    final value = aStr(b['link_value']);
    _search = TextEditingController(text: _type == 'search' ? value : '');
    _product = _type == 'product' ? value : '0';
    _category = _type == 'category' ? value : '0';
    _active = widget.banner == null ? true : aBool(b['is_active']);
    _showOn = kShowOn.containsKey(aStr(b['show_on'])) ? aStr(b['show_on']) : 'both';
  }

  @override
  void dispose() {
    _title.dispose();
    _sub.dispose();
    _label.dispose();
    _search.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1800);

    if (f != null) setState(() => _image = f.path);
  }

  Future<void> _save() async {
    String value = '';

    if (_type == 'product') value = _product;
    if (_type == 'category') value = _category;
    if (_type == 'search') value = _search.text.trim();

    setState(() => _saving = true);

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panelUpload(
        'banner_save',
        {
          'id': '${aInt(widget.banner?['id'])}',
          'title': _title.text.trim(),
          'subtitle': _sub.text.trim(),
          'button_label': _label.text.trim(),
          'color': _color,
          'link_type': _type,
          'link_value': value,
          'sort_order': _sort.text.trim(),
          'is_active': _active ? '1' : '0',
          'show_on': _showOn,
        },
        {if (_image != null) 'image': _image!},
      ),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) {
      adminSay(context, 'Banner saved.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = <String, String>{
      '0': '-',
      for (final p in widget.products) '${aInt(p['id'])}': aStr(p['name']),
    };
    final categories = <String, String>{
      '0': '-',
      for (final c in widget.categories) '${aInt(c['id'])}': aStr(c['name']),
    };

    return AdminSubPage(
      title: widget.banner == null ? 'Add banner' : 'Edit banner',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminField(label: 'Title', controller: _title, maxLength: 120),
                AdminField(label: 'Subtitle', controller: _sub, maxLength: 160),
                AdminField(label: 'Button text', controller: _label, maxLength: 40),
                AdminPicker(
                  label: 'Colour',
                  value: _color,
                  options: const {'blush': 'Pink', 'sky': 'Blue', 'sand': 'Sand', 'rose': 'Rose'},
                  onChanged: (v) => setState(() => _color = v),
                ),
                const Text('Image (up to 5 MB). Leave empty to use the linked product photo.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_image == null && aStr(widget.banner?['image']).isNotEmpty)
                      AdminThumb(image: aStr(widget.banner?['image']), size: 56),
                    if (_image != null) const ATag('New image chosen', kind: 'ok'),
                    const SizedBox(width: 10),
                    AdminButton('Choose image', kind: 'gray', small: true, onPressed: _pick),
                  ],
                ),
                const SizedBox(height: 16),
                AdminPicker(
                  label: 'When tapped, open',
                  value: _type,
                  options: const {'none': 'Nothing', 'product': 'A product', 'category': 'A category', 'search': 'A search'},
                  onChanged: (v) => setState(() => _type = v),
                ),
                if (_type == 'product')
                  AdminPicker(
                    label: 'Product',
                    value: _product,
                    options: products,
                    onChanged: (v) => setState(() => _product = v),
                  ),
                if (_type == 'category')
                  AdminPicker(
                    label: 'Category',
                    value: _category,
                    options: categories,
                    onChanged: (v) => setState(() => _category = v),
                  ),
                if (_type == 'search') AdminField(label: 'Search words', controller: _search, maxLength: 200),
                AdminField(label: 'Order (smallest first)', controller: _sort, keyboard: TextInputType.number),
                AdminPicker(
                  label: 'Show this banner on',
                  value: _showOn,
                  options: kShowOn,
                  onChanged: (v) => setState(() => _showOn = v),
                ),
                AdminSwitch(label: 'Show this banner', value: _active, onChanged: (v) => setState(() => _active = v)),
                const SizedBox(height: 8),
                AdminButton('Save banner', busy: _saving, onPressed: _save),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ flash deals

class AdminFlashScreen extends StatefulWidget {
  const AdminFlashScreen({super.key});

  @override
  State<AdminFlashScreen> createState() => _AdminFlashScreenState();
}

class _AdminFlashScreenState extends State<AdminFlashScreen> with AdminLoad<AdminFlashScreen> {
  final TextEditingController _search = TextEditingController();
  final Map<int, TextEditingController> _price = <int, TextEditingController>{};
  final Map<int, TextEditingController> _orig = <int, TextEditingController>{};
  final Map<int, bool> _flash = <int, bool>{};
  String _ends = '';
  bool _saving = false;

  @override
  Future<Map<String, dynamic>> fetch() async {
    final d = await AdminApi.instance.panel('flash_get', query: {'q': _search.text.trim()});

    for (final p in aList(d['products'])) {
      final id = aInt(p['id']);
      _price.putIfAbsent(id, () => TextEditingController()).text = aStr(p['price']);
      _orig.putIfAbsent(id, () => TextEditingController()).text = aStr(p['original_price']);
      _flash[id] = aBool(p['is_flash_deal']);
    }

    _ends = aStr(d['ends_at']);

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
    for (final c in _price.values) {
      c.dispose();
    }
    for (final c in _orig.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final d = data;

    if (d == null) return;

    setState(() => _saving = true);

    final items = <Map<String, dynamic>>[
      for (final p in aList(d['products']))
        {
          'id': aInt(p['id']),
          'flash': _flash[aInt(p['id'])] == true,
          'price': double.tryParse(_price[aInt(p['id'])]?.text.trim() ?? '') ?? 0,
          'orig': double.tryParse(_orig[aInt(p['id'])]?.text.trim() ?? '') ?? 0,
        },
    ];

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel('flash_save', body: {'ends_at': _ends, 'items': items}),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) {
      adminSay(context, 'Saved. The app and the website show the new flash deals.');
      load();
    }
  }

  Future<void> _clearAll() async {
    if (!await adminConfirm(context, 'Remove every product from flash deals?')) return;
    if (!mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('flash_clear', body: {}));

    if (ok) load();
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final products = aList(d['products']);

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => load(),
                    decoration: AdminField.decoration('Search products by name'),
                  ),
                ),
                const SizedBox(width: 8),
                AdminButton('Search', kind: 'gray', onPressed: load),
              ],
            ),
            const SizedBox(height: 14),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sale ends at (Nairobi time, optional)', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text(_ends.isEmpty ? 'No countdown' : _ends)),
                      AdminButton('Pick time', small: true, kind: 'gray', onPressed: () async {
                        final v = await adminPickDateTime(context);
                        if (v != null) setState(() => _ends = v);
                      }),
                      const SizedBox(width: 8),
                      AdminButton('Clear', small: true, kind: 'gray', onPressed: () => setState(() => _ends = '')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AdminMuted('Shows a real countdown in the app. When this time passes, the flash deals section hides by itself. Now: ${aStr(d['now'])}.'),
                  if (aBool(d['ended']))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'This end time has passed, so flash deals are hidden. Pick a new time to show them again.',
                        style: TextStyle(color: AC.red, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
            for (final p in products)
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AdminThumb(image: aStr(p['image']), emoji: aStr(p['emoji']), bg: aStr(p['bg_color']), size: 48),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(aStr(p['name']), maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                              AdminMuted(
                                '${('${aStr(p['color'])} ${aStr(p['size'])}').trim()} stock ${aInt(p['stock'])}'.trim(),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _flash[aInt(p['id'])] == true,
                          onChanged: (v) => setState(() => _flash[aInt(p['id'])] = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AdminField(
                            label: 'Sale price',
                            controller: _price[aInt(p['id'])]!,
                            keyboard: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AdminField(
                            label: 'Old price',
                            controller: _orig[aInt(p['id'])]!,
                            keyboard: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const AdminMuted('The discount % is worked out from the sale price and the old price.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                AdminButton('Save flash deals', busy: _saving, onPressed: _save),
                AdminButton('Clear all', kind: 'red', onPressed: _clearAll),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }
}
