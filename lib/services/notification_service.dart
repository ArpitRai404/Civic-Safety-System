import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class NotificationService {
  static Future<void> setupInteractedMessage(BuildContext context) async {
    RemoteMessage? initialMessage = 
        await FirebaseMessaging.instance.getInitialMessage();
    
    if (initialMessage != null) {
      _handleMessage(initialMessage, context);
    }


    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message, context);
    });


    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message: ${message.notification?.title}');
      

      _showLocalNotification(message, context);
      

      if (message.data['type'] == 'emergency') {
        _handleEmergencyNotification(message, context);
      }
    });
  }

  static void _handleMessage(RemoteMessage message, BuildContext context) {
    if (message.data['type'] == 'emergency') {
      final provider = Provider.of<AppProvider>(context, listen: false);
      
      provider.handleIncomingEmergency(
        victimId: message.data['victim_id'] ?? 'unknown',
        lat: double.tryParse(message.data['victim_lat'] ?? '0') ?? 0,
        lon: double.tryParse(message.data['victim_lon'] ?? '0') ?? 0,
        distance: double.tryParse(message.data['distance'] ?? '0') ?? 0,
      );
      

      Navigator.pushNamed(context, '/alerts');
    }
  }

  static void _showLocalNotification(RemoteMessage message, BuildContext context) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.notification?.title ?? 'New Alert'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            Navigator.pushNamed(context, '/alerts');
          },
        ),
      ),
    );
  }

  static void _handleEmergencyNotification(RemoteMessage message, BuildContext context) {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🚨 EMERGENCY ALERT!'),
        content: Text(
          'Someone ${message.data['distance']}km away needs help!\n\n'
          'Please check the alerts screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/alerts');
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

}
