import 'package:flutter/material.dart';

import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_service.dart';

class SellerApplyPage extends StatefulWidget {
  const SellerApplyPage({super.key});

  @override
  State<SellerApplyPage> createState() => _SellerApplyPageState();
}

class _SellerApplyPageState extends State<SellerApplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();

  final _service = SellerService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _successMessage;

  @override
  void dispose() {
    _businessController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final message = await _service.apply(
        businessName: _businessController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        description: _descriptionController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _successMessage = message;
      });
    } on SellerApplyException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send your application. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateBusiness(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Enter your business name.';
    }

    if (text.length < 2) {
      return 'Business name must be at least 2 characters.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Enter your email address.';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Create a password.';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    return null;
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IanovaColors.background,
      appBar: AppBar(
        title: const Text(
          'Sell on IANOVA',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: _successMessage != null
            ? _SuccessView(
                message: _successMessage!,
                onDone: () => Navigator.of(context).pop(),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(IanovaSpacing.xl),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(IanovaSpacing.lg),
                      decoration: BoxDecoration(
                        color: IanovaColors.sky,
                        borderRadius: BorderRadius.circular(
                          IanovaSpacing.radiusXLarge,
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reach more customers',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: IanovaColors.primary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Apply to sell on IANOVA. We review every '
                            'application and email you once it is approved.',
                            style: TextStyle(
                              color: IanovaColors.secondary,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: IanovaSpacing.xl),
                    TextFormField(
                      controller: _businessController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration(
                        label: 'Business name',
                        icon: Icons.storefront_outlined,
                      ),
                      validator: _validateBusiness,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: IanovaSpacing.md),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: _decoration(
                        label: 'Email address',
                        icon: Icons.email_outlined,
                      ),
                      validator: _validateEmail,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: IanovaSpacing.md),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: _decoration(
                        label: 'Phone (optional)',
                        icon: Icons.phone_outlined,
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: IanovaSpacing.md),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      decoration: _decoration(
                        label: 'Tell us about your business',
                        hint: 'What do you sell, and what makes your '
                            'business a good fit for IANOVA?',
                        icon: Icons.notes_rounded,
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: IanovaSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                      decoration: _decoration(
                        label: 'Seller password',
                        icon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: IanovaSpacing.xl),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: IanovaColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              IanovaSpacing.radiusMedium,
                            ),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Apply to sell'),
                      ),
                    ),
                    const SizedBox(height: IanovaSpacing.md),
                    const Text(
                      'You will use this email and password to sign in to the '
                      'seller area on the IANOVA website.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: IanovaColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.message,
    required this.onDone,
  });

  final String message;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(IanovaSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: IanovaColors.sand,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 44,
                color: IanovaColors.success,
              ),
            ),
            const SizedBox(height: IanovaSpacing.xl),
            const Text(
              'Application sent',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IanovaSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: IanovaColors.secondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: IanovaSpacing.xxl),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: IanovaColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    IanovaSpacing.radiusMedium,
                  ),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
