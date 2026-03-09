// ignore_for_file: library_private_types_in_public_api

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'resource.dart';
import 'loginsignup.dart';
import 'schools.dart';


List<CameraDescription> cameras = [];


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
