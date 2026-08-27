import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/api_models.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

class NotificationDetailScreen extends StatelessWidget {
  final ApiNotification notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final isHindi = context.isHindi;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(notification.getName(isHindi).isNotEmpty ? notification.getName(isHindi) : 'Detail'),
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.image != null)
              AppNetworkImage(
                url: notification.image!,
                width: double.infinity,
                height: 250,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.getName(isHindi),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.maroon,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (notification.getTitle(isHindi).isNotEmpty)
                    Text(
                      notification.getTitle(isHindi),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.sandalwood),
                  const SizedBox(height: 16),
                  Text(
                    notification.getDescription(isHindi),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black87,
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
