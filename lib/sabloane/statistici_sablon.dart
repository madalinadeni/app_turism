class StatisticiSablon {
  final int totalLocatii;
  final int totalRecenzii;
  final double ratingMediu;

  final Map<String, int> locatiiPeCategorie;
  final Map<String, double> ratingMediuPeJudet;
  final Map<String, int> recenziiPeJudet;

  const StatisticiSablon({
    required this.totalLocatii,
    required this.totalRecenzii,
    required this.ratingMediu,
    required this.locatiiPeCategorie,
    required this.ratingMediuPeJudet,
    required this.recenziiPeJudet,
  });

  factory StatisticiSablon.empty() {
    return const StatisticiSablon(
      totalLocatii: 0,
      totalRecenzii: 0,
      ratingMediu: 0,
      locatiiPeCategorie: {},
      ratingMediuPeJudet: {},
      recenziiPeJudet: {},
    );
  }

  List<MapEntry<String, int>> get categoriiPopulare {
    final categorii = locatiiPeCategorie.entries.toList();

    categorii.sort((a, b) => b.value.compareTo(a.value));

    return categorii;
  }

  List<MapEntry<String, double>> get judeteApreciate {
    final judete = ratingMediuPeJudet.entries
        .where((entry) => (recenziiPeJudet[entry.key] ?? 0) > 0)
        .toList();

    judete.sort((a, b) => b.value.compareTo(a.value));

    return judete;
  }
}
