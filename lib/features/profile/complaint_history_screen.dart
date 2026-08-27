import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';

class ComplaintHistoryScreen extends StatefulWidget {
  const ComplaintHistoryScreen({super.key});

  @override
  State<ComplaintHistoryScreen> createState() => _ComplaintHistoryScreenState();
}

class _ComplaintHistoryScreenState extends State<ComplaintHistoryScreen> {
  List<dynamic> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('local_complaints');
    if (data != null) {
      setState(() {
        _complaints = jsonDecode(data);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('myComplaints')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_outlined, size: 64, color: AppColors.sandalwood),
                      const SizedBox(height: 16),
                      Text(context.tr('noComplaints'), style: const TextStyle(color: AppColors.maroon)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _complaints.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = _complaints[i];
                    final date = DateTime.tryParse(c['date'] ?? '') ?? DateTime.now();
                    final formattedDate = DateFormat.yMMMd(context.isHindi ? 'hi' : 'en').add_jm().format(date);

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          c['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroon),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('${context.tr('complainRef')}: ', style: const TextStyle(fontSize: 12)),
                                Text(
                                  c['ref'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16, color: AppColors.gold),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: c['ref']));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
