import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../chat.dart';

// ping alert
showPingAlert(BuildContext context, String cid, String alias) async {
  if (await Vibration.hasVibrator()) {
    Vibration.vibrate();
  }
  // show the dialog
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Color(0xff040d5a),
        title: Text("Alert",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            )),
        content: Container(
          height: 150,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              color: Colors.grey.withOpacity(.3)),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(
              child: Text(
                "User with CID $cid and Alias $alias pinged you. Do you want to chat with this user?",
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'UbuntuTitling',
                    height: 1.2),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text(
              "Open",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () async {
              popUntilRoot();
              await Provider.of<ChatProvider>(context, listen: false)
                  .disposeSocket();
              await Future.delayed(Duration(seconds: 1));
              String myId =
                  await Provider.of<ChatProvider>(context, listen: false)
                      .cs
                      .getDeviceId();
              String convid =
                  await Provider.of<ChatProvider>(context, listen: false)
                      .cs
                      .getConvid(myId, cid.trim());
              OneContext().push(
                MaterialPageRoute(
                    builder: (_) => ChatScreen(
                          peerName: alias,
                          toId: cid,
                          convid: convid,
                        )),
              );
              Navigator.of(context).pop();
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

// show multiple pings alert
showPingMultiAlert(BuildContext context, List<Map> pings) async {
  if (await Vibration.hasVibrator()) {
    Vibration.vibrate();
  }
  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Color(0xff040d5a),
        title: Text("Multiple Ping Requests",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            )),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: getPingsChild(pings, context)),
        ),
        actions: [
          TextButton(
            child: Text(
              "Dismiss",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
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

Map getPingsCount(List<Map> maps) {
  Map count = {};
  List<String> ids = [];
  // find distinct ids
  for (Map m in maps) {
    if (ids.contains(m['from_id'])) {
      continue;
    }
    ids.add(m['from_id']);
  }
  // count for each id
  for (String s in ids) {
    int c = 0;
    for (Map n in maps) {
      if (s == n['from_id']) {
        c++;
      }
    }
    if (c == 0) c = 1;
    count[s] = c;
  }
  return count;
}

List<Widget> getPingsChild(List<Map> pings, BuildContext context) {
  List<Widget> pingsChilds = [];
  List<String> added = [];
  Map countOfPings = getPingsCount(pings);
  for (Map m in pings) {
    if (added.contains(m['from_id'])) {
      continue;
    }
    pingsChilds.add(Stack(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          margin: EdgeInsets.only(top: 15),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(.3),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Row(
            children: [
              Flexible(
                  child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        "Alias ",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'UbuntuTitling'),
                      ),
                      Text(
                        "${m['from_alias']}",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: [
                      Text(
                        "CID ",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'UbuntuTitling'),
                      ),
                      Text(
                        "${m['from_id']}",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white),
                      )
                    ],
                  )
                ],
              )),
              GestureDetector(
                onTap: () async {
                  popUntilRoot();
                  await Provider.of<ChatProvider>(context, listen: false)
                      .disposeSocket();
                  await Future.delayed(Duration(seconds: 1));
                  String myId =
                      await Provider.of<ChatProvider>(context, listen: false)
                          .cs
                          .getDeviceId();
                  String convid =
                      await Provider.of<ChatProvider>(context, listen: false)
                          .cs
                          .getConvid(myId, m['from_id'].trim());
                  OneContext().push(
                    MaterialPageRoute(
                        builder: (_) => ChatScreen(
                            peerName: m['from_alias'],
                            toId: m['from_id'],
                            convid: convid)),
                  );
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        "Chat",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        Positioned(
            top: 3,
            right: 0,
            child: Container(
              width: 25,
              height: 25,
              decoration:
                  BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  "${countOfPings[m['from_id']]}",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ))
      ],
    ));
    added.add(m['from_id']);
  }
  return pingsChilds;
}

showProgress(BuildContext context, String msg) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Color(0xff040d5a),
        title: Text("Please wait!",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            )),
        content: Container(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(children: [
              SpinKitCircle(
                color: Colors.orange,
                size: 30,
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                '$msg...',
                style: TextStyle(color: Colors.white),
              )
            ]),
          ),
        ),
      );
    },
  );
}
