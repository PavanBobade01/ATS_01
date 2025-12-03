import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Checks if a JWT token exists
  Future<bool> _checkLoginStatus() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ambulance Swift (Police)',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Police theme
        brightness: Brightness.dark,
      ),
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          // Show loading spinner while checking
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // If token exists, go to map
          if (snapshot.hasData && snapshot.data == true) {
            return const MapScreen();
          }
          // Otherwise, go to login
          return LoginScreen();
        },
      ),
    );
  }
}