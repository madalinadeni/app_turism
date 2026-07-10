import 'package:cloud_firestore/cloud_firestore.dart';

class PlannerSablon {
  final String id;
  final String titlu;
  final String utilizatorId;
  final DateTime creatLa;
  final DateTime dataInceput;
  final DateTime dataFinal;
  final List<Map<String, dynamic>> locatii;

  PlannerSablon({
    required this.id,
    required this.titlu,
    required this.utilizatorId,
    required this.creatLa,
    required this.dataInceput,
    required this.dataFinal,
    required this.locatii,
  });

  factory PlannerSablon.fromMap(Map<String, dynamic> map, String id) {
    return PlannerSablon(
      id: id,
      titlu: map['titlu'] ?? '',
      utilizatorId: map['utilizatorId'] ?? '',
      creatLa: (map['creatLa'] as Timestamp).toDate(),
      dataInceput: (map['dataInceput'] as Timestamp).toDate(),
      dataFinal: (map['dataFinal'] as Timestamp).toDate(),
      locatii: List<Map<String, dynamic>>.from(map['locatii'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titlu': titlu,
      'utilizatorId': utilizatorId,
      'creatLa': Timestamp.fromDate(creatLa),
      'dataInceput': Timestamp.fromDate(dataInceput),
      'dataFinal': Timestamp.fromDate(dataFinal),
      'locatii': locatii,
    };
  }
}
