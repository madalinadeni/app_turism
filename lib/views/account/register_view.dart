import 'package:flutter/material.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Email')),
            const TextField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            ElevatedButton(onPressed: () {}, child: const Text('Register')),

            TextButton(
              onPressed: () {
                Navigator.pop(context); // înapoi la Login
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
