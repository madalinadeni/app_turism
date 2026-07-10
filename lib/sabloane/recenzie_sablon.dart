import 'package:cloud_firestore/cloud_firestore.dart';

class SablonRecenzie {
  final String id;
  final String locatieId;
  final String userId;
  final String numeUtilizator;
  final String comentariu;
  final double rating;
  final DateTime data;

  SablonRecenzie({
    required this.id,
    required this.locatieId,
    required this.userId,
    required this.numeUtilizator,
    required this.comentariu,
    required this.rating,
    required this.data,
  });

  factory SablonRecenzie.fromMap(Map<String, dynamic> map, String id) {
    return SablonRecenzie(
      id: id,
      locatieId: map['locatieId'] ?? '',
      userId: map['userId'] ?? '',
      numeUtilizator: map['numeUtilizator'] ?? '',
      comentariu: map['comentariu'] ?? '',
      rating: (map['rating'] as num).toDouble(),
      data: (map['data'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'locatieId': locatieId,
      'userId': userId,
      'numeUtilizator': numeUtilizator,
      'comentariu': comentariu,
      'rating': rating,
      'data': data,
    };
  }
}
