import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import 'widgets.dart';

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;

  const NetworkErrorWidget({
    super.key,
    required this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.maroon.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: AppColors.maroon,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('networkErrorTitle') ?? 'No Internet Connection',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.maroon,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? context.tr('networkErrorSubtitle') ?? 'Please check your connection and try again.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GoldButton(
              label: context.tr('retry') ?? 'Try Again',
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
