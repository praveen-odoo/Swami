import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/language_toggle.dart';
import '../../shared/widgets/widgets.dart';
import '../auth/login_screen.dart';
import 'complaint_screen.dart';
import 'complaint_history_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final signedIn = authState.status == AuthStatus.signedIn;
    final locale = ref.watch(localeProvider);
    final isHindi = locale.languageCode == 'hi';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile')),
        automaticallyImplyLeading: false,
        actions: [
          if (signedIn)
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.error),
              tooltip: context.tr('logout'),
              onPressed: () => _confirmLogout(context, ref),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  signedIn ? _UserCard(user: authState.user!, isHindi: isHindi) : const _GuestCard(),
                  const SizedBox(height: 24),

                  // --------------------------------------------------- Language
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.translate, color: AppColors.maroon),
                      title: Text(context.tr('language')),
                      subtitle: Text(context.tr('languageSubtitle')),
                      trailing: const LanguageToggle(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ----------------------------------------------- Edit profile
                  if (signedIn) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.edit_outlined, color: AppColors.maroon),
                        title: Text(context.tr('editProfile')),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.gold),
                        onTap: () => _showEditSheet(context, ref),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // --------------------------------------------------- Complaint
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.report_problem_outlined, color: AppColors.maroon),
                      title: Text(context.tr('complain')),
                      subtitle: Text(context.tr('complainSubtitle')),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.gold),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ComplaintScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --------------------------------------------------- Complaint History
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history, color: AppColors.maroon),
                      title: Text(context.tr('myComplaints')),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.gold),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ComplaintHistoryScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // -------------------------------------------------- About app
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Version 1.0.0',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static IconData _socialIcon(String key) {
    switch (key) {
      case 'YouTube': return Icons.play_circle_outline;
      case 'Facebook': return Icons.facebook;
      case 'Instagram': return Icons.camera_alt_outlined;
      case 'X (Twitter)': return Icons.alternate_email;
      default: return Icons.language;
    }
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('comingSoon'))));
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(dialogContext.tr('logout')),
        content: Text(dialogContext.tr('logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.tr('logout'), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authProvider.notifier).signOut();
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.read(authProvider).user;
    final name = TextEditingController(text: user?.name ?? '');
    final phone = TextEditingController(text: user?.phone ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(22, 22, 22, MediaQuery.of(sheetContext).viewInsets.bottom + 22),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(sheetContext.tr('editProfile'), style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 18),
              AppTextField(
                controller: name,
                label: sheetContext.tr('fullName'),
                prefixIcon: Icons.person_outline,
                validator: (v) => Validators.name(sheetContext, v),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: phone,
                label: sheetContext.tr('phone'),
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.phone(sheetContext, v),
              ),
              const SizedBox(height: 20),
              GoldButton(
                label: sheetContext.tr('save'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await authNotifier.updateProfile(name: name.text, phone: phone.text);
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(sheetContext.tr('profileUpdated'))));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.isHindi});
  final AppUser user;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.maroonGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.goldGradient),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name.characters.first.toUpperCase() : 'ॐ',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.maroonDark),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.onDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (user.email.isNotEmpty)
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onDark.withValues(alpha: 0.85)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (user.phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: AppColors.goldLight),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            user.phone,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onDark.withValues(alpha: 0.85)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  '${context.tr('memberSince')}: ${DateFormat.yMMM(isHindi ? 'hi' : 'en').format(user.createdAt)}',
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.maroonGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const OmEmblem(size: 56, onDark: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('guest'), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.goldLight)),
                    const SizedBox(height: 4),
                    Text(context.tr('guestPrompt'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onDark.withValues(alpha: 0.9))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GoldButton(
            label: context.tr('login'),
            icon: Icons.login,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen(inAppFlow: true))),
          ),
        ],
      ),
    );
  }
}
