class SablonUser {
  final String uid;
  final String nume;
  final String email;
  final String imagineProfil;
  final List<String> preferate;
  final int puncte; // pentru sistemul de niveluri

  SablonUser({
    required this.uid,
    required this.nume,
    required this.email,
    required this.imagineProfil,
    this.preferate = const [],
    this.puncte = 0,
  });

  // Convertim UserModel în map pentru Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nume': nume,
      'email': email,
      'imagineProfil': imagineProfil,
      'preferate': preferate,
      'puncte': puncte,
    };
  }

  // Convertim map-ul din Firestore în UserModel
  factory SablonUser.fromMap(Map<String, dynamic> map) {
    return SablonUser(
      uid: map['uid'] ?? '',
      nume: map['nume'] ?? '',
      email: map['email'] ?? '',
      imagineProfil: map['imagineProfil'] ?? '',
      preferate: List<String>.from(map['preferate'] ?? []),
      puncte: map['puncte'] ?? 0,
    );
  }
}
