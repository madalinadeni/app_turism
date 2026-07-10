import 'package:flutter/material.dart';
import '../../sabloane/locatie_sablon.dart';
import '../../service/locatie_service.dart';
import '../location_details_page.dart';

class FavoritesTab extends StatelessWidget {
  FavoritesTab({super.key});

  final LocatieService _service = LocatieService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SablonLocatie>>(
      stream: _service.favoriteLocationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Eroare: ${snapshot.error}'));
        }

        final locatii = snapshot.data ?? [];

        if (locatii.isEmpty) {
          return const Center(child: Text('Nu ai favorite încă.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: locatii.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final locatie = locatii[index];

            return ListTile(
              leading: locatie.imagini.isNotEmpty
                  ? Image.network(
                      locatie.imagini.first,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.place),
                    )
                  : const Icon(Icons.place),

              title: Text(locatie.nume),
              subtitle: Text(locatie.judet),

              trailing: IconButton(
                icon: Icon(Icons.favorite, color: Colors.red.shade400),
                onPressed: () async {
                  await _service.removeFavorite(locatie.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${locatie.nume} a fost eliminată din favorite.',
                        ),
                      ),
                    );
                  }
                },
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LocationDetailsPage(locatie: locatie),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
