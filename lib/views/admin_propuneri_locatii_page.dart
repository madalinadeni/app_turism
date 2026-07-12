import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../service/locatie_service.dart';
import '../service/rol_service.dart';
import 'admin_propunere_locatie_detalii_page.dart';

class AdminPropuneriLocatiiPage extends StatefulWidget {
  const AdminPropuneriLocatiiPage({super.key});

  @override
  State<AdminPropuneriLocatiiPage> createState() =>
      _AdminPropuneriLocatiiPageState();
}

class _AdminPropuneriLocatiiPageState extends State<AdminPropuneriLocatiiPage> {
  final LocatieService _locatieService = LocatieService();
  final RolService _rolService = RolService();

  String _formateazaData(dynamic valoare) {
    if (valoare is! Timestamp) {
      return 'Dată necunoscută';
    }

    final data = valoare.toDate();

    final zi = data.day.toString().padLeft(2, '0');
    final luna = data.month.toString().padLeft(2, '0');
    final an = data.year.toString();

    final ora = data.hour.toString().padLeft(2, '0');
    final minut = data.minute.toString().padLeft(2, '0');

    return '$zi.$luna.$an • $ora:$minut';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _rolService.esteAdmin(),
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (roleSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Propuneri locații')),
            body: Center(
              child: Text(
                'Rolul utilizatorului nu a putut fi verificat: '
                '${roleSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final esteAdmin = roleSnapshot.data ?? false;

        if (!esteAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Acces restricționat')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nu ai permisiunea să accesezi această pagină.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Propuneri locații')),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _locatieService.getPropuneriInAsteptare(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Propunerile nu au putut fi încărcate: '
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final propuneri = snapshot.data ?? [];

              if (propuneri.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 72,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nu există propuneri în așteptare.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: propuneri.length,
                itemBuilder: (context, index) {
                  final propunere = propuneri[index];

                  final nume =
                      propunere['nume']?.toString() ?? 'Locație fără nume';

                  final oras = propunere['oras']?.toString() ?? '';
                  final judet = propunere['judet']?.toString() ?? '';
                  final categorie =
                      propunere['categorie']?.toString() ?? 'Necunoscută';

                  final imagini = List<String>.from(
                    propunere['imagini'] ?? const [],
                  );

                  final creatorId =
                      propunere['creatorId']?.toString() ?? 'Necunoscut';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminPropunereLocatieDetaliiPage(
                              propunere: propunere,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imagini.isNotEmpty)
                            Image.network(
                              imagini.first,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }

                                    return const SizedBox(
                                      height: 180,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  width: double.infinity,
                                  height: 180,
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 60,
                                  ),
                                );
                              },
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 180,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_outlined, size: 60),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nume,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        [oras, judet]
                                            .where(
                                              (element) =>
                                                  element.trim().isNotEmpty,
                                            )
                                            .join(', '),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.category_outlined,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(categorie),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_outlined,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formateazaData(propunere['trimisaLa']),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Creator: $creatorId',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Verifică propunerea',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
