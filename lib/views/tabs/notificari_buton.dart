import 'package:flutter/material.dart';
import 'package:app_turism/service/notificari_service.dart';
import 'package:app_turism/views/notificari_page.dart';

class NotificariButon extends StatelessWidget {
  const NotificariButon({super.key});

  @override
  Widget build(BuildContext context) {
    final notificariService = NotificariService();

    return StreamBuilder<int>(
      stream: notificariService.getNumarNotificariNecitite(),
      initialData: 0,
      builder: (context, snapshot) {
        final numar = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notificări',
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificariPage()),
                );
              },
            ),
            if (numar > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    numar > 99 ? '99+' : numar.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
