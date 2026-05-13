import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'supabase_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String defaultChannelId = 'clubmanager_default_channel';
  static const String defaultChannelName = 'ClubManager Sport';
  static const String defaultChannelDescription =
      'Notifiche principali di ClubManager Sport';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    await _initializeLocalNotifications();
    await _requestNotificationPermissions();
    await _saveCurrentTokenIfAuthenticated();

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      unawaited(_saveToken(token));
    });

    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((
      event,
    ) {
      final user = event.session?.user;

      if (user == null) {
        return;
      }

      unawaited(_saveCurrentTokenIfAuthenticated());
    });

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _authSubscription?.cancel();
    await _foregroundSubscription?.cancel();

    _tokenRefreshSubscription = null;
    _authSubscription = null;
    _foregroundSubscription = null;
    _initialized = false;
  }

  Future<void> refreshTokenRegistration() async {
    await _saveCurrentTokenIfAuthenticated();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(settings: settings);

    const channel = AndroidNotificationChannel(
      defaultChannelId,
      defaultChannelName,
      description: defaultChannelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestNotificationPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _saveCurrentTokenIfAuthenticated() async {
    if (!SupabaseService.isConfigured) {
      return;
    }

    final user = SupabaseService.client.auth.currentUser;

    if (user == null) {
      return;
    }

    final token = await _messaging.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    if (!SupabaseService.isConfigured) {
      return;
    }

    final user = SupabaseService.client.auth.currentUser;

    if (user == null) {
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final platform = _platformName();

    try {
      final existing = await SupabaseService.client
          .from('push_tokens')
          .select('id')
          .eq('user_id', user.id)
          .eq('token', token)
          .maybeSingle();

      if (existing == null) {
        await SupabaseService.client.from('push_tokens').insert({
          'user_id': user.id,
          'token': token,
          'platform': platform,
          'is_active': true,
          'last_seen_at': now,
        });
      } else {
        final existingId = (existing['id'] ?? '').toString();

        if (existingId.isEmpty) {
          return;
        }

        await SupabaseService.client
            .from('push_tokens')
            .update({
              'platform': platform,
              'is_active': true,
              'last_seen_at': now,
            })
            .eq('id', existingId);
      }

      await SupabaseService.client.from('notification_preferences').upsert({
        'user_id': user.id,
        'push_enabled': true,
        'updated_at': now,
      });
    } on PostgrestException catch (error) {
      debugPrint('Errore salvataggio token push: ${error.message}');
    } catch (error) {
      debugPrint('Errore salvataggio token push: $error');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    if (title == null || title.trim().isEmpty) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      defaultChannelId,
      defaultChannelName,
      channelDescription: defaultChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  String _platformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'unknown';
    }
  }
}
