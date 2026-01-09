import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize local notifications
  try {
    await LocalNotificationService().initialize();
    print('[LocalNotification] Initialized successfully');
  } catch (e) {
    print('[LocalNotification] Initialization error: $e');
  }

  runApp(const TramDocApp());
  print(
    '[Firestore] projectId=${FirebaseFirestore.instance.app.options.projectId}',
  );
}
