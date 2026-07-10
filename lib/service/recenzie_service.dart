import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../sabloane/recenzie_sablon.dart';
import 'gamification_service.dart';

class RecenzieService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Adaugă o recenzie
  Future<void> addReview({
    required String locatieId,
    required String comentariu,
    required double rating,
    required String numeUtilizator,
  }) async {
    final uid = _auth.currentUser!.uid;

    final alreadyReviewed = await hasUserReviewed(locatieId);

    if (alreadyReviewed) {
      throw Exception('Ai adăugat deja o recenzie pentru această locație.');
    }

    await _db.collection('locatii').doc(locatieId).collection('recenzii').add({
      'locatieId': locatieId,
      'userId': uid,
      'numeUtilizator': numeUtilizator,
      'comentariu': comentariu,
      'rating': rating,
      'data': Timestamp.now(),
    });

    await updateLocationRating(locatieId);
    await GamificationService().adaugaPuncte(10);
  }

  /// Obține toate recenziile unei locații
  Stream<List<SablonRecenzie>> getReviews(String locatieId) {
    return _db
        .collection('locatii')
        .doc(locatieId)
        .collection('recenzii')
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SablonRecenzie.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateReview(
    String locatieId,
    String reviewId, {
    required String comentariu,
    required double rating,
  }) async {
    await _db
        .collection('locatii')
        .doc(locatieId)
        .collection('recenzii')
        .doc(reviewId)
        .update({
          'comentariu': comentariu,
          'rating': rating,
          'data': Timestamp.now(),
        });

    await updateLocationRating(locatieId);
  }

  /// Șterge o recenzie
  Future<void> deleteReview(String locatieId, String reviewId) async {
    await _db
        .collection('locatii')
        .doc(locatieId)
        .collection('recenzii')
        .doc(reviewId)
        .delete();

    await updateLocationRating(locatieId);
  }

  /// Recalculează ratingul mediu al locației
  Future<void> updateLocationRating(String locatieId) async {
    final snapshot = await _db
        .collection('locatii')
        .doc(locatieId)
        .collection('recenzii')
        .get();

    double total = 0;
    int recenziiValide = 0;

    for (final doc in snapshot.docs) {
      final ratingValue = doc.data()['rating'];

      if (ratingValue is num) {
        total += ratingValue.toDouble();
        recenziiValide++;
      }
    }

    final average = recenziiValide == 0 ? 0.0 : total / recenziiValide;

    await _db.collection('locatii').doc(locatieId).update({
      'rating': average,
      'nrRecenzii': recenziiValide,
    });
  }

  Future<bool> hasUserReviewed(String locatieId) async {
    final uid = _auth.currentUser!.uid;

    final snapshot = await _db
        .collection('locatii')
        .doc(locatieId)
        .collection('recenzii')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<int> getMyReviewsCount() async {
    final uid = _auth.currentUser!.uid;

    final locatiiSnapshot = await _db.collection('locatii').get();

    int count = 0;

    for (final locatieDoc in locatiiSnapshot.docs) {
      final recenziiSnapshot = await locatieDoc.reference
          .collection('recenzii')
          .where('userId', isEqualTo: uid)
          .get();

      count += recenziiSnapshot.docs.length;
    }

    return count;
  }
}
