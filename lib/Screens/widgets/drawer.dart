import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/group.dart';
import 'package:encapp/Providers/group_chat.dart';
import 'package:encapp/Screens/GroupFavMsgs.dart';
import 'package:encapp/Screens/GroupProfile.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:vibration/vibration.dart';

import '../AliasPage.dart';
import '../ChatProfilePage.dart';
import '../ContactsPage.dart';
import '../FavouriteMessagePage.dart';
import '../InviteFriend.dart';
import '../SettingPage.dart';
import '../UnlockPage.dart';

Widget getDrawer(
    BuildContext context, String cid, String name, Function callBack) {
  return Drawer(
    child: Container(
      color: Color(0xff040d5a),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xff040d5a),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);

                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(builder: (_) => AliasPage()),
                  )
                      .then((value) async {
                    callBack();
                  });
                },
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Enc.',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            color: Colors.white,
                            fontFamily: 'UbuntuTitling'),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.blue, width: 1),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  bottomRight: Radius.circular(7),
                                )),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                name,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: "$cid"));
                                  Vibration.vibrate(duration: 100);
                                  Toast.show('Copied!', context,
                                      textColor: Colors.black,
                                      backgroundColor: Colors.white,
                                      backgroundRadius: 10);
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      'CID: $cid',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Icon(
                                      Icons.copy_outlined,
                                      color: Colors.grey,
                                      size: 15,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          Icon(
                            Icons.person_outline,
                            color: Colors.white,
                          )
                        ],
                      ),
                    ]),
              )),
          ListTile(
            title: const Text(
              'Contacts',
              style: TextStyle(color: Colors.white),
            ),
            leading: Icon(
              Icons.contact_mail_sharp,
              color: Colors.white,
            ),
            onTap: () {
              Navigator.pop(context);

              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ContactsPage()),
              );
            },
          ),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          ListTile(
            title: const Text(
              'Settings',
              style: TextStyle(color: Colors.white),
            ),
            leading: Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onTap: () async {
              Navigator.pop(context);
              Navigator.of(context)
                  .push(
                MaterialPageRoute(builder: (_) => SettingPage()),
              )
                  .then((value) async {
                await Provider.of<ChatProvider>(OneContext().context,
                        listen: false)
                    .fetchDialogues();
                await Provider.of<GroupChatProvider>(OneContext().context,
                        listen: false)
                    .fetchDialogues();
                await Provider.of<GroupProvider>(OneContext().context,
                        listen: false)
                    .getAllGroups();
              });
            },
          ),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          ListTile(
            title: const Text(
              'Delete All Chats',
              style: TextStyle(color: Colors.red),
            ),
            leading: Icon(
              Icons.delete,
              color: Colors.red,
            ),
            onTap: () {
              showDeleteDialog(context);
            },
          ),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          ListTile(
            title: const Text(
              'Lock',
              style: TextStyle(color: Colors.white),
            ),
            leading: Icon(
              Icons.lock_outline,
              color: Colors.white,
            ),
            onTap: () {
              OneContext().pushReplacement(
                MaterialPageRoute(builder: (_) => UnlockPage()),
              );
            },
          ),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
        ],
      ),
    ),
  );
}

void showDeleteDialog(BuildContext context) {
  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      bool submit = false;
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text("Delete All Chats"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Text("This will delete all conversations")),
              SizedBox(
                height: 30,
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                    child: Text(
                      "CANCEL",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Spacer(),
                  submit
                      ? SpinKitCircle(color: Colors.blue, size: 30)
                      : InkWell(
                          onTap: () async {
                            setState(() {
                              submit = true;
                            });
                            await Provider.of<ChatProvider>(
                                    OneContext().context,
                                    listen: false)
                                .deleteAllConversations();
                            await Provider.of<GroupChatProvider>(
                                    OneContext().context,
                                    listen: false)
                                .deleteAllConversations();
                            await Provider.of<ChatProvider>(
                                    OneContext().context,
                                    listen: false)
                                .fetchDialogues();
                            await Provider.of<GroupChatProvider>(
                                    OneContext().context,
                                    listen: false)
                                .fetchDialogues();
                            await Provider.of<GroupProvider>(
                                    OneContext().context,
                                    listen: false)
                                .getAllGroups();
                            setState(() {
                              submit = false;
                            });
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          child: Text(
                            "PROCEED",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                        )
                ],
              ),
            ],
          ),
        );
      });
    },
  );
}

