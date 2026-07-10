import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CertificatePage extends StatelessWidget {
  const CertificatePage({super.key});

  String formatDate(DateTime date) {
    final zi = date.day.toString().padLeft(2, '0');
    final luna = date.month.toString().padLeft(2, '0');
    final an = date.year.toString();

    return '$zi.$luna.$an';
  }

  Future<void> exportCertificatePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final nume =
        (data['nume'] != null && data['nume'].toString().trim().isNotEmpty)
        ? data['nume']
        : FirebaseAuth.instance.currentUser?.displayName ??
              FirebaseAuth.instance.currentUser?.email ??
              'Utilizator';
    final puncte = data['puncte'] ?? 0;
    final nivel = data['nivel'] ?? 1;
    final titlu = data['titlu'] ?? 'Explorator Începător';
    final badge = data['badge'] ?? '🌱';
    final dataEmitere = formatDate(DateTime.now());

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(36),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 4)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'TOURMATE',
                  style: pw.TextStyle(
                    fontSize: 30,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 20),

                pw.Text(
                  'CERTIFICAT OFICIAL DE EXPLORATOR',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 30),

                pw.Text(
                  'Acest certificat confirmă că',
                  style: const pw.TextStyle(fontSize: 16),
                ),

                pw.SizedBox(height: 12),

                pw.Text(
                  nume.toString().toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 20),

                pw.Text(
                  'a demonstrat implicare în explorarea atracțiilor turistice din România prin aplicația TourMate.',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 15),
                ),

                pw.SizedBox(height: 30),

                pw.Divider(),

                pw.SizedBox(height: 20),

                pw.Text(
                  'Titlu obținut',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '$badge $titlu',
                  style: const pw.TextStyle(fontSize: 20),
                ),

                pw.SizedBox(height: 18),

                pw.Text(
                  'Nivel',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('$nivel', style: const pw.TextStyle(fontSize: 18)),

                pw.SizedBox(height: 18),

                pw.Text(
                  'Puncte acumulate',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '$puncte puncte',
                  style: const pw.TextStyle(fontSize: 18),
                ),

                pw.SizedBox(height: 18),

                pw.Text(
                  'Data emiterii',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(dataEmitere, style: const pw.TextStyle(fontSize: 16)),

                pw.Spacer(),

                pw.Divider(),

                pw.SizedBox(height: 12),

                pw.Text(
                  'Generat automat de TourMate',
                  style: const pw.TextStyle(fontSize: 12),
                ),

                pw.SizedBox(height: 20),

                pw.Text(
                  'Semnătura TourMate',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Certificatul meu')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('utilizatori')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final nume =
              (data['nume'] != null &&
                  data['nume'].toString().trim().isNotEmpty)
              ? data['nume']
              : FirebaseAuth.instance.currentUser?.displayName ??
                    FirebaseAuth.instance.currentUser?.email ??
                    'Utilizator';
          final puncte = data['puncte'] ?? 0;
          final nivel = data['nivel'] ?? 1;
          final titlu = data['titlu'] ?? 'Explorator Începător';
          final badge = data['badge'] ?? '🌱';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Colors.amber, width: 3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 56)),

                        const SizedBox(height: 12),

                        const Text(
                          'TOURMATE',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'CERTIFICAT OFICIAL\nDE EXPLORATOR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Acest certificat confirmă că',
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          nume.toString().toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'a demonstrat implicare în explorarea atracțiilor turistice din România prin aplicația TourMate.',
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        const Divider(),

                        const SizedBox(height: 16),

                        Text(
                          '$badge $titlu',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text('Nivel $nivel'),

                        const SizedBox(height: 8),

                        Text('$puncte puncte acumulate'),

                        const SizedBox(height: 16),

                        Text('Data emiterii: ${formatDate(DateTime.now())}'),

                        const SizedBox(height: 24),

                        const Divider(),

                        const SizedBox(height: 12),

                        const Text(
                          'Semnătura TourMate',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => exportCertificatePdf(data),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportă certificatul PDF'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
