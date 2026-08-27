import 'package:flutter/widgets.dart';

import '../localization/app_localizations.dart';

/// Centralised, localized validators used by every form in the app.
class Validators {
  Validators._();

  static final _emailRe = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$");
  static final _nameRe = RegExp(r"^[a-zA-Z\u0900-\u097F][a-zA-Z\u0900-\u097F .']{2,}$");
  static final _phoneRe = RegExp(r'^[6-9]\d{9}$');
  // >=8 chars, at least one letter, one digit, one special char
  static final _passwordRe = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:,.<>?/\\|~`]).{8,}$');

  static String? required(BuildContext context, String? v) {
    if (v == null || v.trim().isEmpty) return context.tr('requiredField');
    return null;
  }

  static String? name(BuildContext context, String? v) {
    final r = required(context, v);
    if (r != null) return r;
    if (!_nameRe.hasMatch(v!.trim())) return context.tr('invalidName');
    return null;
  }

  static String? email(BuildContext context, String? v) {
    final r = required(context, v);
    if (r != null) return r;
    if (!_emailRe.hasMatch(v!.trim())) return context.tr('invalidEmail');
    return null;
  }

  static String? phone(BuildContext context, String? v) {
    final r = required(context, v);
    if (r != null) return r;
    final cleaned = v!.replaceAll(RegExp(r'[\s\-]'), '');
    if (!_phoneRe.hasMatch(cleaned)) return context.tr('invalidPhone');
    return null;
  }

  static String? password(BuildContext context, String? v) {
    final r = required(context, v);
    if (r != null) return r;
    if (!_passwordRe.hasMatch(v!)) return context.tr('weakPassword');
    return null;
  }

  static String? confirmPassword(
      BuildContext context, String? v, String original) {
    final r = required(context, v);
    if (r != null) return r;
    if (v != original) return context.tr('passwordMismatch');
    return null;
  }

  static String? donationAmount(BuildContext context, String? v) {
    final r = required(context, v);
    if (r != null) return r;
    final n = num.tryParse(v!.trim());
    if (n == null || n < 11) return context.tr('invalidAmount');
    return null;
  }
}
