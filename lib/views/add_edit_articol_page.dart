import 'package:flutter/material.dart';

import '../sabloane/articol_sablon.dart';
import '../service/articol_service.dart';

class AddEditArticolPage extends StatefulWidget {
  final SablonArticol? articol;

  const AddEditArticolPage({super.key, this.articol});

  @override
  State<AddEditArticolPage> createState() => _AddEditArticolPageState();
}

class _AddEditArticolPageState extends State<AddEditArticolPage> {
  final _formKey = GlobalKey<FormState>();
  final ArticolService _articolService = ArticolService();

  late final TextEditingController _titluController;
  late final TextEditingController _continutController;
  late final TextEditingController _imagineController;
  late final TextEditingController _autorController;

  final List<String> _categorii = const [
    'Trasee montane',
    'Gastronomie',
    'Tradiții',
    'Festivaluri',
    'Sfaturi de călătorie',
    'Altele',
  ];

  String _categorieSelectata = 'Trasee montane';
  bool _seSalveaza = false;

  bool get _esteEditare => widget.articol != null;

  @override
  void initState() {
    super.initState();

    final articol = widget.articol;

    _titluController = TextEditingController(text: articol?.titlu ?? '');

    _continutController = TextEditingController(text: articol?.continut ?? '');

    _imagineController = TextEditingController(text: articol?.imagine ?? '');

    _autorController = TextEditingController(
      text: articol?.autor ?? 'TourMate',
    );

    if (articol != null && _categorii.contains(articol.categorie)) {
      _categorieSelectata = articol.categorie;
    } else if (articol != null) {
      _categorieSelectata = 'Altele';
    }
  }

  @override
  void dispose() {
    _titluController.dispose();
    _continutController.dispose();
    _imagineController.dispose();
    _autorController.dispose();

    super.dispose();
  }

  Future<void> _salveazaArticol() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _seSalveaza = true;
    });

    try {
      final articol = SablonArticol(
        id: widget.articol?.id ?? '',
        titlu: _titluController.text.trim(),
        continut: _continutController.text.trim(),
        categorie: _categorieSelectata,
        imagine: _imagineController.text.trim(),
        autor: _autorController.text.trim(),
        dataPublicarii: widget.articol?.dataPublicarii ?? DateTime.now(),
      );

      if (_esteEditare) {
        await _articolService.updateArticol(articol);
      } else {
        await _articolService.addArticol(articol);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esteEditare
                ? 'Articolul nu a putut fi actualizat: $e'
                : 'Articolul nu a putut fi adăugat: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _seSalveaza = false;
        });
      }
    }
  }

  Widget _previewImagine() {
    final url = _imagineController.text.trim();

    if (url.isEmpty) {
      return Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.image_outlined,
          size: 70,
          color: Colors.grey.shade500,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            width: double.infinity,
            height: 190,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (_, __, ___) {
          return Container(
            width: double.infinity,
            height: 190,
            color: Colors.grey.shade200,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 8),
                Text('URL-ul imaginii nu este valid'),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _validareCampObligatoriu(String? value, String denumire) {
    if (value == null || value.trim().isEmpty) {
      return 'Completează câmpul „$denumire”.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esteEditare ? 'Editează articolul' : 'Adaugă articol'),
      ),
      body: AbsorbPointer(
        absorbing: _seSalveaza,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titluController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Titlu',
                  hintText: 'Introdu titlul articolului',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  return _validareCampObligatoriu(value, 'Titlu');
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _categorieSelectata,
                decoration: const InputDecoration(
                  labelText: 'Categorie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categorii.map((categorie) {
                  return DropdownMenuItem<String>(
                    value: categorie,
                    child: Text(categorie),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _categorieSelectata = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _autorController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Autor',
                  hintText: 'Numele autorului',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  return _validareCampObligatoriu(value, 'Autor');
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _imagineController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL imagine',
                  hintText: 'https://exemplu.ro/imagine.jpg',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image_outlined),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 14),

              _previewImagine(),

              const SizedBox(height: 16),

              TextFormField(
                controller: _continutController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 10,
                maxLines: 20,
                decoration: const InputDecoration(
                  labelText: 'Conținut',
                  hintText: 'Scrie conținutul articolului...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final eroare = _validareCampObligatoriu(value, 'Conținut');

                  if (eroare != null) {
                    return eroare;
                  }

                  if (value!.trim().length < 50) {
                    return 'Conținutul trebuie să aibă minimum 50 de caractere.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _seSalveaza ? null : _salveazaArticol,
                  icon: _seSalveaza
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _esteEditare
                              ? Icons.save_outlined
                              : Icons.publish_outlined,
                        ),
                  label: Text(
                    _seSalveaza
                        ? 'Se salvează...'
                        : _esteEditare
                        ? 'Salvează modificările'
                        : 'Publică articolul',
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
