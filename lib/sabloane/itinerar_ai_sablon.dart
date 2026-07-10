class ItinerarAi {
  final String titlu;
  final String rezumat;
  final String zona;
  final int numarZile;
  final double bugetTotalEstimat;
  final List<String> sfaturi;
  final List<ZiItinerarAi> zile;

  const ItinerarAi({
    required this.titlu,
    required this.rezumat,
    required this.zona,
    required this.numarZile,
    required this.bugetTotalEstimat,
    required this.sfaturi,
    required this.zile,
  });

  factory ItinerarAi.fromMap(Map<String, dynamic> map) {
    final zileRaw = map['zile'];
    final sfaturiRaw = map['sfaturi'];

    return ItinerarAi(
      titlu: map['titlu']?.toString() ?? 'Itinerar turistic',
      rezumat: map['rezumat']?.toString() ?? '',
      zona: map['zona']?.toString() ?? '',
      numarZile: _toInt(map['numarZile']),
      bugetTotalEstimat: _toDouble(map['bugetTotalEstimat']),
      sfaturi: sfaturiRaw is List
          ? sfaturiRaw.map((sfat) => sfat.toString()).toList()
          : const [],
      zile: zileRaw is List
          ? zileRaw
                .whereType<Map>()
                .map(
                  (zi) => ZiItinerarAi.fromMap(Map<String, dynamic>.from(zi)),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titlu': titlu,
      'rezumat': rezumat,
      'zona': zona,
      'numarZile': numarZile,
      'bugetTotalEstimat': bugetTotalEstimat,
      'sfaturi': sfaturi,
      'zile': zile.map((zi) => zi.toMap()).toList(),
    };
  }
}

class ZiItinerarAi {
  final int zi;
  final String titlu;
  final List<ActivitateItinerarAi> activitati;

  const ZiItinerarAi({
    required this.zi,
    required this.titlu,
    required this.activitati,
  });

  factory ZiItinerarAi.fromMap(Map<String, dynamic> map) {
    final activitatiRaw = map['activitati'];

    return ZiItinerarAi(
      zi: _toInt(map['zi']),
      titlu: map['titlu']?.toString() ?? '',
      activitati: activitatiRaw is List
          ? activitatiRaw
                .whereType<Map>()
                .map(
                  (activitate) => ActivitateItinerarAi.fromMap(
                    Map<String, dynamic>.from(activitate),
                  ),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zi': zi,
      'titlu': titlu,
      'activitati': activitati.map((activitate) => activitate.toMap()).toList(),
    };
  }
}

class ActivitateItinerarAi {
  final String ora;
  final String locatieId;
  final String numeLocatie;
  final String categorie;
  final String motiv;
  final double durataOre;
  final double costEstimat;

  const ActivitateItinerarAi({
    required this.ora,
    required this.locatieId,
    required this.numeLocatie,
    required this.categorie,
    required this.motiv,
    required this.durataOre,
    required this.costEstimat,
  });

  factory ActivitateItinerarAi.fromMap(Map<String, dynamic> map) {
    return ActivitateItinerarAi(
      ora: map['ora']?.toString() ?? '',
      locatieId: map['locatieId']?.toString() ?? '',
      numeLocatie: map['numeLocatie']?.toString() ?? '',
      categorie: map['categorie']?.toString() ?? '',
      motiv: map['motiv']?.toString() ?? '',
      durataOre: _toDouble(map['durataOre']),
      costEstimat: _toDouble(map['costEstimat']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ora': ora,
      'locatieId': locatieId,
      'numeLocatie': numeLocatie,
      'categorie': categorie,
      'motiv': motiv,
      'durataOre': durataOre,
      'costEstimat': costEstimat,
    };
  }
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
