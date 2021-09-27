import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavouriteMessagePage extends StatefulWidget {
  String peerName;
  FavouriteMessagePage({this.peerName});
  @override
  _FavouriteMessagePageState createState() =>
      _FavouriteMessagePageState(peerName: peerName);
}

class _FavouriteMessagePageState extends State<FavouriteMessagePage> {
  double w, h;
  String myId;
  String toId;
  String myName;
  String peerName;
  int flag = -1; // me
  ChatProvider chatProvider;
  _FavouriteMessagePageState({this.peerName});
  init() async {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String nam = sharedPreferences.getString('alias');
    chatProvider.fetchFavouriteMsgs();
    setState(() {
      myId = chatProvider.from_id;
      toId = chatProvider.to_id;
      myName = nam;
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  List<Widget> renderMsgs(List<MessageModel> msgs1) {
    List<Widget> rm = [];
    for (MessageModel m in msgs1) {
      if (m.fromId == myId) {
        // i'm sender
        if (flag == 0) {
          rm.add(myMsg(
            msg: m.msg,
            time: DateFormat("hh:mm").format(m.datetime).toString(),
            isRead: m.read == 1,
            type: 0,
          ));
        } else {
          rm.add(
            myMsg(
                msg: m.msg,
                time: DateFormat("hh:mm").format(m.datetime).toString(),
                isRead: m.read == 1,
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
              name: peerName,
              time: DateFormat("hh:mm").format(m.datetime).toString(),
              type: 0,
            ),
          );
        } else {
          rm.add(
            otherMsg(
              msg: m.msg,
              name: peerName,
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
    final cp = context.watch<ChatProvider>();
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
            ...renderMsgs(cp.favMsgs)
          ],
        ),
      ),
    );
  }

  Widget myMsg({String msg, String time, bool isRead, int type}) {
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
              Text(myId, style: TextStyle(color: Colors.grey[500])),
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
              Text(toId, style: TextStyle(color: Colors.cyan)),
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
