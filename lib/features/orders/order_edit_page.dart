import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../models/order.dart';
import 'order_manage_service.dart';

/// Edit a pending order. Pops with 'updated' or 'cancelled'.
class OrderEditPage extends StatefulWidget {
  const OrderEditPage({super.key, required this.order});

  final Order order;

  @override
  State<OrderEditPage> createState() => _OrderEditPageState();
}

class _OrderEditPageState extends State<OrderEditPage> {
  final _service = OrderManageService();
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final Map<int, int> _quantities;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.order.guestPhone);
    _address = TextEditingController(text: widget.order.address);
    _quantities = {
      for (final item in widget.order.items) item.id: item.quantity,
    };
  }

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    if (_address.text.trim().isEmpty) {
      _toast('Delivery address is required.');
      return;
    }

    if (_quantities.values.every((q) => q == 0)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove every item?'),
          content: const Text('This will cancel the whole order.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep order'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cancel order'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;
    }

    setState(() => _saving = true);

    try {
      final cancelled = await _service.update(
        widget.order.id,
        phone: _phone.text,
        address: _address.text,
        quantities: _quantities,
      );

      if (!mounted) return;

      Navigator.of(context).pop(cancelled ? 'cancelled' : 'updated');
    } on OrderManageException catch (error) {
      if (!mounted) return;

      _toast(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit order #${widget.order.id}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Delivery address'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final item in widget.order.items)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: _quantities[item.id] == 0
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _quantities[item.id] == 0
                                  ? 'Will be removed'
                                  : formatKsh(item.unitPrice),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: (_quantities[item.id] ?? 0) > 0
                            ? () => setState(
                                  () => _quantities[item.id] =
                                      (_quantities[item.id] ?? 0) - 1,
                                )
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${_quantities[item.id] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () => _quantities[item.id] =
                              (_quantities[item.id] ?? 0) + 1,
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 4),
            const Text(
              'Set a quantity to 0 to remove an item. Delivery is worked out '
              'again for the new total.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              child: Text(_saving ? 'Saving...' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
