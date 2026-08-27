import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/language_toggle.dart';
import '../../shared/widgets/widgets.dart';
import '../shell/main_shell.dart';
import 'forgot_password_screen.dart';
import '../../core/data/sample_data.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.inAppFlow = false});

  final bool inAppFlow;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  
  bool _obscure = true;
  bool _useOtp = true; // Default to OTP login
  bool _otpSent = false;
  bool _isRegistered = false;
  bool _checkingStatus = false;
  bool _isSubscriber = false;

  @override
  void initState() {
    super.initState();
    _mobile.addListener(_onMobileChanged);
  }

  void _onMobileChanged() {
    final text = _mobile.text.trim();
    if (text.length == 10) {
      _checkUserStatus(text);
    } else {
      if (_isRegistered) {
        setState(() {
          _isRegistered = false;
          _isSubscriber = false;
        });
      }
    }
  }

  Future<void> _checkUserStatus(String mobile) async {
    if (_checkingStatus) return;
    setState(() => _checkingStatus = true);
    
    final exists = await ref.read(authProvider.notifier).checkUserStatus(
      mobile,
      onUserFound: (foundName, isSub) {
        if (mounted) {
          setState(() {
            _isSubscriber = isSub;
            if (foundName.isNotEmpty && foundName != 'Guest') {
              _name.text = foundName;
            }
          });
        }
      },
    );
    
    if (mounted) {
      setState(() {
        _isRegistered = exists;
        _checkingStatus = false;
      });
    }
  }

  @override
  void dispose() {
    _mobile.removeListener(_onMobileChanged);
    _name.dispose();
    _mobile.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _enterApp() {
    if (widget.inAppFlow && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
    }
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    final mobileStr = _mobile.text.trim();
    final nameStr = _name.text.trim();
    debugPrint('🔑 [LoginScreen] Requesting OTP for: Name="$nameStr", Mobile="$mobileStr"');
    
    final response = await ref.read(authProvider.notifier).requestOtp(
      mobileStr,
      name: nameStr,
      isSubscriber: _isSubscriber, // Passing the status found during /home check
    );
    
    final result = response['result'] as AuthResult;
    final isSub = response['isSubscriber'] as bool? ?? false;

    // In Flutter, form validation messages don't always update instantly 
    // when language changes unless build is triggered.
    // By calling setState here, we ensure localized messages are picked up.
    if (!mounted) return;
    
    if (result == AuthResult.ok) {
      setState(() {
        _otpSent = true;
        _isSubscriber = isSub; // Sync with what the server says
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP Sent to your mobile')));
      
      // Auto-fill logic from local storage (demo/convenience)
      final prefs = await SharedPreferences.getInstance();
      final lastOtp = prefs.getString('last_otp_$mobileStr');
      if (lastOtp != null) {
        setState(() => _otp.text = lastOtp);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP. Try again.')));
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final String nameInput = _name.text.trim();
    final String mobileInput = _mobile.text.trim();
    debugPrint('🔑 [LoginScreen] Submitting: Name="$nameInput", Mobile="$mobileInput", UseOTP=$_useOtp');

    final AuthResult result;
    if (_useOtp) {
      if (!_otpSent) {
        await _requestOtp();
        return;
      }
      debugPrint('🔑 [LoginScreen] Verifying OTP with name: $nameInput, subscriber: $_isSubscriber');
      result = await ref.read(authProvider.notifier).verifyOtp(
        mobileInput,
        _otp.text.trim(),
        name: nameInput,
        subscriber: _isSubscriber,
      );
    } else {
      debugPrint('🔑 [LoginScreen] Logging in with password for: $nameInput, subscriber: $_isSubscriber');
      result = await ref.read(authProvider.notifier).signInOrSignUp(
        email: mobileInput, // Parameter name is email but we pass mobile
        password: _password.text,
        name: nameInput,
        subscriber: _isSubscriber,
      );
    }

    if (!mounted) return;
    if (result == AuthResult.ok) {
      _enterApp();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('invalidCredentials'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authProvider).busy;

    return Scaffold(
      backgroundColor: AppColors.maroonDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: const AppNetworkImage(
              url: SampleData.portrait,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    AppColors.maroonDark.withValues(alpha: 0.75),
                    AppColors.maroonDark,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: const LanguageToggle(onDark: true),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    const OmEmblem(size: 80, onDark: true),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('appName'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 30),
                    
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildField(
                                  controller: _name,
                                  label: context.tr('fullName'),
                                  icon: Icons.person_outline,
                                  validator: (v) => Validators.name(context, v),
                                  enabled: !_otpSent,
                                ),
                                const SizedBox(height: 16),
                                if (_isRegistered && !_otpSent) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.verified_user_outlined, color: AppColors.gold, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Found: ${_name.text}\nWelcome back! Proceed with OTP.',
                                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                _buildField(
                                  controller: _mobile,
                                  label: context.tr('phone'),
                                  icon: Icons.phone_android_outlined,
                                  type: TextInputType.phone,
                                  maxLength: 10,
                                  validator: (v) => Validators.phone(context, v),
                                  enabled: !_otpSent,
                                  suffix: _checkingStatus 
                                    ? const SizedBox(
                                        width: 20, 
                                        height: 20, 
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                                        )
                                      )
                                    : null,
                                ),
                                const SizedBox(height: 16),
                                if (_otpSent) ...[
                                  _buildField(
                                    controller: _otp,
                                    label: 'Enter OTP',
                                    icon: Icons.onetwothree_outlined,
                                    type: TextInputType.number,
                                    action: TextInputAction.done,
                                    validator: (v) => Validators.required(context, v),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                
                                GoldButton(
                                  label: _otpSent ? context.tr('login') : 'Request OTP',
                                  busy: busy,
                                  onPressed: _submit,
                                ),
                                
                                if (_otpSent) ...[
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => setState(() => _otpSent = false),
                                    child: const Text('Change Number', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: _enterAsGuest,
                      icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white70),
                      label: Text(
                        context.tr('continueAsGuest'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? type,
    TextInputAction? action,
    bool enabled = true,
    int? maxLength,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      enabled: enabled,
      maxLength: maxLength,
      textInputAction: action ?? TextInputAction.next,
      validator: validator,
      style: TextStyle(color: enabled ? Colors.white : Colors.white54),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: AppColors.goldLight, size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
    );
  }

  void _enterAsGuest() {
    if (widget.inAppFlow && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(false);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
    }
  }
}
