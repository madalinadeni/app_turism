import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:app_turism/service/locatie_service.dart';

class PropunerileMelePage extends StatefulWidget {
  const PropunerileMelePage({super.key});

  @override
  State<PropunerileMelePage> createState() => _PropunerileMelePageState();
}

class _PropunerileMelePageState extends State<PropunerileMelePage> {
  final LocatieService _locatieService = LocatieService();

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

  String _statusText(String status) {
    switch (status) {
      case 'aprobata':
        return 'Aprobată';
      case 'respinsa':
        return 'Respinsă';
      case 'inAsteptare':
      default:
        return 'În așteptare';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'aprobata':
        return Colors.green;
      case 'respinsa':
        return Colors.red;
      case 'in asteptare':
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'aprobata':
        return Icons.check_circle;
      case 'respinsa':
        return Icons.cancel;
      case 'in asteptare':
      default:
        return Icons.hourglass_top;
    }
  }

  List<String> _imaginiDinPropunere(Map<String, dynamic> propunere) {
    final valoare = propunere['imagini'];

    if (valoare is! List) {
      return [];
    }

    return valoare
        .map((element) => element.toString())
        .where((element) => element.trim().isNotEmpty)
        .toList();
  }

  Widget _statusBadge(String status) {
    final culoare = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: culoare.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: culoare),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 16, color: culoare),
          const SizedBox(width: 6),
          Text(
            _statusText(status),
            style: TextStyle(color: culoare, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPropunereCard(Map<String, dynamic> propunere) {
    final nume = propunere['nume']?.toString() ?? 'Locație fără nume';
    final oras = propunere['oras']?.toString() ?? '';
    final judet = propunere['judet']?.toString() ?? '';
    final categorie = propunere['categorie']?.toString() ?? 'Necunoscută';
    final status = propunere['status']?.toString() ?? 'inAsteptare';
    final motivRespingere =
        propunere['motivRespingere']?.toString().trim() ?? '';

    final imagini = _imaginiDinPropunere(propunere);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagini.isNotEmpty)
            Image.network(
              imagini.first,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (_, __, ___) {
                return Container(
                  height: 180,
                  width: double.infinity,
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
              height: 180,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_outlined, size: 60),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusBadge(status),
                const SizedBox(height: 12),
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
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        [oras, judet]
                            .where((element) => element.trim().isNotEmpty)
                            .join(', '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.category_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(categorie),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(_formateazaData(propunere['trimisaLa'])),
                  ],
                ),
                if (status == 'aprobata') ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Locația ta a fost aprobată și publicată. Ai primit 20 de puncte.',
                    ),
                  ),
                ],
                if (status == 'respinsa') ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      motivRespingere.isEmpty
                          ? 'Propunerea a fost respinsă.'
                          : 'Motiv respingere: $motivRespingere',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Propunerile mele')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _locatieService.getPropunerileMele(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Propunerile nu au putut fi încărcate: ${snapshot.error}',
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
                      Icons.add_location_alt_outlined,
                      size: 72,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Nu ai trimis încă nicio propunere de locație.',
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
              return _buildPropunereCard(propuneri[index]);
            },
          );
        },
      ),
    );
  }
}
