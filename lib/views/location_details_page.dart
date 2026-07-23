import 'package:flutter/material.dart';
import '../sabloane/locatie_sablon.dart';
import 'edit_location_page.dart';
import '../service/locatie_service.dart';
import '../service/recenzie_service.dart';
import '../sabloane/recenzie_sablon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/rol_service.dart';

class LocationDetailsPage extends StatefulWidget {
  final SablonLocatie locatie;

  const LocationDetailsPage({super.key, required this.locatie});

  @override
  State<LocationDetailsPage> createState() => _LocationDetailsPageState();
}

class _LocationDetailsPageState extends State<LocationDetailsPage> {
  bool esteFavorita = false;
  final _reviewController = TextEditingController();
  double _rating = 5;
  final RecenzieService _recenzieService = RecenzieService();
  final RolService _rolService = RolService();
  int _currentImageIndex = 0;
  @override
  void initState() {
    super.initState();
    verificaFavorita();
  }

  Future<void> verificaFavorita() async {
    final favorita = await LocatieService().isFavorite(widget.locatie.id);

    if (!mounted) return;

    setState(() {
      esteFavorita = favorita;
    });
  }

  Future<void> toggleFavorita() async {
    if (esteFavorita) {
      await LocatieService().removeFavorite(widget.locatie.id);
    } else {
      await LocatieService().addFavorite(widget.locatie.id);
    }

    if (!mounted) return;

    setState(() {
      esteFavorita = !esteFavorita;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esteFavorita ? 'Adăugat la favorite ❤️' : 'Eliminat din favorite 💔',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> addReview() async {
    if (_reviewController.text.trim().isEmpty) return;

    final nume = await getUserName();

    try {
      await _recenzieService.addReview(
        locatieId: widget.locatie.id,
        comentariu: _reviewController.text.trim(),
        rating: _rating,
        numeUtilizator: nume,
      );

      _reviewController.clear();

      final locatieActualizata = await LocatieService().getLocatie(
        widget.locatie.id,
      );

      if (!mounted) return;

      if (locatieActualizata != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LocationDetailsPage(locatie: locatieActualizata),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Recenzie adăugată ⭐")));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<String> getUserName() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('utilizatori')
        .doc(uid)
        .get();

    if (!doc.exists) {
      return "Utilizator";
    }

    final nume = doc.data()?['nume'];

    if (nume == null || nume.toString().trim().isEmpty) {
      return "Utilizator";
    }

    return nume;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    final zi = date.day.toString().padLeft(2, '0');
    final luna = date.month.toString().padLeft(2, '0');
    final an = date.year.toString();

    final ora = date.hour.toString().padLeft(2, '0');
    final minut = date.minute.toString().padLeft(2, '0');

    return '$zi.$luna.$an • $ora:$minut';
  }

  Widget buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;

        IconData icon;

        if (rating >= starValue) {
          icon = Icons.star;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }

        return Icon(icon, color: Colors.amber, size: 18);
      }),
    );
  }

  Future<void> editReview(SablonRecenzie recenzie) async {
    final controller = TextEditingController(text: recenzie.comentariu);
    double editRating = recenzie.rating;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Editează recenzia'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rating: ${editRating.toStringAsFixed(1)} ⭐'),
                    Slider(
                      value: editRating,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: editRating.toStringAsFixed(1),
                      onChanged: (value) {
                        setDialogState(() {
                          editRating = value;
                        });
                      },
                    ),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Modifică recenzia...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Anulează'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Salvează'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      await _recenzieService.updateReview(
        widget.locatie.id,
        recenzie.id,
        comentariu: controller.text.trim(),
        rating: editRating,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recenzia a fost actualizată.')),
      );
    }

