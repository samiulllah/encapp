import 'package:flutter/material.dart';
import 'package:encapp/Models/dialogues.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Providers/group.dart';
import 'package:encapp/Screens/GroupChat.dart';
import 'package:provider/provider.dart';
import 'CreatePage.dart';
import 'chat.dart';

class GroupChatPage extends StatefulWidget {
  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  GroupProvider groupProvider;

  init() async {
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    await groupProvider.getAllGroups();
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GroupProvider>();
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
        backgroundColor: Color(0xff040d5a),
        body: Container(
          width: w,
          height: h,
          child: gp.groups != null
              ? gp.groups.length > 0
                  ? Container(
                      height: h - h * .15,
                      width: w,
                      child: renderGroupList(gp.groups))
                  : Center(child: showStartConverstaion(w, h))
              : Center(child: showStartConverstaion(w, h)),
        ));
  }

  Widget showStartConverstaion(double w, double h) {
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
              "Start my by creating a group",
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(
            height: h * .02,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: w * .15),
            child: Text(
              "Your secure group display here",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          SizedBox(
            height: h * .05,
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreateScreen()),
              );
            },
            child: Text(
              "CREATE GROUP",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget renderGroupList(List<GroupModel> groups) {
    return ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return singleItem(groups[index]);
        });
  }

  Widget singleItem(GroupModel gm) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => GroupChatScreen(
                    gm: gm,
                  )),
        );
      },
      child: Container(
        color: Color(0xff040d5a),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
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
                  Text(
                    gm.lastSender + " : ${gm.lastMsg}",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey, fontSize: 11),
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
              Divider(
                color: Colors.grey,
                height: 1,
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
