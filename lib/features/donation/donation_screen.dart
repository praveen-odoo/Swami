import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/constants/payment_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/home_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/widgets.dart';

class DonationScreen extends ConsumerStatefulWidget {
  const DonationScreen({super.key});

  @override
  ConsumerState<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends ConsumerState<DonationScreen> {
  static const _presets = [101, 251, 501, 1100, 2100];

  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController(text: '501');
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  
  String _purposeKey = 'annadaan';
  bool _isLoading = false;
  bool _isAnonymous = false;

  Razorpay? _razorpay;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (mounted && user != null && !_isAnonymous) {
        _name.text = user.name;
        _email.text = user.email;
        _phone.text = user.phone;
      }
    });
  }

  void _initRazorpay() {
    try {
      final r = Razorpay();
      r.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
      r.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
      r.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
      _razorpay = r;
    } catch (e) {
      debugPrint("RAZORPAY: Initialization Error -> $e");
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _amount.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _proceed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    
    if (_razorpay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('paymentError'))));
      return;
    }

    setState(() => _isLoading = true);

    final rupees = num.tryParse(_amount.text.trim()) ?? 0;
    final paise = (rupees * 100).round();
    final user = ref.read(authProvider).user;

    // Logic for Razorpay Prefill:
    String prefillName = 'Guest Donor';
    String prefillEmail = 'seva@swamianandswaroop.com'; 
    String prefillPhone = '+919876543210'; 

    if (_isAnonymous) {
      prefillName = 'Gupt Daani';
      // Use professional-looking dummy data with +91 to bypass Razorpay's contact screen
      prefillEmail = 'seva@divyapath.org';
      prefillPhone = '+919998887770'; 
    } else {
      if (user != null) {
        prefillName = user.name;
        prefillEmail = user.email;
        prefillPhone = user.phone.startsWith('+91') ? user.phone : '+91${user.phone}';
      } else {
        prefillName = _name.text.trim();
        prefillEmail = _email.text.trim();
        final p = _phone.text.trim();
        prefillPhone = p.startsWith('+91') ? p : '+91$p';
      }
    }

    final options = {
      'key': PaymentConfig.razorpayKeyId,
      'amount': paise,
      'name': 'Swami Anand Swaroop',
      'currency': 'INR',
      'description': 'Seva Daan',
      'prefill': {
        'name': prefillName,
        'contact': prefillPhone,
        'email': prefillEmail,
      },
      'readonly': {
        'contact': true,
        'email': true,
        'name': true,
      },
      'modal': {
        'confirm_close': true,
      },
      'theme': {'color': '#4E0D0D'},
      'send_sms_hash': true,
      'retry': {'enabled': false},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('paymentError'))));
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (mounted) setState(() => _isLoading = false);
    
    // Record donation to API
    final rupees = num.tryParse(_amount.text.trim()) ?? 0;
    final user = ref.read(authProvider).user;
    
    try {
      await ref.read(homeServiceProvider).recordDonation({
        'amount': rupees,
        'currency': 'INR',
        'donor_name': _isAnonymous ? 'Gupt Donor' : (_name.text.isEmpty ? user?.name : _name.text),
        'donor_mobile': _isAnonymous ? '' : (_phone.text.isEmpty ? user?.phone : _phone.text),
        'donor_email': _isAnonymous ? '' : (_email.text.isEmpty ? user?.email : _email.text),
        'gateway_reference': response.paymentId,
        'status': 'success',
        'note': 'Seva: $_purposeKey',
      });
    } catch (e) {
      debugPrint('Error recording donation: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text(context.tr('paymentSuccess'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("ID: ${response.paymentId}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            GoldButton(
              label: 'OK', 
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            ),
          ],
        ),
      ),
    );
  }

  void _onPaymentError(PaymentFailureResponse response) {
    // 1. Immediately hide loading to reveal the UI background
    if (mounted) setState(() => _isLoading = false);
    
    // 2. If it's just a user cancellation (Code 2), don't show any annoying error
    if (response.code == 2) {
      debugPrint("RAZORPAY: Payment cancelled. Returning to screen.");
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${context.tr('paymentFailed')}: ${response.message}"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final purposes = ['annadaan', 'gaushala', 'education', 'templeSeva'];
    final isLoggedIn = ref.watch(authProvider).status == AuthStatus.signedIn;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.ivory, // Solid background to prevent black screen
        appBar: AppBar(title: Text(context.tr('donation'))),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppColors.maroonGradient,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.volunteer_activism, color: AppColors.goldLight, size: 34),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              context.tr('donationSubtitle'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
  
                    Text(context.tr('donationPurpose'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: purposes.map((key) {
                        final selected = _purposeKey == key;
                        return ChoiceChip(
                          label: Text(context.tr(key)),
                          selected: selected,
                          selectedColor: AppColors.maroon,
                          labelStyle: TextStyle(
                              color: selected ? AppColors.onDark : AppColors.textPrimary,
                              fontWeight: FontWeight.w600),
                          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
                          onSelected: (_) => setState(() => _purposeKey = key),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
  
                    Text(context.tr('selectAmount'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _presets.map((amt) {
                        final selected = _amount.text == '$amt';
                        return ChoiceChip(
                          label: Text('₹$amt'),
                          selected: selected,
                          selectedColor: AppColors.gold,
                          labelStyle: TextStyle(
                              color: selected ? AppColors.maroonDark : AppColors.textPrimary,
                              fontWeight: FontWeight.w700),
                          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
                          onSelected: (_) => setState(() => _amount.text = '$amt'),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
  
                    AppTextField(
                      controller: _amount,
                      label: context.tr('customAmount'),
                      prefixIcon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.donationAmount(context, v),
                    ),
                    const SizedBox(height: 16),
  
                    Row(
                      children: [
                        Checkbox(
                          value: _isAnonymous,
                          activeColor: AppColors.maroon,
                          onChanged: (v) => setState(() {
                            _isAnonymous = v ?? false;
                            if (_isAnonymous) {
                              _name.clear();
                              _email.clear();
                              _phone.clear();
                            }
                          }),
                        ),
                        Text(context.tr('guptDaan'), style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
  
                    if (!_isAnonymous && !isLoggedIn) ...[
                      AppTextField(
                        controller: _name,
                        label: context.tr('fullName'),
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (v) => Validators.name(context, v),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _email,
                        label: context.tr('email'),
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) => Validators.email(context, v),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _phone,
                        label: context.tr('phone'),
                        prefixIcon: Icons.phone_android_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        validator: (v) => Validators.phone(context, v),
                      ),
                      const SizedBox(height: 28),
                    ] else ...[
                      const SizedBox(height: 28),
                    ],
  
                    GoldButton(
                      label: context.tr('proceedToPay'),
                      icon: Icons.lock_outline,
                      onPressed: _proceed,
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.gold),
                      SizedBox(height: 16),
                      Text("Securely connecting...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