    controller.dispose();
  }

  Future<void> _stergeLocatia() async {
    final esteAdmin = await _rolService.esteAdmin();

    if (!mounted) return;

    if (!esteAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu ai permisiunea să ștergi locații.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ștergere locație'),
        content: const Text('Sigur dorești să ștergi această locație?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await LocatieService().deleteLocatie(widget.locatie.id);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Locația nu a putut fi ștearsă: '
            '${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.locatie.nume),
        actions: [
          IconButton(
            tooltip: esteFavorita
                ? 'Elimină din favorite'
                : 'Adaugă la favorite',
            icon: Icon(
              esteFavorita ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: toggleFavorita,
          ),

          StreamBuilder<bool>(
            stream: _rolService.urmaresteRolAdmin(),
            initialData: false,
            builder: (context, snapshot) {
              final esteAdmin = snapshot.data ?? false;

              if (!esteAdmin) {
                return const SizedBox.shrink();
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editează locația',
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final esteIncaAdmin = await _rolService.esteAdmin();

                      if (!context.mounted) return;

                      if (!esteIncaAdmin) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Nu ai permisiunea să editezi locații.',
                            ),
                          ),
                        );
                        return;
                      }

                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditLocationPage(locatie: widget.locatie),
                        ),
                      );

                      if (updated == true && context.mounted) {
                        final locatieActualizata = await LocatieService()
                            .getLocatie(widget.locatie.id);

                        if (!context.mounted) return;

                        if (locatieActualizata != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationDetailsPage(
                                locatie: locatieActualizata,
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),

                  IconButton(
                    tooltip: 'Șterge locația',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _stergeLocatia,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagine principală
            if (widget.locatie.imagini.isNotEmpty)
              SizedBox(
                height: 250,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    PageView.builder(
                      itemCount: widget.locatie.imagini.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          widget.locatie.imagini[index],
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 80,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    if (widget.locatie.imagini.length > 1)
                      Positioned(
                        bottom: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.locatie.imagini.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentImageIndex == index ? 10 : 8,
                              height: _currentImageIndex == index ? 10 : 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Container(
                height: 250,
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 80),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.locatie.nume,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 5),
                      Text('${widget.locatie.oras}, ${widget.locatie.judet}'),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 5),
                      Text(
                        '${widget.locatie.rating} (${widget.locatie.nrRecenzii} recenzii)',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Categorie: ${widget.locatie.categorie}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text('Program: ${widget.locatie.orar}'),

                  const SizedBox(height: 10),

                  Text(
                    'Preț: ${widget.locatie.pretMin} - ${widget.locatie.pretMax} lei',
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Descriere',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text(widget.locatie.descriere),

                  const SizedBox(height: 20),

                  const Text(
                    'Facilități',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.locatie.facilitati
                        .map((facilitate) => Chip(label: Text(facilitate)))
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Coordonate',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text('Latitudine: ${widget.locatie.latitudine}'),

                  Text('Longitudine: ${widget.locatie.longitudine}'),

                  const SizedBox(height: 30),

                  const Text(
                    "Scrie o recenzie",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  Text("Rating: ${_rating.toStringAsFixed(1)} ⭐"),

                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                  ),

                  TextField(
                    controller: _reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Scrie experiența ta...",
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: addReview,
                      child: const Text("Trimite recenzia"),
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    "Recenzii",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  StreamBuilder<List<SablonRecenzie>>(
                    stream: _recenzieService.getReviews(widget.locatie.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Text('Eroare: ${snapshot.error}');
                      }

                      final recenzii = snapshot.data ?? [];

                      if (recenzii.isEmpty) {
                        return const Text('Nu există recenzii încă.');
                      }

                      final currentUserId =
                          FirebaseAuth.instance.currentUser!.uid;

                      return Column(
                        children: recenzii.map((recenzie) {
                          final isMyReview = recenzie.userId == currentUserId;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.blueAccent,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildStars(recenzie.rating),
                                  const SizedBox(height: 4),
                                  Text(
                                    recenzie.numeUtilizator,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(recenzie.comentariu),
                                  const SizedBox(height: 6),
                                  Text(
                                    formatDate(recenzie.data),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isMyReview
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            editReview(recenzie);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            await _recenzieService.deleteReview(
                                              widget.locatie.id,
                                              recenzie.id,
                                            );

                                            if (!mounted) return;

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Recenzia a fost ștearsă.',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
