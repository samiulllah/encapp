import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:encapp/Models/dialogues.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Models/single_group_dialogues.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/dialogue.dart';
import 'package:encapp/Providers/group.dart';
import 'package:encapp/Providers/home.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Services/chat.dart';
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:one_context/one_context.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CreatePage.dart';
import 'GroupChat.dart';
import 'chat.dart';
import 'package:provider/provider.dart';

//
class SingleChatPage extends StatefulWidget {
  String myId;
  SingleChatPage({this.myId});
  @override
  _SingleChatPageState createState() => _SingleChatPageState(myId: myId);
}

class _SingleChatPageState extends State<SingleChatPage>
    with WidgetsBindingObserver {
  String myId;
  SharedPreferences sharedPreferences;
  _SingleChatPageState({this.myId});
  int noSelected = 0;

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Provider.of<ChatProvider>(context, listen: false).fetchDialogues();
    }
  }

  init() async {
    await Provider.of<GroupProvider>(context, listen: false).getAllGroups();
    Provider.of<ChatProvider>(context, listen: false).fetchDialogues();
  }

  @override
  void initState() {
    init();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ChatProvider>();
    final gp = context.watch<GroupProvider>();
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    Provider.of<DialogueProvider>(context, listen: false)
        .combineBoth(cp.dialogues, gp.groups);
    return Scaffold(
      backgroundColor: Color(0xff040d5a),
      body: (cp.dialogues.length > 0 && myId != null) ||
              (gp.groups != null && gp.groups.length > 0)
          ? Container(
              height: h,
              width: w,
              child: Consumer<DialogueProvider>(builder: (context, dp, child) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ...renderAllDialogues(dp.dls, cp.unreadMap, gp.unreadMap,
                          w, cp.preview, dp),
                    ],
                  ),
                );
              }))
          : Center(child: showStartConversation(w, h)),
    );
  }

  Widget showStartConversation(double w, double h) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/conversation.png",
            fit: BoxFit.contain,
            width: 100,
            height: 100,
          ),
          SizedBox(
            height: h * .05,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: w * .2),
            child: Text(
              "Start my first conversation",
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(
            height: h * .02,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: w * .15),
            child: Text(
              "Are you ready to chat? Get started with private and secure chat",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          SizedBox(
            height: h * .05,
          ),
          GestureDetector(
            onTap: () {
              OneContext().push(
                MaterialPageRoute(builder: (_) => CreateScreen()),
              );
            },
            child: Text(
              "START NOW",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> renderAllDialogues(
      List<SingleGroupDialogues> dialogues,
      List<Map> unreadMapSingle,
      List<Map> unreadMapGroup,
      double w,
      bool preview,
      DialogueProvider hp) {
    List<Widget> childs = [];
    for (SingleGroupDialogues sg in dialogues) {
      int unread = 0;
      if (sg.i == 0) {
        // single dialogue
        for (Map m in unreadMapSingle) {
          if (m.containsKey(sg.s.convid)) {
            unread = m[sg.s.convid];
          }
        }
        childs.add(singleItem(sg.s, unread, w, preview, sg.selected, hp));
      } else {
        // group dialogue
        for (Map m in unreadMapGroup) {
          if (m.containsKey(sg.g.grpId)) {
            unread = m[sg.g.grpId];
          }
        }
        childs.add(groupSingleItem(sg.g, unread, preview, w, sg.selected, hp));
      }
    }
    return childs;
  }

  Widget singleItem(MessageModel dm, int unread, double w, bool preview,
      bool selected, DialogueProvider hp) {
    return Material(
      color: selected ? Colors.grey.withOpacity(.4) : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (hp.noSelected > 0) {
            hp.selectItem(dm.convid);
          } else {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                  builder: (_) => ChatScreen(
                      peerName: dm.fromId == myId ? dm.toAlias : dm.fromAlias,
                      toId: dm.fromId == myId ? dm.toId : dm.fromId,
                      convid: dm.convid)),
            )
                .then((value) {
              // if (mounted)
              //   Provider.of<ChatProvider>(context, listen: false)
              //       .fetchDialogues();
            });
          }
        },
        onLongPress: () {
          hp.selectItem(dm.convid);
        },
        child: Container(
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Row(
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
                    width: 15,
                  ),
                  if (myId != null)
                    Text(
                      dm.fromId.trim() == myId.trim()
                          ? dm.toAlias
                          : dm.fromAlias,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          fontSize: 16),
                    ),
                  Spacer(),
                  if (unread > 0)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.orange),
                      child: Center(
                          child: Text(
                        "${unread}",
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      )),
                    ),
                  SizedBox(
                    width: w * .04,
                  ),
                  Text(
                    dm.getDateTimeClause()[0],
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                ],
              ),
              SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 25,
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  if (dm.fromId == myId && !preview)
                    Icon(
                      Icons.check,
                      color: dm.read == 1 ? Colors.green : Colors.blue,
                      size: 18,
                    ),
                  SizedBox(
                    width: 5,
                  ),
                  if (!preview)
                    Container(
                      width: w * .5,
                      child: Text(
                        dm.delMsg == 1 ? "message removed" : dm.msg,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color:
                                dm.delMsg == 1 ? Colors.grey : Colors.white70,
                            fontSize: 14),
                      ),
                    ),
                  Spacer(),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    dm.getDateTimeClause()[1],
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.grey.withOpacity(.5),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget groupSingleItem(GroupModel gm, int nosUnread, bool preview, double w,
      bool selected, DialogueProvider hp) {
    return Material(
      color: selected ? Colors.grey.withOpacity(.4) : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (hp.noSelected > 0) {
            hp.selectItem(gm.grpId);
          } else {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                  builder: (_) => GroupChatScreen(
                        gm: gm,
                      )),
            )
                .then((value) async {
              if (mounted)
                await Provider.of<GroupProvider>(context, listen: false)
                    .getAllGroups();
            });
          }
        },
        onLongPress: () {
          hp.selectItem(gm.grpId);
        },
        child: Container(
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  stackedRects(),
                  SizedBox(
                    width: 15,
                  ),
                  Text(
                    gm.grpName,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        fontSize: 16),
                  ),
                  Spacer(),
                  if (nosUnread > 0)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.orange),
                      child: Center(
                          child: Text(
                        "${nosUnread}",
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      )),
                    ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .04,
                  ),
                  Text(
                    gm.getDateTimeClause()[0],
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  SizedBox(
                    width: 20,
                  )
                ],
              ),
              SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 50,
                  ),
                  if (!preview)
                    Container(
                      width: w * .5,
                      child: Text(
                        gm.lastSender + " : ${gm.lastMsg}",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ),
                  Spacer(),
                  Text(
                    gm.getDateTimeClause()[1],
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  SizedBox(
                    width: 20,
                  )
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.grey.withOpacity(.5),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget stackedRects() {
    return Container(
      height: 18,
      width: 18,
      child: Stack(
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                )),
          ),
          Positioned(
              top: 3,
              left: 3,
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    )),
              ))
        ],
      ),
    );
  }
}
