import 'package:flutter/material.dart';
import 'package:app_turism/sabloane/locatie_sablon.dart';
import 'package:app_turism/service/locatie_service.dart';
import 'package:app_turism/views/location_details_page.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final LocatieService _locatieService = LocatieService();

  Set<String> favoriteIds = {};

  String _searchText = '';

  String _selectedCategory = 'Toate';

  final List<String> categorii = [
    'Toate',

    'Castel',

    'Muzeu',

    'Mănăstire',

    'Parc',

    'Traseu',

    'Lac',
  ];

  @override
  void initState() {
    super.initState();

    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final ids = await _locatieService.getFavoriteIds();

    if (!mounted) return;

    setState(() {
      favoriteIds = ids.toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SablonLocatie>>(
      future: _locatieService.getAllLocatii(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Eroare: ${snapshot.error}'));
        }

        final locatii = snapshot.data ?? [];

        final filteredLocatii = locatii.where((locatie) {
          final matchesSearch = locatie.nume.toLowerCase().contains(
            _searchText.toLowerCase(),
          );

          final matchesCategory =
              _selectedCategory == 'Toate' ||
              locatie.categorie == _selectedCategory;

          return matchesSearch && matchesCategory;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),

              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Caută locații...',

                  prefixIcon: const Icon(Icons.search),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              ),
            ),

            SizedBox(
              height: 50,

              child: ListView.builder(
                scrollDirection: Axis.horizontal,

                itemCount: categorii.length,

                itemBuilder: (context, index) {
                  final categorie = categorii[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),

                    child: ChoiceChip(
                      label: Text(categorie),

                      selected: _selectedCategory == categorie,

                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = categorie;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: filteredLocatii.isEmpty
                  ? const Center(child: Text('Nu există rezultate.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),

                      itemCount: filteredLocatii.length,

                      separatorBuilder: (_, _) => const SizedBox(height: 16),

                      itemBuilder: (context, index) {
                        final locatie = filteredLocatii[index];

                        final isFavorite = favoriteIds.contains(locatie.id);

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),

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

                                      errorBuilder: (_, _, _) {
                                        return const Icon(
                                          Icons.place,

                                          size: 40,

                                          color: Colors.blueAccent,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.place,

                                    size: 40,

                                    color: Colors.blueAccent,
                                  ),

                            title: Text(locatie.nume),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LocationDetailsPage(locatie: locatie),
                                ),
                              );

                              await loadFavorites();

                              if (!mounted) return;

                              setState(() {});
                            },
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(locatie.judet),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,

                                      color: Colors.amber,

                                      size: 16,
                                    ),

                                    const SizedBox(width: 4),

                                    Text(locatie.rating.toStringAsFixed(1)),
                                  ],
                                ),
                              ],
                            ),

                            trailing: IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,

                                color: Colors.red,
                              ),

                              onPressed: () async {
                                try {
                                  if (isFavorite) {
                                    await _locatieService.removeFavorite(
                                      locatie.id,
                                    );
                                  } else {
                                    await _locatieService.addFavorite(
                                      locatie.id,
                                    );
                                  }

                                  if (!mounted) return;
                                  setState(() {
                                    if (isFavorite) {
                                      favoriteIds.remove(locatie.id);
                                    } else {
                                      favoriteIds.add(locatie.id);
                                    }
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isFavorite
                                            ? 'Eliminat din favorite 💔'
                                            : 'Adăugat la favorite ❤️',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Eroare: $e')),
                                  );
                                }
                              },
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
}
