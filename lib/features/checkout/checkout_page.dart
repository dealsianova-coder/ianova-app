import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';
import '../../core/storage/auth_storage.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/checkout_result.dart';
import '../../models/user_address.dart';
import '../auth/login_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final ApiService _api = ApiService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  List<UserAddress> _addresses = [];
  UserAddress? _selectedAddress;

  bool _isLoading = true;
  bool _isPlacingOrder = false;
  bool _isAddingAddress = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCheckoutData();
  }

  @override
  void dispose() {
    _api.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCheckoutData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await AuthStorage.getUser();
      final addresses = await _api.getAddresses();

      if (!mounted) return;

      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
      }

      UserAddress? selected;

      if (addresses.isNotEmpty) {
        selected = addresses.where((item) => item.isDefault).firstOrNull;

        selected ??= addresses.first;

        _applyAddress(selected);
      }

      setState(() {
        _addresses = addresses;
        _selectedAddress = selected;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        final loggedIn = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
        );

        if (loggedIn == true) {
          await _loadCheckoutData();
          return;
        }
      }

      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load checkout information.';
        _isLoading = false;
      });
    }
  }

  void _applyAddress(UserAddress address) {
    _nameController.text = address.recipientName;
    _phoneController.text = address.phone;
    _addressController.text = address.address;
  }

  void _selectAddress(UserAddress address) {
    setState(() {
      _selectedAddress = address;
      _isAddingAddress = false;
    });

    _applyAddress(address);
  }

  void _startNewAddress() {
    setState(() {
      _selectedAddress = null;
      _isAddingAddress = true;
    });

    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  Future<void> _placeOrder() async {
    if (_isPlacingOrder) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final result = await _api.checkout(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
      );

      if (!mounted) return;

      await _showOrderSuccess(result);
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
          content: Text('Unable to place your order. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  Future<void> _showOrderSuccess(CheckoutResult result) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: IanovaColors.success,
              ),
              SizedBox(width: IanovaSpacing.sm),
              Expanded(
                child: Text('Order placed'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${result.orderId}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: IanovaSpacing.lg),
              _TotalRow(
                label: 'Subtotal',
                value: result.subtotal,
              ),
              const SizedBox(height: IanovaSpacing.sm),
              _TotalRow(
                label: 'Delivery',
                value: result.delivery,
              ),
              const Divider(height: IanovaSpacing.xl),
              _TotalRow(
                label: 'Total',
                value: result.total,
                emphasized: true,
              ),
              const SizedBox(height: IanovaSpacing.lg),
              const Text(
                'Your order is now pending and has been recorded successfully.',
                style: TextStyle(
                  color: IanovaColors.secondary,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IanovaColors.background,
      appBar: AppBar(
        title: const Text(
          'Checkout',
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(IanovaSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: IanovaColors.muted,
              ),
              const SizedBox(height: IanovaSpacing.lg),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: IanovaColors.secondary,
                ),
              ),
              const SizedBox(height: IanovaSpacing.xl),
              FilledButton(
                onPressed: _loadCheckoutData,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          IanovaSpacing.lg,
          IanovaSpacing.lg,
          IanovaSpacing.lg,
          IanovaSpacing.xxxl,
        ),
        children: [
          const Text(
            'Delivery details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: IanovaSpacing.sm),
          const Text(
            'Choose a saved address or enter a new delivery address.',
            style: TextStyle(
              color: IanovaColors.secondary,
            ),
          ),
          const SizedBox(height: IanovaSpacing.lg),
          _buildAddressSelector(),
          const SizedBox(height: IanovaSpacing.xl),
          _buildFormFields(),
          const SizedBox(height: IanovaSpacing.xl),
          _buildPlaceOrderButton(),
        ],
      ),
    );
  }

  Widget _buildAddressSelector() {
    if (_addresses.isEmpty || _isAddingAddress) {
      return _NewAddressCard(
        onCancel: _addresses.isEmpty ? null : () {
          final address = _addresses.firstWhere(
            (item) => item.isDefault,
            orElse: () => _addresses.first,
          );
          _selectAddress(address);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._addresses.map(
          (address) => Padding(
            padding: const EdgeInsets.only(
              bottom: IanovaSpacing.sm,
            ),
            child: _AddressCard(
              address: address,
              selected: _selectedAddress?.id == address.id,
              onTap: () => _selectAddress(address),
            ),
          ),
        ),
        const SizedBox(height: IanovaSpacing.sm),
        OutlinedButton.icon(
          onPressed: _startNewAddress,
          icon: const Icon(Icons.add),
          label: const Text('Use a new address'),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Recipient name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter the recipient name.';
            }
            return null;
          },
        ),
        const SizedBox(height: IanovaSpacing.md),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            final email = value?.trim() ?? '';

            if (email.isEmpty) {
              return 'Enter your email.';
            }

            if (!email.contains('@') || !email.contains('.')) {
              return 'Enter a valid email address.';
            }

            return null;
          },
        ),
        const SizedBox(height: IanovaSpacing.md),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter your phone number.';
            }
            return null;
          },
        ),
        const SizedBox(height: IanovaSpacing.md),
        TextFormField(
          controller: _addressController,
          minLines: 3,
          maxLines: 5,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Delivery address',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 48),
              child: Icon(Icons.location_on_outlined),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter your delivery address.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _isPlacingOrder ? null : _placeOrder,
        child: _isPlacingOrder
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Place order',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final UserAddress address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        IanovaSpacing.radiusMedium,
      ),
      child: Container(
        padding: const EdgeInsets.all(IanovaSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            IanovaSpacing.radiusMedium,
          ),
          border: Border.all(
            color: selected
                ? IanovaColors.primary
                : IanovaColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected
                  ? IanovaColors.primary
                  : IanovaColors.muted,
            ),
            const SizedBox(width: IanovaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: IanovaSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: IanovaColors.soft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.recipientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address.phone,
                    style: const TextStyle(
                      color: IanovaColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: IanovaColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewAddressCard extends StatelessWidget {
  const _NewAddressCard({
    required this.onCancel,
  });

  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IanovaSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          IanovaSpacing.radiusMedium,
        ),
        border: Border.all(
          color: IanovaColors.border,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.add_location_alt_outlined,
            color: IanovaColors.secondary,
          ),
          const SizedBox(width: IanovaSpacing.md),
          const Expanded(
            child: Text(
              'New delivery address',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: emphasized
                ? IanovaColors.primary
                : IanovaColors.secondary,
            fontWeight: emphasized
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          'KSh ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: emphasized
                ? FontWeight.w900
                : FontWeight.w700,
            fontSize: emphasized ? 18 : 15,
          ),
        ),
      ],
    );
  }
}
