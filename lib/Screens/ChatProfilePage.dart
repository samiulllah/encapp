import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/group_chat.dart';
import 'package:encapp/Providers/home.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Screens/widgets/floating_action.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:vibration/vibration.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'AliasPage.dart';

class ChatProfilePage extends StatefulWidget {
  String alias, cid;
  bool add;
  ChatProfilePage({this.alias, this.cid, this.add});
  @override
  _ChatProfilePageState createState() => _ChatProfilePageState();
}

class _ChatProfilePageState extends State<ChatProfilePage> {
  bool value1 = false;
  double w, h;
  SharedPreferences sharedPreferences;

  init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      value1 = sharedPreferences.containsKey('snooze${widget.cid}')
          ? sharedPreferences.getBool('snooze${widget.cid}')
          : false;
    });
  }

  showDeleteContactDialog(BuildContext context) async {
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xff040d5a),
          title: Text("Delete Contact",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              )),
          content: Text(
            "Do you want to delete this contact?",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              child: Text("Cancel",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                "Delete",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              onPressed: () async {
                int delete = 0;
                bool exist =
                    await Provider.of<UserProvider>(context, listen: false)
                        .doesContactExist(widget.cid);
                if (exist) {
                  delete =
                      await Provider.of<UserProvider>(context, listen: false)
                          .deleteContact(widget.cid);
                }
                Navigator.of(context).pop();
                if (delete == 1) OneContext().pop();
              },
            )
          ],
        );
      },
    );
  }

  void popUntilRoot({Object result}) {
    if (OneContext().canPop()) {
      OneContext().pop();
      popUntilRoot();
    }
  }

  showDeleteChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xff040d5a),
          title: Text("Delete Chat",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: Text(
            "If You delete, you will lose chat and other history.",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(
                "Delete",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              onPressed: () async {
                await Provider.of<ChatProvider>(context, listen: false)
                    .deleteConversation();
                await Provider.of<ChatProvider>(OneContext().context,
                        listen: false)
                    .disposeSocket();
                await Future.delayed(Duration(seconds: 1));
                Navigator.pop(context);
                popUntilRoot();
              },
            )
          ],
        );
      },
    );
  }

  showBlockDialog(BuildContext context) {
    bool b = Provider.of<ChatProvider>(context, listen: false).block == 1
        ? true
        : false;
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xff040d5a),
          title: Text(b ? "Unblock User" : "Block User",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              )),
          content: Text(
            "Do you want to ${b ? 'unblock' : 'block'} ${widget.alias}?",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                b ? "Unblock" : "Block",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () async {
                if (!b) {
                  int block = 0;
                  bool exist =
                      await Provider.of<UserProvider>(context, listen: false)
                          .doesContactExist(widget.cid);
                  if (exist) {
                    block =
                        await Provider.of<UserProvider>(context, listen: false)
                            .blockContact(widget.cid, 1);
                    Provider.of<ChatProvider>(context, listen: false)
                        .setBlock(1);
                  } else {
                    // first add contact then block it.
                    await Provider.of<UserProvider>(context, listen: false)
                        .addFriend({'alias': widget.alias, 'cid': widget.cid});
                    block =
                        await Provider.of<UserProvider>(context, listen: false)
                            .blockContact(widget.cid, 1);
                    Provider.of<ChatProvider>(context, listen: false)
                        .setBlock(1);
                  }
                  Navigator.of(context).pop();
                  if (block == 1) OneContext().pop();
                } else {
                  int block = 0;
                  bool exist =
                      await Provider.of<UserProvider>(context, listen: false)
                          .doesContactExist(widget.cid);
                  if (exist) {
                    block =
                        await Provider.of<UserProvider>(context, listen: false)
                            .unblockUser(widget.cid, 1);
                    Provider.of<ChatProvider>(context, listen: false)
                        .setBlock(0);
                  }
                  Navigator.of(context).pop();
                  if (block == 1) OneContext().pop();
                }
              },
            )
          ],
        );
      },
    );
  }

  void contactAdded() {
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xff040d5a),
          content: Text(
            "\'${widget.alias}\' has been added to your contact list.",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Ok",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                )),
            SizedBox(
              width: 5,
            )
          ],
        );
      },
    );
  }

  @override
  void initState() {
    init();
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
      if (widget.add) {
        contactAdded();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HomeProvider>();
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xff040d5a),
      appBar: AppBar(
        brightness: Brightness.dark,
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: hp.isConnected
          ? SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: Colors.blue,
                    height: 10,
                  ),
                  Container(
                    height: 100,
                    color: Colors.blue,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                            ),
                            Text(
                              widget.alias,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 22),
                            ),
                            Spacer(),
                            SizedBox(
                              width: 10,
                            )
                          ],
                        ),
                        Spacer(),
                        Container(
                          color: Colors.pinkAccent,
                          height: 30,
                          child: Center(
                            child: Text(
                              "Secured with AES ",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        'CID',
                        style: TextStyle(color: Colors.white),
                      ),
                      Spacer(),
                      Text(
                        widget.cid,
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: "${widget.cid}"));
                          Vibration.vibrate(duration: 100);
                          Toast.show('Copied!', context,
                              textColor: Colors.black,
                              backgroundColor: Colors.white,
                              backgroundRadius: 10);
                        },
                        child: Icon(
                          Icons.copy,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Divider(
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  GestureDetector(
                    onTap: () {
                      Toast.show('Coming soon!', context,
                          textColor: Colors.black,
                          backgroundColor: Colors.white,
                          backgroundRadius: 10);
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                        ),
                        Text(
                          'Color',
                          style: TextStyle(color: Colors.white),
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xff7c94b6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Divider(
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        'Groups in Common',
                        style: TextStyle(color: Colors.white),
                      ),
                      Spacer(),
                      Text(
                        '0',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Divider(
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        'Tone',
                        style: TextStyle(color: Colors.white),
                      ),
                      Spacer(),
                      Text(
                        'Default',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Divider(
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 0,
                  ),
                  Container(
                    height: 40,
                    child: SettingsList(
                      backgroundColor: Color(0xff040d5a),
                      physics: const NeverScrollableScrollPhysics(),
                      sections: [
                        SettingsSection(
                          tiles: [
                            SettingsTile.switchTile(
                              title: 'Snooze Notifications',
                              titleTextStyle: TextStyle(color: Colors.white),
                              // leading: Icon(Icons.fingerprint),
                              switchValue: value1,
                              onToggle: (bool value) {
                                setState(() {
                                  value1 = value;
                                });
                                sharedPreferences.setBool(
                                    'snooze${widget.cid}', value);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 0,
                  ),
                  Divider(
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        'Repeat',
                        style: TextStyle(color: Colors.white),
                      ),
                      Spacer(),
                      Text(
                        'Default',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Divider(
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        'Vibrate',
                        style: TextStyle(color: Colors.white),
                      ),
                      Spacer(),
                      Text(
                        'Default',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Divider(
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  GestureDetector(
                    onTap: () {
                      showDeleteChatDialog(context);
                    },
                    child: Container(
                      color: Color(0xff040d5a),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12,
                            ),
                            Text(
                              'Delete Chat',
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                            Spacer(),
                            Text(
                              '',
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Divider(
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 60,
                  ),
                  if (Provider.of<ChatProvider>(context, listen: false).block !=
                      2)
                    GestureDetector(
                      onTap: () {
                        showBlockDialog(context);
                      },
                      child: Container(
                        height: 50,
                        width: 300,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Center(
                          child: Text(
                            Provider.of<ChatProvider>(context, listen: false)
                                        .block ==
                                    0
                                ? 'BLOCK USER'
                                : 'UNBLOCK USER',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () async {
                      showDeleteContactDialog(context);
                    },
                    child: Container(
                      height: 50,
                      width: 300,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.red,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child: Text(
                          'DELETE CONTACT',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  )
                ],
              ),
            )
          : noConnection(w, h),
    );
  }
}
