import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../service/notificari_service.dart';

class NotificariPage extends StatefulWidget {
  const NotificariPage({super.key});

  @override
  State<NotificariPage> createState() => _NotificariPageState();
}

class _NotificariPageState extends State<NotificariPage> {
  final NotificariService _notificariService = NotificariService();

  String _formateazaData(dynamic valoare) {
    if (valoare is! Timestamp) {
      return 'Acum';
    }

    final data = valoare.toDate();

    final zi = data.day.toString().padLeft(2, '0');
    final luna = data.month.toString().padLeft(2, '0');
    final an = data.year.toString();

    final ora = data.hour.toString().padLeft(2, '0');
    final minut = data.minute.toString().padLeft(2, '0');

    return '$zi.$luna.$an • $ora:$minut';
  }

  IconData _iconPentruTip(String tip) {
    switch (tip) {
      case 'propunere_aprobata':
        return Icons.check_circle;
      case 'propunere_respinsa':
        return Icons.cancel;
      case 'favorit':
        return Icons.favorite;
      case 'planner':
        return Icons.event_note;
      case 'itinerar_ai':
        return Icons.auto_awesome;
      case 'recenzie':
        return Icons.rate_review;
      case 'puncte':
        return Icons.stars;
      default:
        return Icons.notifications;
    }
  }

  Color _culoarePentruTip(String tip) {
    switch (tip) {
      case 'propunere_aprobata':
        return Colors.green;
      case 'propunere_respinsa':
        return Colors.red;
      case 'favorit':
        return Colors.pink;
      case 'planner':
        return Colors.blue;
      case 'itinerar_ai':
        return Colors.deepPurple;
      case 'recenzie':
        return Colors.orange;
      case 'puncte':
        return Colors.amber.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificări'),
        actions: [
          TextButton(
            onPressed: () async {
              await _notificariService.marcheazaToateCaCitite();
            },
            child: const Text('Marchează citite'),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificariService.getNotificari(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Notificările nu au putut fi încărcate: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final notificari = snapshot.data ?? [];

          if (notificari.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 76,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Nu ai notificări încă.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notificari.length,
            itemBuilder: (context, index) {
              final notificare = notificari[index];

              final id = notificare['id']?.toString() ?? '';
              final titlu = notificare['titlu']?.toString() ?? 'Notificare';
              final mesaj = notificare['mesaj']?.toString() ?? '';
              final tip = notificare['tip']?.toString() ?? '';
              final citita = notificare['citita'] == true;
              final puncte = (notificare['puncte'] as num?)?.toInt() ?? 0;

              final culoare = _culoarePentruTip(tip);

              return Dismissible(
                key: ValueKey(id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await _notificariService.stergeNotificare(id);
                },
                child: Card(
                  elevation: citita ? 1 : 4,
                  color: citita ? null : culoare.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: citita ? Colors.transparent : culoare,
                      width: citita ? 0 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: culoare.withValues(alpha: 0.14),
                      child: Icon(_iconPentruTip(tip), color: culoare),
                    ),
                    title: Text(
                      titlu,
                      style: TextStyle(
                        fontWeight: citita
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mesaj),
                          if (puncte > 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              '+$puncte puncte',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            _formateazaData(notificare['creataLa']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: citita
                        ? null
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                    onTap: () async {
                      if (!citita && id.isNotEmpty) {
                        await _notificariService.marcheazaCaCitita(id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
