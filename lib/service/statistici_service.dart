import 'package:cloud_firestore/cloud_firestore.dart';
import '../sabloane/statistici_sablon.dart';

class StatisticiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<StatisticiSablon> getStatistici() async {
    final locatiiSnapshot = await _db.collection('locatii').get();

    int totalLocatii = locatiiSnapshot.docs.length;
    int totalRecenzii = 0;

    double sumaRatingPonderata = 0;

    final Map<String, int> locatiiPeCategorie = {};
    final Map<String, double> sumaRatingPeJudet = {};
    final Map<String, int> recenziiPeJudet = {};

    for (final document in locatiiSnapshot.docs) {
      final data = document.data();

      final categorie = _citesteText(
        data['categorie'],
        valoareImplicita: 'Necunoscută',
      );

      final judet = _citesteText(data['judet'], valoareImplicita: 'Necunoscut');

      final rating = _citesteDouble(data['rating']);
      final nrRecenzii = _citesteInt(data['nrRecenzii']);

      // Numărul locațiilor din fiecare categorie
      locatiiPeCategorie[categorie] = (locatiiPeCategorie[categorie] ?? 0) + 1;

      // Numărul total de recenzii
      totalRecenzii += nrRecenzii;

      // Rating ponderat după numărul de recenzii
      if (nrRecenzii > 0) {
        sumaRatingPonderata += rating * nrRecenzii;

        sumaRatingPeJudet[judet] =
            (sumaRatingPeJudet[judet] ?? 0) + rating * nrRecenzii;

        recenziiPeJudet[judet] = (recenziiPeJudet[judet] ?? 0) + nrRecenzii;
      }
    }

    final ratingMediu = totalRecenzii == 0
        ? 0.0
        : sumaRatingPonderata / totalRecenzii;

    final Map<String, double> ratingMediuPeJudet = {};

    for (final entry in sumaRatingPeJudet.entries) {
      final nrRecenziiJudet = recenziiPeJudet[entry.key] ?? 0;

      ratingMediuPeJudet[entry.key] = nrRecenziiJudet == 0
          ? 0.0
          : entry.value / nrRecenziiJudet;
    }

    return StatisticiSablon(
      totalLocatii: totalLocatii,
      totalRecenzii: totalRecenzii,
      ratingMediu: ratingMediu,
      locatiiPeCategorie: locatiiPeCategorie,
      ratingMediuPeJudet: ratingMediuPeJudet,
      recenziiPeJudet: recenziiPeJudet,
    );
  }

  String _citesteText(dynamic valoare, {required String valoareImplicita}) {
    if (valoare == null || valoare.toString().trim().isEmpty) {
      return valoareImplicita;
    }

    return valoare.toString().trim();
  }

  int _citesteInt(dynamic valoare) {
    if (valoare is int) {
      return valoare;
    }

    if (valoare is num) {
      return valoare.toInt();
    }

    return int.tryParse(valoare?.toString() ?? '') ?? 0;
  }

  double _citesteDouble(dynamic valoare) {
    if (valoare is num) {
      return valoare.toDouble();
    }

    return double.tryParse(valoare?.toString() ?? '') ?? 0.0;
  }
}
