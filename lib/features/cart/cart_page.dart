import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/cart.dart';
import '../../models/cart_item.dart';
import '../../widgets/ianova_product_image.dart';
import '../auth/login_page.dart';
import '../checkout/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({
    super.key,
    this.onContinueShopping,
    this.onCartChanged,
    this.refreshToken = 0,
  });

  final VoidCallback? onContinueShopping;
  final VoidCallback? onCartChanged;
  final int refreshToken;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final ApiService _api = ApiService();

  Cart? _cart;
  bool _isLoading = true;
  String? _error;
  int? _busyProductId;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void didUpdateWidget(covariant CartPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadCart();
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cart = await _api.getCart();

      if (!mounted) return;

      setState(() {
        _cart = cart;
        _isLoading = false;
      });

      widget.onCartChanged?.call();
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load your cart.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openLogin() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );

    if (loggedIn == true) {
      await _loadCart();
    }
  }

  Future<void> _changeQuantity(
    CartItem item,
    int newQuantity,
  ) async {
    if (_busyProductId != null) return;

    if (newQuantity < 1) {
      await _removeItem(item);
      return;
    }

    setState(() {
      _busyProductId = item.productId;
    });

    try {
      await _api.updateCartItem(
        productId: item.productId,
        quantity: newQuantity,
      );

      if (!mounted) return;

      await _loadCart();
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update cart. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyProductId = null;
        });
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    if (_busyProductId != null) return;

    setState(() {
      _busyProductId = item.productId;
    });

    try {
      await _api.removeFromCart(
        productId: item.productId,
      );

      if (!mounted) return;

      await _loadCart();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product removed from your cart.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to remove product. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyProductId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IanovaColors.background,
      appBar: AppBar(
        title: const Text(
          'Your cart',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }
Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      final requiresLogin = _error!.toLowerCase().contains('sign in');

      return _CartError(
        message: _error!,
        actionLabel: requiresLogin ? 'Sign in' : 'Try again',
        onAction: requiresLogin ? _openLogin : _loadCart,
      );
    }

    final cart = _cart;

    if (cart == null || cart.isEmpty) {
      return _EmptyCart(
        onContinueShopping: widget.onContinueShopping ?? () {},
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCart,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          IanovaSpacing.lg,
          IanovaSpacing.lg,
          IanovaSpacing.lg,
          140,
        ),
        children: [
          Text(
            '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: IanovaSpacing.md),
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(
                bottom: IanovaSpacing.md,
              ),
              child: _CartItemCard(
                item: item,
                isBusy: _busyProductId == item.productId,
                onDecrease: () => _changeQuantity(
                  item,
                  item.quantity - 1,
                ),
                onIncrease: () => _changeQuantity(
                  item,
                  item.quantity + 1,
                ),
                onRemove: () => _removeItem(item),
              ),
            ),
          ),
          const SizedBox(height: IanovaSpacing.md),
          _SummaryCard(
            cart: cart,
            onCheckout: () async {
              final completed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const CheckoutPage(),
                ),
              );

              if (completed == true && mounted) {
                await _loadCart();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.isBusy,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final CartItem item;
  final bool isBusy;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return Container(
      padding: const EdgeInsets.all(IanovaSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          IanovaSpacing.radiusMedium,
        ),
        border: Border.all(
          color: IanovaColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    IanovaSpacing.radiusSmall,
                  ),
                  child: IanovaProductImage(
                    image: product.image,
                    emoji: product.emoji,
                    backgroundColor: product.bgColor,
                  ),
                ),
              ),
              const SizedBox(width: IanovaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: IanovaSpacing.sm),
                    Text(
                      'KSh ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: IanovaSpacing.sm),
                    Text(
                      'KSh ${item.itemTotal.toStringAsFixed(0)} total',
                      style: const TextStyle(
                        color: IanovaColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: IanovaSpacing.md),
          Row(
            children: [
              _QuantityButton(
                icon: Icons.remove,
                onPressed: isBusy ? null : onDecrease,
              ),
              const SizedBox(width: IanovaSpacing.sm),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 44,
                ),
                alignment: Alignment.center,
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(width: IanovaSpacing.sm),
              _QuantityButton(
                icon: Icons.add,
                onPressed: isBusy ? null : onIncrease,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: isBusy ? null : onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 19,
                ),
                label: const Text('Remove'),
                style: TextButton.styleFrom(
                  foregroundColor: IanovaColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              IanovaSpacing.radiusSmall,
            ),
          ),
          side: const BorderSide(
            color: IanovaColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 19,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.cart,
    required this.onCheckout,
  });

  final Cart cart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IanovaSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          IanovaSpacing.radiusLarge,
        ),
        border: Border.all(
          color: IanovaColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  color: IanovaColors.secondary,
                ),
              ),
              const Spacer(),
              Text(
                'KSh ${cart.subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: IanovaSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onCheckout,
              child: const Text(
                'Proceed to checkout',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({
    required this.onContinueShopping,
  });

  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(IanovaSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: IanovaColors.soft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 52,
                color: IanovaColors.secondary,
              ),
            ),
            const SizedBox(height: IanovaSpacing.xl),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: IanovaSpacing.sm),
            const Text(
              'Products you add will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: IanovaColors.secondary,
              ),
            ),
            const SizedBox(height: IanovaSpacing.xl),
            FilledButton(
              onPressed: onContinueShopping,
              child: const Text('Continue shopping'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartError extends StatelessWidget {
  const _CartError({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(IanovaSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: IanovaColors.muted,
            ),
            const SizedBox(height: IanovaSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: IanovaColors.secondary,
              ),
            ),
            const SizedBox(height: IanovaSpacing.xl),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
