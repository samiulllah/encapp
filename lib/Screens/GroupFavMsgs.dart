import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Models/group_message.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/group_chat.dart';
import 'package:encapp/Providers/user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupFavouriteMessagePage extends StatefulWidget {
  GroupModel gm;
  GroupFavouriteMessagePage({this.gm});
  @override
  _GroupFavouriteMessagePageState createState() =>
      _GroupFavouriteMessagePageState();
}

class _GroupFavouriteMessagePageState extends State<GroupFavouriteMessagePage> {
  double w, h;
  int flag = -1; // me
  String myId;

  GroupChatProvider chatProvider;
  init() async {
    chatProvider = Provider.of<GroupChatProvider>(context, listen: false);
    chatProvider.fetchFavouriteMsgs();
    String id = await chatProvider.cs.getDeviceId();
    setState(() {
      myId = id;
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  List<Widget> renderMsgs(List<GroupMessageModel> msgs1) {
    List<Widget> rm = [];
    for (GroupMessageModel m in msgs1) {
      if (m.fromId == myId) {
        // i'm sender
        if (flag == 0) {
          rm.add(myMsg(
            msg: m.msg,
            time: DateFormat("hh:mm").format(m.datetime).toString(),
            isRead: m.read == 1,
            name: m.fromAlias == null ? m.fromId : m.fromAlias,
            type: 0,
          ));
        } else {
          rm.add(
            myMsg(
                msg: m.msg,
                time: DateFormat("hh:mm").format(m.datetime).toString(),
                isRead: m.read == 1,
                name: m.fromAlias == null ? m.fromId : m.fromAlias,
                type: 0), //0
          );
        }

        flag = 0;
      } else {
        // i'm receiver
        if (flag == 1) {
          rm.add(
            otherMsg(
              msg: m.msg,
              name: m.fromAlias == null ? m.fromId : m.fromAlias,
              time: DateFormat("hh:mm").format(m.datetime).toString(),
              type: 0,
            ),
          );
        } else {
          rm.add(
            otherMsg(
              msg: m.msg,
              name: m.fromAlias == null ? m.fromId : m.fromAlias,
              time: DateFormat("hh:mm").format(m.datetime).toString(),
              type: 0,
            ),
          );
        }
        flag = 1;
      }
    }
    return rm;
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<GroupChatProvider>();
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xff040d5a),
      appBar: AppBar(
        brightness: Brightness.dark,
        backgroundColor: Color(0xff040d5a),
        elevation: 2,
        title: Text(
          'Favourite messages',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'UbuntuTitling',
          ),
        ),
        leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back_sharp,
              color: Colors.white,
            )),
      ),
      body: Container(
        height: h,
        width: w,
        child: Column(
          children: [
            Container(
              width: w,
              height: 1,
              color: Colors.grey,
            ),
            SizedBox(
              height: 15,
            ),
            ...renderMsgs(cp.favMsgs)
          ],
        ),
      ),
    );
  }

  Widget myMsg({String msg, String time, bool isRead, int type, String name}) {
    String burnTime = '5d';
    return Container(
      margin: EdgeInsets.only(top: 10),
      width: w,
      child: Column(children: [
        if (type == 0)
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 10,
              ),
              Text(name, style: TextStyle(color: Colors.grey[500])),
              SizedBox(
                width: 10,
              ),
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    )),
              ),
              SizedBox(
                width: 10,
              ),
            ],
          ),
        SizedBox(
          height: 10,
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              msg,
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: 10,
            ),
          ],
        ),
        SizedBox(
          height: 5,
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              burnTime,
              style: TextStyle(color: Colors.blue, fontSize: 11),
            ),
            SizedBox(
              width: 10,
            ),
            Text(time, style: TextStyle(color: Colors.grey, fontSize: 11)),
            SizedBox(
              width: 10,
            ),
            Icon(
              Icons.check,
              color: Colors.green,
              size: 18,
            ),
            SizedBox(
              width: 10,
            ),
          ],
        )
      ]),
    );
  }

  Widget otherMsg(
      {String msg, String time, String name, bool isRead, int type}) {
    String burnTime = '5d';
    return Container(
      width: w,
      child: Column(children: [
        if (type == 0)
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 10,
              ),
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyan, width: 2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    )),
              ),
              SizedBox(
                width: 10,
              ),
              Text(name, style: TextStyle(color: Colors.cyan)),
              SizedBox(
                width: 10,
              ),
            ],
          ),
        SizedBox(
          height: 10,
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 10,
            ),
            Text(
              msg,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        SizedBox(
          height: 5,
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 10,
            ),
            Text(
              time,
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            SizedBox(
              width: 10,
            ),
            Text(burnTime, style: TextStyle(color: Colors.blue, fontSize: 11)),
          ],
        )
      ]),
    );
  }
}
