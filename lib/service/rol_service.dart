import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RolService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> esteAdmin() async {
    final utilizator = _auth.currentUser;

    if (utilizator == null) {
      return false;
    }

    final document = await _db
        .collection('utilizatori')
        .doc(utilizator.uid)
        .get();

    if (!document.exists) {
      return false;
    }

    final data = document.data();

    return data?['rol']?.toString().toLowerCase() == 'admin';
  }

  Stream<bool> urmaresteRolAdmin() {
    final utilizator = _auth.currentUser;

    if (utilizator == null) {
      return Stream<bool>.value(false);
    }

    return _db.collection('utilizatori').doc(utilizator.uid).snapshots().map((
      document,
    ) {
      final data = document.data();

      return data?['rol']?.toString().toLowerCase() == 'admin';
    });
  }
}
