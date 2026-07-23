import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificariService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _notificariRef(String uid) {
    return _db.collection('utilizatori').doc(uid).collection('notificari');
  }

  Future<void> adaugaNotificarePentruUtilizator({
    required String utilizatorId,
    required String titlu,
    required String mesaj,
    required String tip,
    int puncte = 0,
    String referintaId = '',
  }) async {
    await _notificariRef(utilizatorId).add({
      'titlu': titlu,
      'mesaj': mesaj,
      'tip': tip,
      'puncte': puncte,
      'referintaId': referintaId,
      'citita': false,
      'creataLa': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getNotificari() {
    final uid = _uid;

    if (uid == null) {
      return Stream.value([]);
    }

    return _notificariRef(
      uid,
    ).orderBy('creataLa', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((document) {
        return {'id': document.id, ...document.data()};
      }).toList();
    });
  }

  Stream<int> getNumarNotificariNecitite() {
    final uid = _uid;

    if (uid == null) {
      return Stream.value(0);
    }

    return _notificariRef(uid)
        .where('citita', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> marcheazaCaCitita(String notificareId) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    await _notificariRef(uid).doc(notificareId).update({'citita': true});
  }

  Future<void> marcheazaToateCaCitite() async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    final snapshot = await _notificariRef(
      uid,
    ).where('citita', isEqualTo: false).get();

    final batch = _db.batch();

    for (final document in snapshot.docs) {
      batch.update(document.reference, {'citita': true});
    }

    await batch.commit();
  }

  Future<void> stergeNotificare(String notificareId) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    await _notificariRef(uid).doc(notificareId).delete();
  }
}
