import 'package:flutter/material.dart';
import '../sabloane/planner_sablon.dart';
import '../service/planner_service.dart';
import 'create_planner_page.dart';
import 'planner_details_page.dart';
import 'generator_itinerar_ai_page.dart';

class PlannerPage extends StatelessWidget {
  PlannerPage({super.key});

  final PlannerService _plannerService = PlannerService();

  String formatDate(DateTime date) {
    final zi = date.day.toString().padLeft(2, '0');
    final luna = date.month.toString().padLeft(2, '0');
    final an = date.year.toString();

    return '$zi.$luna.$an';
  }

  int durataZile(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planificările mele')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'generator_itinerar_ai',
            tooltip: 'Generează itinerar cu AI',
            onPressed: () async {
              final salvat = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const GeneratorItinerarAiPage(),
                ),
              );

              if (salvat == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Planificarea AI a fost adăugată.'),
                  ),
                );
              }
            },
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'creare_itinerar_manual',
            tooltip: 'Creează itinerar manual',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePlannerPage()),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<List<PlannerSablon>>(
        stream: _plannerService.getMyPlanners(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Eroare: ${snapshot.error}'));
          }

          final planners = snapshot.data ?? [];

          if (planners.isEmpty) {
            return const Center(child: Text('Nu ai nicio planificare încă.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: planners.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final planner = planners[index];

              return Card(
                elevation: 4,
                child: ListTile(
                  leading: const Icon(
                    Icons.event_note,
                    color: Colors.blueAccent,
                  ),
                  title: Text(planner.titlu),
                  subtitle: Text(
                    '${formatDate(planner.dataInceput)} - ${formatDate(planner.dataFinal)}\n'
                    '${durataZile(planner.dataInceput, planner.dataFinal)} zile • '
                    '${planner.locatii.length} locații',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Ștergere itinerar'),
                          content: const Text(
                            'Sigur dorești să ștergi această planificare?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Anulează'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Șterge'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _plannerService.deletePlanner(planner.id);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Planificarea a fost ștearsă.'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlannerDetailsPage(planner: planner),
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
