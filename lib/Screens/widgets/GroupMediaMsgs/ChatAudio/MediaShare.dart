import 'package:flutter/material.dart';
import 'package:encapp/Models/friends.dart';
import 'package:encapp/Models/group_message.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/user.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../chat.dart';

class MediaShareWithScreen extends StatefulWidget {
  GroupMessageModel msg;
  MediaShareWithScreen({this.msg});
  @override
  _MediaShareWithScreenState createState() => _MediaShareWithScreenState();
}

class _MediaShareWithScreenState extends State<MediaShareWithScreen> {
  UserProvider userProvider;

  void getAllMyContacts() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.getContacts();
  }

  @override
  void initState() {
    getAllMyContacts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UserProvider>();
    return Scaffold(
      backgroundColor: Color(0xff040d5a),
      appBar: AppBar(
        brightness: Brightness.dark,
        backgroundColor: Color(0xff040d5a),
        leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back_sharp,
              color: Colors.white,
            )),
        elevation: 0,
        title: Text(
          "Share With",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: 1,
              color: Colors.grey,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * .02,
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: up.contacts.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () async {
                        // String myId = await Provider.of<ChatProvider>(context,
                        //         listen: false)
                        //     .cs
                        //     .getDeviceId();
                        // String convid = await Provider.of<ChatProvider>(context,
                        //         listen: false)
                        //     .cs
                        //     .getConvid(myId, myContacts[index].cid.trim());
                        // SharedPreferences sharedPreference =
                        //     await SharedPreferences.getInstance();
                        // String myAlias = sharedPreference.getString('alias');
                        // MessageModel m = new MessageModel(
                        //     convid: convid,
                        //     fromId: myId,
                        //     toId: myContacts[index].cid.trim(),
                        //     read: 0,
                        //     fromAlias: myAlias,
                        //     toAlias: myContacts[index].alias.trim(),
                        //     msg: '',
                        //     favourite: 0,
                        //     datetime: DateTime.now(),
                        //     delMsg: 0,
                        //     msgType: widget.msg.msgType,
                        //     localUrl: widget.msg.localUrl,
                        //     replyId: -1);
                        // Navigator.of(context).push(
                        //   MaterialPageRoute(
                        //       builder: (_) => ChatScreen(
                        //             peerName: myContacts[index].alias,
                        //             toId: myContacts[index].cid,
                        //             convid: convid,
                        //             md: m,
                        //           )),
                        // );
                      },
                      child: Container(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        margin: const EdgeInsets.only(left: 8, right: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.blue, width: 2),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                  )),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              up.contacts[index].alias,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            )
                          ],
                        ),
                      ),
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}
