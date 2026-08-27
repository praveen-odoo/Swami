import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

enum AuthResult { ok, invalidCredentials, userNotFound, emailExists, emailNotFound, error, invalidOtp }

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
    this.isSubscriber = false,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime createdAt;
  final bool isSubscriber;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': createdAt.toIso8601String(),
        'isSubscriber': isSubscriber,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) {
    // Robust name detection for various API structures (Odoo, Custom, etc.)
    String? name = j['name']?.toString() ?? 
                  j['display_name']?.toString() ?? 
                  j['full_name']?.toString() ?? 
                  j['name_hi']?.toString() ?? 
                  j['name_en']?.toString();
    
    // If still null or empty, use 'Guest' as fallback (UI can further fallback to phone)
    if (name == null || name.trim().isEmpty) {
      name = 'Guest';
    }

    final isSub = j['is_subscriber'] == true || 
                  j['subscriber'] == true || 
                  j['isSubscriber'] == true ||
                  j['is_subscriber'] == 1 ||
                  j['subscriber'] == 1 ||
                  j['is_subscription'] == true ||
                  j['is_subscription'] == 1;

    return AppUser(
        id: (j['id'] ?? j['uid'] ?? j['email'] ?? 'guest').toString(),
        name: name,
        email: j['email'] as String? ?? j['contact_email'] as String? ?? '',
        phone: j['mobile'] as String? ?? j['phone'] as String? ?? j['contact_phone'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        isSubscriber: isSub,
      );
  }

  AppUser copyWith({String? name, String? phone, bool? isSubscriber}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        createdAt: createdAt,
        isSubscriber: isSubscriber ?? this.isSubscriber,
      );
}

class AuthService {
  final ApiService _api;
  AuthService(this._api);

  static const _boxName = 'auth_box_v4';
  static const _sessionKey = 'active_user_id';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<AuthResult> login(String mobile, String password, {String? name}) async {
    try {
      debugPrint('🚀 [AuthService] Login Request for: $mobile');
      final response = await _api.post('/auth/login', body: {
        'mobile': mobile,
        'password': password,
        if (name != null && name.isNotEmpty) 'name': name,
      }, authenticated: false);
      debugPrint('📥 [AuthService] Login Response: $response');

      if (response != null && response['data'] != null) {
        final data = response['data'];
        final token = data['token'] as String?;
        if (token != null) {
          await _api.setToken(token);
          
          // If name is provided and not in the response, we might want to store it later
          // or pass it to fetchAndStoreUser if possible. 
          // For now, fetchAndStoreUser will get the official name from Odoo.
          return await fetchAndStoreUser();
        }
      }
      return AuthResult.invalidCredentials;
    } catch (e) {
      debugPrint('Login Error: $e');
      return AuthResult.error;
    }
  }

