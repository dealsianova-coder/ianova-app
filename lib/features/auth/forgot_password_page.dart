import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';

/// Reset a forgotten password with a 6-digit code sent by email.
/// kind: 'user' (shopper), 'seller' or 'admin'.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.kind = 'user', this.initialEmail = ''});

  final String kind;
  final String initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _codeStep = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _post(String file, Map<String, String> data) async {
    final r = await http.post(
      Uri.parse('${IanovaApiConfig.baseUrl}/api/$file'),
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({...data, 'kind': widget.kind}),
    );
    try {
      final d = jsonDecode(r.body);
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
    return {'success': false, 'error': 'Invalid server response.'};
  }

  String? _passwordProblem(String p) {
    if (p.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[A-Za-z]').hasMatch(p) || !RegExp(r'\d').hasMatch(p)) {
      return 'Use at least one letter and one number.';
    }
    return null;
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final d = await _post('forgot_password.php', {'email': email});
      if (d['success'] == true) {
        setState(() => _codeStep = true);
      } else {
        setState(() => _error = d['error']?.toString() ?? 'Could not send the code.');
      }
    } catch (_) {
      setState(() => _error = 'No connection. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final problem = _passwordProblem(_pass.text);
    if (_code.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your email.');
      return;
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    if (_pass.text != _pass2.text) {
      setState(() => _error = 'The two passwords do not match.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final d = await _post('reset_password.php', {
        'email': _email.text.trim(),
        'code': _code.text.trim(),
        'password': _pass.text,
      });
      if (!mounted) return;
      if (d['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed. Sign in with your new password.')),
        );
        Navigator.of(context).pop();
      } else {
        setState(() => _error = d['error']?.toString() ?? 'Could not reset the password.');
      }
    } catch (_) {
      setState(() => _error = 'No connection. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IanovaColors.background,
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(IanovaSpacing.xl),
          children: [
            Container(
              padding: const EdgeInsets.all(IanovaSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE3E7EF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _codeStep ? 'Enter your code' : 'Forgot your password?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _codeStep
                        ? 'We emailed a 6-digit code to ${_email.text.trim()}. It works for 30 minutes.'
                        : 'Enter your email and we will send you a 6-digit code.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: IanovaColors.secondary, height: 1.4),
                  ),
                  const SizedBox(height: IanovaSpacing.xl),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: IanovaSpacing.lg),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFFB0102F))),
                    ),
                  TextField(
                    controller: _email,
                    enabled: !_busy && !_codeStep,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  if (_codeStep) ...[
                    const SizedBox(height: IanovaSpacing.lg),
                    TextField(
                      controller: _code,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: '6-digit code',
                        counterText: '',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                    ),
                    const SizedBox(height: IanovaSpacing.lg),
                    TextField(
                      controller: _pass,
                      enabled: !_busy,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        helperText: 'At least 8 characters, with a letter and a number.',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: IanovaSpacing.lg),
                    TextField(
                      controller: _pass2,
                      enabled: !_busy,
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                  ],
                  const SizedBox(height: IanovaSpacing.xl),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _busy ? null : (_codeStep ? _reset : _send),
                      child: _busy
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_codeStep ? 'Save new password' : 'Send code',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  if (_codeStep)
                    TextButton(
                      onPressed: _busy ? null : () => setState(() { _codeStep = false; _error = null; }),
                      child: const Text('Use a different email / send a new code'),
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
