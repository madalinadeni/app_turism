import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../sabloane/mesaj_chat_sablon.dart';
import '../service/ai_service.dart';
import 'location_details_page.dart';
import '../sabloane/locatie_sablon.dart';

class ChatTuristicPage extends StatefulWidget {
  const ChatTuristicPage({super.key});

  @override
  State<ChatTuristicPage> createState() => _ChatTuristicPageState();
}

class _ChatTuristicPageState extends State<ChatTuristicPage> {
  final AiService _aiService = AiService();

  final TextEditingController _mesajController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<MesajChatSablon> _mesaje = [];

  bool _seTrimite = false;
  String? _eroare;

  @override
  void initState() {
    super.initState();

    _mesaje.add(
      MesajChatSablon.asistent(
        continut:
            'Bună! Sunt asistentul turistic TourMate. '
            'Te pot ajuta să găsești locații, activități și idei '
            'pentru excursia ta.',
        sugestii: const [
          'Ce pot vizita în Brașov?',
          'Recomandă-mi locuri pentru copii',
          'Ce atracții în aer liber există?',
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mesajController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _trimiteMesaj([String? textSugestie]) async {
    if (_seTrimite) {
      return;
    }

    final mesaj = (textSugestie ?? _mesajController.text).trim();

    if (mesaj.length < 2) {
      setState(() {
        _eroare = 'Mesajul trebuie să conțină minimum 2 caractere.';
      });

      return;
    }

    if (mesaj.length > 500) {
      setState(() {
        _eroare = 'Mesajul este prea lung.';
      });

      return;
    }

    final istoric = _mesaje
        .map((mesajChat) => mesajChat.toIstoricMap())
        .toList();

    final mesajUtilizator = MesajChatSablon.utilizator(mesaj);

    _mesajController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _mesaje.add(mesajUtilizator);
      _seTrimite = true;
      _eroare = null;
    });

    _mergiLaUltimulMesaj();

    try {
      final rezultat = await _aiService.chatTuristic(
        mesaj: mesaj,
        istoric: istoric,
      );

      final mesajAsistent = MesajChatSablon.fromAiResponse(rezultat);

      if (!mounted) {
        return;
      }

      setState(() {
        _mesaje.add(mesajAsistent);
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
          _seTrimite = false;
        });

        _mergiLaUltimulMesaj();
      }
    }
  }

  void _mergiLaUltimulMesaj() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  void _stergeConversatia() {
    setState(() {
      _mesaje
        ..clear()
        ..add(
          MesajChatSablon.asistent(
            continut:
                'Conversația a fost resetată. '
                'Cu ce te pot ajuta?',
            sugestii: const [
              'Recomandă-mi un muzeu',
              'Ce pot vizita într-o zi?',
              'Unde pot merge cu familia?',
            ],
          ),
        );

      _eroare = null;
    });
  }

  String _formateazaOra(DateTime data) {
    final ora = data.hour.toString().padLeft(2, '0');
    final minut = data.minute.toString().padLeft(2, '0');

    return '$ora:$minut';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined),
            SizedBox(width: 10),
            Text('Asistent turistic'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Resetează conversația',
            onPressed: _seTrimite ? null : _stergeConversatia,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                itemCount: _mesaje.length + (_seTrimite ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_seTrimite && index == _mesaje.length) {
                    return _indicatorScriere();
                  }

                  return _mesajCard(_mesaje[index]);
                },
              ),
            ),
            if (_eroare != null) _mesajEroare(),
            _zonaIntroducereMesaj(),
          ],
        ),
      ),
    );
  }

  Widget _mesajCard(MesajChatSablon mesaj) {
    final esteUtilizator = mesaj.esteUtilizator;

    return Align(
      alignment: esteUtilizator ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.86,
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: esteUtilizator
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: esteUtilizator
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(esteUtilizator ? 18 : 4),
                  bottomRight: Radius.circular(esteUtilizator ? 4 : 18),
                ),
              ),
              child: SelectableText(
                mesaj.continut,
                style: TextStyle(
                  color: esteUtilizator
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formateazaOra(mesaj.trimisLa),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (mesaj.esteAsistent && mesaj.locatieIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              _locatiiRecomandate(mesaj.locatieIds),
            ],
            if (mesaj.esteAsistent && mesaj.sugestii.isNotEmpty) ...[
              const SizedBox(height: 10),
              _sugestii(mesaj.sugestii),
            ],
          ],
        ),
      ),
    );
  }

  Widget _indicatorScriere() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('TourMate scrie...'),
          ],
        ),
      ),
    );
  }

  Widget _sugestii(List<String> sugestii) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sugestii.map((sugestie) {
        return ActionChip(
          avatar: const Icon(Icons.chat_bubble_outline, size: 17),
          label: Text(sugestie),
          onPressed: _seTrimite ? null : () => _trimiteMesaj(sugestie),
        );
      }).toList(),
    );
  }

  Widget _locatiiRecomandate(List<String> locatieIds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Locații recomandate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...locatieIds.map(_cardLocatie),
      ],
    );
  }

  Widget _cardLocatie(String locatieId) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('locatii')
          .doc(locatieId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() ?? {};
        final locatie = SablonLocatie.fromMap(data, snapshot.data!.id);

        final nume = data['nume']?.toString() ?? 'Locație turistică';
        final categorie = data['categorie']?.toString() ?? '';
        final oras = data['oras']?.toString() ?? '';
        final judet = data['judet']?.toString() ?? '';

        final imaginiRaw = data['imagini'];
        final imagini = imaginiRaw is List
            ? imaginiRaw
                  .map((imagine) => imagine.toString())
                  .where((imagine) => imagine.isNotEmpty)
                  .toList()
            : <String>[];

        final zona = [
          oras,
          judet,
        ].where((element) => element.isNotEmpty).join(', ');

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imagini.isNotEmpty
                  ? Image.network(
                      imagini.first,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) {
                        return const SizedBox(
                          width: 55,
                          height: 55,
                          child: Icon(Icons.place_outlined),
                        );
                      },
                    )
                  : const SizedBox(
                      width: 55,
                      height: 55,
                      child: Icon(Icons.place_outlined),
                    ),
            ),
            title: Text(
              nume,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              [
                categorie,
                zona,
              ].where((element) => element.isNotEmpty).join(' • '),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LocationDetailsPage(locatie: locatie),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _mesajEroare() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _eroare!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Închide',
            onPressed: () {
              setState(() {
                _eroare = null;
              });
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _zonaIntroducereMesaj() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _mesajController,
              enabled: !_seTrimite,
              minLines: 1,
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Întreabă ceva despre călătorii...',
                prefixIcon: Icon(Icons.travel_explore),
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onSubmitted: (_) {
                if (!_seTrimite) {
                  _trimiteMesaj();
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'Trimite',
            onPressed: _seTrimite ? null : () => _trimiteMesaj(),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
