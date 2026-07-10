import 'package:flutter/material.dart';
import '../sabloane/locatie_sablon.dart';
import '../service/locatie_service.dart';
import 'location_details_page.dart';

class TopLocationsPage extends StatelessWidget {
  TopLocationsPage({super.key});

  final LocatieService _locatieService = LocatieService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top 10 atracții turistice')),
      body: FutureBuilder<List<SablonLocatie>>(
        future: _locatieService.getTopRatedLocations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Eroare: ${snapshot.error}'));
          }

          final locatii = snapshot.data ?? [];

          if (locatii.isEmpty) {
            return const Center(child: Text('Nu există locații disponibile.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: locatii.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final locatie = locatii[index];

              return Card(
                elevation: 4,
                child: ListTile(
                  leading: locatie.imagini.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            locatie.imagini.first,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.place),
                          ),
                        )
                      : const Icon(Icons.place, size: 40),

                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: index == 0
                            ? Colors.amber
                            : index == 1
                            ? Colors.grey
                            : index == 2
                            ? Colors.brown
                            : Colors.blueAccent,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(locatie.nume)),
                    ],
                  ),
                  subtitle: Text(
                    '${locatie.oras}, ${locatie.judet}\n'
                    '⭐ ${locatie.rating.toStringAsFixed(1)} • ${locatie.nrRecenzii} recenzii',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
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
        },
      ),
    );
  }
}
