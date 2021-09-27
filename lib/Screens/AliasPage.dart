import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Services/user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:vibration/vibration.dart';

class AliasPage extends StatefulWidget {
  @override
  _AliasPageState createState() => _AliasPageState();
}

class _AliasPageState extends State<AliasPage> {
  String cid = '', alias = '';
  bool loading = true;

  SharedPreferences sharedPreferences;
  init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      loading = true;
    });
    String nam = 'Thakur';
    UserService us = new UserService();
    String cd = await us.getDeviceId();
    setState(() {
      cid = cd;
      alias = nam;
      loading = false;
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                    builder: (_) => EditAliasPage(
                          cid: cid,
                          alias: alias,
                        )),
              )
                  .then((value) {
                init();
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0, top: 10),
              child: Icon(
                Icons.edit,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
      body: !loading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacer(),
                Center(
                  child: Container(
                    width: 25,
                    height: 20,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.cyan, width: 2),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(7),
                          bottomRight: Radius.circular(7),
                        )),
                  ),
                ),
                Center(
                    child: SizedBox(
                  height: 15,
                )),
                Text(
                  'Edit Alias',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
                Center(
                    child: SizedBox(
                  height: 8,
                )),
                Center(
                    child: Text(
                  alias.isEmpty ? cid : alias,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 18),
                )),
                SizedBox(
                  height: 40,
                ),
                Center(
                    child: Text(
                  'Contact ID (CID)',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                )),
                SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: "$cid"));
                    Vibration.vibrate(duration: 100);
                    Toast.show('Copied!', context,
                        textColor: Colors.black,
                        backgroundColor: Colors.white,
                        backgroundRadius: 10);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                          child: Text(
                        cid,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 17),
                      )),
                      SizedBox(
                        width: 10,
                      ),
                      Icon(
                        Icons.copy,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
                Spacer(),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 1,
                  color: Colors.grey,
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Text(
                    "Your contact id CID can't be changed. Your alias may be changed, which is visible to people when they add you as Contact, to groups, Chat.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              ],
            )
          : Container(),
    );
  }
}

class EditAliasPage extends StatefulWidget {
  String cid, alias;

  EditAliasPage({this.cid, this.alias});
  @override
  _EditAliasPageState createState() =>
      _EditAliasPageState(cid: cid, alias: alias);
}

class _EditAliasPageState extends State<EditAliasPage> {
  String cid, alias, aliasNew = '';
  bool updating = false;

  updateAlias() async {
    if (aliasNew.isEmpty || aliasNew.length == 0) {
      Toast.show("Please enter alias!", context);
      return;
    }
    if (alias == aliasNew) {
      Toast.show("Please enter different alias to update!", context);
      return;
    }
    if (!updating) {
      setState(() {
        updating = true;
      });
      // update
      bool update = await Provider.of<UserProvider>(context, listen: false)
          .updateAlias(cid, aliasNew);
      if (update) {
        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        sharedPreferences.setString('alias', aliasNew);
        Navigator.of(context).pop();
      } else {
        Toast.show("Failed updating alias!", context);
      }
      setState(() {
        updating = false;
      });
    }
  }

  _EditAliasPageState({this.cid, this.alias});

  @override
  Widget build(BuildContext context) {
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
        actions: [
          GestureDetector(
            onTap: () {
              updateAlias();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0, top: 10),
              child: Icon(
                Icons.done,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Edit Alias',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'UbuntuTitling',
                  fontSize: 22),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: new TextField(
              style: TextStyle(color: Colors.white),
              controller: TextEditingController(
                text: alias.isEmpty ? cid : alias,
              ),
              onChanged: (val) {
                aliasNew = val;
              },
              decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  border: OutlineInputBorder(),
                  hintText: 'Enter Alias',
                  hintStyle: TextStyle(
                      fontWeight: FontWeight.w300, color: Colors.grey)),
            ),
          ),
          Spacer(),
          !updating
              ? GestureDetector(
                  onTap: () async {
                    updateAlias();
                  },
                  child: Container(
                    height: 50,
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        shape: BoxShape.rectangle),
                    child: Center(
                      child: Text(
                        'RESET ALIAS',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                )
              : SpinKitCircle(
                  color: Colors.cyan,
                  size: 25,
                ),
          SizedBox(
            height: 30,
          )
        ],
      ),
    );
  }
}
