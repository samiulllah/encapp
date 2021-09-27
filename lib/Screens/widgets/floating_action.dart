import 'dart:async';

import 'package:flutter/material.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/group_chat.dart';
import 'package:encapp/Services/user.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:encapp/Providers/user.dart';
import 'package:toast/toast.dart';
import '../AddContact.dart';
import '../CreatePage.dart';
import '../UnlockPage.dart';
import 'UpdateApp/UpdateAvailable.dart';

Widget getFloatingAction(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      GestureDetector(
        onTap: () async {
          ChatProvider chatProvider =
              Provider.of<ChatProvider>(UserService.homeContext, listen: false);
          GroupChatProvider groupChatProvider = Provider.of<GroupChatProvider>(
              UserService.homeContext,
              listen: false);
          UserProvider userProvider =
              Provider.of<UserProvider>(UserService.homeContext, listen: false);

          userProvider.us.socket.disconnect();
          chatProvider.disposeSocket();
          if (chatProvider.t != null && chatProvider.t.isActive)
            chatProvider.t.cancel();
          if (chatProvider.t1 != null && chatProvider.t1.isActive)
            chatProvider.t1.cancel();
          groupChatProvider.disposeSocket();
          if (groupChatProvider.t != null && groupChatProvider.t.isActive)
            groupChatProvider.t.cancel();
          if (groupChatProvider.t1 != null && groupChatProvider.t1.isActive)
            groupChatProvider.t1.cancel();
          bool update = await userProvider.isUpdateAvailable();
          print("update : $update");
          if (update) {
            OneContext().pushReplacement(
              MaterialPageRoute(builder: (_) => UpdateAvailableScreen()),
            );
            return;
          }
          OneContext().pushReplacement(
            MaterialPageRoute(builder: (_) => UnlockPage()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 18,
            child: Icon(
              Icons.lock_outline,
              color: Colors.black,
            ),
          ),
        ),
      ),
      FloatingActionButton(
        onPressed: () {
          // Add your onPressed code here!
          Navigator.of(context)
              .push(
            MaterialPageRoute(builder: (_) => CreateScreen()),
          )
              .then((value) {
            Provider.of<ChatProvider>(context, listen: false).fetchDialogues();
          });
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue,
      ),
    ],
  );
}

Widget getFloatingAction1(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      GestureDetector(
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => UnlockPage()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 18,
            child: Icon(
              Icons.lock_outline,
              color: Colors.black,
            ),
          ),
        ),
      ),
      FloatingActionButton(
        onPressed: () {
          // Add your onPressed code here!
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddContact()),
          );
        },
        child: const Icon(
          Icons.person_add_alt_1_rounded,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue,
      ),
    ],
  );
}

Widget noConnection(double w, double h) {
  return NoConnection();
}

class NoConnection extends StatefulWidget {
  const NoConnection({Key key}) : super(key: key);

  @override
  _NoConnectionState createState() => _NoConnectionState();
}

class _NoConnectionState extends State<NoConnection> {
  double w, h;
  bool loading = false;
  int connect = 0;

  @override
  Widget build(BuildContext context) {
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;
    return Container(
      color: Color(0xff040d5a),
      width: w,
      height: h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.signal_cellular_connected_no_internet_4_bar_outlined,
            color: Colors.white,
            size: w * .2,
          ),
          SizedBox(
            height: h * .07,
          ),
          Text(
            "Check you internet connection.",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          SizedBox(
            height: h * .1,
          ),
          if (!loading)
            GestureDetector(
              onTap: () async {
                setState(() {
                  loading = true;
                });
                await Provider.of<UserProvider>(context, listen: false)
                    .initSocket();
                await Future.delayed(Duration(seconds: 5), () {
                  if (mounted) {
                    Toast.show("Failed!", context);
                    setState(() {
                      connect++;
                      loading = false;
                    });
                  }
                });
              },
              child: Container(
                width: w * .5,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                    color: Colors.cyan,
                    borderRadius: BorderRadius.all(Radius.circular(15))),
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_outlined,
                      color: Colors.brown,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(connect >= 1 ? "Try Again" : "Connect",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            letterSpacing: .5))
                  ],
                ),
              ),
            ),
          SizedBox(
            height: h * .1,
          ),
          if (loading)
            Text(
              "connecting...",
              style: TextStyle(color: Colors.cyanAccent, fontSize: 18),
            ),
        ],
      ),
    );
  }
}
