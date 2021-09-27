import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Providers/group.dart';
import 'package:encapp/Providers/home.dart';
import 'package:encapp/Screens/widgets/AddMoreMembers.dart';
import 'package:encapp/Screens/widgets/floating_action.dart';
import 'package:encapp/Screens/widgets/loadingAlert.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

import 'NewGroupPage.dart';

class GroupProfileScreen extends StatefulWidget {
  GroupModel gm;
  String myId;
  GroupProfileScreen({this.gm, this.myId});
  @override
  _GroupProfileScreenState createState() =>
      _GroupProfileScreenState(gm: gm, myId: myId);
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  GroupModel gm;
  String myId;
  bool value1 = false;
  double w, h;
  SharedPreferences sharedPreferences;
  GroupProvider groupProvider;
  init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      value1 = sharedPreferences.containsKey('snooze${widget.gm.grpId}')
          ? sharedPreferences.getBool('snooze${widget.gm.grpId}')
          : false;
    });
  }

  _GroupProfileScreenState({this.gm, this.myId});
  @override
  void initState() {
    init();
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HomeProvider>();
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;

    return hp.isConnected
        ? Scaffold(
            backgroundColor: Color(0xff040d5a),
            appBar: AppBar(
              brightness: Brightness.dark,
              backgroundColor: Colors.blue,
              elevation: 0,
            ),
            body: SingleChildScrollView(
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
                              gm.grpName,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 22),
                            ),
                            Spacer(),
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
                  description(),
                  line(),
                  members(),
                  line(),
                  setting(value1)
                ],
              ),
            ))
        : noConnection(w, h);
  }

  Widget description() {
    return Container(
      alignment: Alignment.topLeft,
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Description",
            style: TextStyle(color: Colors.blue),
          ),
          SizedBox(
            height: 15,
          ),
          Text(
            gm.desc,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget line() {
    return Container(
      height: 1,
      width: MediaQuery.of(context).size.width,
      color: Colors.grey,
    );
  }

  Widget members() {
    return Container(
      alignment: Alignment.topLeft,
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${gm.members.length} members",
            style: TextStyle(color: Colors.blue),
          ),
          SizedBox(
            height: 15,
          ),
          if (myId == gm.ownerId)
            GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                      builder: (_) => AddMembersScreen(
                            gm: gm,
                          )),
                )
                    .then((value) {
                  setState(() {
                    gm = groupProvider.getFresh(gm.grpId);
                  });
                });
              },
              child: Container(
                child: Row(
                  children: [
                    Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: Colors.blue),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                        )),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      "Add members",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
          SizedBox(
            height: 10,
          ),
          for (Members m in gm.members)
            Container(
              margin: EdgeInsets.only(top: 15),
              child: Row(
                children: [
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
                  Text(
                    m.alias != null ? m.alias : m.id,
                    style: TextStyle(color: Colors.white),
                  ),
                  if (m.id == myId)
                    Text(
                      "(You)",
                      style: TextStyle(color: Colors.white),
                    ),
                  Spacer(),
                  if (m.id == gm.ownerId)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          color: Colors.blue),
                      child: Center(
                        child: Text(
                          "Owner",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  if (myId == gm.ownerId && m.id != myId)
                    GestureDetector(
                      onTap: () {
                        _moreSheet(
                            context, m.alias != null ? m.alias : m.id, m.id);
                      },
                      child: Icon(
                        Icons.more_vert_outlined,
                        color: Colors.grey,
                      ),
                    )
                ],
              ),
            ),
          SizedBox(
            height: 40,
          ),
          Text(
            "General",
            style: TextStyle(color: Colors.blue),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            "Share Chat",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget switchSetting(String title, bool value, Function callback) {
    return Container(
      height: MediaQuery.of(context).size.height * .05,
      child: Row(
        children: [
          SizedBox(
            width: 10,
          ),
          Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          Spacer(),
          Switch(
              value: value,
              onChanged: (select) {
                callback(select);
              }),
          SizedBox(
            width: 5,
          )
        ],
      ),
    );
  }

  Widget setting(bool flag) {
    return Container(
        alignment: Alignment.topLeft,
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            "Settings",
            style: TextStyle(color: Colors.blue),
          ),
          Container(
            height: 40,
            margin: EdgeInsets.only(top: 10),
            child: switchSetting('Snooze Notifications', flag, (val) {
              sharedPreferences.setBool('snooze${widget.gm.grpId}', val);
              setState(() {
                value1 = val;
              });
            }),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * .04),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            child: InkWell(
              onTap: () async {
                if (myId == gm.ownerId) {
                  // destroy
                  showProgress("Destroying");
                  bool f = await groupProvider.destroyGroup(gm);
                  if (f) {
                    Toast.show("Destroyed!", context);
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  } else {
                    Toast.show("Failed to destroy", context);
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                } else {
                  // leave
                  showProgress("Leaving");
                  bool f = await groupProvider.leaveGroup(gm);
                  if (f) {
                    Toast.show("Leaved!", context);
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  } else {
                    Toast.show("Failed to leave", context);
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 50,
                decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.transparent,
                    border: Border.all(color: Colors.deepOrangeAccent)),
                child: Center(
                    child: Text(
                  "${myId == gm.ownerId ? "Destroy  Group" : "Leave  Group"}",
                  style: TextStyle(
                      color: Colors.deepOrangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )),
              ),
            ),
          )
        ]));
  }

  void _moreSheet(BuildContext context, String name, String id) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Color(0xff040d5a),
        builder: (context) {
          bool submit = false;
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateD) {
            return Wrap(
              children: <Widget>[
                InkWell(
                  onTap: () {},
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                    child: Row(
                      children: <Widget>[
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
                        SizedBox(width: 10),
                        Text(
                          name,
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                line(),
                InkWell(
                  onTap: () async {
                    setStateD(() {
                      submit = true;
                    });
                    bool update = await groupProvider.removeMember(gm, id);
                    if (update) {
                      Toast.show("Removed!", context);
                      setState(() {
                        gm.members.removeWhere((element) => element.id == id);
                      });
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pop();
                      Toast.show("Failed to remove!", context);
                    }
                    setStateD(() {
                      submit = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        !submit
                            ? Text(
                                "Remove From Group",
                                style:
                                    TextStyle(color: Colors.red, fontSize: 18),
                              )
                            : SpinKitCircle(
                                color: Colors.orange,
                                size: 25,
                              ),
                      ],
                    ),
                  ),
                )
              ],
            );
          });
        });
  }
}
