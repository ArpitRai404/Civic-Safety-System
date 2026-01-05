import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SosCountdownScreen extends StatefulWidget {
  const SosCountdownScreen({super.key});

  @override
  State<SosCountdownScreen> createState() => _SosCountdownScreenState();
}

class _SosCountdownScreenState extends State<SosCountdownScreen> {
  int _countdown = 15;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      if (_countdown > 0 && !_isCancelled) {
        setState(() => _countdown--);
        _startCountdown();
      } else if (_countdown == 0 && !_isCancelled) {
        _triggerEmergency();
      }
    });
  }

  void _triggerEmergency() async {
    final provider = context.read<AppProvider>();
    final result = await provider.triggerEmergency();
    
    if (!mounted) return;
    
    Navigator.pop(context);
    
    if (result != null) {
      final count = result['count'] ?? 0;
      
      if (count == 0) {
        // NO USERS NEARBY - show different message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Emergency Activated'),
            content: const Text(
              'Your emergency alert is active!\n\n'
              'No other Safety App users detected within 1.5km radius.\n\n'
              'Please consider:\n'
              '• Calling emergency services directly (112/911)\n'
              '• Contacting trusted contacts\n'
              '• Moving to a safer, public location',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Call emergency number
                  _callEmergency();
                },
                child: const Text('📞 Call 112'),
              ),
            ],
          ),
        );
      } else {
        // SUCCESS WITH USERS
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Emergency Alert Sent!'),
            content: Text(
              'Help request sent to $count nearby user${count == 1 ? '' : 's'}.\n\n'
              'They have been notified and can respond to assist.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      // ACTUAL FAILURE
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌ Failed to Send'),
          content: const Text(
            'Could not send emergency alert.\n\n'
            'Please check your internet connection and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Retry emergency
                _triggerEmergency();
              },
              child: const Text('🔄 Try Again'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _callEmergency() async {
    const url = 'tel:112';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch phone dialer'),
        ),
      );
    }
  }

  void _cancelEmergency() {
    setState(() => _isCancelled = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_countdown',
              style: const TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Emergency will be triggered in',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
            
            const SizedBox(height: 40),
            
            const Icon(
              Icons.warning,
              size: 80,
              color: Colors.red,
            ),
            
            const SizedBox(height: 20),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'If you\'re in danger, do not cancel. Help will be sent to nearby users.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            
            const Spacer(),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _cancelEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'CANCEL EMERGENCY',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}