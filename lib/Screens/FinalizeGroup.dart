import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encapp/Models/friends.dart';
import 'package:encapp/Models/group.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:encapp/Providers/group.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

class FinalizeGroupScreen extends StatefulWidget {
  const FinalizeGroupScreen({Key key}) : super(key: key);

  @override
  _FinalizeGroupScreenState createState() => _FinalizeGroupScreenState();
}

class _FinalizeGroupScreenState extends State<FinalizeGroupScreen> {
  TextEditingController name = new TextEditingController();
  TextEditingController desc = new TextEditingController();
  GroupProvider groupProvider;
  double w, h;
  String myId, myAlias;
  bool loading = true;
  bool submitLoading = false;

  init() async {
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String nam = sharedPreferences.getString('alias');
    String id = await groupProvider.getDeviceId();
    setState(() {
      myId = id;
      myAlias = nam;
      loading = false;
    });
    FriendsModel f = groupProvider.friends[0];
    FriendsModel me = new FriendsModel(cid: myId, alias: myAlias, block: 0);
    me.selected = true;
    groupProvider.friends[0] = me;
    groupProvider.friends.add(f);
  }

  proceedToCreate() async {
    if (name.text.isEmpty || desc.text.isEmpty) {
      Toast.show("Please enter all group details", context);
      return;
    }
    setState(() {
      submitLoading = true;
    });
    List<Members> members = [];
    for (FriendsModel friendsModel in groupProvider.friends) {
      if (friendsModel.selected) {
        members
            .add(new Members(id: friendsModel.cid, alias: friendsModel.alias));
      }
    }
    GroupModel gm = new GroupModel(
        grpName: name.text, desc: desc.text, ownerId: myId, members: members);
    bool created = await groupProvider.createGroup(gm);
    if (created) {
      await groupProvider.getAllGroups();
      // navigate to
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Toast.show("Created!", context);
    } else {
      Toast.show("Failed to create!", context);
    }
    setState(() {
      submitLoading = false;
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GroupProvider>();
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xff040d5a),
      appBar: AppBar(
        brightness: Brightness.dark,
        elevation: 0,
        title: Text(
          'New Group',
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
                      color: Colors.blue, fontFamily: 'UbuntuTitling')),
            ),
          ),
          SizedBox(
            width: 10,
          )
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: h * .02,
          ),
          textField("Group Name", name),
          SizedBox(
            height: h * .02,
          ),
          textField("Group description", desc),
          SizedBox(
            height: h * .02,
          ),
          if (!loading)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.topLeft,
              child: Row(
                children: [
                  Text("Members",
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'UbuntuTitling',
                          fontSize: 20)),
                  Spacer(),
                  !submitLoading
                      ? GestureDetector(
                          onTap: () {
                            proceedToCreate();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            child: Center(
                                child: Text(
                              "Done",
                              style: TextStyle(color: Colors.white),
                            )),
                          ),
                        )
                      : SpinKitCircle(
                          color: Colors.orange,
                          size: 25,
                        ),
                  SizedBox(
                    width: 10,
                  )
                ],
              ),
            ),
          SizedBox(
            height: h * .02,
          ),
          if (!loading)
            Expanded(
              child: getContacts(gp.friends),
            )
        ],
      ),
    );
  }

  Widget getContacts(List<FriendsModel> myContacts) {
    return myContacts.length > 0
        ? Container(
            margin: EdgeInsets.symmetric(horizontal: 25),
            child: ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: myContacts.length,
                itemBuilder: (context, index) {
                  bool owner = myContacts[index].cid == myId;
                  print(myContacts[index].alias);
                  return GestureDetector(
                    onTap: () {
                      // do selection
                      if (!owner)
                        groupProvider.selectContact(myContacts[index].cid);
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      margin: EdgeInsets.symmetric(vertical: 10),
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
                          if (!owner)
                            myContacts[index].selected
                                ? Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                  )
                                : Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.grey,
                                  ),
                          if (owner)
                            Text(
                              'Owner',
                              style: TextStyle(color: Colors.blue),
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

  Widget textField(String title, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 18),
      child: Container(
        height: 45,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          style: TextStyle(color: Colors.white),
          decoration: new InputDecoration(
            border: new OutlineInputBorder(
                borderSide: new BorderSide(color: Colors.white)),
            enabledBorder: const OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white, width: 0.0),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white, width: 0.0),
            ),
            labelStyle: TextStyle(color: Colors.white70),
            labelText: title,
          ),
        ),
      ),
    );
  }
}