Widget getEndDrawer(
    BuildContext context, String peerName, String cid, Function callback) {
  return Drawer(
    child: Container(
      color: Color(0xff040d5a),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 50,
          ),
          ListTile(
            title: const Text(
              'View Profile',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'UbuntuTitling',
              ),
            ),
            // leading: Icon(Icons.contact_mail_sharp,color: Colors.white,),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                    builder: (_) => ChatProfilePage(
                          alias: peerName,
                          cid: cid,
                          add: false,
                        )),
              )
                  .then((value) {
                callback();
              });
            },
          ),
          Divider(
            color: Colors.grey,
            indent: 20,
            endIndent: 20,
          ),
          ListTile(
            title: const Text(
              'Favourite messages',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'UbuntuTitling',
              ),
            ),
            // leading: Icon(Icons.settings,color: Colors.white,),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => FavouriteMessagePage(
                          peerName: peerName,
                        )),
              );
            },
          ),
          Divider(
            color: Colors.grey,
            indent: 20,
            endIndent: 20,
          ),
          ListTile(
            title: const Text(
              'Block contact',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'UbuntuTitling',
              ),
            ),
            // leading: Icon(Icons.delete,color: Colors.red,),
            onTap: () {
              Navigator.pop(context);
              showBlockDialog(context);
            },
          ),
          Divider(
            color: Colors.grey,
            indent: 20,
            endIndent: 20,
          ),
          ListTile(
            title: const Text(
              'Clear chat history',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'UbuntuTitling',
              ),
            ),
            // leading: Icon(Icons.person_add_rounded,color: Colors.white,),
            onTap: () {
              Navigator.pop(context);
              showClearChatDialog(context, 0);
            },
          ),
          Divider(
            color: Colors.grey,
            indent: 20,
            endIndent: 20,
          ),
          ListTile(
            title: const Text(
              'Delete chat',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'UbuntuTitling',
              ),
            ),
            // leading: Icon(Icons.article_outlined,color: Colors.white,),
            onTap: () {
              Navigator.pop(context);
              showDeleteChatDialog(context, 0);
            },
          ),
          Divider(
            color: Colors.grey,
            indent: 20,
            endIndent: 20,
          ),
        ],
      ),
    ),
  );
}

showBlockDialog(BuildContext context) {
  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Color(0xff040d5a),
        title: Text("Block User",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          "Do you want to block Sami?",
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
              "Block",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      );
    },
  );
}

showClearChatDialog(BuildContext context, int mode) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Color(0xff040d5a),
        title: Text("Clear Chat",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          "If You clear, you'll lose all messages but it will still appear in chat list.",
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
              "Clear",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            onPressed: () async {
              if (mode == 0) {
                await Provider.of<ChatProvider>(context, listen: false)
                    .deleteChatHistory();
                Navigator.pop(context);
              } else {
                await Provider.of<GroupChatProvider>(context, listen: false)
                    .deleteChatHistory();
                Navigator.pop(context);
              }
            },
          )
        ],
      );
    },
  );
}

showDeleteChatDialog(BuildContext context, int mode) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      bool submit = false;
      return StatefulBuilder(builder: (context, setState) {
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
            if (!submit)
              TextButton(
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            if (submit)
              Container(
                margin: EdgeInsets.only(bottom: 10, right: 10),
                child: SpinKitCircle(
                  size: 25,
                  color: Colors.orange,
                ),
              ),
            if (!submit)
              TextButton(
                child: Text(
                  "Delete",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                onPressed: () async {
                  setState(() {
                    submit = true;
                  });
                  if (mode == 0) {
                    await Provider.of<ChatProvider>(context, listen: false)
                        .deleteConversation();
                    await Provider.of<ChatProvider>(OneContext().context,
                            listen: false)
                        .disposeSocket();
                    await Future.delayed(Duration(seconds: 1));
                    Navigator.pop(context);
                    popUntilRoot();
                  } else {
                    await Provider.of<GroupChatProvider>(context, listen: false)
                        .deleteConversation();
                    await Provider.of<GroupChatProvider>(OneContext().context,
                            listen: false)
                        .disposeSocket();
                    await Future.delayed(Duration(seconds: 1));
                    Navigator.pop(context);
                    popUntilRoot();
                  }
                  setState(() {
                    submit = false;
                  });
                },
              )
          ],
        );
      });
    },
  );
}

void popUntilRoot({Object result}) {
  if (OneContext().canPop()) {
    OneContext().pop();
    popUntilRoot();
  }
}

Widget getEndDrawerForGroupChat(
    BuildContext context, GroupModel gm, String myId) {
  return Drawer(
    child: Container(
      color: Color(0xff040d5a),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 50,
          ),
          ListTile(
            title: const Text(
              'Group Info',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'UbuntuTitling',
              ),
            ),
            // leading: Icon(Icons.contact_mail_sharp,color: Colors.white,),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => GroupProfileScreen(
                          gm: gm,
                          myId: myId,
                        )),
              );
            },
          ),
          Divider(
            color: Colors.grey,
            indent: 20,
            endIndent: 20,
          ),
          ListTile(
            title: const Text(
              'Favourite messages',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'UbuntuTitling',
              ),
            ),
            // leading: Icon(Icons.settings,color: Colors.white,),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => GroupFavouriteMessagePage(
                          gm: gm,
                        )),
              );
            },
          ),
          Divider(
            color: Colors.grey,
            indent: 20,
            endIndent: 20,
          ),
          ListTile(
            title: const Text(
              'Clear chat history',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'UbuntuTitling',
              ),
            ),
            // leading: Icon(Icons.person_add_rounded,color: Colors.white,),
            onTap: () {
              Navigator.pop(context);
              showClearChatDialog(context, 1);
            },
          ),
          Divider(
            color: Colors.grey,
            indent: 20,
            endIndent: 20,
          ),
          ListTile(
            title: const Text(
              'Delete chat',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'UbuntuTitling',
              ),
            ),
            // leading: Icon(Icons.article_outlined,color: Colors.white,),
            onTap: () {
              Navigator.pop(context);
              showDeleteChatDialog(context, 1);
            },
          ),
          Divider(
            color: Colors.grey,
            indent: 20,
            endIndent: 20,
          ),
        ],
      ),
    ),
  );
}
