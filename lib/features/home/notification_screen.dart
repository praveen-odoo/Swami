import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/providers/home_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final notifications = homeState.data?.notifications ?? [];
    final isHindi = context.isHindi;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(context.tr('notifications')),
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.sandalwood),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('noChats'), // Reuse or add noNotifications
                    style: const TextStyle(color: AppColors.maroon, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: notifications.length,
              itemBuilder: (context, i) {
                final n = notifications[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.image != null)
                          AppNetworkImage(url: n.image!, height: 180, width: double.infinity),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.maroon.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.notifications_active, color: AppColors.maroon, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      n.getName(isHindi),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroon, fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                n.getTitle(isHindi),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                n.getDescription(isHindi),
                                style: TextStyle(color: Colors.black.withValues(alpha: 0.7), height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
