import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../sabloane/planner_sablon.dart';
import 'gamification_service.dart';

class PlannerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _plannerCollection => _db.collection('itinerarii');

  String get _uid => _auth.currentUser!.uid;

  Future<void> createPlanner({
    required String titlu,
    required DateTime dataInceput,
    required DateTime dataFinal,
    required List<Map<String, dynamic>> locatii,
  }) async {
    await _plannerCollection.add({
      'titlu': titlu,
      'utilizatorId': _uid,
      'creatLa': Timestamp.now(),
      'dataInceput': Timestamp.fromDate(dataInceput),
      'dataFinal': Timestamp.fromDate(dataFinal),
      'locatii': locatii,
    });

    await GamificationService().adaugaPuncte(5);
  }

  Stream<List<PlannerSablon>> getMyPlanners() {
    return _plannerCollection
        .where('utilizatorId', isEqualTo: _uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => PlannerSablon.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Future<void> updatePlanner({
    required String plannerId,
    required String titlu,
    required DateTime dataInceput,
    required DateTime dataFinal,
    required List<Map<String, dynamic>> locatii,
  }) async {
    await _plannerCollection.doc(plannerId).update({
      'titlu': titlu,
      'dataInceput': Timestamp.fromDate(dataInceput),
      'dataFinal': Timestamp.fromDate(dataFinal),
      'locatii': locatii,
    });
  }

  Future<void> deletePlanner(String plannerId) async {
    await _plannerCollection.doc(plannerId).delete();
  }

  Future<void> addLocationToPlanner({
    required String plannerId,
    required String locatieId,
    required String titlu,
  }) async {
    await _plannerCollection.doc(plannerId).update({
      'locatii': FieldValue.arrayUnion([
        {'uid': locatieId, 'titlu': titlu},
      ]),
    });
  }

  Future<void> removeLocationFromPlanner({
    required String plannerId,
    required String locatieId,
    required String titlu,
  }) async {
    await _plannerCollection.doc(plannerId).update({
      'locatii': FieldValue.arrayRemove([
        {'uid': locatieId, 'titlu': titlu},
      ]),
    });
  }
}
