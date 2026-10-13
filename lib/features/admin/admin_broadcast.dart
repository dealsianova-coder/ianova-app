import 'package:flutter/material.dart';

import '../../core/network/api_service.dart' show ApiException;
import '../../core/theme/ianova_theme.dart';
import 'admin_api.dart';

/// Send one message to many sellers at once. Each seller gets their own copy,
/// greeted by their own business name.
class AdminBroadcastPage extends StatefulWidget {
  const AdminBroadcastPage({super.key, required this.onExpired});

  final VoidCallback onExpired;

  @override
  State<AdminBroadcastPage> createState() => _AdminBroadcastPageState();
}

class _AdminBroadcastPageState extends State<AdminBroadcastPage> {
  final TextEditingController _message = TextEditingController();

  List<Map<String, dynamic>> _sellers = [];
  List<Map<String, dynamic>> _history = [];
  final Set<int> _selected = {};

  bool _loading = true;
  bool _sending = false;
  bool _mention = true;
  String _status = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _message.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return [];

    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  int _id(Map<String, dynamic> seller) => int.tryParse('${seller['id']}') ?? 0;

  String _cap(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  Future<void> _load() async {
    try {
      final data = await AdminApi.instance.raw('broadcast_options');

      if (!mounted) return;

      setState(() {
        _sellers = _maps(data['sellers']);
        _history = _maps(data['history']);
        _error = null;
        _loading = false;

        if (_selected.isEmpty) _pick('all');
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401) widget.onExpired();

      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load sellers.';
        _loading = false;
      });
    }
  }

  /// Quick selection: all (not rejected), one status, or none.
  void _pick(String kind) {
    _selected.clear();

    for (final seller in _sellers) {
      final status = '${seller['status']}';
      final take = kind == 'all'
          ? status != 'rejected'
          : kind == 'none'
              ? false
              : status == kind;

      if (take) _selected.add(_id(seller));
    }
  }

  String _firstSelectedName() {
    for (final seller in _sellers) {
      if (_selected.contains(_id(seller))) return '${seller['business_name']}';
    }

    return 'Your Shop';
  }

  String _preview() {
    final text = _message.text.trim();
    final name = _firstSelectedName();

    if (text.toLowerCase().contains('{name}')) {
      return text.replaceAll(RegExp(r'\{name\}', caseSensitive: false), name);
    }

    if (_mention) return text.isEmpty ? 'Hello $name,' : 'Hello $name,\n\n$text';

    return text;
  }

  void _say(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _send() async {
    final text = _message.text.trim();

    if (_sending) return;

    if (_selected.isEmpty) {
      _say('Select at least one seller.');
      return;
    }

    if (text.isEmpty && _status.isEmpty) {
      _say('Write a message first.');
      return;
    }

    final count = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Send to $count seller${count == 1 ? '' : 's'}?'),
        content: Text(
          _status.isEmpty
              ? 'Each seller will receive their own message.'
              : 'Each seller will receive their own message, and their status '
                  'will be set to ${_cap(_status)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _sending = true);

    try {
      final data = await AdminApi.instance.raw(
        'broadcast_send',
        body: {
          'message': text,
          'ids': _selected.toList(),
          'mention': _mention,
          'status': _status,
        },
      );

      final names = [
        for (final name in (data['names'] is List ? data['names'] as List : []))
          '$name',
      ];

      _message.clear();
      _status = '';
      await _load();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Sent to ${names.length} seller'
              '${names.length == 1 ? '' : 's'}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(child: Text(names.join('\n'))),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) widget.onExpired();

      if (mounted) _say(error.message);
    } catch (_) {
      if (mounted) _say('Could not send. Check your connection.');
    }

    if (mounted) setState(() => _sending = false);
  }

  Widget _chip(String label, String kind) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: () => setState(() => _pick(kind)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message sellers')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _sellers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _message,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Write your message to the sellers…',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Greet each seller by name'),
                      subtitle: const Text(
                        'You can also type {name} anywhere in the message.',
                      ),
                      value: _mention,
                      onChanged: (value) => setState(() => _mention = value),
                    ),
                    if (_selected.isNotEmpty &&
                        (_message.text.trim().isNotEmpty || _mention))
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: IanovaColors.soft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Example of what one seller receives',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(_preview()),
                          ],
                        ),
                      ),
                    Text(
                      'Recipients (${_selected.length} selected)',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chip('All', 'all'),
                          _chip('Approved', 'approved'),
                          _chip('Pending', 'pending'),
                          _chip('Suspended', 'suspended'),
                          _chip('None', 'none'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: IanovaColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: IanovaColors.border),
                      ),
                      child: Column(
                        children: [
                          if (_sellers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No sellers yet.'),
                            ),
                          for (final seller in _sellers)
                            CheckboxListTile(
                              dense: true,
                              value: _selected.contains(_id(seller)),
                              onChanged: (value) => setState(() {
                                if (value == true) {
                                  _selected.add(_id(seller));
                                } else {
                                  _selected.remove(_id(seller));
                                }
                              }),
                              title: Text(
                                '${seller['business_name']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(_cap('${seller['status']}')),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Also change status of selected sellers',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('No change')),
                        DropdownMenuItem(
                          value: 'approved',
                          child: Text('Approve (reactivate)'),
                        ),
                        DropdownMenuItem(
                          value: 'suspended',
                          child: Text('Suspend'),
                        ),
                        DropdownMenuItem(
                          value: 'rejected',
                          child: Text('Reject'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _status = value ?? ''),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _sending
                            ? 'Sending…'
                            : 'Send to ${_selected.length} seller'
                                '${_selected.length == 1 ? '' : 's'}',
                      ),
                    ),
                    if (_history.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const Text(
                        'Recent broadcasts',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final item in _history)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: IanovaColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: IanovaColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['created_at']} · '
                                '${item['recipient_count']} sellers',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: IanovaColors.muted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item['message']}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
    );
  }
}
