import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
      ),
      body: provider.alerts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No emergency alerts',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.alerts.length,
              itemBuilder: (context, index) {
                final alert = provider.alerts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.red[50],
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(
                      alert.victimName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${alert.distance.toStringAsFixed(2)} km away'),
                        Text(
                          '${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.location_on),
                      onPressed: () {
                        // TODO: Show location on map
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}