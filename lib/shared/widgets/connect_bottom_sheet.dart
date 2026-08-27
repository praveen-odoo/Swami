import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/data/sample_data.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/api_models.dart';
import '../../core/theme/app_colors.dart';

void showConnectBottomSheet(BuildContext context, ApiProfile? profile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ConnectBottomSheet(profile: profile),
  );
}

class ConnectBottomSheet extends StatelessWidget {
  const ConnectBottomSheet({super.key, this.profile});
  final ApiProfile? profile;

  Future<void> _launchUrl(String? urlString, String fallback) async {
    final url = Uri.parse(urlString ?? fallback);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) {
      _launchUrl(null, SampleData.whatsappUrl);
      return;
    }
    
    // 1. Clean the phone number (remove everything except digits)
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // 2. Handle missing country code
    // If it's a 10-digit number, it's likely an Indian number without +91
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    } 
    // If it starts with 0 (Indian local format), replace 0 with 91
    else if (cleanPhone.length == 11 && cleanPhone.startsWith('0')) {
      cleanPhone = '91${cleanPhone.substring(1)}';
    }

    final url = Uri.parse('https://wa.me/$cleanPhone');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr('connect'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.maroon,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _SocialItem(
                icon: Icons.facebook,
                label: context.tr('facebook'),
                color: const Color(0xFF1877F2),
                onTap: () => _launchUrl(profile?.facebook, SampleData.facebookUrl),
              ),
              _SocialItem(
                icon: Icons.play_circle_filled,
                label: context.tr('youtube'),
                color: const Color(0xFFFF0000),
                onTap: () => _launchUrl(profile?.youtube, SampleData.youtubeUrl),
              ),
              _SocialItem(
                icon: Icons.language,
                label: context.tr('website'),
                color: AppColors.gold,
                onTap: () => _launchUrl(profile?.website, profile?.website ?? 'https://swamianandswaroop.com'),
              ),
              _SocialItem(
                icon: Icons.camera_alt,
                label: context.tr('instagram'),
                color: const Color(0xFFE4405F),
                onTap: () => _launchUrl(profile?.instagram, SampleData.instagramUrl),
              ),
              _SocialItem(
                icon: Icons.close,
                label: context.tr('twitter'),
                color: Colors.black,
                onTap: () => _launchUrl(profile?.twitter, SampleData.twitterUrl),
              ),
              _SocialItem(
                icon: Icons.chat,
                label: context.tr('whatsapp'),
                color: const Color(0xFF25D366),
                onTap: () => _launchWhatsApp(profile?.whatsapp ?? profile?.phone),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SocialItem extends StatelessWidget {
  const _SocialItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
