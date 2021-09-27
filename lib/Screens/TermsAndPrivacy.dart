import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'OnboardingPage.dart';

class PrivacyTerms extends StatefulWidget {
  const PrivacyTerms({Key key}) : super(key: key);

  @override
  _PrivacyTermsState createState() => _PrivacyTermsState();
}

class _PrivacyTermsState extends State<PrivacyTerms> {
  bool valuefirst = false;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff040d5a),
        elevation: 0,
        brightness: Brightness.dark,
      ),
      backgroundColor: Color(0xff040d5a),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: h * 0.2,
          ),
          Center(
              child: Text(
            'Enc.',
            style: TextStyle(
                fontSize: 40, color: Colors.white, fontFamily: 'UbuntuTitling'),
          )),
          SizedBox(
            height: 20,
          ),
          Center(
            child: Text('Trusted for data and privacy protection',
                style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
          SizedBox(
            height: h * 0.2,
          ),
          Container(
            height: h * 0.07,
            width: w * 0.8,
            color: Color(0xff383b45),
            child: Row(
              children: [
                Theme(
                  data: ThemeData(unselectedWidgetColor: Colors.white),
                  child: Checkbox(
                    checkColor: Colors.black,
                    activeColor: Colors.lightBlue,
                    value: this.valuefirst,
                    onChanged: (bool value) {
                      setState(() {
                        this.valuefirst = value;
                      });
                    },
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                          text:
                              'By creating an account, you agree to the\nEnc.',
                          style: TextStyle(fontSize: 12)),
                      TextSpan(
                          text: ' Terms of Use',
                          style:
                              TextStyle(fontSize: 12, color: Colors.lightBlue)),
                      TextSpan(text: ' and ', style: TextStyle(fontSize: 12)),
                      TextSpan(
                          text: 'Privacy Policy',
                          style:
                              TextStyle(fontSize: 12, color: Colors.lightBlue)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: h * 0.06,
          ),
          GestureDetector(
            onTap: () {
              if (valuefirst == true) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OnboardingPage()),
                );
              }
            },
            child: Container(
                height: h * 0.072,
                width: w * 0.6,
                decoration: BoxDecoration(
                  color: valuefirst ? Colors.lightBlue : Colors.grey,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                    child: Text(
                  'Continue',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ))),
          ),
        ],
      ),
    );
  }
}
