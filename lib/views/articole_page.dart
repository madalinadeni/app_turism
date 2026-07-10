import 'package:flutter/material.dart';

import '../sabloane/articol_sablon.dart';
import '../service/articol_service.dart';
import 'add_edit_articol_page.dart';

class ArticolePage extends StatefulWidget {
  const ArticolePage({super.key});

  @override
  State<ArticolePage> createState() => _ArticolePageState();
}

class _ArticolePageState extends State<ArticolePage> {
  final ArticolService _articolService = ArticolService();

  final List<String> _categorii = const [
    'Toate',
    'Trasee montane',
    'Gastronomie',
    'Tradiții',
    'Festivaluri',
    'Sfaturi de călătorie',
  ];

  String _categorieSelectata = 'Toate';

  String _formatDate(DateTime date) {
    final zi = date.day.toString().padLeft(2, '0');
    final luna = date.month.toString().padLeft(2, '0');
    final an = date.year.toString();

    return '$zi.$luna.$an';
  }

  List<SablonArticol> _filtreazaArticole(List<SablonArticol> articole) {
    if (_categorieSelectata == 'Toate') {
      return articole;
    }

    return articole
        .where((articol) => articol.categorie == _categorieSelectata)
        .toList();
  }

  void _afiseazaPrevizualizare(SablonArticol articol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (articol.imagine.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        articol.imagine,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return Container(
                            height: 220,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) {
                          return _imagineImplicita(height: 220);
                        },
                      ),
                    )
                  else
                    _imagineImplicita(height: 220),

                  const SizedBox(height: 20),

                  Text(
                    articol.categorie,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    articol.titlu,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: 5),
                      Expanded(child: Text(articol.autor)),
                      const Icon(Icons.calendar_today_outlined, size: 17),
                      const SizedBox(width: 5),
                      Text(_formatDate(articol.dataPublicarii)),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Text(
                    articol.continut,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _imagineImplicita({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.article_outlined,
        size: 70,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _categorieChips() {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categorii.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final categorie = _categorii[index];

          return ChoiceChip(
            label: Text(categorie),
            selected: _categorieSelectata == categorie,
            onSelected: (_) {
              setState(() {
                _categorieSelectata = categorie;
              });
            },
          );
        },
      ),
    );
  }

  Widget _articolCard(SablonArticol articol) {
    return Card(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _afiseazaPrevizualizare(articol);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (articol.imagine.isNotEmpty)
              Image.network(
                articol.imagine,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return Container(
                    height: 190,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) {
                  return _imagineImplicita(height: 190);
                },
              )
            else
              _imagineImplicita(height: 190),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          articol.categorie,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Opțiuni',
                        onSelected: (value) async {
                          if (value == 'editare') {
                            final rezultat = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddEditArticolPage(articol: articol),
                              ),
                            );

                            if (rezultat == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Articolul a fost actualizat.'),
                                ),
                              );
                            }
                          }

                          if (value == 'stergere') {
                            await _stergeArticol(articol);
                          }
                        },
                        itemBuilder: (context) {
                          return const [
                            PopupMenuItem<String>(
                              value: 'editare',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined),
                                  SizedBox(width: 10),
                                  Text('Editează'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'stergere',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text('Șterge'),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Text(
                    articol.titlu,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    articol.continut,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 17),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          articol.autor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(_formatDate(articol.dataPublicarii)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.article_outlined, size: 90, color: Colors.grey.shade400),
        const SizedBox(height: 20),
        const Text(
          'Nu există articole în această categorie.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Articolele publicate vor apărea aici.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Future<void> _stergeArticol(SablonArticol articol) async {
    final confirmare = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ștergere articol'),
          content: Text(
            'Sigur dorești să ștergi articolul „${articol.titlu}”?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Șterge'),
            ),
          ],
        );
      },
    );

    if (confirmare != true) {
      return;
    }

    try {
      await _articolService.deleteArticol(articol.id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Articolul a fost șters.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Articolul nu a putut fi șters: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blog turistic')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final rezultat = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditArticolPage()),
          );

          if (rezultat == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Articolul a fost publicat.')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Articol nou'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          _categorieChips(),

          const SizedBox(height: 14),

          Expanded(
            child: StreamBuilder<List<SablonArticol>>(
              stream: _articolService.getArticole(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Articolele nu au putut fi încărcate.\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final toateArticolele = snapshot.data ?? <SablonArticol>[];

                final articoleFiltrate = _filtreazaArticole(toateArticolele);

                if (articoleFiltrate.isEmpty) {
                  return _emptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: articoleFiltrate.length,
                  itemBuilder: (context, index) {
                    return _articolCard(articoleFiltrate[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
