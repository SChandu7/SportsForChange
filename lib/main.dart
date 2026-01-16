// ignore_for_file: library_private_types_in_public_api

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'resource.dart';
import 'loginsignup.dart';
import 'schools.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

List<CameraDescription> cameras = [];

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase FIRST
  await Firebase.initializeApp();

  // ✅ Initialize notifications
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Camera init SAFE
  try {
    cameras = await availableCameras();
  } catch (e) {
    cameras = [];
  }

  // ✅ SharedPreferences SAFE
  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString('username');

  runApp(
    ChangeNotifierProvider(
      create: (_) => resource(),
      child: MyApp(username: username),
    ),
  );
}

class MyApp extends StatefulWidget {
  final String? username;
  const MyApp({super.key, required this.username});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: widget.username == null
          ? LoginPage()
          : widget.username == "admin"
          ? AdminDashboard(username: "admin")
          : ParticularPtPage(username: widget.username!),
    );
  }
}
