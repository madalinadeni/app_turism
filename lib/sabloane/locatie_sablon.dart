class SablonLocatie {
  final String id;
  final String nume;
  final String descriere;
  final String categorie;
  final String judet;
  final String oras;
  final String orar;

  final List<String> imagini;

  final double latitudine;
  final double longitudine;

  final double pretMin;
  final double pretMax;

  final double rating;
  final int nrRecenzii;

  final List<String> facilitati;
  final bool popular;

  SablonLocatie({
    required this.id,
    required this.nume,
    required this.descriere,
    required this.categorie,
    required this.judet,
    required this.oras,
    required this.orar,
    required this.imagini,
    required this.latitudine,
    required this.longitudine,
    required this.pretMin,
    required this.pretMax,
    required this.rating,
    required this.nrRecenzii,
    required this.facilitati,
    required this.popular,
  });

  factory SablonLocatie.fromMap(Map<String, dynamic> data, String id) {
    final coordonate = data['coordonate'] ?? {};

    return SablonLocatie(
      id: id,
      nume: data['nume'] ?? '',
      descriere: data['descriere'] ?? '',
      categorie: data['categorie'] ?? '',
      judet: data['judet'] ?? '',
      oras: data['oras'] ?? '',
      orar: data['orar'] ?? '',
      imagini: List<String>.from(data['imagini'] ?? []),

      latitudine: (coordonate['lat'] ?? 0).toDouble(),
      longitudine: (coordonate['lng'] ?? 0).toDouble(),

      pretMin: (data['pretMin'] ?? 0).toDouble(),
      pretMax: (data['pretMax'] ?? 0).toDouble(),

      rating: (data['rating'] ?? 0).toDouble(),
      nrRecenzii: data['nrRecenzii'] ?? 0,

      facilitati: List<String>.from(data['facilitati'] ?? []),

      popular: data['popular'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nume': nume,
      'descriere': descriere,
      'categorie': categorie,
      'judet': judet,
      'oras': oras,
      'orar': orar,

      'imagini': imagini,

      'coordonate': {'lat': latitudine, 'lng': longitudine},

      'pretMin': pretMin,
      'pretMax': pretMax,

      'rating': rating,
      'nrRecenzii': nrRecenzii,

      'facilitati': facilitati,

      'popular': popular,
    };
  }
}
