import 'package:flutter/material.dart';
import '../top_locations_page.dart';
import '../map_page.dart';
import '../planner_page.dart';
import '../articole_page.dart';
import '../statistici_page.dart';
import '../ai_test_page.dart';
import 'package:app_turism/service/recomandari_service.dart';
import '../location_details_page.dart';
import '../chat_turistic_page.dart';
import 'notificari_buton.dart';
import 'package:app_turism/service/fcm_service.dart';

class HomePageTab extends StatefulWidget {
  const HomePageTab({super.key});

  @override
  State<HomePageTab> createState() => _HomePageTabState();
}

class _HomePageTabState extends State<HomePageTab> {
  final TextEditingController _searchController = TextEditingController();

  Future<void> _deschideCautareaInteligenta() async {
    final text = _searchController.text.trim();

    if (text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introdu o căutare de minimum 3 caractere.'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AiTestPage(initialText: text)),
    );

    if (!mounted) return;

    _searchController.clear();
    _reincarcaRecomandari();
  }

  Future<void> _deschideChatTuristic() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatTuristicPage()),
    );
  }

  final RecomandariService _recomandariService = RecomandariService();

  late Future<List<RecomandareLocatie>> _recomandariFuture;

  @override
  void initState() {
    super.initState();

    _recomandariFuture = _recomandariService.getRecomandari();
    FcmService().initializeaza();
  }

  void _reincarcaRecomandari() {
    setState(() {
      _recomandariFuture = _recomandariService.getRecomandari();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _recomandariSection() {
    return FutureBuilder<List<RecomandareLocatie>>(
      future: _recomandariFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 38),
                  const SizedBox(height: 8),
                  const Text(
                    'Recomandările nu au putut fi încărcate.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _reincarcaRecomandari,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Încearcă din nou'),
                  ),
                ],
              ),
            ),
          );
        }

        final recomandari = snapshot.data ?? <RecomandareLocatie>[];

        if (recomandari.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 45,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nu există încă suficiente locații pentru recomandări.',
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recomandări pentru tine',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizează recomandările',
                  onPressed: _reincarcaRecomandari,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 315,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recomandari.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 14);
                },
                itemBuilder: (context, index) {
                  final recomandare = recomandari[index];
                  final locatie = recomandare.locatie;

                  return SizedBox(
                    width: 235,
                    child: Card(
                      elevation: 4,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LocationDetailsPage(locatie: locatie),
                            ),
                          );

                          if (mounted) {
                            _reincarcaRecomandari();
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 125,
                              child: locatie.imagini.isNotEmpty
                                  ? Image.network(
                                      locatie.imagini.first,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.high,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return _imagineRecomandare();
                                          },
                                    )
                                  : _imagineRecomandare(),
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

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            '${locatie.oras}, '
                                            '${locatie.judet}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 18,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          locatie.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(' (${locatie.nrRecenzii})'),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Expanded(
                                      child: Text(
                                        recomandare.motiv,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Vezi detalii',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _imagineRecomandare() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 50,
        color: Colors.grey.shade500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'TourMate',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
            const NotificariButon(),
          ],
        ),

        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Ex: Vreau un castel aproape de Brașov',
            prefixIcon: const Icon(Icons.auto_awesome),
            suffixIcon: IconButton(
              tooltip: 'Caută cu AI',
              icon: const Icon(Icons.search),
              onPressed: _deschideCautareaInteligenta,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          onSubmitted: (_) {
            _deschideCautareaInteligenta();
          },
        ),
        const SizedBox(height: 16),

        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 36,
            ),
            title: const Text(
              'Top 10 atracții turistice',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Vezi cele mai apreciate locații după rating'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TopLocationsPage()),
              );
            },
          ),
        ),

        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.event_note,
              color: Colors.blueAccent,
              size: 36,
            ),
            title: const Text(
              'Planificările mele',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Creează și salvează itinerarii de vacanță'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlannerPage()),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _deschideChatTuristic,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    child: Icon(Icons.smart_toy_outlined, size: 28),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asistent turistic AI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Primește recomandări și răspunsuri despre locațiile din aplicație.',
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        _recomandariSection(),

        const SizedBox(height: 16),

        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.bar_chart)),
            title: const Text(
              'Statistici turistice',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Vezi grafice despre locații, recenzii și județe',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatisticsPage()),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.article_outlined)),
            title: const Text(
              'Blog turistic',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Trasee, gastronomie, tradiții și sfaturi de călătorie',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ArticolePage()),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapPage()),
            );
          },
          icon: const Icon(Icons.map),
          label: const Text('Vezi pe hartă'),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
