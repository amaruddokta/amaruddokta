// ignore_for_file: unused_import

import 'package:amar_uddokta/madmin/screens/AdminUserList.dart';
import 'package:amar_uddokta/madmin/screens/admin_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    // Keyboard hide
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Step 1: Sign in
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        // Step 2: Check for admin role
        final user = response.user;
        final isAdmin = user?.userMetadata?['admin'] == true;

        if (isAdmin) {
          // Step 3: Navigate to admin screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen()),
          );
        } else {
          setState(() {
            _error = '⛔ আপনার অ্যাকাউন্টে অ্যাডমিন অনুমতি নেই!';
          });
          await Supabase.instance.client.auth.signOut();

          // Optional: show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⛔ আপনি অ্যাডমিন নন!')),
          );
        }
      } else {
        setState(() {
          _error = 'Invalid login credentials';
        });
      }
    } catch (e) {
      setState(() {
        _error = '🔥 ত্রুটি: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাডমিন লগইন')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'ইমেইল',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'পাসওয়ার্ড',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('লগইন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
