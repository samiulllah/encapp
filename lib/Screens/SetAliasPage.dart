import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Screens/HomePage.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';

class SetAliasPage extends StatefulWidget {
  String password;
  SetAliasPage({this.password});
  @override
  _SetAliasPageState createState() => _SetAliasPageState();
}

class _SetAliasPageState extends State<SetAliasPage> {
  TextEditingController textEditingController = new TextEditingController();

  void popUntilRoot({Object result}) {
    if (OneContext().canPop()) {
      OneContext().pop();
      popUntilRoot();
    }
  }

  navigate() async {
    popUntilRoot();
    OneContext().pushReplacement(
      MaterialPageRoute(
          builder: (_) => HomePage(
                myId: 'myId',
              )),
    );
  }

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
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: h * 0.1,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 28.0, left: 20),
                child: Text(
                  'Set Your Alias',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20),
                child: new TextField(
                  controller: textEditingController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      border: OutlineInputBorder(),
                      hintText: 'CID',
                      hintStyle: TextStyle(
                          fontWeight: FontWeight.w300, color: Colors.grey)),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20),
                child: Text(
                  'This is how your contacts will see you in Enc.'
                  'Your Alias can be changed at any time',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20),
                child: Text(
                  'If you do not set an Alias,your CID will be used.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(
                height: h * 0.36,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 20,
                  ),
                  GestureDetector(
                      onTap: () {
                        navigate();
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      )),
                  Expanded(
                    child: Container(),
                  ),
                  GestureDetector(
                    onTap: () {
                      navigate();
                    },
                    child: Container(
                        height: h * 0.07,
                        width: w * 0.38,
                        decoration: BoxDecoration(
                          color: Colors.lightBlue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Center(
                            child: Text(
                          'Continue',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800),
                        ))),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                ],
              )
            ],
          ),
        ));
  }
}
