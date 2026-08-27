import 'package:flutter/foundation.dart';
import '../models/api_models.dart';
import 'api_service.dart';

class HomeService {
  final ApiService _api;
  HomeService(this._api);

  Future<ApiHomeData> fetchHomeData() async {
    try {
      final response = await _api.get('/home', authenticated: false);
      if (response != null) {
        return ApiHomeData.fromJson(response);
      }
      return ApiHomeData();
    } catch (e) {
      debugPrint('🚨 [HomeService] Failed to fetch home data: $e');
      rethrow;
    }
  }

  // The 'thaughts' are now part of ApiHomeData
  
  Future<Map<String, dynamic>> registerComplaint(Map<String, dynamic> data) async {
    final response = await _api.post('/complain', body: data, authenticated: false);
    return response ?? {};
  }
  
  Future<Map<String, dynamic>> recordDonation(Map<String, dynamic> data) async {
    final response = await _api.post('/donate', body: data, authenticated: false);
    return response ?? {};
  }

  Future<List<dynamic>> fetchMeetings() async {
    final response = await _api.get('/meetings', authenticated: true);
    if (response != null && response['data'] is List) {
      return response['data'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> joinMeeting(int meetingId) async {
    final response = await _api.post('/meetings/join', body: {'meeting_id': meetingId}, authenticated: true);
    return response ?? {};
  }
}
