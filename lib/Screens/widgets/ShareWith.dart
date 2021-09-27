import 'package:flutter/material.dart';
import 'package:encapp/Models/friends.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/user.dart';
import 'package:provider/provider.dart';

import '../chat.dart';

class ShareWithScreen extends StatefulWidget {
  const ShareWithScreen({Key key}) : super(key: key);

  @override
  _ShareWithScreenState createState() => _ShareWithScreenState();
}

class _ShareWithScreenState extends State<ShareWithScreen> {
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
                        String m = await Provider.of<ChatProvider>(context,
                                listen: false)
                            .getSelected();
                        String myId = await Provider.of<ChatProvider>(context,
                                listen: false)
                            .cs
                            .getDeviceId();
                        String convid = await Provider.of<ChatProvider>(context,
                                listen: false)
                            .cs
                            .getConvid(myId, up.contacts[index].cid.trim());
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                  peerName: up.contacts[index].alias,
                                  toId: up.contacts[index].cid,
                                  forMsg: m,
                                  convid: convid)),
                        );
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
