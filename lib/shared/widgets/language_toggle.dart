import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isHindi = locale.languageCode == 'hi';

    Widget chip(String label, bool selected) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.goldGradient : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.maroonDark
                  : Colors.white, // Always white text on the dark toggle bg
            ),
          ),
        );

    return Semantics(
      button: true,
      label: 'Change language / भाषा बदलें',
      child: GestureDetector(
        onTap: () => ref.read(localeProvider.notifier).toggle(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                // Semi-transparent dark background so it works everywhere
                color: Colors.black.withValues(alpha: 0.4), 
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  chip('हिं', isHindi),
                  chip('EN', !isHindi),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
