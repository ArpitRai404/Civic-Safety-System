import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  static FirebaseMessaging? _messaging;
  static String? _fcmToken;

  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      
      // Get Firebase Messaging instance
      _messaging = FirebaseMessaging.instance;
      
      // Request permission for notifications
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
      
      log('📱 Notification permission status: ${settings.authorizationStatus}');
      
      // Get FCM token
      _fcmToken = await _messaging!.getToken();
      log('✅ FCM Token obtained: ${_fcmToken?.substring(0, 20)}...');
      
      // Configure foreground message handling
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('📨 Foreground message received: ${message.notification?.title}');
        log('📦 Message data: ${message.data}');
        
        // Handle emergency notification
        if (message.data['type'] == 'emergency') {
          log('🚨 EMERGENCY NOTIFICATION RECEIVED!');
          log('Victim ID: ${message.data['victim_id']}');
          log('Distance: ${message.data['distance']}km');
        }
      });
      
      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('📱 App opened from background via notification');
      });
      
      // Get initial message if app was opened from terminated state
      RemoteMessage? initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        log('📱 App opened from terminated state with notification');
      }
      
    } catch (e) {
      log('❌ Firebase initialization error: $e');
    }
  }

  static String? get fcmToken => _fcmToken;
  
  static Future<void> refreshToken() async {
    try {
      _fcmToken = await _messaging?.getToken();
      log('🔄 Refreshed FCM Token: ${_fcmToken?.substring(0, 20)}...');
    } catch (e) {
      log('❌ Error refreshing FCM token: $e');
    }
  }
}