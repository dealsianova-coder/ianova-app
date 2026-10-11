import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/theme/ianova_theme.dart';

class _Place {
  const _Place(this.name, this.detail, this.label);

  final String name;
  final String detail;
  final String label;
}

/// Shows real places under an address box while the customer types.
///
/// Well-known Kenyan towns and estates appear instantly; more places from
/// OpenStreetMap join the list a moment later. Tap one to fill the box.
class AddressSuggestions extends StatefulWidget {
  const AddressSuggestions({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<AddressSuggestions> createState() => _AddressSuggestionsState();
}

class _AddressSuggestionsState extends State<AddressSuggestions> {
  final http.Client _client = http.Client();

  Timer? _debounce;
  List<_Place> _local = const [];
  List<_Place> _remote = const [];
  bool _loading = false;
  bool _done = false;
  String _picked = '';
  String _lastText = '';
  int _request = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant AddressSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onChanged);
    _client.close();
    super.dispose();
  }

  /// True only while the customer is typing in this address box, so saved
  /// addresses that fill the box by themselves do not pop up suggestions.
  bool _fieldHasFocus() {
    final context = FocusManager.instance.primaryFocus?.context;

    if (context == null) return false;

    EditableText? editable;

    if (context.widget is EditableText) {
      editable = context.widget as EditableText;
    } else {
      editable = context.findAncestorWidgetOfExactType<EditableText>();
    }

    return editable != null && identical(editable.controller, widget.controller);
  }

  void _clear() {
    _request++;
    _debounce?.cancel();

    if (mounted &&
        (_local.isNotEmpty || _remote.isNotEmpty || _loading || _done)) {
      setState(() {
        _local = const [];
        _remote = const [];
        _loading = false;
        _done = false;
      });
    }
  }

  void _onChanged() {
    final text = widget.controller.text.trim();

    if (text == _lastText) return;

    _lastText = text;

    if (text == _picked || !_fieldHasFocus()) {
      _clear();
      return;
    }

    final query = text.split('\n').last.trim();

    if (query.length < 3) {
      _clear();
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _search(query),
    );
  }

  Future<List<_Place>> _fetch(String query, {required bool localOnly}) async {
    final params = <String, String>{'q': query};

    if (localOnly) params['mode'] = 'local';

    final uri = Uri.parse('${IanovaApiConfig.baseUrl}/api/places.php')
        .replace(queryParameters: params);
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(Duration(seconds: localOnly ? 5 : 9));

    final data = jsonDecode(response.body);
    final raw = data is Map ? data['places'] : null;
    final places = <_Place>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;

        final label = item['label']?.toString() ?? '';

        if (label.isEmpty) continue;

        places.add(
          _Place(
            item['name']?.toString() ?? label,
            item['detail']?.toString() ?? '',
            label,
          ),
        );
      }
    }

    return places;
  }

  Future<void> _search(String query) async {
    final id = ++_request;

    setState(() {
      _local = const [];
      _remote = const [];
      _loading = true;
      _done = false;
    });

    // Instant answer from the built-in list.
    _fetch(query, localOnly: true).then((places) {
      if (!mounted || id != _request) return;

      setState(() => _local = places);
    }).catchError((_) {});

    // Fuller answer (built-in + OpenStreetMap) a moment later.
    try {
      final places = await _fetch(query, localOnly: false);

      if (!mounted || id != _request) return;

      setState(() {
        _remote = places;
        _loading = false;
        _done = true;
      });
    } catch (_) {
      if (!mounted || id != _request) return;

      setState(() {
        _loading = false;
        _done = true;
      });
    }
  }

  List<_Place> _merged() {
    final seen = <String>{};
    final out = <_Place>[];

    for (final place in [..._local, ..._remote]) {
      if (seen.add(place.label.toLowerCase())) out.add(place);
    }

    return out.take(10).toList();
  }

  void _pick(_Place place) {
    _request++;
    _picked = place.label;
    _lastText = place.label;

    widget.controller.text = place.label;
    widget.controller.selection = TextSelection.collapsed(
      offset: place.label.length,
    );

    setState(() {
      _local = const [];
      _remote = const [];
      _loading = false;
      _done = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final places = _merged();

    if (places.isEmpty && !_loading && !_done) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: IanovaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: IanovaColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loading)
            const ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          for (final place in places)
            InkWell(
              onTap: () => _pick(place),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 20,
                      color: IanovaColors.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (place.detail.isNotEmpty)
                            Text(
                              place.detail,
                              style: const TextStyle(
                                fontSize: 12,
                                color: IanovaColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_loading && places.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Searching places…',
                style: TextStyle(color: IanovaColors.muted),
              ),
            ),
          if (!_loading && _done && places.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'No matching places. You can type your full address.',
                style: TextStyle(color: IanovaColors.muted),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 2, 12, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 10, color: IanovaColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