  Future<bool> checkUserStatus(String mobile, {Function(String, bool)? onUserFound}) async {
    try {
      debugPrint('🔍 [AuthService] Checking registration for: $mobile');
      
      // Try POST with is_subscriber=true (Reverted back to is_subscriber for filtering support)
      dynamic res;
      try {
        res = await _api.post('/home', body: {'is_subscriber': true}, authenticated: false);
      } catch (e) {
        debugPrint('⚠️ [AuthService] POST /home (true) failed, trying GET fallback...');
        res = await _api.get('/home?is_subscriber=true', authenticated: false);
      }
      
      if (res != null && res['data'] != null && res['data'] is Map) {
        final d = res['data'] as Map<String, dynamic>;
        final profile = d['profile'] as Map<String, dynamic>?;

        // 1. Check if the mobile belongs to Swami Ji (main profile)
        if (profile != null) {
          final profileMobile = (profile['contact_phone'] ?? profile['mobile'] ?? '').toString().trim();
          final targetMobile = mobile.trim();
          
          debugPrint('🔍 [AuthService] Checking Swami Ji profile: "$profileMobile" vs "$targetMobile"');
          
          if (profileMobile == targetMobile || 
              profileMobile.endsWith(targetMobile) || 
              targetMobile.endsWith(profileMobile)) {
            final foundName = (profile['name'] ?? profile['politician'] ?? '').toString();
            debugPrint('🎯 [AuthService] User identified as Swami Ji: $foundName');
            if (onUserFound != null) onUserFound(foundName, true); 
            return true;
          }
        }

        // 2. Check member_records
        final memberRecords = profile?['member_records'];
        if (memberRecords is Map) {
          debugPrint('🔍 [AuthService] Scanning ${memberRecords.length} member records...');
          for (var id in memberRecords.keys) {
            final info = memberRecords[id];
            if (info is Map) {
              final storedMobile = (info['mobile'] ?? info['phone'] ?? '').toString().trim();
              final targetMobile = mobile.trim();
              
              if (storedMobile == targetMobile || 
                  storedMobile.endsWith(targetMobile) || 
                  targetMobile.endsWith(storedMobile)) {
                final foundName = (info['name'] ?? '').toString();
                final isSub = info['is_subscriber'] == true || 
                             info['subscriber'] == true || 
                             info['is_subscriber'] == 1 ||
                             info['subscriber'] == 1 ||
                             info['is_subscription'] == true ||
                             info['is_subscription'] == 1;
                
                debugPrint('🎯 [AuthService] Match found in records! Name: $foundName');
                if (onUserFound != null) onUserFound(foundName, isSub);
                return true;
              }
            }
          }
        }
      }

      // If not found in subscribers, try non-subscribers (Reverted to is_subscriber=false)
      dynamic resNon;
      try {
        resNon = await _api.post('/home', body: {'is_subscriber': false}, authenticated: false);
      } catch (e) {
        debugPrint('⚠️ [AuthService] POST /home (false) failed, trying GET fallback...');
        resNon = await _api.get('/home?is_subscriber=false', authenticated: false);
      }

      if (resNon != null && resNon['data'] != null && resNon['data'] is Map) {
         final profileNon = (resNon['data'] as Map)['profile'];
         final memberRecords = profileNon?['member_records'];
         if (memberRecords is Map) {
           debugPrint('🔍 [AuthService] Scanning ${memberRecords.length} non-subscriber records...');
           for (var info in memberRecords.values) {
             if (info is Map) {
               final storedMobile = (info['mobile'] ?? info['phone'] ?? '').toString().trim();
               final targetMobile = mobile.trim();
               
               if (storedMobile == targetMobile || 
                   storedMobile.endsWith(targetMobile) || 
                   targetMobile.endsWith(storedMobile)) {
                 final foundName = (info['name'] ?? '').toString();
                 debugPrint('🎯 [AuthService] Match found in non-subscribers! Name: $foundName');
                 if (onUserFound != null) onUserFound(foundName, false);
                 return true;
               }
             }
           }
         }
      }

    } catch (e) {
      debugPrint('⚠️ [AuthService] checkUserStatus failed: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>> requestOtp(String mobile, {String? name, bool? isSubscriber}) async {
    try {
      final requestBody = {
        'mobile': mobile,
        if (name != null && name.isNotEmpty) 'name': name,
        if (isSubscriber != null) 'is_subscriber': isSubscriber,
      };

      debugPrint('🚀 [AuthService] Requesting OTP: $requestBody');

      final response = await _api.post('/auth/request-otp', body: requestBody, authenticated: false);
      
      debugPrint('📥 [AuthService] OTP Response: $response');

      if (response != null && response['success'] == true) {
        // Handle response with 'message' and 'is_subscription'
        final message = response['message'] as String? ?? '';
        final isSub = response['is_subscription'] == true || response['is_subscription'] == 1;
        
        // Extract OTP from message for auto-fill convenience (if present)
        final otpMatch = RegExp(r'\d{6}').firstMatch(message);
        if (otpMatch != null) {
          final otp = otpMatch.group(0);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_otp_$mobile', otp!);
        }
        return {'result': AuthResult.ok, 'isSubscriber': isSub};
      }
      return {'result': AuthResult.error, 'isSubscriber': false};
    } catch (e) {
      debugPrint('Request OTP Error: $e');
      return {'result': AuthResult.error, 'isSubscriber': false};
    }
  }

  Future<AuthResult> verifyOtp(String mobile, String otp, {String? name, bool? subscriber}) async {
    try {
      final requestBody = {
        'mobile': mobile,
        'otp': otp,
        if (name != null && name.isNotEmpty) 'name': name,
        if (subscriber != null) 'subscriber': subscriber,
      };
      
      debugPrint('🚀 [AuthService] Verifying OTP: $requestBody');
      
      final response = await _api.post('/auth/verify-otp', body: requestBody, authenticated: false);

      debugPrint('📥 [AuthService] Verify Response: $response');

      if (response != null && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        
        // Token might be at the top level or inside 'data'
        final token = (response['token'] ?? data?['token']) as String?;
        if (token != null) {
          await _api.setToken(token);
        }

        // If member info is in data.member (as per your Postman response)
        if (data != null && data['member'] != null) {
          final member = data['member'] as Map<String, dynamic>;
          final serverName = member['name']?.toString() ?? '';
          
          debugPrint('🎯 [AuthService] Server returned member: $serverName');
          
          final user = AppUser(
            id: member['id'].toString(),
            name: (serverName.trim().isNotEmpty && serverName != 'Guest') ? serverName : (name ?? mobile),
            email: (member['email'] ?? '').toString(),
            phone: (member['mobile'] ?? member['phone'] ?? mobile).toString(),
            createdAt: DateTime.now(),
            isSubscriber: member['is_subscriber'] == true || 
                          member['subscriber'] == true || 
                          member['is_subscriber'] == 1 ||
                          member['is_subscription'] == true ||
                          member['is_subscription'] == 1 ||
                          (subscriber ?? false),
          );
          
          final box = await _getBox();
          await box.put('profile', jsonEncode(user.toJson()));
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_sessionKey, user.id);
          
          return AuthResult.ok;
        }

        // If 'member' object is missing but we have a successful login, fetch full profile
        debugPrint('⚠️ [AuthService] Member data missing in response, fetching full profile...');
        return await fetchAndStoreUser();
      }
      return AuthResult.invalidCredentials;
    } catch (e) {
      debugPrint('🚨 [AuthService] Verify OTP Error: $e');
      return AuthResult.error;
    }
  }

  Future<AuthResult> fetchAndStoreUser() async {
    try {
      debugPrint('🚀 [AuthService] Fetching profile (/me)...');
      final response = await _api.get('/me', authenticated: true);
      debugPrint('📥 [AuthService] Profile Response: $response');
      if (response != null && response['data'] != null) {
        final userData = response['data'] as Map<String, dynamic>;
        final user = AppUser.fromJson(userData);
        
        final box = await _getBox();
        await box.put('profile', jsonEncode(user.toJson()));
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionKey, user.id);
        
        return AuthResult.ok;
      }
      return AuthResult.userNotFound;
    } catch (e) {
      debugPrint('Fetch User Error: $e');
      return AuthResult.error;
    }
  }

  Future<void> updateProfile(AppUser user) async {
    // Note: API might not have a direct profile update yet, but we store it locally
    final box = await _getBox();
    await box.put('profile', jsonEncode(user.toJson()));
  }

  Future<AppUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_sessionKey);
    if (id == null) return null;
    
    final box = await _getBox();
    final raw = box.get('profile');
    if (raw == null) return null;
    
    return AppUser.fromJson(jsonDecode(raw as String));
  }

  Future<void> signOut() async {
    await _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove('auth_token'); // Ensure it's gone from all possible keys
    final box = await _getBox();
    await box.clear(); // Clear all user profile data
  }

  Future<AuthResult> signInOrSignUp({
    required String email, 
    required String password,
    String? name,
    String? phone,
    bool? subscriber,
  }) async {
    final requestBody = {
      'mobile': email,
      'password': password,
      if (name != null && name.isNotEmpty) 'name': name,
      if (subscriber != null) 'subscriber': subscriber,
    };
    debugPrint('📤 [AuthService] signInOrSignUp Request: $requestBody');
    return login(email, password, name: name);
  }

  Future<AuthResult> resetPassword({required String email, required String newPassword}) async => AuthResult.ok;
}
