import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_service.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/user_address.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  final _api = ApiService();

  List<UserAddress> _addresses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final addresses = await _api.getAddresses();

      if (!mounted) return;

      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Unable to load your addresses.';
      });
    }
  }

  Future<void> _addAddress() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddressFormPage(),
      ),
    );

    if (saved == true) {
      await _loadAddresses();
    }
  }

  Future<void> _editAddress(UserAddress address) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(address: address),
      ),
    );

    if (saved == true) {
      await _loadAddresses();
    }
  }

  Future<void> _deleteAddress(UserAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete address?'),
          content: Text(
            'Remove "${address.label}" from your saved addresses?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _api.deleteAddress(id: address.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted.'),
        ),
      );

      await _loadAddresses();
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
          content: Text('Unable to delete address.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IanovaColors.background,
      appBar: AppBar(
        title: const Text(
          'Delivery addresses',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _addAddress,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add address'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAddresses,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(IanovaSpacing.xl),
        children: [
          const SizedBox(height: IanovaSpacing.huge),
          Icon(
            Icons.location_off_outlined,
            size: 56,
            color: IanovaColors.secondary,
          ),
          const SizedBox(height: IanovaSpacing.lg),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: IanovaSpacing.lg),
          Center(
            child: FilledButton.icon(
              onPressed: _loadAddresses,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    if (_addresses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(IanovaSpacing.xl),
        children: [
          const SizedBox(height: IanovaSpacing.huge),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: IanovaColors.soft,
              borderRadius: BorderRadius.circular(
                IanovaSpacing.radiusXLarge,
              ),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 42,
            ),
          ),
          const SizedBox(height: IanovaSpacing.xl),
          const Text(
            'No delivery addresses',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: IanovaSpacing.sm),
          Text(
            'Add an address to make checkout faster and easier.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: IanovaColors.secondary,
                ),
          ),
          const SizedBox(height: IanovaSpacing.xl),
          FilledButton.icon(
            onPressed: _addAddress,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add your first address'),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        IanovaSpacing.xl,
        IanovaSpacing.xl,
        IanovaSpacing.xl,
        120,
      ),
      itemCount: _addresses.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: IanovaSpacing.md),
      itemBuilder: (context, index) {
        final address = _addresses[index];

        return _AddressCard(
          address: address,
          onEdit: () => _editAddress(address),
          onDelete: () => _deleteAddress(address),
        );
      },
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  final UserAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Future<void> _openInGoogleMaps(BuildContext context) async {
    final query = Uri.encodeComponent(address.address.trim());

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This address does not have a location to open.'),
        ),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open Google Maps.'),
        ),
      );
    }
  }

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
          color: address.isDefault
              ? IanovaColors.primary
              : IanovaColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: IanovaSpacing.sm,
                    vertical: IanovaSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: IanovaColors.soft,
                    borderRadius: BorderRadius.circular(
                      IanovaSpacing.radiusSmall,
                    ),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: IanovaSpacing.md),
          Text(
            address.recipientName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: IanovaSpacing.xs),
          Text(address.phone),
          const SizedBox(height: IanovaSpacing.xs),
          Text(
            address.address,
            style: const TextStyle(
              color: IanovaColors.secondary,
            ),
          ),
          const SizedBox(height: IanovaSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openInGoogleMaps(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open in Google Maps'),
            ),
          ),
          const SizedBox(height: IanovaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: IanovaSpacing.sm),
              IconButton(
                tooltip: 'Delete address',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({
    super.key,
    this.address,
  });

  final UserAddress? address;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _labelController = TextEditingController();
  final _recipientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _api = ApiService();

  bool _isDefault = false;
  bool _isSaving = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();

    final address = widget.address;

    if (address != null) {
      _labelController.text = address.label;
      _recipientController.text = address.recipientName;
      _phoneController.text = address.phone;
      _addressController.text = address.address;
      _isDefault = address.isDefault;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _recipientController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        await _api.updateAddress(
          id: widget.address!.id,
          label: _labelController.text,
          recipientName: _recipientController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          isDefault: _isDefault,
        );
      } else {
        await _api.addAddress(
          label: _labelController.text,
          recipientName: _recipientController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          isDefault: _isDefault,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Address updated successfully.'
                : 'Address added successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
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
          content: Text('Unable to save address.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _required(
    String? value,
    String message,
    int maxLength,
  ) {
    final clean = value?.trim() ?? '';

    if (clean.isEmpty) {
      return message;
    }

    if (clean.length > maxLength) {
      return 'Maximum $maxLength characters.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IanovaColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit address' : 'Add address',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(IanovaSpacing.xl),
            children: [
              TextFormField(
                controller: _labelController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Address label',
                  hintText: 'Home, Work, etc.',
                  prefixIcon: Icon(Icons.bookmark_outline_rounded),
                ),
                validator: (value) => _required(
                  value,
                  'Enter an address label.',
                  50,
                ),
              ),
              const SizedBox(height: IanovaSpacing.md),
              TextFormField(
                controller: _recipientController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Recipient name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => _required(
                  value,
                  'Enter the recipient name.',
                  120,
                ),
              ),
              const SizedBox(height: IanovaSpacing.md),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) => _required(
                  value,
                  'Enter a phone number.',
                  30,
                ),
              ),
              const SizedBox(height: IanovaSpacing.md),
              TextFormField(
                controller: _addressController,
                keyboardType: TextInputType.streetAddress,
                textInputAction: TextInputAction.newline,
                maxLines: 4,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Delivery address',
                  hintText: 'Enter your full delivery address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) => _required(
                  value,
                  'Enter the delivery address.',
                  255,
                ),
              ),
              const SizedBox(height: IanovaSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Use as default address',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Use this address automatically at checkout.',
                ),
                value: _isDefault,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _isDefault = value;
                        });
                      },
              ),
              const SizedBox(height: IanovaSpacing.xl),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save changes' : 'Add address',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
