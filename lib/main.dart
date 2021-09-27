import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/dialogue.dart';
import 'package:encapp/Providers/group.dart';
import 'package:encapp/Providers/group_chat.dart';
import 'package:encapp/Screens/SetAliasPage.dart';
import 'package:encapp/Screens/TermsAndPrivacy.dart';
import 'package:encapp/Screens/widgets/UpdateApp/UpdateAvailable.dart';
import 'package:encapp/Services/Notifications/notifications.dart';
import 'package:encapp/Services/chat.dart';
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:encapp/Services/group_chat.dart';
import 'package:encapp/Services/user.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:one_context/one_context.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:vibration/vibration.dart';
import 'Providers/home.dart';
import 'Providers/user.dart';
import 'Screens/HomePage.dart';
import 'Screens/UnlockPage.dart';
import 'package:flutter_isolate/flutter_isolate.dart';

Future<void> main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GlobalKey key = OneContext().key;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => HomeProvider()),
          ChangeNotifierProvider(create: (context) => UserProvider()),
          ChangeNotifierProvider(create: (context) => GroupProvider()),
          ChangeNotifierProvider(create: (context) => ChatProvider()),
          ChangeNotifierProvider(create: (context) => DialogueProvider()),
          ChangeNotifierProvider(create: (context) => GroupChatProvider()),
        ],
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: MaterialApp(
            builder: OneContext().builder,
            navigatorKey: key,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(),
            home: HomePage(
              myId: 'myId',
            ),
          ),
        ));
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  UserProvider userProvider;

  navigate() async {
    OneContext().pushReplacement(
      MaterialPageRoute(builder: (_) => PrivacyTerms()),
    );
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([]);
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      navigate();
    });
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
          backgroundColor: Color(0xff040d5a),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                Text(
                  "Enc.",
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'UbuntuTitling',
                      fontWeight: FontWeight.bold,
                      fontSize: 40),
                ),
                Spacer(),
                SpinKitFadingFour(
                  color: Colors.cyan,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * .2,
                )
              ],
            ),
          )),
    );
  }
}
