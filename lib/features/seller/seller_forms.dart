import 'package:flutter/material.dart';

import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_models.dart';
import 'seller_service.dart';

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

ButtonStyle _primaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: IanovaColors.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(IanovaSpacing.radiusMedium),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
  );
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';

  if (email.isEmpty) {
    return 'Enter your email address.';
  }

  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email address.';
  }

  return null;
}

class SellerApplyForm extends StatefulWidget {
  const SellerApplyForm({
    super.key,
    required this.service,
    required this.onSession,
  });

  final SellerService service;
  final ValueChanged<SellerSession> onSession;

  @override
  State<SellerApplyForm> createState() => _SellerApplyFormState();
}

class _SellerApplyFormState extends State<SellerApplyForm> {
  final _formKey = GlobalKey<FormState>();
  final _businessController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _businessController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session = await widget.service.apply(
        businessName: _businessController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        description: _descriptionController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      widget.onSession(session);
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(IanovaSpacing.xl),
        children: [
          Container(
            padding: const EdgeInsets.all(IanovaSpacing.lg),
            decoration: BoxDecoration(
              color: IanovaColors.sky,
              borderRadius: BorderRadius.circular(IanovaSpacing.radiusXLarge),
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
                  'Apply to sell on IANOVA. Our team replies right here in '
                  'the app once your application is reviewed.',
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
            validator: (value) {
              final text = value?.trim() ?? '';

              if (text.length < 2) {
                return 'Enter your business name.';
              }

              return null;
            },
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
              hint: 'What do you sell, and what makes your business a good '
                  'fit for IANOVA?',
              icon: Icons.notes_rounded,
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: IanovaSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _isLoading ? null : _submit(),
            decoration: _decoration(
              label: 'Seller password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: _isLoading
                    ? null
                    : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters.';
              }

              return null;
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: IanovaSpacing.xl),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: _primaryButtonStyle(),
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
            'Use this email and password to sign in here, and to the seller '
            'area on the IANOVA website.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: IanovaColors.muted),
          ),
        ],
      ),
    );
  }
}

class SellerLoginForm extends StatefulWidget {
  const SellerLoginForm({
    super.key,
    required this.service,
    required this.onSession,
  });

  final SellerService service;
  final ValueChanged<SellerSession> onSession;

  @override
  State<SellerLoginForm> createState() => _SellerLoginFormState();
}

class _SellerLoginFormState extends State<SellerLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session = await widget.service.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      widget.onSession(session);
    } on SellerApplyException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign in. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(IanovaSpacing.xl),
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in with the email and password from your seller '
            'application to see replies from our team.',
            style: TextStyle(color: IanovaColors.secondary, height: 1.35),
          ),
          const SizedBox(height: IanovaSpacing.xl),
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
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _isLoading ? null : _submit(),
            decoration: _decoration(
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: _isLoading
                    ? null
                    : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter your password.';
              }

              return null;
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: IanovaSpacing.xl),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: _primaryButtonStyle(),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Sign in'),
            ),
          ),
        ],
      ),
    );
  }
}
