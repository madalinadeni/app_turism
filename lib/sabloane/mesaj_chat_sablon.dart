enum RolMesajChat { utilizator, asistent }

class MesajChatSablon {
  final String continut;
  final RolMesajChat rol;
  final DateTime trimisLa;
  final List<String> locatieIds;
  final List<String> sugestii;

  const MesajChatSablon({
    required this.continut,
    required this.rol,
    required this.trimisLa,
    this.locatieIds = const [],
    this.sugestii = const [],
  });

  bool get esteUtilizator => rol == RolMesajChat.utilizator;

  bool get esteAsistent => rol == RolMesajChat.asistent;

  factory MesajChatSablon.utilizator(String continut) {
    return MesajChatSablon(
      continut: continut.trim(),
      rol: RolMesajChat.utilizator,
      trimisLa: DateTime.now(),
    );
  }

  factory MesajChatSablon.asistent({
    required String continut,
    List<String> locatieIds = const [],
    List<String> sugestii = const [],
  }) {
    return MesajChatSablon(
      continut: continut.trim(),
      rol: RolMesajChat.asistent,
      trimisLa: DateTime.now(),
      locatieIds: locatieIds,
      sugestii: sugestii,
    );
  }

  factory MesajChatSablon.fromAiResponse(Map<String, dynamic> map) {
    final locatieIdsRaw = map['locatieIds'];
    final sugestiiRaw = map['sugestii'];

    return MesajChatSablon.asistent(
      continut: map['raspuns']?.toString() ?? 'Nu am putut genera un răspuns.',
      locatieIds: locatieIdsRaw is List
          ? locatieIdsRaw
                .map((id) => id.toString())
                .where((id) => id.isNotEmpty)
                .toList()
          : const [],
      sugestii: sugestiiRaw is List
          ? sugestiiRaw
                .map((sugestie) => sugestie.toString())
                .where((sugestie) => sugestie.isNotEmpty)
                .take(3)
                .toList()
          : const [],
    );
  }

  Map<String, String> toIstoricMap() {
    return {'rol': esteUtilizator ? 'user' : 'assistant', 'continut': continut};
  }
}
