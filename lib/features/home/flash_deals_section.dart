import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/product.dart';
import '../../widgets/ianova_product_card.dart';

/// Flash deals on a soft rose band. The cards drift slowly sideways and
/// stop while the user touches them.
class FlashDealsSection extends StatefulWidget {
  const FlashDealsSection({
    super.key,
    required this.products,
    required this.onSeeAll,
    required this.onProductTap,
    this.onCartChanged,
  });

  final List<Product> products;
  final VoidCallback onSeeAll;
  final ValueChanged<Product> onProductTap;
  final VoidCallback? onCartChanged;

  @override
  State<FlashDealsSection> createState() => _FlashDealsSectionState();
}

class _FlashDealsSectionState extends State<FlashDealsSection>
    with SingleTickerProviderStateMixin {
  /// Logical pixels per second. Slow on purpose.
  static const double _speed = 20;

  final ScrollController _scroll = ScrollController();
  late final Ticker _ticker;
  Timer? _resume;
  Duration _last = Duration.zero;
  bool _paused = false;

  bool get _drifts => widget.products.length >= 2;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);

    if (_drifts) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant FlashDealsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_drifts && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!_drifts && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _resume?.cancel();
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final seconds = math.min(
      0.05,
      (elapsed - _last).inMicroseconds / 1000000,
    );
    _last = elapsed;

    if (_paused || !_scroll.hasClients) return;

    _scroll.jumpTo(_scroll.offset + _speed * seconds);
  }

  void _pause() {
    _resume?.cancel();
    _paused = true;
  }

  void _scheduleResume() {
    _resume?.cancel();
    _resume = Timer(const Duration(milliseconds: 2500), () {
      _paused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.products;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        IanovaSpacing.md,
        IanovaSpacing.sm,
        IanovaSpacing.md,
        IanovaSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: IanovaColors.roseTint,
        borderRadius: BorderRadius.circular(IanovaSpacing.radiusXLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              IanovaSpacing.lg,
              IanovaSpacing.lg,
              IanovaSpacing.sm,
              IanovaSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: IanovaColors.danger,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: IanovaSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flash deals',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Limited-time prices',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: IanovaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: widget.onSeeAll,
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 318,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _pause(),
              onPointerUp: (_) => _scheduleResume(),
              onPointerCancel: (_) => _scheduleResume(),
              child: ListView.builder(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  IanovaSpacing.lg,
                  IanovaSpacing.xs,
                  IanovaSpacing.lg,
                  IanovaSpacing.lg,
                ),
                itemCount: _drifts ? null : items.length,
                itemBuilder: (context, index) {
                  final product = items[index % items.length];

                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: SizedBox(
                      width: 190,
                      child: IanovaProductCard(
                        product: product,
                        animateBadge: true,
                        onTap: () => widget.onProductTap(product),
                        onCartChanged: widget.onCartChanged,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
