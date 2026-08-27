import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/login_screen.dart';
import '../localization/app_localizations.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';

/// Guest-mode gate. Call before any confidential feature (seva/daan,
/// profile edits, sankalp, event registration). If the user is a guest,
/// shows a polite "sign in required" dialog and routes to the login
/// screen. Returns true only when the user is signed in afterwards.
///
/// Always pass the calling widget's [WidgetRef] so we can read the auth
/// provider. (The old parameter-less `ensureSignedIn` always returned
/// false, which silently blocked guests from ever registering.)
Future<bool> ensureSignedInWithRef(BuildContext context, WidgetRef ref) async {
  final auth = ref.read(authProvider);
  if (auth.status == AuthStatus.signedIn) return true;

  final goToLogin = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: const Icon(Icons.lock_outline, color: AppColors.gold, size: 34),
      title: Text(dialogContext.tr('loginRequired')),
      content: Text(dialogContext.tr('loginRequiredBody'),
          textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(dialogContext.tr('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.maroon),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(dialogContext.tr('login')),
        ),
      ],
    ),
  );
  if (goToLogin != true || !context.mounted) return false;

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoginScreen(inAppFlow: true)),
  );
  if (!context.mounted) return false;
  return ref.read(authProvider).status == AuthStatus.signedIn;
}
