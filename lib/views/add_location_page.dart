import 'dart:io';
import 'package:app_turism/sabloane/locatie_sablon.dart';
import 'package:app_turism/service/locatie_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _formKey = GlobalKey<FormState>();

  final _numeController = TextEditingController();
  final _descriereController = TextEditingController();
  final _categorieController = TextEditingController();
  final _judetController = TextEditingController();
  final _orasController = TextEditingController();
  final _orarController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _pretMinController = TextEditingController();
  final _pretMaxController = TextEditingController();
  final _facilitatiController = TextEditingController();

  final LocatieService _locatieService = LocatieService();

  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (!mounted) return;

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();

      final uid = FirebaseAuth.instance.currentUser!.uid;

      final ref = FirebaseStorage.instance
          .ref()
          .child('propuneri_locatii')
          .child(uid)
          .child('$fileName.jpg');

      print("Începe upload...");

      final taskSnapshot = await ref.putFile(_selectedImage!);

      print("Upload terminat!");
      print("State: ${taskSnapshot.state}");

      final url = await ref.getDownloadURL();

      print("URL generat: $url");

      return url;
    } catch (e) {
      print("EROARE STORAGE:");
      print(e);
      rethrow;
    }
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
      }

      final locatie = SablonLocatie(
        id: '',
        nume: _numeController.text.trim(),
        descriere: _descriereController.text.trim(),
        categorie: _categorieController.text.trim(),
        judet: _judetController.text.trim(),
        oras: _orasController.text.trim(),
        orar: _orarController.text.trim(),
        imagini: imageUrl != null ? [imageUrl] : [],
        latitudine:
            double.tryParse(_latController.text.trim().replaceAll(',', '.')) ??
            0,
        longitudine:
            double.tryParse(_lngController.text.trim().replaceAll(',', '.')) ??
            0,
        pretMin:
            double.tryParse(
              _pretMinController.text.trim().replaceAll(',', '.'),
            ) ??
            0,
        pretMax:
            double.tryParse(
              _pretMaxController.text.trim().replaceAll(',', '.'),
            ) ??
            0,
        rating: 0,
        nrRecenzii: 0,
        facilitati: _facilitatiController.text
            .split(',')
            .map((element) => element.trim())
            .where((element) => element.isNotEmpty)
            .toList(),

        popular: false,
      );

      await _locatieService.trimitePropunereLocatie(locatie);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Propunerea a fost trimisă și va fi verificată de un administrator.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Eroare: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _numeController.dispose();
    _descriereController.dispose();
    _categorieController.dispose();
    _judetController.dispose();
    _orasController.dispose();
    _orarController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _pretMinController.dispose();
    _pretMaxController.dispose();
    _facilitatiController.dispose();

    super.dispose();
  }

  Widget _buildField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Completează câmpul';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Propune o locație')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildField(_numeController, 'Nume'),
                    _buildField(_descriereController, 'Descriere'),
                    _buildField(_categorieController, 'Categorie'),
                    _buildField(_judetController, 'Județ'),
                    _buildField(_orasController, 'Oraș'),
                    _buildField(_orarController, 'Orar'),
                    _buildField(_latController, 'Latitudine'),
                    _buildField(_lngController, 'Longitudine'),
                    _buildField(_pretMinController, 'Preț minim'),
                    _buildField(_pretMaxController, 'Preț maxim'),
                    _buildField(
                      _facilitatiController,
                      'Facilități (separate prin virgulă)',
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Alege imagine'),
                    ),

                    const SizedBox(height: 10),

                    if (_selectedImage != null)
                      Image.file(
                        _selectedImage!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveLocation,
                      child: const Text('Trimite spre aprobare'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
