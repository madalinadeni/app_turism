import 'package:app_turism/sabloane/locatie_sablon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gamification_service.dart';

class LocatieService {
  final CollectionReference locatieCollection = FirebaseFirestore.instance
      .collection('locatii');

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obține toate locațiile
  Future<List<SablonLocatie>> getAllLocatii() async {
    final snapshot = await locatieCollection.get();
    return snapshot.docs
        .map(
          (doc) =>
              SablonLocatie.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Adaugă o locație
  Future<void> addLocatie(SablonLocatie locatie) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final data = locatie.toMap();

    data['creatorId'] = uid;

    await locatieCollection.add(data);

    await GamificationService().adaugaPuncte(20);
  }

  // Obține o locație după ID
  Future<SablonLocatie?> getLocatie(String id) async {
    final doc = await locatieCollection.doc(id).get();
    if (doc.exists) {
      return SablonLocatie.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Actualizează o locație
  Future<void> updateLocatie(String id, Map<String, dynamic> data) async {
    await locatieCollection.doc(id).update(data);
  }

  // Șterge o locație
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

    await GamificationService().adaugaPuncte(2);
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
}
