import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'Models/message.dart';
import 'Services/Notifications/notifications.dart';
import 'Services/chat.dart';
import 'Services/database/DBHelper.dart';

void main() async {
  print("FCM calls main");
  WidgetsFlutterBinding.ensureInitialized();
  const platform = MethodChannel('matrix.app/notify');
  platform.setMethodCallHandler((call) async {
    print("FCM Invoke method");
    await FlutterIsolate.spawn(handleNotification, call.arguments.toString());
    // iso.controlPort = await completer.future;
    // (await completer.future)
    //     .send('This is from myIsolate, please update dialoges');
    return;
  });
}

void handleNotification(String arg) async {
  print("Isolate FCm");
  Map map = jsonDecode(arg);
  // decrypt msg
  ChatService cs = new ChatService();
  String key = cs.getKey(
      map['to_id'].toString().trim(), map['from_id'].toString().trim());
  map['msg'] = cs.decrypt(map['msg'], key);
  MessageModel md = MessageModel.fromJson(map);
  // notify user
  BackgroundNotifications ns = new BackgroundNotifications();
  ns.initLocal();
  ns.createSimpleNotification("New messages", "");
  // now save message to db
  DBHelper db = new DBHelper();
  db.saveMsg(md);
  // update dialogues
}
