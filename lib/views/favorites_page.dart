import 'package:flutter/material.dart';
import '../service/locatie_service.dart';
import '../sabloane/locatie_sablon.dart';
import 'location_details_page.dart';

class FavoritesPage extends StatelessWidget {
  FavoritesPage({super.key});

  final LocatieService _locatieService = LocatieService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritele mele')),
      body: FutureBuilder<List<SablonLocatie>>(
        future: _locatieService.getFavoriteLocations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Eroare: ${snapshot.error}'));
          }

          final locatii = snapshot.data ?? [];

          if (locatii.isEmpty) {
            return const Center(child: Text('Nu ai locații favorite încă ❤️'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: locatii.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final locatie = locatii[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: locatie.imagini.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            locatie.imagini.first,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.place, size: 40),

                  title: Text(locatie.nume),

                  subtitle: Text('${locatie.oras}, ${locatie.judet}'),

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
