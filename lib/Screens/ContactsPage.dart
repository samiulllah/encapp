import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:encapp/Models/friends.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Screens/widgets/floating_action.dart';
import 'package:provider/provider.dart';

import 'AddContact.dart';
import 'NewGroupPage.dart';
import 'UnlockPage.dart';
import 'chat.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
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
              if (up.noSelected > 0)
                userProvider.unselectAll();
              else
                Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back_sharp,
              color: Colors.white,
            )),
        elevation: 0,
        title: up.noSelected > 0 ? header(up.noSelected) : Container(),
      ),
      body: Container(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'All Contacts',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontFamily: 'UbuntuTitling'),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Container(
                    height: 40,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: new BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: Color(0xff2e304f),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      border: new Border.all(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: new TextField(
                        textAlign: TextAlign.start,
                        style: TextStyle(color: Colors.white),
                        decoration: new InputDecoration(
                          hintText: 'Search',
                          suffixIcon: Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * .05,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "CONTACT LIST",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * .03,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 5,
            ),
            if (up.contacts == null || up.contacts.length == 0)
              Text(
                'No contacts found.',
                style: TextStyle(color: Colors.white),
              ),
            Expanded(
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: up.contacts.length,
                  itemBuilder: (context, index) {
                    return Material(
                      color: up.contacts[index].selected
                          ? Colors.grey.withOpacity(.4)
                          : Colors.transparent,
                      child: InkWell(
                        onLongPress: () {
                          userProvider.selectContact(up.contacts[index].cid);
                        },
                        onTap: () async {
                          if (userProvider.noSelected > 0) {
                            userProvider.selectContact(up.contacts[index].cid);
                          } else {
                            String myId = await Provider.of<ChatProvider>(
                                    context,
                                    listen: false)
                                .cs
                                .getDeviceId();
                            String convid = await Provider.of<ChatProvider>(
                                    context,
                                    listen: false)
                                .cs
                                .getConvid(myId, up.contacts[index].cid.trim());
                            await Navigator.of(context)
                                .push(
                              MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                        peerName: up.contacts[index].alias,
                                        toId: up.contacts[index].cid,
                                        convid: convid,
                                      )),
                            )
                                .then((value) async {
                              await userProvider.getContacts();
                            });
                          }
                        },
                        child: Column(
                          children: [
                            if (index == 0)
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 1,
                                color: Colors.grey,
                              ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.blue, width: 2),
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
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: 1,
                              color: Colors.grey,
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
      floatingActionButton: getFloatingAction1(context),
    );
  }

  Widget newRow(IconData icon, String title, Function callback) {
    return InkWell(
      onTap: () {
        callback();
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey,
              size: 30,
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Spacer(),
            Icon(
              Icons.keyboard_arrow_right,
              color: Colors.grey,
              size: 30,
            ),
            SizedBox(
              width: 10,
            )
          ],
        ),
      ),
    );
  }

  Widget header(int nosSelected) {
    double h = MediaQuery.of(context).size.height;
    return Container(
      height: h * .1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            'Selected  $nosSelected',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Spacer(),
          GestureDetector(
            onTap: () async {
              await userProvider.deleteSelected();
            },
            child: Icon(
              Icons.delete,
              color: Colors.red,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
