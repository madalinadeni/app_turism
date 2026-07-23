import 'package:app_turism/sabloane/locatie_sablon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gamification_service.dart';
import 'notificari_service.dart';

class LocatieService {
  final CollectionReference locatieCollection = FirebaseFirestore.instance
      .collection('locatii');

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GamificationService _gamificationService = GamificationService();
  final NotificariService _notificariService = NotificariService();

  Future<List<SablonLocatie>> getAllLocatii() async {
    final snapshot = await locatieCollection.get();
    return snapshot.docs
        .map(
          (doc) =>
              SablonLocatie.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<void> addLocatie(SablonLocatie locatie) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final data = locatie.toMap();

    data['creatorId'] = uid;

    await locatieCollection.add(data);
  }

  Future<SablonLocatie?> getLocatie(String id) async {
    final doc = await locatieCollection.doc(id).get();
    if (doc.exists) {
      return SablonLocatie.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateLocatie(String id, Map<String, dynamic> data) async {
    await locatieCollection.doc(id).update(data);
  }

  Future<void> deleteLocatie(String id) async {
    await locatieCollection.doc(id).delete();
  }

  Future<void> addFavorite(String locatieId) async {
    final uid = _auth.currentUser!.uid;

    final existing = await _db
        .collection('utilizatori')
        .doc(uid)
        .collection('preferate')
        .where('locatieId', isEqualTo: locatieId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return;
    }

    await _db.collection('utilizatori').doc(uid).collection('preferate').add({
      'locatieId': locatieId,
      'adaugatLa': Timestamp.now(),
    });

    await _gamificationService.adaugaPuncte(
      2,
      motiv: 'adăugarea unei locații la favorite',
      tip: 'favorit',
      referintaId: locatieId,
    );
  }

  Future<void> removeFavorite(String locatieId) async {
    final uid = _auth.currentUser!.uid;

    final snapshot = await _db
        .collection('utilizatori')
        .doc(uid)
        .collection('preferate')
        .where('locatieId', isEqualTo: locatieId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<bool> isFavorite(String locatieId) async {
    final uid = _auth.currentUser!.uid;

    final snapshot = await _db
        .collection('utilizatori')
        .doc(uid)
        .collection('preferate')
        .where('locatieId', isEqualTo: locatieId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<List<String>> getFavoriteIds() async {
    final uid = _auth.currentUser!.uid;

    final snapshot = await _db
        .collection('utilizatori')
        .doc(uid)
        .collection('preferate')
        .get();

    return snapshot.docs.map((doc) => doc['locatieId'] as String).toList();
  }

  Future<List<SablonLocatie>> getFavoriteLocations() async {
    final favoriteIds = await getFavoriteIds();

    if (favoriteIds.isEmpty) {
      return [];
    }

    final List<SablonLocatie> locatii = [];

    for (final id in favoriteIds) {
      final locatie = await getLocatie(id);

      if (locatie != null) {
        locatii.add(locatie);
      }
    }

    return locatii;
  }

  Stream<List<SablonLocatie>> favoriteLocationsStream() {
    final uid = _auth.currentUser!.uid;

    return _db
        .collection('utilizatori')
        .doc(uid)
        .collection('preferate')
        .snapshots()
        .asyncMap((snapshot) async {
          List<SablonLocatie> locatii = [];

          for (final doc in snapshot.docs) {
            final locatie = await getLocatie(doc['locatieId']);

            if (locatie != null) {
              locatii.add(locatie);
            }
          }

          return locatii;
        });
  }

  Stream<Set<String>> getFavoritesStream() {
    final uid = _auth.currentUser!.uid;

    return _db
        .collection('utilizatori')
        .doc(uid)
        .collection('preferate')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc['locatieId'] as String).toSet();
        });
  }

  Stream<int> favoriteCount() {
    final uid = _auth.currentUser!.uid;

    return _db
        .collection('utilizatori')
        .doc(uid)
        .collection('preferate')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<List<SablonLocatie>> getTopRatedLocations({int limit = 10}) async {
    final snapshot = await locatieCollection.get();

    final locatii = snapshot.docs
        .map(
          (doc) =>
              SablonLocatie.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();

    locatii.sort((a, b) {
      final ratingCompare = b.rating.compareTo(a.rating);

      if (ratingCompare != 0) {
        return ratingCompare;
      }

      return b.nrRecenzii.compareTo(a.nrRecenzii);
    });

    return locatii.take(limit).toList();
  }

  Future<String> trimitePropunereLocatie(SablonLocatie locatie) async {
    final utilizator = FirebaseAuth.instance.currentUser;

    if (utilizator == null) {
      throw Exception(
        'Trebuie să fii autentificat pentru a propune o locație.',
      );
    }

    final data = locatie.toMap();

    data.addAll({
      'creatorId': utilizator.uid,
      'status': 'inAsteptare',
      'trimisaLa': FieldValue.serverTimestamp(),
      'verificataLa': null,
      'verificataDe': null,
      'motivRespingere': '',
      'puncteAcordate': false,
    });

    final document = await FirebaseFirestore.instance
        .collection('propuneri_locatii')
        .add(data);

    return document.id;
  }

  Stream<List<Map<String, dynamic>>> getPropuneriInAsteptare() {
    return FirebaseFirestore.instance
        .collection('propuneri_locatii')
        .where('status', isEqualTo: 'inAsteptare')
        .snapshots()
        .map((snapshot) {
          final propuneri = snapshot.docs.map((document) {
            return <String, dynamic>{'id': document.id, ...document.data()};
          }).toList();

          propuneri.sort((prima, aDoua) {
            final primaData = prima['trimisaLa'];
            final aDouaData = aDoua['trimisaLa'];

            if (primaData is! Timestamp && aDouaData is! Timestamp) {
              return 0;
            }

            if (primaData is! Timestamp) {
              return 1;
            }

            if (aDouaData is! Timestamp) {
              return -1;
            }

            return aDouaData.compareTo(primaData);
          });

          return propuneri;
        });
  }

  Future<void> aprobaPropunereLocatie(String propunereId) async {
    final utilizatorCurent = FirebaseAuth.instance.currentUser;

    if (utilizatorCurent == null) {
      throw Exception('Trebuie să fii autentificat.');
    }

    final db = FirebaseFirestore.instance;

    final adminRef = db.collection('utilizatori').doc(utilizatorCurent.uid);
    final propunereRef = db.collection('propuneri_locatii').doc(propunereId);
    final locatieRef = db.collection('locatii').doc(propunereId);

    String creatorIdPentruNotificare = '';
    String numeLocatiePentruNotificare = 'Locația propusă';

    await db.runTransaction((transaction) async {
      final adminDocument = await transaction.get(adminRef);

      final rol = adminDocument.data()?['rol']?.toString().trim().toLowerCase();

      if (rol != 'admin') {
        throw Exception('Nu ai permisiunea să aprobi locații.');
      }

      final propunereDocument = await transaction.get(propunereRef);

      if (!propunereDocument.exists) {
        throw Exception('Propunerea nu mai există.');
      }

      final propunereData = propunereDocument.data()!;

      final status = propunereData['status']?.toString();

      if (status != 'inAsteptare') {
        throw Exception('Această propunere a fost deja verificată.');
      }

      if (propunereData['puncteAcordate'] == true) {
        throw Exception(
          'Punctele pentru această propunere au fost deja acordate.',
        );
      }

      final creatorId = propunereData['creatorId']?.toString() ?? '';

      if (creatorId.isEmpty) {
        throw Exception('Propunerea nu are un creator valid.');
      }

      final creatorRef = db.collection('utilizatori').doc(creatorId);

      final creatorDocument = await transaction.get(creatorRef);

      if (!creatorDocument.exists) {
        throw Exception(
          'Contul utilizatorului care a trimis propunerea nu există.',
        );
      }

      final creatorData = creatorDocument.data() ?? {};
      final puncteActuale = (creatorData['puncte'] as num?)?.toInt() ?? 0;
      final puncteNoi = puncteActuale + 20;

      final locatieData = Map<String, dynamic>.from(propunereData);

      locatieData.remove('status');
      locatieData.remove('trimisaLa');
      locatieData.remove('verificataLa');
      locatieData.remove('verificataDe');
      locatieData.remove('motivRespingere');
      locatieData.remove('puncteAcordate');
      locatieData.remove('locatiePublicataId');

      locatieData.addAll({
        'creatorId': creatorId,
        'publicataLa': FieldValue.serverTimestamp(),
        'aprobataDe': utilizatorCurent.uid,
      });

      transaction.set(locatieRef, locatieData);

      transaction.update(propunereRef, {
        'status': 'aprobata',
        'verificataLa': FieldValue.serverTimestamp(),
        'verificataDe': utilizatorCurent.uid,
        'motivRespingere': '',
        'puncteAcordate': true,
        'locatiePublicataId': locatieRef.id,
      });

      transaction.update(creatorRef, {
        'puncte': puncteNoi,
        'nivel': _gamificationService.calculeazaNivel(puncteNoi),
        'titlu': _gamificationService.calculeazaTitlu(puncteNoi),
        'badge': _gamificationService.calculeazaBadge(puncteNoi),
      });

      creatorIdPentruNotificare = creatorId;

      final numeLocatie = propunereData['nume']?.toString().trim();
      if (numeLocatie != null && numeLocatie.isNotEmpty) {
        numeLocatiePentruNotificare = numeLocatie;
      }
    });

    if (creatorIdPentruNotificare.isNotEmpty) {
      await _notificariService.adaugaNotificarePentruUtilizator(
        utilizatorId: creatorIdPentruNotificare,
        titlu: 'Propunere aprobată',
        mesaj:
            'Locația „$numeLocatiePentruNotificare” a fost aprobată și publicată. Ai primit 20 de puncte.',
        tip: 'propunere_aprobata',
        puncte: 20,
        referintaId: propunereId,
      );
    }
  }

  Future<void> respingePropunereLocatie({
    required String propunereId,
    required String motiv,
  }) async {
    final utilizatorCurent = FirebaseAuth.instance.currentUser;

    if (utilizatorCurent == null) {
      throw Exception('Trebuie să fii autentificat.');
    }

    final motivCuratat = motiv.trim();

    if (motivCuratat.length < 5) {
      throw Exception(
        'Motivul respingerii trebuie să conțină minimum 5 caractere.',
      );
    }

    final db = FirebaseFirestore.instance;

    final adminRef = db.collection('utilizatori').doc(utilizatorCurent.uid);
    final propunereRef = db.collection('propuneri_locatii').doc(propunereId);

    String creatorIdPentruNotificare = '';
    String numeLocatiePentruNotificare = 'Locația propusă';

    await db.runTransaction((transaction) async {
      final adminDocument = await transaction.get(adminRef);

      final rol = adminDocument.data()?['rol']?.toString().trim().toLowerCase();

      if (rol != 'admin') {
        throw Exception('Nu ai permisiunea să respingi locații.');
      }

      final propunereDocument = await transaction.get(propunereRef);

      if (!propunereDocument.exists) {
        throw Exception('Propunerea nu mai există.');
      }

      final propunereData = propunereDocument.data()!;

      if (propunereData['status'] != 'inAsteptare') {
        throw Exception('Această propunere a fost deja verificată.');
      }

      transaction.update(propunereRef, {
        'status': 'respinsa',
        'verificataLa': FieldValue.serverTimestamp(),
        'verificataDe': utilizatorCurent.uid,
        'motivRespingere': motivCuratat,
        'puncteAcordate': false,
      });

      creatorIdPentruNotificare = propunereData['creatorId']?.toString() ?? '';

      final numeLocatie = propunereData['nume']?.toString().trim();
      if (numeLocatie != null && numeLocatie.isNotEmpty) {
        numeLocatiePentruNotificare = numeLocatie;
      }
    });

    if (creatorIdPentruNotificare.isNotEmpty) {
      await _notificariService.adaugaNotificarePentruUtilizator(
        utilizatorId: creatorIdPentruNotificare,
        titlu: 'Propunere respinsă',
        mesaj:
            'Locația „$numeLocatiePentruNotificare” a fost respinsă. Motiv: $motivCuratat',
        tip: 'propunere_respinsa',
        puncte: 0,
        referintaId: propunereId,
      );
    }
  }

  Stream<List<Map<String, dynamic>>> getPropunerileMele() {
    final utilizator = _auth.currentUser;

    if (utilizator == null) {
      return Stream.value([]);
    }

    return _db
        .collection('propuneri_locatii')
        .where('creatorId', isEqualTo: utilizator.uid)
        .snapshots()
        .map((snapshot) {
          final propuneri = snapshot.docs.map((document) {
            return <String, dynamic>{'id': document.id, ...document.data()};
          }).toList();

          propuneri.sort((prima, aDoua) {
            final primaData = prima['trimisaLa'];
            final aDouaData = aDoua['trimisaLa'];

            if (primaData is! Timestamp && aDouaData is! Timestamp) {
              return 0;
            }

            if (primaData is! Timestamp) {
              return 1;
            }

            if (aDouaData is! Timestamp) {
              return -1;
            }

            return aDouaData.compareTo(primaData);
          });

          return propuneri;
        });
  }
}
