import 'package:cloud_firestore/cloud_firestore.dart';
import '../sabloane/user_sablon.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colecția utilizatori
  CollectionReference get usersCollection =>
      _firestore.collection('Utilizatori');

  // Crează sau actualizează utilizator
  Future<void> setUser(SablonUser user) async {
    await usersCollection.doc(user.uid).set(user.toMap());
  }

  // Obține un utilizator după uid
  Future<SablonUser?> getUser(String uid) async {
    final doc = await usersCollection.doc(uid).get();
    if (doc.exists) {
      return SablonUser.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Actualizează câmpuri specifice
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await usersCollection.doc(uid).update(data);
  }
}
