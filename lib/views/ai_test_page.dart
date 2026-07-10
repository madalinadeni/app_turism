import 'package:flutter/material.dart';
import '../service/ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../sabloane/locatie_sablon.dart';
import 'location_details_page.dart';

class AiTestPage extends StatefulWidget {
  final String initialText;

  const AiTestPage({super.key, this.initialText = ''});

  @override
  State<AiTestPage> createState() => _AiTestPageState();
}

class _LocatieCuScor {
  final SablonLocatie locatie;
  final double scor;

  const _LocatieCuScor({required this.locatie, required this.scor});
}

class _AiTestPageState extends State<AiTestPage> {
  final TextEditingController _controller = TextEditingController();
  final AiService _aiService = AiService();

  bool _seIncarca = false;
  Map<String, dynamic>? _rezultat;
  String? _eroare;

  List<SablonLocatie> _locatiiGasite = [];
  bool _aFostExecutataCautarea = false;

  @override
  void initState() {
    super.initState();

    _controller.text = widget.initialText;

    if (widget.initialText.trim().length >= 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _testeazaCautarea();
      });
    }
  }

  Future<void> _testeazaCautarea() async {
    final text = _controller.text.trim();

    if (text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introdu o căutare de minimum 3 caractere.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _seIncarca = true;
      _rezultat = null;
      _eroare = null;
      _locatiiGasite = [];
      _aFostExecutataCautarea = false;
    });

    try {
      // AI-ul extrage filtrele din cererea utilizatorului.
      final rezultat = await _aiService.cautareInteligenta(text);

      // Căutăm locațiile din Firestore folosind filtrele AI.
      final locatii = await _cautaLocatiiDupaFiltre(rezultat);

      if (!mounted) return;

      setState(() {
        _rezultat = rezultat;
        _locatiiGasite = locatii;
        _aFostExecutataCautarea = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _eroare = e.toString().replaceFirst('Exception: ', '');
        _aFostExecutataCautarea = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _seIncarca = false;
        });
      }
    }
  }

  Future<List<SablonLocatie>> _cautaLocatiiDupaFiltre(
    Map<String, dynamic> filtre,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('locatii')
        .get();

    final toateLocatiile = snapshot.docs.map((document) {
      return SablonLocatie.fromMap(document.data(), document.id);
    }).toList();

    final categorie = _normalizeaza(filtre['categorie']?.toString() ?? '');

    final oras = _normalizeaza(filtre['oras']?.toString() ?? '');

    final judet = _normalizeaza(filtre['judet']?.toString() ?? '');

    final facilitati = List<String>.from(filtre['facilitati'] ?? const []);

    final cuvinteCheie = List<String>.from(filtre['cuvinteCheie'] ?? const []);

    final potrivitCopii = filtre['potrivitCopii'] == true;
    final gratuit = filtre['gratuit'] == true;
    final inAerLiber = filtre['inAerLiber'] == true;

    final termeniCategorie = _termeniPentruCategorie(categorie);

    final rezultate = <_LocatieCuScor>[];

    for (final locatie in toateLocatiile) {
      final textLocatie = _normalizeaza(
        [
          locatie.nume,
          locatie.descriere,
          locatie.categorie,
          locatie.oras,
          locatie.judet,
          locatie.orar,
          ...locatie.facilitati,
        ].join(' '),
      );

      final textZona = _normalizeaza(
        [
          locatie.oras,
          locatie.judet,
          locatie.nume,
          locatie.descriere,
        ].join(' '),
      );

      // Categoria poate fi identificată și din numele locației.
      final categoriePotrivita =
          categorie.isEmpty ||
          termeniCategorie.any((termen) => textLocatie.contains(termen));

      // Dacă utilizatorul spune Brașov, verificăm atât orașul,
      // cât și județul, numele sau descrierea locației.
      final zonaPotrivita =
          (oras.isEmpty && judet.isEmpty) ||
          (oras.isNotEmpty && textZona.contains(oras)) ||
          (judet.isNotEmpty && textZona.contains(judet));

      final copiiPotrivit =
          !potrivitCopii || _estePotrivitaPentruCopii(textLocatie);

      final gratuitPotrivit = !gratuit || _esteGratuita(locatie, textLocatie);

      final aerLiberPotrivit = !inAerLiber || _esteInAerLiber(textLocatie);

      if (!categoriePotrivita ||
          !zonaPotrivita ||
          !copiiPotrivit ||
          !gratuitPotrivit ||
          !aerLiberPotrivit) {
        continue;
      }

      double scor = 0;

      if (categorie.isNotEmpty && categoriePotrivita) {
        scor += 6;
      }

      if ((oras.isNotEmpty || judet.isNotEmpty) && zonaPotrivita) {
        scor += 5;
      }

      for (final facilitate in facilitati) {
        final termen = _normalizeaza(facilitate);

        if (termen.isNotEmpty && textLocatie.contains(termen)) {
          scor += 2;
        }
      }

      for (final cuvant in cuvinteCheie) {
        final termen = _normalizeaza(cuvant);

        if (termen.isNotEmpty && textLocatie.contains(termen)) {
          scor += 1;
        }
      }

      if (potrivitCopii && _estePotrivitaPentruCopii(textLocatie)) {
        scor += 3;
      }

      if (gratuit && _esteGratuita(locatie, textLocatie)) {
        scor += 3;
      }

      if (inAerLiber && _esteInAerLiber(textLocatie)) {
        scor += 3;
      }

      // Ratingul este folosit doar pentru departajare.
      scor += locatie.rating * 0.2;

      rezultate.add(_LocatieCuScor(locatie: locatie, scor: scor));
    }

    rezultate.sort((a, b) => b.scor.compareTo(a.scor));

    return rezultate.map((rezultat) => rezultat.locatie).toList();
  }

  String _normalizeaza(String text) {
    return text
        .toLowerCase()
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ș', 's')
        .replaceAll('ş', 's')
        .replaceAll('ț', 't')
        .replaceAll('ţ', 't')
        .trim();
  }

  List<String> _termeniPentruCategorie(String categorie) {
    if (categorie.isEmpty) {
      return [];
    }

    final categoriiSimilare = <String, List<String>>{
      'castel': ['castel', 'cetate', 'palat', 'fortareata'],
      'muzeu': ['muzeu', 'muzee', 'memorial', 'expozitie'],
      'hotel': ['hotel', 'cazare', 'pensiune', 'resort'],
      'restaurant': ['restaurant', 'gastronomie', 'mancare', 'culinar'],
      'traseu': ['traseu', 'drumetie', 'munte', 'montan'],
      'parc': ['parc', 'gradina', 'natura', 'rezervatie'],
      'biserica': ['biserica', 'manastire', 'catedrala', 'lacase de cult'],
      'atractie': ['atractie', 'obiectiv', 'castel', 'muzeu', 'cetate', 'parc'],
    };

    for (final entry in categoriiSimilare.entries) {
      if (categorie.contains(entry.key) || entry.key.contains(categorie)) {
        return entry.value;
      }
    }

    return [categorie];
  }

  bool _estePotrivitaPentruCopii(String text) {
    const termeni = [
      'copii',
      'familie',
      'familial',
      'loc de joaca',
      'interactiv',
      'zoo',
      'gradina zoologica',
      'parc',
    ];

    return termeni.any(text.contains);
  }

  bool _esteGratuita(SablonLocatie locatie, String text) {
    return text.contains('gratuit') ||
        (locatie.pretMin == 0 && locatie.pretMax == 0);
  }

  bool _esteInAerLiber(String text) {
    const termeni = [
      'aer liber',
      'parc',
      'traseu',
      'drumetie',
      'natura',
      'munte',
      'cascada',
      'rezervatie',
      'gradina',
      'plaja',
      'lac',
    ];

    return termeni.any(text.contains);
  }

  Widget _rezultatCard() {
    final rezultat = _rezultat;

    if (rezultat == null) {
      return const SizedBox.shrink();
    }

    final facilitati = List<String>.from(rezultat['facilitati'] ?? []);

    final cuvinteCheie = List<String>.from(rezultat['cuvinteCheie'] ?? []);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtre identificate de AI',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            _randRezultat('Categorie', rezultat['categorie']),
            _randRezultat('Oraș', rezultat['oras']),
            _randRezultat('Județ', rezultat['judet']),
            _randRezultat(
              'Potrivit pentru copii',
              rezultat['potrivitCopii'] == true ? 'Da' : 'Nu',
            ),
            _randRezultat('Gratuit', rezultat['gratuit'] == true ? 'Da' : 'Nu'),
            _randRezultat(
              'În aer liber',
              rezultat['inAerLiber'] == true ? 'Da' : 'Nu',
            ),

            const SizedBox(height: 12),

            const Text(
              'Facilități',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            facilitati.isEmpty
                ? const Text('Nespecificate')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: facilitati
                        .map((facilitate) => Chip(label: Text(facilitate)))
                        .toList(),
                  ),

            const SizedBox(height: 14),

            const Text(
              'Cuvinte-cheie',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            cuvinteCheie.isEmpty
                ? const Text('Nespecificate')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cuvinteCheie
                        .map((cuvant) => Chip(label: Text(cuvant)))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _randRezultat(String eticheta, dynamic valoare) {
    final text = valoare?.toString().trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              '$eticheta:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(text.isEmpty ? 'Nespecificat' : text)),
        ],
      ),
    );
  }

  Widget _rezultateLocatii() {
    if (_eroare != null || !_aFostExecutataCautarea) {
      return const SizedBox.shrink();
    }

    if (_locatiiGasite.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 55, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              const Text(
                'Nu am găsit locații potrivite.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Încearcă o cerere mai generală.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Locații recomandate (${_locatiiGasite.length})',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._locatiiGasite.map(_locatieCard),
      ],
    );
  }

  Widget _locatieCard(SablonLocatie locatie) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LocationDetailsPage(locatie: locatie),
            ),
          );
        },
        child: Row(
          children: [
            SizedBox(
              width: 115,
              height: 130,
              child: locatie.imagini.isNotEmpty
                  ? Image.network(
                      locatie.imagini.first,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) {
                        return _imagineLocatieImplicita();
                      },
                    )
                  : _imagineLocatieImplicita(),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locatie.nume,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      locatie.categorie,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 17),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${locatie.oras}, ${locatie.judet}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${locatie.rating.toStringAsFixed(1)} '
                          '(${locatie.nrRecenzii})',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagineLocatieImplicita() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade500,
        size: 42,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Căutare inteligentă')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Scrie o cerere turistică în limbaj natural.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Exemplu: „Vreau un castel aproape de Brașov.”',
            style: TextStyle(color: Colors.grey.shade700),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Ce dorești să vizitezi?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              prefixIcon: const Icon(Icons.auto_awesome),
            ),
            onSubmitted: (_) {
              if (!_seIncarca) {
                _testeazaCautarea();
              }
            },
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _seIncarca ? null : _testeazaCautarea,
              icon: _seIncarca
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _seIncarca ? 'AI analizează...' : 'Analizează cererea',
              ),
            ),
          ),

          if (_eroare != null) ...[
            const SizedBox(height: 20),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _eroare!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          _rezultatCard(),

          const SizedBox(height: 20),

          _rezultateLocatii(),
        ],
      ),
    );
  }
}
