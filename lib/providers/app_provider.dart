import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_location.dart';
import '../models/EmergencyAlert.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';

class AppProvider extends ChangeNotifier {
  String? _userId;
  Position? _currentPosition;
  List<UserLocation> _nearbyUsers = [];
  List<EmergencyAlert> _alerts = [];
  bool _isLoading = false;
  bool _isEmergencyActive = false;
  StreamSubscription<Position>? _locationSubscription;
  String? _fcmToken;
  bool _firebaseInitialized = false;

  // Getters
  String? get userId => _userId;
  Position? get currentPosition => _currentPosition;
  List<UserLocation> get nearbyUsers => _nearbyUsers;
  List<EmergencyAlert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  bool get isEmergencyActive => _isEmergencyActive;
  String? get fcmToken => _fcmToken;
  bool get firebaseInitialized => _firebaseInitialized;

  AppProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    log('🔄 Initializing AppProvider...');
    await _loadOrCreateUserId();
    await _initializeFirebase();
    await _startLocationTracking();
    await refreshNearbyUsers();
    log('✅ AppProvider initialized');
  }

  Future<void> _loadOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    
    if (_userId == null) {
      _userId = const Uuid().v4();
      await prefs.setString('user_id', _userId!);
      log('🆕 Created new user ID: ${_userId!.substring(0, 8)}...');
    } else {
      log('👤 Loaded existing user ID: ${_userId!.substring(0, 8)}...');
    }
    notifyListeners();
  }

  Future<void> _initializeFirebase() async {
    try {
      log('🔥 Initializing Firebase...');
      await FirebaseService.initialize();
      _fcmToken = FirebaseService.fcmToken;
      _firebaseInitialized = true;
      
      if (_fcmToken != null) {
        log('✅ Firebase initialized. FCM Token: ${_fcmToken!.substring(0, 20)}...');
      } else {
        log('⚠️ Firebase initialized but no FCM token');
      }
      
      notifyListeners();
    } catch (e) {
      log('❌ Error initializing Firebase: $e');
      _firebaseInitialized = false;
    }
  }

  Future<void> _startLocationTracking() async {
    log('📍 Starting location tracking...');
    
    final hasPermission = await LocationService.checkPermissions();
    if (!hasPermission) {
      log('❌ Location permission denied');
      return;
    }
    
    log('✅ Location permission granted');
    
    // Get initial location
    _currentPosition = await LocationService.getCurrentLocation();
    if (_currentPosition != null) {
      log('📍 Initial location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      await _updateServerLocation();
    }
    notifyListeners();

    // Start listening to location updates
    _locationSubscription = LocationService.getLocationStream().listen(
      (position) async {
        _currentPosition = position;
        log('📍 Location updated: ${position.latitude}, ${position.longitude}');
        await _updateServerLocation();
        notifyListeners();
      },
      onError: (error) {
        log('❌ Location stream error: $error');
      },
    );
    
    log('✅ Location tracking started');
  }

  Future<void> _updateServerLocation() async {
    if (_currentPosition == null || _userId == null) return;
    
    // Refresh FCM token if needed
    if (_fcmToken == null) {
      _fcmToken = FirebaseService.fcmToken;
    }
    
    log('📡 Updating server location with FCM token: ${_fcmToken != null ? "Yes" : "No"}');
    
    await ApiService.updateLocation(
      userId: _userId!,
      lat: _currentPosition!.latitude,
      lon: _currentPosition!.longitude,
      fcmToken: _fcmToken,
    );
  }

  Future<void> refreshNearbyUsers() async {
    if (_userId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    log('🔍 Refreshing nearby users...');
    _nearbyUsers = await ApiService.getNearbyUsers(_userId!);
    
    _isLoading = false;
    notifyListeners();
    
    log('✅ Found ${_nearbyUsers.length} nearby users');
  }

  Future<Map<String, dynamic>?> triggerEmergency() async {
    if (_userId == null || _currentPosition == null) {
      log('❌ Cannot trigger emergency - missing user ID or location');
      return {'error': 'Missing user ID or location'};
    }
    
    log('🚨🚨🚨 TRIGGERING EMERGENCY ALERT 🚨🚨🚨');
    log('User: $_userId');
    log('Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    log('FCM Token available: ${_fcmToken != null}');
    
    _isEmergencyActive = true;
    notifyListeners();

    final result = await ApiService.triggerEmergency(_userId!);
    
    _isEmergencyActive = false;
    notifyListeners();
    
    if (result == null) {
      log('❌ Emergency trigger failed - backend returned null');
      return {'error': 'Backend connection failed'};
    } else if (result.containsKey('error')) {
      log('❌ Emergency trigger failed: ${result['error']}');
      return result;
    } else {
      log('✅ Emergency triggered successfully!');
      log('   Notified ${result['count']} users');
      log('   Users: ${result['notified_users']}');
      
      // Add emergency to our own alerts list
      final emergencyAlert = EmergencyAlert(
        victimId: _userId!,
        victimName: 'You',
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
        timestamp: DateTime.now(),
        distance: 0.0,
      );
      addAlert(emergencyAlert);
      
      return result;
    }
  }

  // Handle incoming emergency from other users
  void handleIncomingEmergency({
    required String victimId,
    required double lat,
    required double lon,
    required double distance,
  }) {
    log('🚨 INCOMING EMERGENCY ALERT!');
    log('From: $victimId');
    log('Location: $lat, $lon');
    log('Distance: ${distance}km');
    
    final emergencyAlert = EmergencyAlert(
      victimId: victimId,
      victimName: 'User ${victimId.substring(0, 8)}',
      lat: lat,
      lon: lon,
      timestamp: DateTime.now(),
      distance: distance,
    );
    
    addAlert(emergencyAlert);
    log('✅ Emergency alert added to list');
  }

  void addAlert(EmergencyAlert alert) {
    _alerts.insert(0, alert);
    notifyListeners();
    log('📝 Alert added. Total alerts: ${_alerts.length}');
  }

  void removeAlert(EmergencyAlert alert) {
    _alerts.remove(alert);
    notifyListeners();
  }

  void cancelEmergency() {
    _isEmergencyActive = false;
    notifyListeners();
    log('🛑 Emergency cancelled');
  }

  Future<void> testNotification() async {
    if (_userId == null) return;
    
    log('🔔 Testing notification...');
    await ApiService.testNotification(_userId!);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    log('♻️ AppProvider disposed');
    super.dispose();
  }
}