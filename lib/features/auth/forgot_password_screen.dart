import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/widgets.dart';

/// Demo password reset: verifies the email exists locally and sets a new
/// password. In production, replace with an OTP / email-link flow from
/// your backend (the form & validation stay the same).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _newPassword = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    
    final result = await ref.read(authProvider.notifier).resetPassword(_email.text, _newPassword.text);
    
    if (!mounted) return;
    if (result == AuthResult.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('passwordResetDone'))));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('emailNotFound'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final busy = authState.busy;
    final localeCode = ref.watch(localeProvider).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('resetPassword'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        // Resets validation messages when the language changes.
        child: KeyedSubtree(
          key: ValueKey(localeCode),
          child: Form(
            key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: OmEmblem(size: 76)),
              const SizedBox(height: 20),
              Text(
                context.tr('resetSubtitle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              AppTextField(
                controller: _email,
                label: context.tr('email'),
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => Validators.email(context, v),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _newPassword,
                label: context.tr('newPassword'),
                prefixIcon: Icons.lock_reset_outlined,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.password(context, v),
                suffix: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 26),
              GoldButton(
                label: context.tr('resetPassword'),
                busy: busy,
                onPressed: _submit,
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
