import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notificari_service.dart';

class GamificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificariService _notificariService = NotificariService();

  String get uid => _auth.currentUser!.uid;

  DocumentReference get userRef => _db.collection('utilizatori').doc(uid);

  Future<void> adaugaPuncte(
    int puncte, {
    String motiv = 'activitate în aplicație',
    String tip = 'puncte',
    String referintaId = '',
    bool trimiteNotificare = true,
  }) async {
    final doc = await userRef.get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;

    final puncteCurente = (data['puncte'] as num?)?.toInt() ?? 0;
    final puncteNoi = puncteCurente + puncte;

    final nivelNou = calculeazaNivel(puncteNoi);
    final titluNou = calculeazaTitlu(puncteNoi);
    final badgeNou = calculeazaBadge(puncteNoi);

    await userRef.update({
      'puncte': puncteNoi,
      'nivel': nivelNou,
      'titlu': titluNou,
      'badge': badgeNou,
    });

    if (trimiteNotificare && puncte > 0) {
      await _notificariService.adaugaNotificarePentruUtilizator(
        utilizatorId: uid,
        titlu: 'Puncte primite',
        mesaj: 'Ai primit $puncte puncte pentru $motiv.',
        tip: tip,
        puncte: puncte,
        referintaId: referintaId,
      );
    }
  }

  int calculeazaNivel(int puncte) {
    if (puncte >= 1000) return 5;
    if (puncte >= 600) return 4;
    if (puncte >= 300) return 3;
    if (puncte >= 100) return 2;
    return 1;
  }

  String calculeazaTitlu(int puncte) {
    if (puncte >= 1000) return 'Master Explorer';
    if (puncte >= 600) return 'Expert Turistic';
    if (puncte >= 300) return 'Aventurier';
    if (puncte >= 100) return 'Călător';
    return 'Explorator Începător';
  }

  String calculeazaBadge(int puncte) {
    if (puncte >= 1000) return '👑';
    if (puncte >= 600) return '🥇';
    if (puncte >= 300) return '🥈';
    if (puncte >= 100) return '🥉';
    return '🌱';
  }
}
