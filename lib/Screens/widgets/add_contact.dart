import 'package:flutter/material.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/group.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Screens/widgets/loadingAlert.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';

import '../ChatProfilePage.dart';

Widget addContact(BuildContext context, double w, double h, String cid,
    String alias, Function reinit) {
  return Container(
    width: w,
    height: h * .2,
    color: Colors.blue,
    child: Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Unknown Contact",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "CID: \'${cid}\' and Alias : \'${alias}\' is not in your contact list. Add this contact so you can be confident all your communication"
            " are secure.",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () {
                showBlockDialog1(context, cid, alias);
              },
              child: Text(
                "BLOCK",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            SizedBox(
              width: 15,
            ),
            InkWell(
              onTap: () async {
                await addDialog(context, cid, alias);
                Provider.of<ChatProvider>(context, listen: false)
                    .disposeSocket();
                bool exit =
                    await Provider.of<UserProvider>(context, listen: false)
                        .doesContactExist(cid);
                if (exit) reinit();
              },
              child: Text(
                "ADD",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            SizedBox(
              width: 15,
            ),
          ],
        )
      ],
    ),
  );
}

showBlockDialog1(BuildContext context, String cid, String alias) {
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
          "Do you want to ${b ? 'unblock' : 'block'} ${alias}?",
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
                        .doesContactExist(cid);
                if (exist) {
                  block =
                      await Provider.of<UserProvider>(context, listen: false)
                          .blockContact(cid, 1);
                  Provider.of<ChatProvider>(context, listen: false).setBlock(1);
                } else {
                  // first add contact then block it.
                  await Provider.of<UserProvider>(context, listen: false)
                      .addFriend({'alias': alias, 'cid': cid});
                  block =
                      await Provider.of<UserProvider>(context, listen: false)
                          .blockContact(cid, 1);
                  Provider.of<ChatProvider>(context, listen: false).setBlock(1);
                }
                Navigator.of(context).pop();
                if (block == 1) OneContext().pop();
              } else {
                int block = 0;
                bool exist =
                    await Provider.of<UserProvider>(context, listen: false)
                        .doesContactExist(cid);
                if (exist) {
                  block =
                      await Provider.of<UserProvider>(context, listen: false)
                          .unblockUser(cid, 1);
                  Provider.of<ChatProvider>(context, listen: false).setBlock(0);
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

addToContacts(BuildContext context, String cid, String alias) async {
  Map map = {'cid': cid, 'alias': alias};
  int add =
      await Provider.of<UserProvider>(context, listen: false).addFriend(map);
  if (add != 0 && add != 99) {
    Navigator.of(context).pop();
    await OneContext().push(
      MaterialPageRoute(
          builder: (BuildContext context) =>
              ChatProfilePage(alias: alias, cid: cid, add: true)),
    );
  } else if (add == 99) {
    Toast.show('Contact already exists', context);
  } else {
    Toast.show('Failed to add!', context);
  }
  return;
}

addDialog(BuildContext context, String cid, String alias) async {
  // show the dialog
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Color(0xff040d5a),
        title: Text("ADD USER",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            )),
        content: Text(
          "Do you want to add $cid to your contact.",
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
              "Add",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () async {
              await addToContacts(context, cid, alias);
            },
          )
        ],
      );
    },
  );
  return;
}
