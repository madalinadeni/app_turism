import 'package:cloud_firestore/cloud_firestore.dart';

class SablonArticol {
  final String id;
  final String titlu;
  final String continut;
  final String categorie;
  final String imagine;
  final String autor;
  final DateTime dataPublicarii;

  const SablonArticol({
    required this.id,
    required this.titlu,
    required this.continut,
    required this.categorie,
    required this.imagine,
    required this.autor,
    required this.dataPublicarii,
  });

  factory SablonArticol.fromMap(Map<String, dynamic> data, String id) {
    final dataFirestore = data['dataPublicarii'];

    DateTime dataPublicarii;

    if (dataFirestore is Timestamp) {
      dataPublicarii = dataFirestore.toDate();
    } else {
      dataPublicarii = DateTime.now();
    }

    return SablonArticol(
      id: id,
      titlu: data['titlu']?.toString() ?? '',
      continut: data['continut']?.toString() ?? '',
      categorie: data['categorie']?.toString() ?? 'Altele',
      imagine: data['imagine']?.toString() ?? '',
      autor: data['autor']?.toString() ?? 'TourMate',
      dataPublicarii: dataPublicarii,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titlu': titlu.trim(),
      'continut': continut.trim(),
      'categorie': categorie.trim(),
      'imagine': imagine.trim(),
      'autor': autor.trim(),
      'dataPublicarii': Timestamp.fromDate(dataPublicarii),
    };
  }

  SablonArticol copyWith({
    String? id,
    String? titlu,
    String? continut,
    String? categorie,
    String? imagine,
    String? autor,
    DateTime? dataPublicarii,
  }) {
    return SablonArticol(
      id: id ?? this.id,
      titlu: titlu ?? this.titlu,
      continut: continut ?? this.continut,
      categorie: categorie ?? this.categorie,
      imagine: imagine ?? this.imagine,
      autor: autor ?? this.autor,
      dataPublicarii: dataPublicarii ?? this.dataPublicarii,
    );
  }
}
