import 'package:flutter/material.dart';
import 'package:encapp/Providers/user.dart';
import 'package:share/share.dart';
import 'package:flutter/services.dart';
import 'package:toast/toast.dart';

class InviteFriend extends StatefulWidget {
  String did;
  InviteFriend({this.did});
  @override
  _InviteFriendState createState() => _InviteFriendState(did: did);
}

class _InviteFriendState extends State<InviteFriend> {
  String gval = '';
  String did;
  _InviteFriendState({this.did});
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xff040d5a),
      appBar: AppBar(
        brightness: Brightness.dark,
        backgroundColor: Color(0xff040d5a),
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: Text(
              'Invite my friends to Enc.',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'UbuntuTitling',
                  fontSize: 25),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                            unselectedWidgetColor: Colors.white,
                            disabledColor: Colors.blue),
                        child: Radio(
                          value: 'Generic Invite',
                          groupValue: gval,
                          onChanged: (val) {
                            setState(() {
                              gval = val;
                            });
                          },
                        ),
                      ),
                      Text(
                        'Generic Invite',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'UbuntuTitling',
                            fontSize: 18),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        'Invite my friends to download Enc by sharing this link multiple times',
                        style: TextStyle(color: Colors.white)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: h * 0.07,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              'https://enc.com/invite',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                  text: "https://matrix.com/invite"));
                              Toast.show("Copied!", context,
                                  duration: Toast.LENGTH_SHORT,
                                  gravity: Toast.BOTTOM);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Icon(
                                Icons.copy,
                                color: Colors.white,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                            unselectedWidgetColor: Colors.white,
                            disabledColor: Colors.blue),
                        child: Radio(
                          value: 'Personalized',
                          groupValue: gval,
                          onChanged: (val) {
                            setState(() {
                              gval = val;
                            });
                          },
                        ),
                      ),
                      Text(
                        'Personalized',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'UbuntuTitling',
                            fontSize: 18),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        'Generate a unique link that includes my Contact ID(CID). Invite my friends to download '
                        'Enc. and automatically add me as a contact.',
                        style: TextStyle(color: Colors.white)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Flexible(
                          child: Text(
                            "This secure link expires after 72 hours and self-destructs after 5 uses",
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Share.share(
                  'Install app using this url https://matrix.com/invite and connect with me using my CID : $did');
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                child: Container(
                    height: h * 0.072,
                    width: w * 0.84,
                    decoration: BoxDecoration(
                      color: Colors.lightBlue,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                        child: Text(
                      'Send My Invite',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
