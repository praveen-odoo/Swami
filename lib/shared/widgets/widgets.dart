import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Image widget that works for BOTH local assets and network URLs.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  bool get _isAsset => url.startsWith('assets/');
  bool get _isBase64 => url.length > 50 && !url.contains('/') && !url.contains('.');

  @override
  Widget build(BuildContext context) {
    final Widget image;

    if (_isAsset) {
      image = Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stack) {
          debugPrint('Asset load error ($url): $error');
          return Container(
            width: width,
            height: height,
            color: AppColors.sandalwood,
            child: const Icon(Icons.image_not_supported_outlined,
                color: AppColors.gold, size: 36),
          );
        },
      );
    } else if (_isBase64) {
      image = Image.memory(
        base64Decode(url),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stack) {
          debugPrint('Base64 decode error: $error');
          return Container(
            width: width,
            height: height,
            color: AppColors.sandalwood,
            child: const Icon(Icons.image_not_supported_outlined,
                color: AppColors.gold, size: 36),
          );
        },
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, _) => Container(
          width: width,
          height: height,
          color: AppColors.sandalwood,
          child: const Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: AppColors.gold),
            ),
          ),
        ),
        errorWidget: (context, failedUrl, error) {
          debugPrint('Image load error ($failedUrl): $error');
          return Container(
            width: width,
            height: height,
            color: AppColors.sandalwood,
            child: const Icon(Icons.image_not_supported_outlined,
                color: AppColors.gold, size: 36),
          );
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

/// Primary call-to-action with a gold gradient — the app's signature button.
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.maroonDark,
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: AppColors.maroonDark),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                ],
              ),
      ),
    );
  }
}

/// Labelled text field used across all forms (auth, donation, profile).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.textInputAction = TextInputAction.next,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputAction textInputAction;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      maxLength: maxLength,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: AppColors.gold),
        suffixIcon: suffix,
      ),
    );
  }
}

/// Section title with a small gold rule and an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 12, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// "ॐ" monogram inside a gold ring — used on splash & auth headers.
class OmEmblem extends StatelessWidget {
  const OmEmblem({super.key, this.size = 84, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: onDark ? null : AppColors.maroonGradient,
        color: onDark ? Colors.white.withValues(alpha: 0.08) : null,
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.35),
            blurRadius: 22,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'ॐ',
          style: TextStyle(
            fontSize: size * 0.45,
            color: AppColors.goldLight,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}
