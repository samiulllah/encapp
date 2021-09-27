import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/dialogue.dart';
import 'package:encapp/Providers/group.dart';
import 'package:encapp/Providers/group_chat.dart';
import 'package:encapp/Providers/home.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Screens/SingleChatPage.dart';
import 'package:encapp/Screens/widgets/UpdateApp/UpdateAvailable.dart';
import 'package:encapp/Screens/widgets/alerts.dart';
import 'package:encapp/Screens/widgets/drawer.dart';
import 'package:encapp/Screens/widgets/floating_action.dart';
import 'package:encapp/Services/Notifications/notifications.dart';
import 'package:encapp/Services/chat.dart';
import 'package:encapp/Services/group_chat.dart';
import 'package:encapp/Services/user.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:screen_state/screen_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'GroupChatPage.dart';
import 'UnlockPage.dart';

class HomePage extends StatefulWidget {
  String myId;
  HomePage({this.myId});
  @override
  _HomePageState createState() => _HomePageState(myId: myId);
}

class _HomePageState extends State<HomePage> {
  int currentTab = 0;
  UserProvider userProvider;
  String myId = 'C3DE8127';
  String myName = 'Ronaldo';
  SharedPreferences sharedPreferences;
  _HomePageState({this.myId});
  double w, h;
  bool get condition => null;
  GlobalKey key = OneContext().key;

  @override
  Widget build(BuildContext context) {
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;
    return new WillPopScope(
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Color(0xff040d5a),
            drawerEnableOpenDragGesture: false,
            appBar: AppBar(
              brightness: Brightness.dark,
              backgroundColor: Color(0xff040d5a),
              centerTitle: true,
              leading: Builder(
                builder: (context) => // Ensure Scaffold is in context
                    Center(
                  child: GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Container(
                      margin: EdgeInsets.only(left: 10),
                      child: Text(
                        "Enc.",
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'UbuntuTitling',
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
              title: TabBar(
                indicatorColor: Colors.white,
                onTap: (val) {
                  setState(() {
                    currentTab = val;
                  });
                },
                tabs: [
                  Tab(
                      child: Text(
                    'Chats',
                    style: TextStyle(
                        color: currentTab != 0 ? Colors.grey : Colors.white,
                        fontFamily: 'UbuntuTitling',
                        fontSize: 18),
                  )),
                  Tab(
                      child: Text(
                    'Groups',
                    style: TextStyle(
                        color: currentTab != 1 ? Colors.grey : Colors.white,
                        fontSize: 18,
                        fontFamily: 'UbuntuTitling'),
                  )),
                ],
              ),
              elevation: 0,
            ),
            body: TabBarView(
              children: [
                SingleChatPage(
                  myId: myId,
                ),
                GroupChatPage()
              ],
            ),
            drawer: getDrawer(context, myId, myName, getAlias),
          ),
        ),
        onWillPop: _willPopCallback);
  }

  Future<bool> _willPopCallback() async {
    return true;
  }

  getAlias() async {
    setState(() {
      myName = 'Mr. John';
    });
  }

  Widget header(int nosSelected, DialogueProvider hp) {
    double h = MediaQuery.of(context).size.height;
    return Container(
      height: h * .1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            'Selected  $nosSelected',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Spacer(),
          GestureDetector(
            onTap: () async {
              showProgress(context, "Deleting");
              await hp.deleteSelected();
              hp.unSelectAll();
              await Provider.of<GroupProvider>(context, listen: false)
                  .getAllGroups();
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Icon(
              Icons.delete,
              color: Colors.cyan,
              size: 25,
            ),
          ),
          SizedBox(
            width: 15,
          ),
          GestureDetector(
            onTap: () async {
              hp.unSelectAll();
            },
            child: Icon(
              Icons.cancel_outlined,
              color: Colors.cyan,
              size: 25,
            ),
          ),
          SizedBox(
            width: 10,
          )
        ],
      ),
    );
  }
}
