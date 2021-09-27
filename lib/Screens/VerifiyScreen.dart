import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:qrscan/qrscan.dart' as scanner;

class VerifyScreen extends StatefulWidget {
  @override
  _VerifyScreenState createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  Future _scan() async {
    String barcode = await scanner.scan();
    if (barcode == null) {
      print('nothing return.');
    } else {

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Color(0xff040d5a) ,
      appBar: AppBar(
        backgroundColor:Color(0xff040d5a) ,
        elevation: 2,
        leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back_sharp,
              color: Colors.white,
            )),
        title: Text('Choose Verification Method',style: TextStyle(fontWeight: FontWeight.w600,color: Colors.white),),
      ),
      body: SettingsList(
        backgroundColor: Color(0xff040d5a),
        sections: [
          SettingsSection(
            tiles: [
              SettingsTile(
                title: 'Secret question',
                leading: Icon(Icons.help_outline,color: Colors.white),
                titleTextStyle: TextStyle(color: Colors.white),

                onPressed: (BuildContext context) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AskSecretQuestion()),
                  );
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(builder: (_) => ChatSettingPage()),
                  // );
                },
              ),
              SettingsTile(
                title: 'Scan QR code',
                titleTextStyle: TextStyle(color: Colors.white),
                leading: Icon(Icons.qr_code,color: Colors.white),
                onPressed: (BuildContext context) {
                  _scan();
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(builder: (_) => NotificationSettingPage()),
                  // );
                },
              ),

            ],
          ),
        ],
      ),
    );
  }
}

class AskSecretQuestion extends StatefulWidget {
  @override
  _AskSecretQuestionState createState() => _AskSecretQuestionState();
}

class _AskSecretQuestionState extends State<AskSecretQuestion> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Color(0xff040d5a) ,
      appBar: AppBar(
        backgroundColor:Color(0xff040d5a) ,
        elevation: 2,
        leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back_sharp,
              color: Colors.white,
            )),
        actions: [
          GestureDetector(
            onTap: (){
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0,top: 16),
              child: Text('SEND',style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600),),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: new TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    border: OutlineInputBorder(

                    ),
                    hintText: "Secret Question",
                    hintStyle: TextStyle(fontWeight: FontWeight.w300, color: Colors.grey)
                ),


              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: new TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    border: OutlineInputBorder(

                    ),
                    hintText: "Answer",
                    hintStyle: TextStyle(fontWeight: FontWeight.w300, color: Colors.grey)
                ),


              ),
            ),

          ],
        ),
      ),
    );
  }
}

