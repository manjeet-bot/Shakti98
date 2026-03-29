import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';



class NotificationService {

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;



  static Future<void> initialize() async {

    // Request permission for iOS

    await _messaging.requestPermission(

      alert: true,

      announcement: false,

      badge: true,

      carPlay: false,

      criticalAlert: false,

      provisional: false,

      sound: true,

    );



    // Get FCM token

    String? token = await _messaging.getToken();

    if (kDebugMode) {

      print('FCM Token: $token');

    }



    // Handle foreground messages

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);



    // Handle message when app is opened from notification

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);



    // Check for initial message if app was opened from notification

    RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {

      _handleMessageOpenedApp(initialMessage);

    }

  }



  static void _handleForegroundMessage(RemoteMessage message) {

    if (kDebugMode) {

      print('Received foreground message: ${message.messageId}');

    }



    // Show a snackbar or in-app notification for foreground messages

    // This can be customized based on your app's UI

  }



  static void _handleMessageOpenedApp(RemoteMessage message) {

    if (kDebugMode) {

      print('Message clicked: ${message.messageId}');

    }

    // Navigate to appropriate screen based on message data

    // For example, navigate to chat screen if message contains chatId

  }



  static Future<String?> getFCMToken() async {

    return await _messaging.getToken();

  }



  static Future<void> subscribeToTopic(String topic) async {

    await _messaging.subscribeToTopic(topic);

  }



  static Future<void> unsubscribeFromTopic(String topic) async {

    await _messaging.unsubscribeFromTopic(topic);

  }

}

