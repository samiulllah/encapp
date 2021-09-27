import 'package:flutter/material.dart';
import 'package:flutter_pw_validator/flutter_pw_validator.dart';
import 'package:encapp/Providers/user.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';

import '../../SetPasswordPage.dart';

class OldPassword extends StatefulWidget {
  @override
  _OldPasswordPageState createState() => _OldPasswordPageState();
}

class _OldPasswordPageState extends State<OldPassword> {
  TextEditingController _passwordController = new TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (_passwordController.text.isEmpty) {
      Toast.show("Please enter atleast 8 digit password", context);
      return;
    }
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration(seconds: 1));
    bool unlock = await Provider.of<UserProvider>(context, listen: false)
        .loginUser(_passwordController.text);
    if (unlock) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SetUnlockPasswordPage(mode: 1)),
      );
    } else {
      Toast.show("Incorrect password!", context);
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
              'Enter current password',
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
                      hintText: "Current password",
                      hintStyle: TextStyle(
                          fontWeight: FontWeight.w300, color: Colors.grey)),
                  controller: _passwordController),
            ),
          ],
        ),
      ),
    );
  }
}
