import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encapp/Models/friends.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Providers/group.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Screens/FinalizeGroup.dart';
import 'package:provider/provider.dart';

import 'AddContact.dart';

class NewGroupScreen extends StatefulWidget {
  int mode;
  GroupModel gm;
  NewGroupScreen({this.mode, this.gm});
  @override
  _NewGroupScreenState createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  GroupProvider groupProvider;

  void getAllMyContacts() async {
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    await groupProvider.getContacts();
  }

  void showProgress() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xff040d5a),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Center(
                child: SpinKitCircle(
                  color: Colors.orange,
                  size: 30,
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Adding...",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'UbuntuTitling'),
            )
          ]),
        );
      },
    );
  }

  @override
  void initState() {
    getAllMyContacts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GroupProvider>();
    return Scaffold(
      appBar: AppBar(
        brightness: Brightness.dark,
        elevation: 0,
        title: Text(
          widget.mode == 1 ? 'Add more members' : 'New Group',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontFamily: 'UbuntuTitling'),
        ),
        backgroundColor: Color(0xff040d5a),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: Text("Selected ${gp.nosSelected}",
                  style: TextStyle(
                    color: Colors.blue,
                    fontFamily: 'UbuntuTitling',
                  )),
            ),
          ),
          SizedBox(
            width: 10,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.keyboard_arrow_right_outlined),
        onPressed: () {
          if (widget.mode == 0) {
            Navigator.of(context)
                .push(
              MaterialPageRoute(builder: (_) => FinalizeGroupScreen()),
            )
                .then((value) {
              groupProvider.friends.removeAt(0);
            });
          } else {
            // add more members

          }
        },
      ),
      backgroundColor: Color(0xff040d5a),
      body: Column(children: [
        Container(
          width: MediaQuery.of(context).size.width,
          height: 1,
          color: Colors.grey,
        ),
        SizedBox(
          height: 20,
        ),
        Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 10),
          margin: EdgeInsets.symmetric(horizontal: 20),
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
          height: 40,
        ),
        Expanded(child: getContacts(gp.friends)),
        SizedBox(
          height: MediaQuery.of(context).size.height * .1,
        )
      ]),
    );
  }

  Widget getContacts(List<FriendsModel> myContacts) {
    return myContacts.length > 0
        ? Container(
            margin: EdgeInsets.symmetric(horizontal: 25),
            child: ListView.builder(
                itemCount: myContacts.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // do selection
                      groupProvider.selectContact(myContacts[index].cid);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(.4),
                          borderRadius: BorderRadius.all(Radius.circular(10))),
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
                            myContacts[index].alias == null
                                ? myContacts[index].cid
                                : myContacts[index].alias,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Spacer(),
                          myContacts[index].selected
                              ? Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                )
                              : Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.grey,
                                )
                        ],
                      ),
                    ),
                  );
                }),
          )
        : Text(
            "No Contacts yet.",
            style: TextStyle(color: Colors.white, fontSize: 18),
          );
  }
}
