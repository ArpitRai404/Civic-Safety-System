import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/user_location.dart';

class ApiService {
  static const String baseUrl = 'http://10.73.83.141:8000';


  static Future<bool> updateLocation({
    required String userId,
    required double lat,
    required double lon,
    String? fcmToken,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'user_id': userId,
        'lat': lat,
        'lon': lon,
      };
      
  
      if (fcmToken != null && fcmToken.isNotEmpty) {
        requestBody['fcm_token'] = fcmToken;
        log('📡 Sending location with FCM token');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/location/update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      log('📍 Update location - Status: ${response.statusCode}, Body: ${response.body}');
      
      if (response.statusCode == 200) {
        log('✅ Location updated successfully');
        return true;
      } else {
        log('❌ Location update failed: ${response.body}');
        return false;
      }
    } catch (e) {
      log('❌ Network error updating location: $e');
      log('💡 Tip: Make sure:');
      log('   1. Backend server is running');
      log('   2. IP address is correct: $baseUrl');
      log('   3. Device is on same network');
      return false;
    }
  }


  static Future<UserLocation?> getLocation(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/$userId'),
        headers: {'Accept': 'application/json'},
      );
      
      log('📍 Get location - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('error')) {
          log('⚠️ User not found: ${data['error']}');
          return null;
        }
        return UserLocation(
          id: userId,
          lat: (data['lat'] as num).toDouble(),
          lon: (data['lon'] as num).toDouble(),
        );
      }
      return null;
    } catch (e) {
      log('❌ Error getting location: $e');
      return null;
    }
  }


  static Future<List<UserLocation>> getNearbyUsers(
    String userId, {
    double radius = 1.5,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/nearby/$userId?radius=$radius'),
        headers: {'Accept': 'application/json'},
      );
      
      log('👥 Nearby users - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        log('✅ Found ${data.length} nearby users');
        return data.map((e) => UserLocation.fromJson(e)).toList();
      }
      log('⚠️ No nearby users found');
      return [];
    } catch (e) {
      log('❌ Error getting nearby users: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> triggerEmergency(String userId) async {
    try {
      log('🚨 Triggering emergency for user: $userId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/emergency/$userId'),
        headers: {'Accept': 'application/json'},
      );
      
      log('🚨 Emergency response - Status: ${response.statusCode}, Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('✅ Emergency triggered successfully');
        log('   Notified users: ${data['notified_users']?.length ?? 0}');
        log('   Count: ${data['count']}');
        
        return {
          'message': data['message'] ?? 'Emergency triggered',
          'notified_users': List<String>.from(data['notified_users'] ?? []),
          'count': data['count'] ?? 0,
        };
      } else {
        final errorData = jsonDecode(response.body);
        log('❌ Emergency failed: ${errorData['error'] ?? 'Unknown error'}');
        return {
          'error': errorData['error'] ?? 'Failed to trigger emergency'
        };
      }
    } catch (e) {
      log('❌ Network error triggering emergency: $e');
      return {
        'error': 'Network error: $e'
      };
    }
  }


  static Future<Map<String, dynamic>?> testNotification(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test/notify/$userId'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      log('Test notification error: $e');
      return null;
    }
  }

}
