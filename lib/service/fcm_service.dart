import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
        'tourmate_notificari',
        'Notificări TourMate',
        description:
            'Notificări pentru activități, puncte și propuneri TourMate.',
        importance: Importance.high,
      );

  Future<void> initializeaza() async {
    final utilizator = _auth.currentUser;

    if (utilizator == null) {
      return;
    }

    await _initializeazaNotificariLocale();

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    final token = await _messaging.getToken();

    if (token != null) {
      await _salveazaToken(token);
    }

    _messaging.onTokenRefresh.listen((tokenNou) async {
      await _salveazaToken(tokenNou);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _afiseazaNotificareForeground(message);
    });
  }

  Future<void> _initializeazaNotificariLocale() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings: initializationSettings);

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  Future<void> _afiseazaNotificareForeground(RemoteMessage message) async {
    final titlu =
        message.notification?.title ??
        message.data['titlu']?.toString() ??
        'TourMate';

    final mesaj =
        message.notification?.body ??
        message.data['mesaj']?.toString() ??
        'Ai o notificare nouă.';

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: titlu,
      body: mesaj,
      notificationDetails: notificationDetails,
      payload: message.data['notificareId']?.toString(),
    );
  }

  Future<void> _salveazaToken(String token) async {
    final utilizator = _auth.currentUser;

    if (utilizator == null) {
      return;
    }

    await _db
        .collection('utilizatori')
        .doc(utilizator.uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'token': token,
          'platforma': Platform.isAndroid
              ? 'android'
              : Platform.isIOS
              ? 'ios'
              : 'necunoscut',
          'actualizatLa': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> stergeTokenCurent() async {
    final utilizator = _auth.currentUser;

    if (utilizator == null) {
      return;
    }

    final token = await _messaging.getToken();

    if (token == null) {
      return;
    }

    await _db
        .collection('utilizatori')
        .doc(utilizator.uid)
        .collection('fcmTokens')
        .doc(token)
        .delete();
  }
}
