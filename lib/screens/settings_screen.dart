import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Your User ID'),
              subtitle: Text(provider.userId ?? 'Not available'),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  if (provider.userId != null) {
                    // Copy to clipboard
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: ListTile(
              leading: Icon(
                provider.currentPosition != null 
                    ? Icons.location_on 
                    : Icons.location_off,
                color: provider.currentPosition != null 
                    ? Colors.green 
                    : Colors.red,
              ),
              title: const Text('Location Services'),
              subtitle: Text(
                provider.currentPosition != null
                    ? 'Active'
                    : 'Inactive',
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.emergency),
              title: const Text('Emergency Contacts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Add emergency contacts screen
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Add notification settings
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Add privacy settings
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Card(
            child: ListTile(
              leading: Icon(Icons.info),
              title: Text('About Safety App'),
              subtitle: Text('Version 1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}