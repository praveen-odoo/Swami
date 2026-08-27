import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../core/localization/app_localizations.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/widgets.dart';

class ComplaintScreen extends ConsumerStatefulWidget {
  const ComplaintScreen({super.key});

  @override
  ConsumerState<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends ConsumerState<ComplaintScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isBusy = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);
    try {
      final authState = ref.read(authProvider);
      final signedIn = authState.status == AuthStatus.signedIn;
      final user = authState.user;

      final data = {
        'subject': _titleController.text.trim(),
        'description': _descController.text.trim(),
        if (signedIn) ...{
          'name': user?.name,
          'mobile': user?.phone,
          'user_id': user?.id,
        } else ...{
          'name': _nameController.text.trim(),
          'mobile': _mobileController.text.trim(),
        }
      };
      
      final response = await ref.read(homeServiceProvider).registerComplaint(data);
      
      if (!mounted) return;
      
      // The API returns reference in response['data']['reference']
      final String? refNum = response['data']?['reference']?.toString() ?? 
                            response['reference']?.toString() ??
                            response['data']?['reference_number']?.toString();
      
      if (refNum != null) {
        _saveComplaintLocally(refNum, _titleController.text.trim());
        _showSuccessDialog(refNum);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('complainSuccess'))),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showSuccessDialog(String refNum) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ctx.tr('complainSuccess'),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctx.tr('complainSuccessGuest')),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Text(ctx.tr('complainRef'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: SelectableText(
                          refNum,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.maroon),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20, color: AppColors.gold),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: refNum));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Reference number copied'), duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          GoldButton(
            label: ctx.tr('save'), // Using existing 'save' or could add 'OK'
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveComplaintLocally(String ref, String title) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? existing = prefs.getString('local_complaints');
      List<dynamic> list = existing != null ? jsonDecode(existing) : [];
      
      list.insert(0, {
        'ref': ref,
        'title': title,
        'date': DateTime.now().toIso8601String(),
      });
      
      // Keep only last 20
      if (list.length > 20) list = list.sublist(0, 20);
      
      await prefs.setString('local_complaints', jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving complaint locally: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(authProvider).status == AuthStatus.signedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('complain')),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.tr('complainSubtitle'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.maroon),
                        ),
                        const SizedBox(height: 24),
                        
                        if (!signedIn) ...[
                          AppTextField(
                            controller: _nameController,
                            label: context.tr('guestName'),
                            prefixIcon: Icons.person_outline,
                            validator: (v) => Validators.name(context, v),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _mobileController,
                            label: context.tr('guestMobile'),
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            validator: (v) => Validators.phone(context, v),
                          ),
                          const SizedBox(height: 16),
                        ],

                        AppTextField(
                          controller: _titleController,
                          label: context.tr('complainTitle'),
                          prefixIcon: Icons.subject,
                          validator: (v) => (v == null || v.isEmpty) ? context.tr('requiredField') : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          maxLines: 6,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: context.tr('complainDescription'),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: AppColors.ivory,
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? context.tr('requiredField') : null,
                        ),
                        const Spacer(),
                        const SizedBox(height: 32),
                        GoldButton(
                          label: context.tr('complainSubmit'),
                          onPressed: _submit,
                          busy: _isBusy,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
