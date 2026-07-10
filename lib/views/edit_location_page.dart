import 'package:flutter/material.dart';
import '../sabloane/locatie_sablon.dart';
import '../service/locatie_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditLocationPage extends StatefulWidget {
  final SablonLocatie locatie;

  const EditLocationPage({super.key, required this.locatie});

  @override
  State<EditLocationPage> createState() => _EditLocationPageState();
}

class _EditLocationPageState extends State<EditLocationPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _numeController;
  late TextEditingController _descriereController;
  late TextEditingController _categorieController;
  late TextEditingController _judetController;
  late TextEditingController _orasController;
  late TextEditingController _orarController;
  late TextEditingController _pretMinController;
  late TextEditingController _pretMaxController;
  late TextEditingController _facilitatiController;

  bool _popular = false;
  List<String> _imagini = [];

  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();

    _numeController = TextEditingController(text: widget.locatie.nume);

    _descriereController = TextEditingController(
      text: widget.locatie.descriere,
    );

    _categorieController = TextEditingController(
      text: widget.locatie.categorie,
    );

    _judetController = TextEditingController(text: widget.locatie.judet);

    _orasController = TextEditingController(text: widget.locatie.oras);

    _orarController = TextEditingController(text: widget.locatie.orar);

    _pretMinController = TextEditingController(
      text: widget.locatie.pretMin.toString(),
    );

    _pretMaxController = TextEditingController(
      text: widget.locatie.pretMax.toString(),
    );

    _facilitatiController = TextEditingController(
      text: widget.locatie.facilitati.join(', '),
    );

    _popular = widget.locatie.popular;

    _imagini = List<String>.from(widget.locatie.imagini);
  }

  Future<void> _pickImage() async {
    final pickedImages = await ImagePicker().pickMultiImage();

    if (pickedImages.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedImages.map((image) => File(image.path)));
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';

    final ref = FirebaseStorage.instance
        .ref()
        .child('locatii')
        .child('$fileName.jpg');

    await ref.putFile(image);

    return await ref.getDownloadURL();
  }

  Future<void> _saveChanges() async {
    for (final image in _selectedImages) {
      final imageUrl = await _uploadImage(image);
      _imagini.add(imageUrl);
    }

    await LocatieService().updateLocatie(widget.locatie.id, {
      'nume': _numeController.text,
      'descriere': _descriereController.text,
      'categorie': _categorieController.text,
      'judet': _judetController.text,
      'oras': _orasController.text,
      'orar': _orarController.text,
      'pretMin': double.tryParse(_pretMinController.text) ?? 0,
      'pretMax': double.tryParse(_pretMaxController.text) ?? 0,
      'popular': _popular,
      'imagini': _imagini,
      'facilitati': _facilitatiController.text
          .split(',')
          .map((e) => e.trim())
          .toList(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Locația a fost actualizată')));

    Navigator.pop(context, true);
  }

  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numeController.dispose();
    _descriereController.dispose();
    _categorieController.dispose();
    _judetController.dispose();
    _orasController.dispose();
    _orarController.dispose();
    _pretMinController.dispose();
    _pretMaxController.dispose();
    _facilitatiController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editează locația')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildField('Nume', _numeController),
              buildField('Descriere', _descriereController),
              buildField('Categorie', _categorieController),
              buildField('Județ', _judetController),
              buildField('Oraș', _orasController),
              buildField('Orar', _orarController),
              buildField('Preț minim', _pretMinController),
              buildField('Preț maxim', _pretMaxController),

              buildField(
                'Facilități (separate prin virgulă)',
                _facilitatiController,
              ),

              SwitchListTile(
                title: const Text('Locație populară'),
                value: _popular,
                onChanged: (value) {
                  setState(() {
                    _popular = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Imagini',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _imagini.map((url) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          url,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),

                      Positioned(
                        top: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.red,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 15,
                            ),
                            onPressed: () {
                              setState(() {
                                _imagini.remove(url);
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),

              const SizedBox(height: 15),

              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 20),

                const Text(
                  'Poze selectate',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _selectedImages.map((image) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            image,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),

                        Positioned(
                          top: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.red,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.close,
                                size: 15,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedImages.remove(image);
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],

              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Adaugă imagine'),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Salvează modificările'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
