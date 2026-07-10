import 'package:flutter/material.dart';
import '../sabloane/planner_sablon.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'edit_planner_page.dart';
import '../service/planner_service.dart';
import '../service/locatie_service.dart';
import '../sabloane/itinerar_ai_sablon.dart';

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

  String _formateazaNumar(double valoare) {
    if (valoare == valoare.roundToDouble()) {
      return valoare.toStringAsFixed(0);
    }

    return valoare.toStringAsFixed(2);
  }

  Widget _sectiuneItinerarAi(BuildContext context, ItinerarAi itinerar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Itinerar generat cu AI',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (itinerar.rezumat.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(itinerar.rezumat),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.location_on_outlined, size: 18),
                      label: Text(itinerar.zona),
                    ),
                    Chip(
                      avatar: const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                      ),
                      label: Text(
                        itinerar.numarZile == 1
                            ? '1 zi'
                            : '${itinerar.numarZile} zile',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.payments_outlined, size: 18),
                      label: Text(
                        '${_formateazaNumar(itinerar.bugetTotalEstimat)} lei',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...itinerar.zile.map((zi) => _cardZiAi(context, zi)),
        if (itinerar.sfaturi.isNotEmpty) ...[
          const SizedBox(height: 4),
          _cardSfaturiAi(itinerar.sfaturi),
        ],
      ],
    );
  }

  Widget _cardZiAi(BuildContext context, ZiItinerarAi zi) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(child: Text('${zi.zi}')),
        title: Text(
          zi.titlu.isEmpty ? 'Ziua ${zi.zi}' : zi.titlu,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${zi.activitati.length} '
          '${zi.activitati.length == 1 ? 'activitate' : 'activități'}',
        ),
        children: [
          if (zi.activitati.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nu există activități pentru această zi.'),
            )
          else
            ...zi.activitati.map(
              (activitate) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activitate.ora,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              activitate.numeLocatie,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (activitate.categorie.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          activitate.categorie,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (activitate.motiv.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(activitate.motiv),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_outlined, size: 18),
                              const SizedBox(width: 5),
                              Text(
                                '${_formateazaNumar(activitate.durataOre)} ore',
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.payments_outlined, size: 18),
                              const SizedBox(width: 5),
                              Text(
                                '${_formateazaNumar(activitate.costEstimat)} lei',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardSfaturiAi(List<String> sfaturi) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline),
                SizedBox(width: 8),
                Text(
                  'Sfaturi pentru excursie',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sfaturi.map(
              (sfat) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(sfat)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ItinerarAi? itinerarAi;

    final detaliiAi = planner.detaliiItinerarAi;

    if (planner.generatCuAi && detaliiAi != null) {
      itinerarAi = ItinerarAi.fromMap(detaliiAi);
    }

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

            if (itinerarAi != null) ...[
              _sectiuneItinerarAi(context, itinerarAi),
              const SizedBox(height: 25),
            ],

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
