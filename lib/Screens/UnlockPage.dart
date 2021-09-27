import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/group.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Screens/HomePage.dart';
import 'package:encapp/Screens/widgets/alerts.dart';
import 'package:encapp/Services/chat.dart';
import 'package:encapp/Services/group_chat.dart';
import 'package:encapp/Services/user.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

class UnlockPage extends StatefulWidget {
  @override
  _UnlockPageState createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> {
  bool showPassword = true;
  bool loading = false;
  UserProvider userProvider;
  TextEditingController textEditingController = new TextEditingController();
  bool incorrect = false;
  int tries = 0;
  int totalTries = 0;
  SharedPreferences sharedPreferences;

  applySavedChanges() async {
    GroupChatService gs = new GroupChatService();
    await Provider.of<UserProvider>(context, listen: false).us.doSavedUpdates();
    ChatService cs = new ChatService();
    await gs.insertBackgroundSavedChat();
    await gs.backgroundDeletion();
    await cs.backgroundBlocking();
    await cs.backgroundAliasUpdate();
  }

  loginUser() async {
    // if (textEditingController.text.isEmpty &&
    //     textEditingController.text.length < 8) {
    //   Toast.show("Please enter your 8 digit password", context);
    //   return;
    // }
    // setState(() {
    //   loading = true;
    // });
    // userProvider = Provider.of<UserProvider>(context, listen: false);
    // bool login = await userProvider.loginUser(textEditingController.text);
    // print("login = $login");
    // if (login) {
    //   // home
    //   await applySavedChanges();
    //   await Provider.of<ChatProvider>(context, listen: false).fetchDialogues();
    //   await Provider.of<GroupProvider>(context, listen: false).getAllGroups();
    //   String myId =
    //       await Provider.of<UserProvider>(context, listen: false).getDeviceId();
    //   await Provider.of<UserProvider>(context, listen: false).initSocket();
    //   OneContext().pushReplacement(
    //     MaterialPageRoute(
    //         builder: (_) => HomePage(
    //               myId: myId,
    //             )),
    //   );
    // } else {
    //   if (tries >= totalTries) {
    //     await userProvider.destroyEverything();
    //     return;
    //   }
    //   setState(() {
    //     incorrect = true;
    //     tries++;
    //   });
    // }
    // setState(() {
    //   loading = false;
    // });
    OneContext().pushReplacement(
      MaterialPageRoute(
          builder: (_) => HomePage(
                myId: 'myId',
              )),
    );
  }

  init() async {
    UserService.unlockPage = context;
    sharedPreferences = await SharedPreferences.getInstance();
    String t = sharedPreferences.containsKey('maxTry')
        ? sharedPreferences.getString('maxTry')
        : "3 tries";
    setState(() {
      totalTries = int.parse(t.split(' ')[0].trim());
    });
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    init();
    super.initState();
  }

  @override
  void dispose() {
    UserService.unlockPage = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xff040d5a),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            height: h * 0.2,
          ),
          Center(
              child: Text(
            'Enc.',
            style: TextStyle(
                fontSize: 34, color: Colors.white, fontFamily: 'UbuntuTitling'),
          )),
          SizedBox(
            height: 20,
          ),
          Center(
            child: Text('Trusted for data and privacy protection',
                style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: w * .9,
                    child: TextField(
                      controller: textEditingController,
                      onChanged: (val) {
                        setState(() {
                          incorrect = false;
                        });
                      },
                      obscureText: showPassword,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: incorrect ? Colors.red : Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: incorrect ? Colors.red : Colors.white),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        filled: true,
                        hintStyle: TextStyle(color: Colors.grey),
                        hintText: "Enter password",
                        suffixIcon: loading
                            ? Container(
                                width: 30,
                                height: 30,
                                child: SpinKitFadingFour(
                                  color: Colors.grey,
                                  size: 30,
                                ),
                              )
                            : GestureDetector(
                                onTap: () {
                                  if (showPassword == false) {
                                    setState(() {
                                      showPassword = true;
                                    });
                                  } else {
                                    setState(() {
                                      showPassword = false;
                                    });
                                  }
                                },
                                child: showPassword
                                    ? Icon(
                                        Icons.visibility_off,
                                        size: 30,
                                        color: Colors.grey,
                                      )
                                    : Icon(
                                        Icons.visibility,
                                        size: 30,
                                        color: Colors.white,
                                      ),
                              ),
                        // fillColor: Colors.white70
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  if (incorrect)
                    Text(
                      "Please enter correct password $tries/$totalTries",
                      style: TextStyle(color: Colors.red),
                    )
                ],
              ),
            ),
          ),
          Container(
            height: 50,
            color: Colors.grey.withOpacity(.2),
            child: Row(
              children: [
                SizedBox(
                  width: 10,
                ),
                Icon(
                  Icons.bug_report,
                  color: Colors.grey,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  "Report Issue",
                  style: TextStyle(color: Colors.grey),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    await loginUser();
                  },
                  child: Text(
                    "Unlock",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                SizedBox(
                  width: 20,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
