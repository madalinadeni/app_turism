import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../account/account_settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../certificate_page.dart';
import 'package:app_turism/service/recenzie_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String userName = '';
  String? profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Nume utilizator';
      profileImagePath = prefs.getString('profileImagePath');
    });
  }

  int punctePentruNivelUrmator(int puncte) {
    if (puncte >= 1000) return 1000;
    if (puncte >= 600) return 1000;
    if (puncte >= 300) return 600;
    if (puncte >= 100) return 300;
    return 100;
  }

  int puncteNivelCurent(int puncte) {
    if (puncte >= 1000) return 1000;
    if (puncte >= 600) return 600;
    if (puncte >= 300) return 300;
    if (puncte >= 100) return 100;
    return 0;
  }

  double progresNivel(int puncte) {
    final start = puncteNivelCurent(puncte);
    final next = punctePentruNivelUrmator(puncte);

    if (puncte >= 1000) return 1.0;

    return (puncte - start) / (next - start);
  }

  List<Map<String, dynamic>> getAchievements({
    required int puncte,
    required int nivel,
  }) {
    return [
      {'icon': '🌱', 'title': 'Primii pași', 'unlocked': puncte >= 1},
      {'icon': '🥉', 'title': 'Călător', 'unlocked': puncte >= 100},
      {'icon': '🥈', 'title': 'Aventurier', 'unlocked': puncte >= 300},
      {'icon': '🥇', 'title': 'Expert Turistic', 'unlocked': puncte >= 600},
      {'icon': '👑', 'title': 'Master Explorer', 'unlocked': puncte >= 1000},
      {'icon': '⭐', 'title': 'Nivel 3 atins', 'unlocked': nivel >= 3},
    ];
  }

  Widget _gamificationCard() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('utilizatori')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        final puncte = data['puncte'] ?? 0;
        final nivel = data['nivel'] ?? 1;
        final titlu = data['titlu'] ?? 'Explorator Începător';
        final badge = data['badge'] ?? '🌱';

        final nextLevelPoints = punctePentruNivelUrmator(puncte);
        final progress = progresNivel(puncte);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(badge, style: const TextStyle(fontSize: 42)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titlu,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Nivel $nivel'),
                          Text('$puncte puncte'),

                          const SizedBox(height: 8),

                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(10),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            puncte >= 1000
                                ? 'Nivel maxim atins'
                                : '$puncte / $nextLevelPoints puncte până la nivelul următor',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            _achievementsSection(puncte, nivel),
          ],
        );
      },
    );
  }

  Widget _achievementsSection(int puncte, int nivel) {
    final achievements = getAchievements(puncte: puncte, nivel: nivel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insigne',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: achievements.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            final unlocked = achievement['unlocked'] as bool;

            return Opacity(
              opacity: unlocked ? 1 : 0.35,
              child: Card(
                elevation: unlocked ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        achievement['icon'],
                        style: const TextStyle(fontSize: 30),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        achievement['title'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: unlocked
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        unlocked ? Icons.lock_open : Icons.lock,
                        size: 16,
                        color: unlocked ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _personalStatsCard() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<List<int>>(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('utilizatori')
            .doc(uid)
            .collection('preferate')
            .get()
            .then((snapshot) => snapshot.docs.length),

        RecenzieService().getMyReviewsCount(),

        FirebaseFirestore.instance
            .collection('locatii')
            .where('creatorId', isEqualTo: uid)
            .get()
            .then((snapshot) => snapshot.docs.length),

        FirebaseFirestore.instance
            .collection('itinerarii')
            .where('utilizatorId', isEqualTo: uid)
            .get()
            .then((snapshot) => snapshot.docs.length),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Eroare statistici: ${snapshot.error}'),
            ),
          );
        }

        final favorite = snapshot.data![0];
        final recenzii = snapshot.data![1];
        final locatii = snapshot.data![2];
        final plannere = snapshot.data![3];

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistici personale',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Text('❤️ Favorite: $favorite'),
                Text('⭐ Recenzii scrise: $recenzii'),
                Text('📍 Locații adăugate: $locatii'),
                Text('🗺 Planner-e create: $plannere'),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info utilizator
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: profileImagePath != null
                      ? FileImage(File(profileImagePath!))
                      : const AssetImage('media/hotel.jpeg') as ImageProvider,
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          _gamificationCard(),

          const SizedBox(height: 30),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.workspace_premium,
                color: Colors.amber,
                size: 36,
              ),
              title: const Text(
                'Certificatul meu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Vizualizează și exportă certificatul digital',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CertificatePage()),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          _personalStatsCard(),

          const SizedBox(height: 20),

          // Setări cont
          const Text(
            'Setări cont',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Editează contul'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              // Navighează la AccountSettingsPage și așteaptă update
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
              );
              // Reîncarcă datele după ce utilizatorul a modificat
              _loadUserData();
            },
          ),
        ],
      ),
    );
  }
}
