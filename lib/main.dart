import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'shared/data/app_db.dart';

/// Global database instance — will be replaced by Riverpod provider later.
late final AppDatabase database;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with unified config
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Drift local database
  database = AppDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('${AppConfig.appName} - ${AppConfig.environment}'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'TravelBuddy',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Environment: ${AppConfig.environment}'),
            ],
          ),
        ),
      ),
    );
  }
}
