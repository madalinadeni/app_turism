import 'package:cloud_firestore/cloud_firestore.dart';

class PlannerSablon {
  final String id;
  final String titlu;
  final String utilizatorId;
  final DateTime creatLa;
  final DateTime dataInceput;
  final DateTime dataFinal;
  final List<Map<String, dynamic>> locatii;

  final bool generatCuAi;
  final Map<String, dynamic>? detaliiItinerarAi;

  PlannerSablon({
    required this.id,
    required this.titlu,
    required this.utilizatorId,
    required this.creatLa,
    required this.dataInceput,
    required this.dataFinal,
    required this.locatii,
    this.generatCuAi = false,
    this.detaliiItinerarAi,
  });

  factory PlannerSablon.fromMap(Map<String, dynamic> map, String id) {
    final locatiiRaw = map['locatii'];
    final detaliiAiRaw = map['detaliiItinerarAi'];

    return PlannerSablon(
      id: id,
      titlu: map['titlu']?.toString() ?? '',
      utilizatorId: map['utilizatorId']?.toString() ?? '',
      creatLa: _timestampToDate(map['creatLa']),
      dataInceput: _timestampToDate(map['dataInceput']),
      dataFinal: _timestampToDate(map['dataFinal']),
      locatii: locatiiRaw is List
          ? locatiiRaw
                .whereType<Map>()
                .map((locatie) => Map<String, dynamic>.from(locatie))
                .toList()
          : [],
      generatCuAi: map['generatCuAi'] == true,
      detaliiItinerarAi: detaliiAiRaw is Map
          ? Map<String, dynamic>.from(detaliiAiRaw)
          : null,
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
      'generatCuAi': generatCuAi,
      if (detaliiItinerarAi != null) 'detaliiItinerarAi': detaliiItinerarAi,
    };
  }

  static DateTime _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }
}
