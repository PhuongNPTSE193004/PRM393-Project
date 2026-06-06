import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final AuthService authService = AuthService();

  Future<void> logout(BuildContext context) async {
    await authService.logout();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Airsoft Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to Airsoft Shop',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}