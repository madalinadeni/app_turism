import 'package:flutter/material.dart';
import '../sabloane/planner_sablon.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'edit_planner_page.dart';
import '../service/planner_service.dart';
import '../service/locatie_service.dart';

class PlannerDetailsPage extends StatelessWidget {
  final PlannerSablon planner;

  const PlannerDetailsPage({super.key, required this.planner});

  String formatDate(DateTime date) {
    final zi = date.day.toString().padLeft(2, '0');
    final luna = date.month.toString().padLeft(2, '0');
    final an = date.year.toString();

    return '$zi.$luna.$an';
  }

  int durataZile(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  Future<void> exportPdf() async {
    final pdf = pw.Document();

    final generatedAt = DateTime.now();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'TourMate',
                        style: pw.TextStyle(
                          fontSize: 30,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'ITINERAR DE VACANȚĂ',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                pw.Divider(),

                pw.SizedBox(height: 16),

                pw.Text(
                  'Titlu',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(planner.titlu, style: const pw.TextStyle(fontSize: 16)),

                pw.SizedBox(height: 14),

                pw.Text(
                  'Perioadă',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${formatDate(planner.dataInceput)} - ${formatDate(planner.dataFinal)}',
                ),

                pw.SizedBox(height: 14),

                pw.Text(
                  'Durată',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${durataZile(planner.dataInceput, planner.dataFinal)} zile',
                ),

                pw.SizedBox(height: 14),

                pw.Text(
                  'Număr locații',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('${planner.locatii.length} locații'),

                pw.SizedBox(height: 24),

                pw.Divider(),

                pw.SizedBox(height: 16),

                pw.Text(
                  'Locații incluse',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 12),

                if (planner.locatii.isEmpty)
                  pw.Text('Nu există locații adăugate.')
                else
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(35),
                      1: const pw.FlexColumnWidth(),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '#',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Locație',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...planner.locatii.asMap().entries.map((entry) {
                        final index = entry.key;
                        final locatie = entry.value;

                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('${index + 1}'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(locatie['titlu'] ?? 'Locație'),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),

                pw.Spacer(),

                pw.Divider(),

                pw.Center(
                  child: pw.Text(
                    'Generat automat cu TourMate • ${formatDate(generatedAt)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> addLocationDialog(BuildContext context) async {
    final locatieService = LocatieService();
    final plannerService = PlannerService();

    final allLocations = await locatieService.getAllLocatii();

    final selectedIds = planner.locatii
        .map((locatie) => locatie['uid'].toString())
        .toSet();

    final availableLocations = allLocations
        .where((locatie) => !selectedIds.contains(locatie.id))
        .toList();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: availableLocations.isEmpty
              ? const Center(
                  child: Text('Toate locațiile sunt deja în itinerar.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableLocations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final locatie = availableLocations[index];

                    return Card(
                      child: ListTile(
                        leading: locatie.imagini.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  locatie.imagini.first,
                                  width: 55,
                                  height: 55,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.place),
                                ),
                              )
                            : const Icon(Icons.place),
                        title: Text(locatie.nume),
                        subtitle: Text('${locatie.oras}, ${locatie.judet}'),
                        trailing: const Icon(Icons.add),
                        onTap: () async {
                          await plannerService.addLocationToPlanner(
                            plannerId: planner.id,
                            locatieId: locatie.id,
                            titlu: locatie.nume,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(planner.titlu),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            onPressed: () {
              addLocationDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditPlannerPage(planner: planner),
                ),
              );

              if (updated == true && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: exportPdf,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              planner.titlu,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              'Perioadă: ${formatDate(planner.dataInceput)} - ${formatDate(planner.dataFinal)}',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            Text(
              'Durată: ${durataZile(planner.dataInceput, planner.dataFinal)} zile',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 6),

            Text(
              'Număr locații: ${planner.locatii.length}',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            const Text(
              'Locații incluse',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            if (planner.locatii.isEmpty)
              const Text('Nu există locații adăugate.')
            else
              ...planner.locatii.asMap().entries.map((entry) {
                final index = entry.key;
                final locatie = entry.value;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(locatie['titlu'] ?? 'Locație'),
                    subtitle: Text('ID: ${locatie['uid'] ?? ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await PlannerService().removeLocationFromPlanner(
                          plannerId: planner.id,
                          locatieId: locatie['uid'] ?? '',
                          titlu: locatie['titlu'] ?? '',
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
