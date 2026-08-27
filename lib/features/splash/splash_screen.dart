import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/pravachan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../shell/main_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4000))
    ..forward();

  late final AnimationController _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..forward();

  bool _isInitCalled = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (_isInitCalled) return;
    _isInitCalled = true;

    try {
      await ref.read(localeProvider.notifier).load();
      await ref.read(authProvider.notifier).bootstrap();
      // Load Home data separately to ensure it doesn't block shell navigation if it fails,
      // but also ensure it's called after providers are ready.
      await Future.wait<void>([
        ref.read(homeProvider.notifier).load(),
        ref.read(pravachanProvider.notifier).load(),
      ]).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Splash Init Error/Timeout: $e');
    }
    
    if (mounted) {
      _go();
    }
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Jaisa aapne kaha: Seedha Home (MainShell) par jaao, Login screen mat dikhaao.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 550),
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    final zoom = Tween<double>(begin: 1.0, end: 1.10)
        .animate(CurvedAnimation(parent: _bgController, curve: Curves.easeOut));

    return Scaffold(
      backgroundColor: AppColors.maroonDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScaleTransition(
            scale: zoom,
            child: Image.asset(
              'assets/images/swami.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.maroonGradient),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  AppColors.maroonDark.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.maroonDark.withValues(alpha: 0.82),
                  AppColors.maroonDark,
                ],
                stops: const [0.30, 0.72, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: FadeTransition(
                opacity: fade,
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Column(
                    children: [_omBadge()],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: FadeTransition(
                opacity: fade,
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(28, 0, 28, 46),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 54,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                        FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          context.tr('appName'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('tagline'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                          color: AppColors.onDark.withValues(alpha: 0.92),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('namaste'),
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(
                              AppColors.goldLight),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _omBadge() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.maroonDark.withValues(alpha: 0.35),
        border: Border.all(color: AppColors.gold, width: 1.6),
        boxShadow: [
          BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 16),
        ],
      ),
      child: const Center(
        child: Text(
          'ॐ',
          style: TextStyle(
            fontSize: 28,
            color: AppColors.goldLight,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}
