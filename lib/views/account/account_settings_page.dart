import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_turism/views/add_location_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'propunerile_mele_page.dart';

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

  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final utilizator = FirebaseAuth.instance.currentUser;

    if (utilizator == null) {
      return;
    }

    final uid = utilizator.uid;

    final userRef = FirebaseFirestore.instance
        .collection('utilizatori')
        .doc(uid);

    final document = await userRef.get();

    if (!document.exists) {
      await userRef.set({
        'nume': utilizator.displayName?.trim().isNotEmpty == true
            ? utilizator.displayName
            : 'Utilizator',
        'email': utilizator.email ?? '',
        'imagineProfil': '',
        'puncte': 0,
        'nivel': 1,
        'titlu': 'Explorator Începător',
        'badge': '🌱',
        'rol': 'utilizator',
        'dataCreare': FieldValue.serverTimestamp(),
      });
    }

    final documentActualizat = await userRef.get();
    final data = documentActualizat.data() ?? {};

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('userName');
    await prefs.remove('profileImagePath');

    final pozaSalvata = prefs.getString('profileImagePath_$uid');

    if (!mounted) return;

    setState(() {
      userName = data['nume']?.toString().trim().isNotEmpty == true
          ? data['nume'].toString()
          : 'Utilizator';

      _nameController.text = userName;

      if (pozaSalvata != null && pozaSalvata.trim().isNotEmpty) {
        _profileImage = XFile(pozaSalvata);
      } else {
        _profileImage = null;
      }
    });
  }

  Future<void> _saveName() async {
    final String name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introdu numele utilizatorului')),
      );
      return;
    }

    final utilizator = FirebaseAuth.instance.currentUser;

    if (utilizator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu există utilizator autentificat.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('utilizatori')
        .doc(utilizator.uid)
        .set({
          'nume': name,
          'email': utilizator.email ?? '',
        }, SetOptions(merge: true));

    if (!mounted) return;

    setState(() {
      userName = name;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nume utilizator salvat cu succes!')),
    );
  }

  Future<void> _pickImage() async {
    final utilizator = FirebaseAuth.instance.currentUser;

    if (utilizator == null) {
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('profileImagePath_${utilizator.uid}', image.path);

    if (!mounted) return;

    setState(() {
      _profileImage = image;
    });
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;

                if (user == null) {
                  return;
                }

                final credential = EmailAuthProvider.credential(
                  email: _reAuthEmailController.text.trim(),
                  password: _reAuthPasswordController.text.trim(),
                );

                await user.reauthenticateWithCredential(credential);
                await user.delete();

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (!mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginView()),
                  (route) => false,
                );
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;

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
              title: const Text('Propune locație'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddLocationPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Propunerile mele'),
              subtitle: const Text('Vezi statusul locațiilor trimise'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PropunerileMelePage(),
                  ),
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
