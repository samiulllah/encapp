import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pw_validator/flutter_pw_validator.dart';
import 'package:toast/toast.dart';

import 'SetAliasPage.dart';
import 'dart:io';

class SetPasswordPage extends StatefulWidget {
  @override
  _SetPasswordPageState createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
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
        leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            )),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 28.0, left: 21),
            child: Text(
              'Set Your Password to\nUnlock Matrix',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 28.0, left: 21),
            child: Text(
              'Your password is required each time you '
              'access Enc.. Password protection encrypts '
              'the data stored in your app and safeguards '
              'against unauthorized access to your Enc. account.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(
            height: h * 0.2,
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => SetUnlockPasswordPage(
                          mode: 0,
                        )),
              );
            },
            child: Center(
              child: Container(
                  height: h * 0.072,
                  width: w * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.lightBlue,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                      child: Text(
                    'Set Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ))),
            ),
          ),
        ],
      ),
    );
  }
}

class SetUnlockPasswordPage extends StatefulWidget {
  int mode = 0;
  SetUnlockPasswordPage({this.mode});
  @override
  _SetUnlockPasswordPageState createState() =>
      _SetUnlockPasswordPageState(mode: mode);
}

class _SetUnlockPasswordPageState extends State<SetUnlockPasswordPage> {
  TextEditingController _passwordController = new TextEditingController();
  bool isCorrect = false;
  int mode;
  _SetUnlockPasswordPageState({this.mode});

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (_passwordController.text.isEmpty) {
      Toast.show("Please enter at-least 8 digit password", context);
      return;
    }
    isCorrect = false;
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration(seconds: 1));
    if (isCorrect) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
            builder: (_) => ConfirmUnlockPasswordPage(
                  lastPassword: _passwordController.text,
                  mode: mode,
                )),
      )
          .then((value) {
        _passwordController = new TextEditingController();
      });
    } else {
      Toast.show("Please meet all strong password requirements", context);
    }
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
        title: Row(
          children: [
            Text(
              'Set Unlock Password',
              style: TextStyle(fontSize: 18),
            ),
            Spacer(),
            GestureDetector(
              onTap: () async {
                submit();
              },
              child: Text(
                'NEXT',
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 17),
              ),
            )
          ],
        ),
        leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            )),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: new TextField(
                  style: TextStyle(color: Colors.white),
                  obscureText: true,
                  onSubmitted: (val) {
                    submit();
                  },
                  decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      border: OutlineInputBorder(),
                      hintText: "Unlock Password",
                      hintStyle: TextStyle(
                          fontWeight: FontWeight.w300, color: Colors.grey)),
                  controller: _passwordController),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: new FlutterPwValidator(
                controller: _passwordController,
                minLength: 8,
                uppercaseCharCount: 1,
                numericCharCount: 1,
                specialCharCount: 1,
                width: 400,
                height: 150,
                onSuccess: () {
                  print("its right");
                  isCorrect = true;
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ConfirmUnlockPasswordPage extends StatefulWidget {
  int mode = 0;
  String lastPassword;
  ConfirmUnlockPasswordPage({this.lastPassword, this.mode});
  @override
  _ConfirmUnlockPasswordPageState createState() =>
      _ConfirmUnlockPasswordPageState(mode: mode);
}

class _ConfirmUnlockPasswordPageState extends State<ConfirmUnlockPasswordPage> {
  final TextEditingController _passwordController = new TextEditingController();
  bool correct = false;
  int mode;

  _ConfirmUnlockPasswordPageState({this.mode});

  submit() async {
    correct = false;
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration(seconds: 1));
    if (_passwordController.text.isEmpty) {
      Toast.show("Please enter at-least 8 digit password", context);
      return;
    }
    if (_passwordController.text != widget.lastPassword) {
      Toast.show("Both password aren't same.", context);
      return;
    }
    if (correct) {
      if (mode == 0) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => SetAliasPage(
                    password: widget.lastPassword,
                  )),
        );
      } else {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Toast.show("Password changed successfully!", context);
      }
    } else {
      Toast.show("Please meet all strong password requirements", context);
      return;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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
        title: Row(
          children: [
            Text(
              'Confirm Unlock Password',
              style: TextStyle(fontSize: 16),
            ),
            Spacer(),
            GestureDetector(
              onTap: () async {
                await submit();
              },
              child: Text(
                'NEXT',
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            )
          ],
        ),
        leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            )),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: new TextField(
                  style: TextStyle(color: Colors.white),
                  obscureText: true,
                  onSubmitted: (value) {
                    submit();
                  },
                  decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      border: OutlineInputBorder(),
                      hintText: "Unlock Password",
                      hintStyle: TextStyle(
                          fontWeight: FontWeight.w300, color: Colors.grey)),
                  controller: _passwordController),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: new FlutterPwValidator(
                controller: _passwordController,
                minLength: 8,
                uppercaseCharCount: 1,
                numericCharCount: 1,
                specialCharCount: 1,
                width: 400,
                height: 150,
                onSuccess: () {
                  correct = true;
                },
                // onSuccess: yourCallbackFunction
              ),
            )
          ],
        ),
      ),
    );
  }
}
