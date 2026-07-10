import 'package:cloud_firestore/cloud_firestore.dart';
import '../sabloane/articol_sablon.dart';

class ArticolService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _articoleCollection {
    return _db.collection('articole');
  }

  Stream<List<SablonArticol>> getArticole() {
    return _articoleCollection
        .orderBy('dataPublicarii', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SablonArticol.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<SablonArticol>> getArticoleByCategorie(String categorie) {
    if (categorie == 'Toate') {
      return getArticole();
    }

    return _articoleCollection
        .where('categorie', isEqualTo: categorie)
        .orderBy('dataPublicarii', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SablonArticol.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<SablonArticol?> getArticol(String articolId) async {
    final document = await _articoleCollection.doc(articolId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return SablonArticol.fromMap(document.data()!, document.id);
  }

  Future<void> addArticol(SablonArticol articol) async {
    await _articoleCollection.add(articol.toMap());
  }

  Future<void> updateArticol(SablonArticol articol) async {
    if (articol.id.trim().isEmpty) {
      throw Exception('Articolul nu are un ID valid.');
    }

    await _articoleCollection.doc(articol.id).update(articol.toMap());
  }

  Future<void> deleteArticol(String articolId) async {
    if (articolId.trim().isEmpty) {
      throw Exception('Articolul nu are un ID valid.');
    }

    await _articoleCollection.doc(articolId).delete();
  }
}
