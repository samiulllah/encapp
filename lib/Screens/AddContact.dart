import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encapp/Providers/user.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';

import 'ChatProfilePage.dart';

class AddContact extends StatefulWidget {
  @override
  _AddContactState createState() => _AddContactState();
}

class _AddContactState extends State<AddContact> {
  TextEditingController controller = new TextEditingController();
  bool found = false;
  UserProvider userProvider;
  Map last;
  bool searching = false;
  String error = "The specified contact was not found.";
  bool showError = false;

  void search(String cid) async {
    cid = cid.toUpperCase();
    if (cid.length >= 8) {
      String myId = await userProvider.getDeviceId();
      if (myId == cid) {
        setState(() {
          showError = true;
          error = "You cannot add yourself as a contact.";
        });
        return;
      }
      setState(() {
        searching = true;
      });
      Map f = await userProvider.findUser(cid);
      setState(() {
        found = f != null;
      });
      if (found) {
        FocusScope.of(context).unfocus();
        last = f;
      } else {
        setState(() {
          showError = true;
          error = "The specified contact was not found.";
        });
      }
      setState(() {
        searching = false;
      });
    } else {
      setState(() {
        found = false;
      });
    }
  }

  addToContacts() async {
    if (found) {
      int add = await userProvider.addFriend(last['data']);
      if (last['data']['cid'] == null ||
          last['data']['cid'].toString().isEmpty) {
        setState(() {
          showError = true;
          found = false;
        });
        Toast.show("CID can't be empty!", context);
        return;
      }
      if (add != 0 && add != 99) {
        controller.clear();
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => ChatProfilePage(
                  alias: last['data']['alias'],
                  cid: last['data']['cid'],
                  add: true)),
        );
      } else if (add == 99) {
        Toast.show('Contact already exists', context);
      } else {
        Toast.show('Failed to add!', context);
      }
    }
  }

  @override
  void initState() {
    userProvider = Provider.of<UserProvider>(context, listen: false);
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
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                'New Contact',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontFamily: 'UbuntuTitling'),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: new BoxDecoration(
                shape: BoxShape.rectangle,
                color: Color(0xff2e304f),
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: new Border.all(
                  color: found ? Colors.green : Colors.grey,
                  width: found ? 2.0 : 1.0,
                ),
              ),
              child: Center(
                child: new TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    setState(() {
                      searching = false;
                      showError = false;
                    });
                    search(value);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(8),
                  ],
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Colors.white),
                  decoration: new InputDecoration(
                    hintText: 'Enter CID',
                    suffixIcon: searching
                        ? Container(
                            width: 30,
                            height: 30,
                            child: SpinKitFadingFour(
                              color: Colors.grey,
                              size: 30,
                            ),
                          )
                        : showError
                            ? found
                                ? Icon(Icons.check_circle_outline,
                                    color: Colors.green)
                                : Icon(Icons.cancel_outlined, color: Colors.red)
                            : Container(
                                width: 1,
                                height: 1,
                              ),
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            if (showError)
              Text(
                error,
                style: TextStyle(color: Colors.red),
              )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await addToContacts();
        },
        child: const Icon(
          Icons.done,
          color: Colors.white,
        ),
        backgroundColor: found ? Colors.green : Colors.grey,
      ),
    );
  }
}
