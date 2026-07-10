import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_turism/views/add_location_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_view.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reAuthEmailController = TextEditingController();
  final TextEditingController _reAuthPasswordController =
      TextEditingController();
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  String userName = ''; // Numele utilizatorului vizibil pe profil

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // Încarcă numele salvat din SharedPreferences
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? '';
      _nameController.text = userName;
    });
  }

  // Salvează numele în SharedPreferences și îl face vizibil
  Future<void> _saveName() async {
    final String name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introdu numele utilizatorului')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('utilizatori').doc(uid).set({
      'nume': name,
    }, SetOptions(merge: true));

    setState(() {
      userName = name;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nume utilizator salvat cu succes!')),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, // sau ImageSource.camera
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Schimbă parola'),
        content: TextField(
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Parola nouă'),
          onSubmitted: (value) {},
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          TextButton(onPressed: () {}, child: const Text('Salvează')),
        ],
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();

    // Șterge stiva de navigație și du-te la login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Șterge cont'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: _reAuthEmailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _reAuthPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Parola'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () async {
              try {
                User? user = FirebaseAuth.instance.currentUser;

                if (user != null) {
                  // Re-authenticate user
                  final credential = EmailAuthProvider.credential(
                    email: _reAuthEmailController.text.trim(),
                    password: _reAuthPasswordController.text.trim(),
                  );
                  await user.reauthenticateWithCredential(credential);

                  // Delete user
                  await user.delete();

                  // Navighează la login
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.message ?? 'Eroare la ștergere cont'),
                  ),
                );
              }
            },
            child: const Text('Confirmă'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setări cont')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(File(_profileImage!.path))
                          : const AssetImage('media/hotel.jpeg')
                                as ImageProvider,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(5),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nume utilizator',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveName, child: const Text('Salvează')),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Schimbă parola'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _changePassword,
            ),
            ListTile(
              leading: const Icon(Icons.add_location_alt),
              title: const Text('Adaugă locație'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddLocationPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _logout,
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Șterge cont'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
