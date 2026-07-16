import 'package:flutter/material.dart';

import '../service/locatie_service.dart';

class AdminPropunereLocatieDetaliiPage extends StatefulWidget {
  final Map<String, dynamic> propunere;

  const AdminPropunereLocatieDetaliiPage({super.key, required this.propunere});

  @override
  State<AdminPropunereLocatieDetaliiPage> createState() =>
      _AdminPropunereLocatieDetaliiPageState();
}

class _AdminPropunereLocatieDetaliiPageState
    extends State<AdminPropunereLocatieDetaliiPage> {
  final LocatieService _locatieService = LocatieService();

  bool _seProceseaza = false;
  int _indexImagine = 0;

  String get _propunereId => widget.propunere['id']?.toString() ?? '';

  List<String> get _imagini {
    final valoare = widget.propunere['imagini'];

    if (valoare is! List) {
      return [];
    }

    return valoare
        .map((element) => element.toString())
        .where((element) => element.trim().isNotEmpty)
        .toList();
  }

  List<String> get _facilitati {
    final valoare = widget.propunere['facilitati'];

    if (valoare is! List) {
      return [];
    }

    return valoare
        .map((element) => element.toString())
        .where((element) => element.trim().isNotEmpty)
        .toList();
  }

  String _text(String camp, {String implicit = '-'}) {
    final valoare = widget.propunere[camp];

    if (valoare == null || valoare.toString().trim().isEmpty) {
      return implicit;
    }

    return valoare.toString();
  }

  Future<void> _aprobaPropunerea() async {
    final confirmare = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Aprobă propunerea'),
          content: const Text(
            'Locația va deveni publică, iar utilizatorul va primi 20 de puncte.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Anulează'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.check),
              label: const Text('Aprobă'),
            ),
          ],
        );
      },
    );

    if (confirmare != true) return;

    if (!mounted) return;

    setState(() {
      _seProceseaza = true;
    });

    try {
      await _locatieService.aprobaPropunereLocatie(_propunereId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Locația a fost aprobată și publicată.')),
      );

      Navigator.pop(context, true);
      return;
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _seProceseaza = false;
    });
  }

  Future<void> _respingePropunerea() async {
    final controller = TextEditingController();

    final motiv = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Respinge propunerea'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Motivul respingerii',
              hintText: 'Explică de ce locația nu poate fi publicată...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Anulează'),
            ),
            FilledButton.icon(
              onPressed: () {
                final text = controller.text.trim();

                if (text.length < 5) {
                  return;
                }

                Navigator.pop(dialogContext, text);
              },
              icon: const Icon(Icons.close),
              label: const Text('Respinge'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (motiv == null || motiv.trim().isEmpty) return;

    if (motiv.trim().length < 5) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Motivul trebuie să conțină minimum 5 caractere.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _seProceseaza = true;
    });

    try {
      await _locatieService.respingePropunereLocatie(
        propunereId: _propunereId,
        motiv: motiv,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propunerea a fost respinsă.')),
      );

      Navigator.pop(context, true);
      return;
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _seProceseaza = false;
    });
  }

  Widget _sectiune({required String titlu, required Widget continut}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titlu,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          continut,
        ],
      ),
    );
  }

  Widget _randDetaliu({
    required IconData icon,
    required String titlu,
    required String valoare,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$titlu: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  TextSpan(
                    text: valoare,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nume = _text('nume', implicit: 'Locație fără nume');

    return Scaffold(
      appBar: AppBar(title: const Text('Verifică propunerea')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_imagini.isNotEmpty)
                  SizedBox(
                    height: 260,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        PageView.builder(
                          itemCount: _imagini.length,
                          onPageChanged: (index) {
                            setState(() {
                              _indexImagine = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              _imagini[index],
                              width: double.infinity,
                              height: 260,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progres) {
                                if (progres == null) {
                                  return child;
                                }

                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 70,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        if (_imagini.length > 1)
                          Positioned(
                            bottom: 12,
                            child: Row(
                              children: List.generate(_imagini.length, (index) {
                                final selectata = index == _indexImagine;

                                return Container(
                                  width: selectata ? 10 : 8,
                                  height: selectata ? 10 : 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selectata
                                        ? Colors.white
                                        : Colors.white54,
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 260,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image_outlined, size: 70),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nume,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectiune(
                        titlu: 'Informații generale',
                        continut: Column(
                          children: [
                            _randDetaliu(
                              icon: Icons.category_outlined,
                              titlu: 'Categorie',
                              valoare: _text('categorie'),
                            ),
                            _randDetaliu(
                              icon: Icons.location_city_outlined,
                              titlu: 'Oraș',
                              valoare: _text('oras'),
                            ),
                            _randDetaliu(
                              icon: Icons.map_outlined,
                              titlu: 'Județ',
                              valoare: _text('judet'),
                            ),
                            _randDetaliu(
                              icon: Icons.schedule_outlined,
                              titlu: 'Program',
                              valoare: _text('orar'),
                            ),
                          ],
                        ),
                      ),
                      _sectiune(
                        titlu: 'Descriere',
                        continut: Text(_text('descriere')),
                      ),
                      _sectiune(
                        titlu: 'Preț',
                        continut: Text(
                          '${_text('pretMin', implicit: '0')} – '
                          '${_text('pretMax', implicit: '0')} lei',
                        ),
                      ),
                      _sectiune(
                        titlu: 'Coordonate',
                        continut: Column(
                          children: [
                            _randDetaliu(
                              icon: Icons.my_location,
                              titlu: 'Latitudine',
                              valoare: _text('latitudine'),
                            ),
                            _randDetaliu(
                              icon: Icons.explore_outlined,
                              titlu: 'Longitudine',
                              valoare: _text('longitudine'),
                            ),
                          ],
                        ),
                      ),
                      _sectiune(
                        titlu: 'Facilități',
                        continut: _facilitati.isEmpty
                            ? const Text('Nu au fost specificate.')
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _facilitati
                                    .map(
                                      (facilitate) =>
                                          Chip(label: Text(facilitate)),
                                    )
                                    .toList(),
                              ),
                      ),
                      _sectiune(
                        titlu: 'Datele autorului',
                        continut: _randDetaliu(
                          icon: Icons.person_outline,
                          titlu: 'ID utilizator',
                          valoare: _text('creatorId'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_seProceseaza)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _seProceseaza ? null : _respingePropunerea,
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Respinge'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _seProceseaza ? null : _aprobaPropunerea,
                  icon: const Icon(Icons.check),
                  label: const Text('Aprobă'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
