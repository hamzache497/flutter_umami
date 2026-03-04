// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:umami_flutter/umami_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Umami analytics — returns immediately, never blocks.
  UmamiAnalytics.init(
    websiteId: 'your-website-id',
    serverUrl: 'https://your-umami.example.com',
    hostname: 'example_app',
    enableLogging: true,
    onError: (error) => print('Analytics error: $error'),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Umami Flutter Example',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Track this screen view
    UmamiAnalytics.trackScreen('HomeScreen');

    return Scaffold(
      appBar: AppBar(title: const Text('Umami Flutter Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            UmamiAnalytics.trackEvent(
              'button_tap',
              data: {
                'button': 'example',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          },
          child: const Text('Track Event'),
        ),
      ),
    );
  }
}
