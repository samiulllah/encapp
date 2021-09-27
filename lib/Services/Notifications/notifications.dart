import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:encapp/Services/user.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:volume_control/volume_control.dart';

class NotificationService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String token;

  Future<void> initNotifications() async {
    await getPermissions();
  }

  // get permissions
  Future<void> getPermissions() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<String> getFreshToken() async {
    await FirebaseMessaging.instance.getToken().then((tok) {
      token = tok;
    });
    return token;
  }
}

class BackgroundNotifications {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // initialize local notifications
  initLocal() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
            onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);
  }

  Future selectNotification(String payload) async {
    print('payload = $payload');
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {}
  createSimpleNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            playSound: false,
            sound: null,
            showWhen: false);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: 'item x');
    await playSound();
  }

  Future<void> playSound() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String ringtone = sharedPreferences.containsKey('ringtone')
        ? sharedPreferences.getString('ringtone')
        : "Ding";
    bool sound = sharedPreferences.containsKey('notificationSound')
        ? sharedPreferences.getBool('notificationSound')
        : true;
    bool vibrate = sharedPreferences.containsKey('notificationVibration')
        ? sharedPreferences.getBool('notificationVibration')
        : false;
    String repeat = sharedPreferences.containsKey('ringtoneRepeat')
        ? sharedPreferences.getString('ringtoneRepeat')
        : "1 time";
    int r = int.parse(repeat.split(' ')[0].trim());
    if (sound) {
      for (int i = 0; i < r; i++) {
        VolumeControl.setVolume(1);
        String mp3Url = 'sounds/$ringtone.mp3';
        AudioCache audioPlayer = AudioCache();
        await audioPlayer.play(mp3Url);
        if (vibrate) Vibration.vibrate();
        await Future.delayed(Duration(seconds: 10));
      }
    } else if (vibrate) {
      for (int i = 0; i < r; i++) {
        Vibration.vibrate();
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }
}
