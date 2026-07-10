import 'package:flutter/material.dart';
import '../sabloane/itinerar_ai_sablon.dart';
import '../service/ai_service.dart';
import '../service/planner_service.dart';

class GeneratorItinerarAiPage extends StatefulWidget {
  const GeneratorItinerarAiPage({super.key});

  @override
  State<GeneratorItinerarAiPage> createState() =>
      _GeneratorItinerarAiPageState();
}

class _GeneratorItinerarAiPageState extends State<GeneratorItinerarAiPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _zonaController = TextEditingController();
  final TextEditingController _bugetController = TextEditingController();
  final TextEditingController _preferinteController = TextEditingController();

  final AiService _aiService = AiService();
  final PlannerService _plannerService = PlannerService();

  int _numarZile = 1;
  bool _cuCopii = false;
  bool _seGenereaza = false;
  bool _seSalveaza = false;

  String? _eroare;
  ItinerarAi? _itinerar;

  @override
  void dispose() {
    _zonaController.dispose();
    _bugetController.dispose();
    _preferinteController.dispose();
    super.dispose();
  }

  Future<void> _genereazaItinerariu() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bugetText = _bugetController.text.trim().replaceAll(',', '.');

    final buget = double.tryParse(bugetText) ?? 0;

    setState(() {
      _seGenereaza = true;
      _eroare = null;
      _itinerar = null;
    });

    try {
      final rezultat = await _aiService.genereazaItinerariu(
        zona: _zonaController.text.trim(),
        zile: _numarZile,
        buget: buget,
        preferinte: _preferinteController.text.trim(),
        cuCopii: _cuCopii,
      );

      final itinerar = ItinerarAi.fromMap(rezultat);

      if (!mounted) {
        return;
      }

      setState(() {
        _itinerar = itinerar;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _eroare = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _seGenereaza = false;
        });
      }
    }
  }

  String? _valideazaZona(String? value) {
    final zona = value?.trim() ?? '';

    if (zona.length < 2) {
      return 'Introdu un oraș sau un județ.';
    }

    return null;
  }

  String? _valideazaBuget(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final buget = double.tryParse(text.replaceAll(',', '.'));

    if (buget == null) {
      return 'Introdu un buget valid.';
    }

    if (buget < 0) {
      return 'Bugetul nu poate fi negativ.';
    }

    if (buget > 100000) {
      return 'Bugetul este prea mare.';
    }

    return null;
  }

  String _formateazaNumar(double valoare) {
    if (valoare == valoare.roundToDouble()) {
      return valoare.toStringAsFixed(0);
    }

    return valoare.toStringAsFixed(2);
  }

  Future<void> _salveazaItinerar() async {
    final itinerar = _itinerar;

    if (itinerar == null || _seSalveaza) {
      return;
    }

    setState(() {
      _seSalveaza = true;
      _eroare = null;
    });

    try {
      await _plannerService.salveazaItinerarAi(itinerar);

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _eroare = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _seSalveaza = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generator itinerar AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _formular(),
          const SizedBox(height: 20),
          if (_seGenereaza) _indicatorGenerare(),
          if (_eroare != null) _mesajEroare(),
          if (_itinerar != null) _rezultatItinerar(_itinerar!),
        ],
      ),
    );
  }

  Widget _formular() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Planifică o excursie',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Completează preferințele, iar AI-ul va folosi '
                'locațiile disponibile în aplicație.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _zonaController,
                validator: _valideazaZona,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Oraș sau județ',
                  hintText: 'Exemplu: Brașov',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _numarZile,
                decoration: const InputDecoration(
                  labelText: 'Număr de zile',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                  border: OutlineInputBorder(),
                ),
                items: List.generate(14, (index) {
                  final zile = index + 1;

                  return DropdownMenuItem<int>(
                    value: zile,
                    child: Text(zile == 1 ? '1 zi' : '$zile zile'),
                  );
                }),
                onChanged: _seGenereaza
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _numarZile = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bugetController,
                validator: _valideazaBuget,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Buget total în lei',
                  hintText: 'Lasă gol sau introdu 0 pentru opțiuni gratuite',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _preferinteController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Preferințe',
                  hintText: 'Exemplu: natură, muzee, castele și trasee ușoare',
                  prefixIcon: Icon(Icons.auto_awesome_outlined),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _cuCopii,
                title: const Text('Excursie cu copii'),
                subtitle: const Text(
                  'AI-ul va favoriza activitățile potrivite familiilor.',
                ),
                secondary: const Icon(Icons.family_restroom),
                onChanged: _seGenereaza
                    ? null
                    : (value) {
                        setState(() {
                          _cuCopii = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _seGenereaza || _seSalveaza
                    ? null
                    : _genereazaItinerariu,
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  _seGenereaza ? 'Se generează...' : 'Generează itinerarul',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indicatorGenerare() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'AI-ul analizează locațiile și construiește itinerarul...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _mesajEroare() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _eroare!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rezultatItinerar(ItinerarAi itinerar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.route, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        itinerar.titlu,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (itinerar.rezumat.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(itinerar.rezumat),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.location_on_outlined, size: 18),
                      label: Text(itinerar.zona),
                    ),
                    Chip(
                      avatar: const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                      ),
                      label: Text(
                        itinerar.numarZile == 1
                            ? '1 zi'
                            : '${itinerar.numarZile} zile',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.payments_outlined, size: 18),
                      label: Text(
                        '${_formateazaNumar(itinerar.bugetTotalEstimat)} lei',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _seSalveaza ? null : _salveazaItinerar,
            icon: _seSalveaza
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _seSalveaza ? 'Se salvează...' : 'Salvează în planificările mele',
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...itinerar.zile.map(_cardZi),
        if (itinerar.sfaturi.isNotEmpty) ...[
          const SizedBox(height: 12),
          _cardSfaturi(itinerar.sfaturi),
        ],
      ],
    );
  }

  Widget _cardZi(ZiItinerarAi zi) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(child: Text('${zi.zi}')),
        title: Text(
          zi.titlu.isEmpty ? 'Ziua ${zi.zi}' : zi.titlu,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${zi.activitati.length} '
          '${zi.activitati.length == 1 ? 'activitate' : 'activități'}',
        ),
        children: [
          if (zi.activitati.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nu au fost găsite activități pentru această zi.'),
            )
          else
            ...zi.activitati.map(_cardActivitate),
        ],
      ),
    );
  }

  Widget _cardActivitate(ActivitateItinerarAi activitate) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activitate.ora,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activitate.numeLocatie,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (activitate.categorie.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                activitate.categorie,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (activitate.motiv.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(activitate.motiv),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_outlined, size: 18),
                    const SizedBox(width: 5),
                    Text('${_formateazaNumar(activitate.durataOre)} ore'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payments_outlined, size: 18),
                    const SizedBox(width: 5),
                    Text('${_formateazaNumar(activitate.costEstimat)} lei'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardSfaturi(List<String> sfaturi) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline),
                SizedBox(width: 8),
                Text(
                  'Sfaturi pentru excursie',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sfaturi.map(
              (sfat) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(sfat)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
