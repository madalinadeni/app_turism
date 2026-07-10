import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../sabloane/locatie_sablon.dart';

class RecomandareLocatie {
  final SablonLocatie locatie;
  final double scor;
  final String motiv;

  const RecomandareLocatie({
    required this.locatie,
    required this.scor,
    required this.motiv,
  });
}

class RecomandariService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<RecomandareLocatie>> getRecomandari({int limita = 6}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Trebuie să fii autentificat pentru a primi recomandări.',
      );
    }

    final uid = user.uid;

    final locatiiSnapshot = await _db.collection('locatii').get();

    if (locatiiSnapshot.docs.isEmpty) {
      return [];
    }

    final locatii = <String, SablonLocatie>{};

    for (final document in locatiiSnapshot.docs) {
      locatii[document.id] = SablonLocatie.fromMap(
        document.data(),
        document.id,
      );
    }

    final categoriiPreferate = <String, double>{};
    final judetePreferate = <String, double>{};

    final favoriteIds = <String>{};
    final locatiiDinItinerarii = <String>{};
    final locatiiRecenzate = <String>{};

    await _analizeazaFavorite(
      uid: uid,
      locatii: locatii,
      favoriteIds: favoriteIds,
      categoriiPreferate: categoriiPreferate,
      judetePreferate: judetePreferate,
    );

    await _analizeazaRecenzii(
      uid: uid,
      locatiiSnapshot: locatiiSnapshot,
      locatii: locatii,
      locatiiRecenzate: locatiiRecenzate,
      categoriiPreferate: categoriiPreferate,
      judetePreferate: judetePreferate,
    );

    await _analizeazaItinerarii(
      uid: uid,
      locatii: locatii,
      locatiiDinItinerarii: locatiiDinItinerarii,
      categoriiPreferate: categoriiPreferate,
      judetePreferate: judetePreferate,
    );

    final recomandari = <RecomandareLocatie>[];

    for (final locatie in locatii.values) {
      // Nu recomandăm din nou locațiile deja favorite
      // sau deja adăugate într-un itinerar.
      if (favoriteIds.contains(locatie.id) ||
          locatiiDinItinerarii.contains(locatie.id)) {
        continue;
      }

      final categorieNormalizata = _normalizeaza(locatie.categorie);

      final judetNormalizat = _normalizeaza(locatie.judet);

      final scorCategorie = categoriiPreferate[categorieNormalizata] ?? 0;

      final scorJudet = judetePreferate[judetNormalizat] ?? 0;

      double scor = 0;

      // Preferințele utilizatorului au cea mai mare influență.
      scor += scorCategorie * 2;
      scor += scorJudet * 1.5;

      // Ratingul și numărul de recenzii ajută la departajare.
      scor += locatie.rating * 1.5;
      scor += _scorRecenzii(locatie.nrRecenzii);

      if (locatie.popular) {
        scor += 1.5;
      }

      // Evităm să recomandăm prea insistent locațiile
      // pe care utilizatorul le-a recenzat deja.
      if (locatiiRecenzate.contains(locatie.id)) {
        scor -= 2;
      }

      recomandari.add(
        RecomandareLocatie(
          locatie: locatie,
          scor: scor,
          motiv: _construiesteMotiv(
            locatie: locatie,
            scorCategorie: scorCategorie,
            scorJudet: scorJudet,
          ),
        ),
      );
    }

    recomandari.sort((a, b) {
      final comparatieScor = b.scor.compareTo(a.scor);

      if (comparatieScor != 0) {
        return comparatieScor;
      }

      return b.locatie.rating.compareTo(a.locatie.rating);
    });

    // Dacă toate locațiile au fost deja favorite sau planificate,
    // afișăm cele mai apreciate locații care nu sunt favorite.
    if (recomandari.isEmpty) {
      final fallback = locatii.values
          .where((locatie) => !favoriteIds.contains(locatie.id))
          .toList();

      fallback.sort((a, b) {
        final comparatieRating = b.rating.compareTo(a.rating);

        if (comparatieRating != 0) {
          return comparatieRating;
        }

        return b.nrRecenzii.compareTo(a.nrRecenzii);
      });

      return fallback.take(limita).map((locatie) {
        return RecomandareLocatie(
          locatie: locatie,
          scor: locatie.rating,
          motiv: 'Locație apreciată de comunitatea TourMate.',
        );
      }).toList();
    }

    return recomandari.take(limita).toList();
  }

  Future<void> _analizeazaFavorite({
    required String uid,
    required Map<String, SablonLocatie> locatii,
    required Set<String> favoriteIds,
    required Map<String, double> categoriiPreferate,
    required Map<String, double> judetePreferate,
  }) async {
    final snapshot = await _db
        .collection('utilizatori')
        .doc(uid)
        .collection('preferate')
        .get();

    for (final document in snapshot.docs) {
      final data = document.data();

      final locatieId = data['locatieId']?.toString() ?? document.id;

      favoriteIds.add(locatieId);

      final locatie = locatii[locatieId];

      if (locatie == null) {
        continue;
      }

      _adaugaPreferinta(categoriiPreferate, locatie.categorie, 3);

      _adaugaPreferinta(judetePreferate, locatie.judet, 2);
    }
  }

  Future<void> _analizeazaRecenzii({
    required String uid,
    required QuerySnapshot<Map<String, dynamic>> locatiiSnapshot,
    required Map<String, SablonLocatie> locatii,
    required Set<String> locatiiRecenzate,
    required Map<String, double> categoriiPreferate,
    required Map<String, double> judetePreferate,
  }) async {
    for (final locatieDocument in locatiiSnapshot.docs) {
      final recenziiSnapshot = await locatieDocument.reference
          .collection('recenzii')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (recenziiSnapshot.docs.isEmpty) {
        continue;
      }

      final recenzie = recenziiSnapshot.docs.first.data();
      final rating = _citesteDouble(recenzie['rating']);

      locatiiRecenzate.add(locatieDocument.id);

      final locatie = locatii[locatieDocument.id];

      if (locatie == null) {
        continue;
      }

      if (rating >= 4) {
        _adaugaPreferinta(categoriiPreferate, locatie.categorie, 3);

        _adaugaPreferinta(judetePreferate, locatie.judet, 2);
      } else if (rating >= 3) {
        _adaugaPreferinta(categoriiPreferate, locatie.categorie, 1);

        _adaugaPreferinta(judetePreferate, locatie.judet, 0.5);
      }
    }
  }

  Future<void> _analizeazaItinerarii({
    required String uid,
    required Map<String, SablonLocatie> locatii,
    required Set<String> locatiiDinItinerarii,
    required Map<String, double> categoriiPreferate,
    required Map<String, double> judetePreferate,
  }) async {
    final snapshot = await _db
        .collection('itinerarii')
        .where('utilizatorId', isEqualTo: uid)
        .get();

    for (final document in snapshot.docs) {
      final ids = _extrageLocatiiDinItinerariu(document.data());

      for (final locatieId in ids) {
        locatiiDinItinerarii.add(locatieId);

        final locatie = locatii[locatieId];

        if (locatie == null) {
          continue;
        }

        _adaugaPreferinta(categoriiPreferate, locatie.categorie, 2);

        _adaugaPreferinta(judetePreferate, locatie.judet, 1);
      }
    }
  }

  Set<String> _extrageLocatiiDinItinerariu(Map<String, dynamic> data) {
    final rezultate = <String>{};

    final valoriPosibile = [
      data['locatii'],
      data['locatiiIds'],
      data['locatieIds'],
      data['locatiiSelectate'],
    ];

    for (final valoare in valoriPosibile) {
      if (valoare is! List) {
        continue;
      }

      for (final element in valoare) {
        if (element is String && element.trim().isNotEmpty) {
          rezultate.add(element.trim());
        }

        if (element is Map) {
          final id = element['id'] ?? element['locatieId'];

          if (id != null && id.toString().trim().isNotEmpty) {
            rezultate.add(id.toString().trim());
          }
        }
      }
    }

    return rezultate;
  }

  void _adaugaPreferinta(
    Map<String, double> preferinte,
    String valoare,
    double puncte,
  ) {
    final cheie = _normalizeaza(valoare);

    if (cheie.isEmpty) {
      return;
    }

    preferinte[cheie] = (preferinte[cheie] ?? 0) + puncte;
  }

  double _scorRecenzii(int nrRecenzii) {
    if (nrRecenzii >= 100) return 3;
    if (nrRecenzii >= 50) return 2.5;
    if (nrRecenzii >= 20) return 2;
    if (nrRecenzii >= 10) return 1.5;
    if (nrRecenzii >= 5) return 1;
    if (nrRecenzii > 0) return 0.5;

    return 0;
  }

  String _construiesteMotiv({
    required SablonLocatie locatie,
    required double scorCategorie,
    required double scorJudet,
  }) {
    if (scorCategorie > 0 && scorJudet > 0) {
      return 'Recomandat deoarece preferi categoria '
          '${locatie.categorie} și locații din ${locatie.judet}.';
    }

    if (scorCategorie > 0) {
      return 'Recomandat deoarece preferi locații din categoria '
          '${locatie.categorie}.';
    }

    if (scorJudet > 0) {
      return 'Recomandat deoarece ai explorat locații din '
          '${locatie.judet}.';
    }

    if (locatie.rating >= 4) {
      return 'Recomandat datorită ratingului ridicat.';
    }

    return 'Locație selectată pe baza popularității sale.';
  }

  String _normalizeaza(String text) {
    return text
        .toLowerCase()
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ș', 's')
        .replaceAll('ş', 's')
        .replaceAll('ț', 't')
        .replaceAll('ţ', 't')
        .trim();
  }

  double _citesteDouble(dynamic valoare) {
    if (valoare is num) {
      return valoare.toDouble();
    }

    return double.tryParse(valoare?.toString() ?? '') ?? 0;
  }
}
