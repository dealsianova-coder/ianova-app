import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/theme/ianova_theme.dart';
import '../../widgets/panel_ui.dart';
import 'seller_ops_service.dart';

Color sellerStatusColor(String status) {
  switch (status) {
    case 'approved':
      return const Color(0xFF17803D);
    case 'pending':
      return const Color(0xFFA05A00);
    default:
      return const Color(0xFFB3261E);
  }
}

class SellerProductCard extends StatelessWidget {
  const SellerProductCard({
    super.key,
    required this.product,
    required this.onRequestReview,
  });

  final SellerProduct product;
  final VoidCallback onRequestReview;

  @override
  Widget build(BuildContext context) {
    final photo = PhotoLookup.forProduct(
      id: product.id,
      name: product.name,
      own: product.image,
    );
    final status = product.status.isEmpty
        ? ''
        : product.status[0].toUpperCase() + product.status.substring(1);
    final lowStock = product.stock <= 3;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ImageBlock(url: photo, radius: 14),
              Positioned(
                left: 8,
                top: 8,
                child: StatusPill(status, sellerStatusColor(product.status)),
              ),
              if (product.locked)
                const Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.lock_rounded,
                        size: 16, color: Color(0xFFB3261E)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            formatKsh(product.price),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              InfoChip(
                'Stock ${product.stock}',
                icon: Icons.inventory_2_outlined,
              ),
              if (lowStock && product.stock > 0)
                const InfoChip('Low', icon: Icons.warning_amber_rounded),
              if (product.option.isNotEmpty) InfoChip(product.option),
            ],
          ),
          if (product.locked) ...[
            const SizedBox(height: 10),
            const Text(
              'Locked by admin',
              style: TextStyle(
                color: Color(0xFFB3261E),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: EdgeInsets.zero,
                ),
                onPressed: onRequestReview,
                child: const Text('Request review'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SellerOrderCard extends StatelessWidget {
  const SellerOrderCard({
    super.key,
    required this.order,
    required this.approving,
    required this.onApprove,
  });

  final SellerOrder order;
  final bool approving;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final waiting = !order.approved;
    final color =
        order.approved ? const Color(0xFF17803D) : const Color(0xFFA05A00);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              StatusPill(waiting ? 'Waiting for you' : 'You approved', color),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            order.createdAt,
            style: const TextStyle(color: IanovaColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: IanovaColors.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.customer,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                if (order.phone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 16, color: IanovaColors.secondary),
                      const SizedBox(width: 8),
                      Text(order.phone,
                          style:
                              const TextStyle(color: IanovaColors.secondary)),
                    ],
                  ),
                ],
                if (order.address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: IanovaColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(order.address,
                            style: const TextStyle(
                                color: IanovaColors.secondary)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ImageBlock(
                    url: PhotoLookup.forProduct(name: line.name),
                    size: 56,
                    radius: 12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Qty ${line.quantity}'
                          '${line.option.isEmpty ? '' : ' · ${line.option}'}',
                          style: const TextStyle(
                            color: IanovaColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatKsh(line.lineTotal),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          const Divider(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your total',
                  style: TextStyle(color: IanovaColors.secondary),
                ),
              ),
              Text(
                formatKsh(order.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          if (order.canApprove) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: approving ? null : onApprove,
                child: approving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Approve order'),
              ),
            ),
          ] else if (order.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              order.note,
              style: const TextStyle(color: IanovaColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
