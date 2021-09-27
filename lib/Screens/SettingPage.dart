import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropdown/flutter_dropdown.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Screens/widgets/ChangePassword/OldPassword.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volume_control/volume_control.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  SharedPreferences sharedPreferences;

  init() async {
    sharedPreferences = await SharedPreferences.getInstance();
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
        title: Text('Settings'),
        elevation: 0,
      ),
      body: Column(children: [
        Divider(
          color: Colors.grey,
          height: 1,
        ),
        textSetting('Chats', Icons.messenger_outline_outlined, () async {
          if (!sharedPreferences.containsKey('dismissOnTouch')) {
            sharedPreferences.setBool('dismissOnTouch', true);
          }
          if (!sharedPreferences.containsKey('enterSendsMsg')) {
            sharedPreferences.setBool('enterSendsMsg', false);
          }
          if (!sharedPreferences.containsKey('hideSendBtn')) {
            sharedPreferences.setBool('hideSendBtn', false);
          }
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => ChatSettingPage(
                      value1: sharedPreferences.getBool('dismissOnTouch'),
                      value2: sharedPreferences.getBool('enterSendsMsg'),
                      value3: sharedPreferences.getBool('hideSendBtn'),
                    )),
          );
        }),
        Divider(
          color: Colors.grey,
          height: 1,
        ),
        textSetting('Notifications', Icons.notifications_none_rounded, () {
          String ringtone = sharedPreferences.containsKey('ringtone')
              ? sharedPreferences.getString('ringtone')
              : "Ding";
          bool sound = sharedPreferences.containsKey('notificationSound')
              ? sharedPreferences.getBool('notificationSound')
              : true;
          bool vibrate = sharedPreferences.containsKey('notificationVibration')
              ? sharedPreferences.getBool('notificationVibration')
              : false;
          String repeat = sharedPreferences.containsKey('ringtoneRepeat')
              ? sharedPreferences.getString('ringtoneRepeat')
              : "1 time";
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => NotificationSettingPage(
                    ringtone: ringtone,
                    sound: sound,
                    vibrate: vibrate,
                    repeat: repeat)),
          );
        }),
        Divider(
          color: Colors.grey,
          height: 1,
        ),
        textSetting('Security', Icons.lock_outline, () {
          String lockAfter = sharedPreferences.containsKey('lockAfter')
              ? sharedPreferences.getString('lockAfter')
              : "2 minutes";
          String maxTries = sharedPreferences.containsKey('maxTry')
              ? sharedPreferences.getString('maxTry')
              : "3 tries";
          String burnTime = sharedPreferences.containsKey('burnTime')
              ? sharedPreferences.getString('burnTime')
              : "Days";
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => SecuritySettingPage(
                      tries: maxTries,
                      lockAfter: lockAfter,
                      burnTime: burnTime,
                    )),
          );
        }),
        Divider(
          color: Colors.grey,
          height: 1,
        ),
        textSetting('Privacy', Icons.privacy_tip_outlined, () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => PrivacySettingPage(
                    value2: sharedPreferences.containsKey('hideMsgPreivew')
                        ? sharedPreferences.getBool('hideMsgPreivew')
                        : false)),
          );
        }),
        Divider(
          color: Colors.grey,
          height: 1,
        ),
      ]),
    );
  }

  Widget textSetting(String title, IconData icon, Function callback) {
    return InkWell(
      onTap: () {
        callback();
      },
      child: Container(
        padding: EdgeInsets.all(8.0),
        margin: EdgeInsets.only(top: 10, bottom: 10),
        height: MediaQuery.of(context).size.height * .05,
        child: Row(
          children: [
            SizedBox(
              width: 10,
            ),
            Icon(
              icon,
              color: Colors.white,
            ),
            SizedBox(
              width: 15,
            ),
            Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatSettingPage extends StatefulWidget {
  bool value1 = true, value2 = false, value3 = false;
  ChatSettingPage({this.value1, this.value2, this.value3});
  @override
  _ChatSettingPageState createState() =>
      _ChatSettingPageState(value1: value1, value2: value2, value3: value3);
}

class _ChatSettingPageState extends State<ChatSettingPage> {
  bool value1 = true, value2 = false, value3 = false;
  SharedPreferences sharedPreferences;

  _ChatSettingPageState({this.value1, this.value2, this.value3});
  init() async {
    sharedPreferences = await SharedPreferences.getInstance();
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
        title: Text('Chats'),
        elevation: 0,
      ),
      body: Column(children: [
        Divider(
          color: Colors.grey,
          height: 1,
        ),
        switchSetting('Dismiss Keyboard On Touch', value1, (bool value) async {
          setState(() {
            value1 = value;
          });
          sharedPreferences.setBool('dismissOnTouch', value);
        }),
        Divider(
          color: Colors.grey,
          height: 1,
        ),
        switchSetting('Enter Sends Message', value2, (bool value) {
          if (value3) return;
          setState(() {
            value2 = value;
          });
          sharedPreferences.setBool('enterSendsMsg', value);
        }),
        Divider(
          color: Colors.grey,
          height: 1,
        ),
        switchSetting('Hide Send Button', value3, (bool value) {
          setState(() {
            value3 = value;
          });
          if (value3) {
            setState(() {
              value2 = false;
            });
          }
          sharedPreferences.setBool('hideSendBtn', value);
        }),
        Divider(
          color: Colors.grey,
          height: 1,
        )
      ]),
    );
  }

  Widget switchSetting(String title, bool value, Function callback) {
    return Container(
      margin: EdgeInsets.only(top: 10, bottom: 10),
      height: MediaQuery.of(context).size.height * .05,
      child: Row(
        children: [
          SizedBox(
            width: 10,
          ),
          Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          Spacer(),
          Switch(
              value: value,
              onChanged: (select) {
                callback(select);
              }),
          SizedBox(
            width: 5,
          )
        ],
      ),
    );
  }
}

class NotificationSettingPage extends StatefulWidget {
  String ringtone, repeat;
  bool sound, vibrate;
  NotificationSettingPage(
      {this.ringtone, this.repeat, this.sound, this.vibrate});
  @override
  _NotificationSettingPagePageState createState() =>
      _NotificationSettingPagePageState(
          ringtone: ringtone, repeat: repeat, sound: sound, vibrate: vibrate);
}

class _NotificationSettingPagePageState extends State<NotificationSettingPage> {
  bool value1 = true, value2 = false, value3 = false, value4 = false;
  String ringtone, repeat;
  bool sound, vibrate;
  SharedPreferences sharedPreferences;
  String tries, lockAfter, burnTime;

  _NotificationSettingPagePageState(
      {this.ringtone, this.repeat, this.sound, this.vibrate});

  init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  refreshData() {
    setState(() {
      ringtone = sharedPreferences.containsKey('ringtone')
          ? sharedPreferences.getString('ringtone')
          : "Ding";
      sound = sharedPreferences.containsKey('notificationSound')
          ? sharedPreferences.getBool('notificationSound')
          : true;
      vibrate = sharedPreferences.containsKey('notificationVibration')
          ? sharedPreferences.getBool('notificationVibration')
          : false;
      repeat = sharedPreferences.containsKey('ringtoneRepeat')
          ? sharedPreferences.getString('ringtoneRepeat')
          : "1 time";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff040d5a),
      appBar: AppBar(
        brightness: Brightness.dark,
        backgroundColor: Color(0xff040d5a),
        title: Text('Notifications'),
        elevation: 0,
      ),
      body: Container(
        child: Column(
          children: [
            Divider(
              color: Colors.grey,
            ),
            switchSetting('encapp Private Notification Service', value1,
                (bool value) {
              setState(() {
                value1 = value;
              });
            }),
            Divider(
              color: Colors.grey,
            ),
            switchSetting('Sound', sound, (bool value) {
              setState(() {
                sound = value;
              });
              sharedPreferences.setBool('notificationSound', value);
              sharedPreferences.setString('sound', value == true ? "1" : "0");
              refreshData();
            }),
            Divider(
              color: Colors.grey,
            ),
            textSetting("Tone", ringtone, () {
              selectRingtone(context);
            }),
            Divider(
              color: Colors.grey,
            ),
            textSetting("Repeat", repeat, () {
              selectRepeat(context);
            }),
            Divider(
              color: Colors.grey,
            ),
            switchSetting('Vibrate', vibrate, (bool value) {
              setState(() {
                vibrate = value;
              });
              sharedPreferences.setBool('notificationVibration', value);
              sharedPreferences.setString('vibrate', value == true ? "1" : "0");
              refreshData();
            }),
            Divider(
              color: Colors.grey,
            )
          ],
        ),
      ),
    );
  }

  void selectRepeat(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> times = [
          '1 time',
          '2 time',
          '3 time',
          '4 time',
          '5 time',
          '6 time',
          '7 time',
          '8 time',
          '9 time',
          '10 time',
        ];
        String gval = repeat;
        return StatefulBuilder(builder: (context, setStateD) {
          return AlertDialog(
            backgroundColor: Color(0xff070738),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Repeat Times",
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 25,
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                      unselectedWidgetColor: Colors.white,
                      disabledColor: Colors.blue),
                  child: Container(
                    height: MediaQuery.of(context).size.height * .5,
                    child: ListView.builder(
                        itemCount: times.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              times[index],
                              style: TextStyle(color: Colors.white),
                            ),
                            leading: Radio(
                              value: times[index],
                              groupValue: gval,
                              onChanged: (value) {
                                setStateD(() {
                                  gval = value;
                                });
                                sharedPreferences.setString(
                                    'ringtoneRepeat', value);
                                refreshData();
                              },
                            ),
                          );
                        }),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.blue),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  Widget switchSetting(String title, bool value, Function callback) {
    return Container(
      height: MediaQuery.of(context).size.height * .05,
      child: Row(
        children: [
          SizedBox(
            width: 10,
          ),
          Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          Spacer(),
          Switch(
              value: value,
              onChanged: (select) {
                callback(select);
              }),
          SizedBox(
            width: 5,
          )
        ],
      ),
    );
  }

  Future<void> playSound(String name, AudioCache audioPlayer) async {
    VolumeControl.setVolume(1);
    String mp3Url = 'sounds/$name.mp3';
    audioPlayer.play(mp3Url);
  }

  void selectRingtone(BuildContext context) {
    final p = AudioPlayer();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> times = [
          'D500',
          'Ting',
          'Note8',
          'Ding',
          'Boxing',
          'Carina',
          'GlassBreak',
          'Gong',
          'Morse',
          'Parrot',
          'Prochitajte',
          'Whistle',
          'Modern',
        ];
        String gval = ringtone;
        return StatefulBuilder(builder: (context, setStateD) {
          return AlertDialog(
            backgroundColor: Color(0xff070738),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Ringtone",
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 25,
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                      unselectedWidgetColor: Colors.white,
                      disabledColor: Colors.blue),
                  child: Container(
                    height: MediaQuery.of(context).size.height * .5,
                    child: ListView.builder(
                        itemCount: times.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              times[index],
                              style: TextStyle(color: Colors.white),
                            ),
                            leading: Radio(
                              value: times[index],
                              groupValue: gval,
                              onChanged: (value) {
                                AudioCache player =
                                    new AudioCache(fixedPlayer: p);
                                p.stop();
                                playSound(value, player);
                                setStateD(() {
                                  gval = value;
                                });
                                sharedPreferences.setString('ringtone', value);
                                refreshData();
                              },
                            ),
                          );
                        }),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.blue),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  Widget textSetting(String title, String subtitle, Function callback) {
    return InkWell(
      onTap: callback,
      child: Container(
        height: MediaQuery.of(context).size.height * .05,
        child: Row(
          children: [
            SizedBox(
              width: 10,
            ),
            Text(
              title,
              style: TextStyle(color: Colors.white),
            ),
            Spacer(),
            Text(subtitle, style: TextStyle(color: Colors.grey)),
            Icon(
              Icons.keyboard_arrow_right_outlined,
              color: Colors.grey,
            ),
            SizedBox(
              width: 5,
            )
          ],
        ),
      ),
    );
  }
}

class PrivacySettingPage extends StatefulWidget {
  bool value2;
  PrivacySettingPage({this.value2});
  @override
  _PrivacySettingPageState createState() =>
      _PrivacySettingPageState(value2: value2);
}

class _PrivacySettingPageState extends State<PrivacySettingPage> {
  SharedPreferences sharedPreferences;
  bool value1 = true,
      value2 = false,
      value3 = false,
      value4 = true,
      value5 = false;

  _PrivacySettingPageState({this.value2});

  init() async {
    sharedPreferences = await SharedPreferences.getInstance();
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
        title: Text('Privacy'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          switchSetting('Ask When Launching External Apps', value1,
              (bool value) {
            setState(() {
              value1 = value;
            });
          }),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          switchSetting('Hide Message Preview', value2, (bool value) {
            setState(() {
              value2 = value;
            });
            sharedPreferences.setBool("hideMsgPreivew", value);
            Provider.of<ChatProvider>(context, listen: false).setPreview(value);
          }),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          switchSetting('Disable Matrix Calling', value3, (bool value) {
            setState(() {
              value3 = value;
            });
          }),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          switchSetting('Start my calls on mute', value4, (bool value) {
            setState(() {
              value4 = value;
            });
          }),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          switchSetting('Start my calls on mute', value5, (bool value) {
            setState(() {
              value5 = value;
            });
          }),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget switchSetting(String title, bool value, Function callback) {
    return Container(
      margin: EdgeInsets.only(top: 10, bottom: 10),
      height: MediaQuery.of(context).size.height * .05,
      child: Row(
        children: [
          SizedBox(
            width: 10,
          ),
          Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          Spacer(),
          Switch(
              value: value,
              onChanged: (select) {
                callback(select);
              }),
          SizedBox(
            width: 5,
          )
        ],
      ),
    );
  }
}

class SecuritySettingPage extends StatefulWidget {
  String tries, lockAfter, burnTime;
  SecuritySettingPage({this.tries, this.lockAfter, this.burnTime});

  @override
  _SecuritySettingPageState createState() => _SecuritySettingPageState(
      tries: tries, lockAfter: lockAfter, burnTime: burnTime);
}

class _SecuritySettingPageState extends State<SecuritySettingPage> {
  SharedPreferences sharedPreferences;
  String tries, lockAfter, burnTime;

  init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  _SecuritySettingPageState({this.tries, this.lockAfter, this.burnTime});
  @override
  void initState() {
    init();
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
        title: Text("Security"),
      ),
      body: Column(
        children: [
          Divider(
            height: 1,
            color: Colors.grey,
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => OldPassword()),
              );
            },
            child: Container(
              child: Column(
                children: [
                  SizedBox(
                    height: h * .03,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "APPLICATION",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Text(
                          "Change Password",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Spacer(),
                        dot(),
                        SizedBox(
                          width: 5,
                        ),
                        dot(),
                        SizedBox(
                          width: 5,
                        ),
                        dot(),
                        SizedBox(
                          width: 5,
                        ),
                        dot(),
                        SizedBox(
                          width: 10,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          InkWell(
            onTap: () {
              maxPasswordAttemtps(context);
            },
            child: Container(
              margin: EdgeInsets.only(top: 10, bottom: 10),
              height: MediaQuery.of(context).size.height * .05,
              child: Row(
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Maximum Password Attempts",
                    style: TextStyle(color: Colors.white),
                  ),
                  Spacer(),
                  Text(tries, style: TextStyle(color: Colors.grey)),
                  Icon(
                    Icons.keyboard_arrow_right_outlined,
                    color: Colors.grey,
                  ),
                  SizedBox(
                    width: 5,
                  )
                ],
              ),
            ),
          ),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          InkWell(
            onTap: () {
              showLockAfterDialog(context);
            },
            child: Container(
              margin: EdgeInsets.only(top: 10, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "Auto Lock After",
                        style: TextStyle(color: Colors.white),
                      ),
                      Spacer(),
                      Text(lockAfter, style: TextStyle(color: Colors.grey)),
                      Icon(
                        Icons.keyboard_arrow_right_outlined,
                        color: Colors.grey,
                      ),
                      SizedBox(
                        width: 5,
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Automatically lock the app after a period of inactivity.",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  )
                ],
              ),
            ),
          ),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          InkWell(
            onTap: () {
              showBurnTimer(context);
            },
            child: Container(
              margin: EdgeInsets.only(top: 10, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "MESSAGES",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "Default Burn Time",
                        style: TextStyle(color: Colors.white),
                      ),
                      Spacer(),
                      Text("5 $burnTime", style: TextStyle(color: Colors.grey)),
                      Icon(
                        Icons.keyboard_arrow_right_outlined,
                        color: Colors.grey,
                      ),
                      SizedBox(
                        width: 5,
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          Divider(
            color: Colors.grey,
            height: 1,
          )
        ],
      ),
    );
  }

  Widget dot() {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
    );
  }

  refreshData() {
    setState(() {
      tries = sharedPreferences.containsKey('maxTry')
          ? sharedPreferences.getString('maxTry')
          : "3 tries";
      lockAfter = sharedPreferences.containsKey('lockAfter')
          ? sharedPreferences.getString('lockAfter')
          : "10 minutes";
      burnTime = sharedPreferences.containsKey('burnTime')
          ? sharedPreferences.getString('burnTime')
          : "Days";
    });
  }

  void maxPasswordAttemtps(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> times = [
          '3 tries',
          '5 tries',
          '10 tries',
          '15 tries',
          '20 tries',
          '25 tries',
          '30 tries'
        ];
        String gval = tries;
        return StatefulBuilder(builder: (context, setStateD) {
          return AlertDialog(
            backgroundColor: Color(0xff070738),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Number of Max Tries",
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 25,
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                      unselectedWidgetColor: Colors.white,
                      disabledColor: Colors.blue),
                  child: Container(
                    height: MediaQuery.of(context).size.height * .5,
                    child: ListView.builder(
                        itemCount: times.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              times[index],
                              style: TextStyle(color: Colors.white),
                            ),
                            leading: Radio(
                              value: times[index],
                              groupValue: gval,
                              onChanged: (value) {
                                setStateD(() {
                                  gval = value;
                                });
                                sharedPreferences.setString('maxTry', value);
                                refreshData();
                              },
                            ),
                          );
                        }),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.blue),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  void showLockAfterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> times = [
          '2 minutes',
          '5 minutes',
          '10 minutes',
          '15 minutes',
          '20 minutes',
          '25 minutes',
          '30 minutes'
        ];
        String gval = lockAfter;
        return StatefulBuilder(builder: (context, setStateD) {
          return AlertDialog(
            backgroundColor: Color(0xff070738),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Auto Lock Time",
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 25,
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                      unselectedWidgetColor: Colors.white,
                      disabledColor: Colors.blue),
                  child: Container(
                    height: MediaQuery.of(context).size.height * .5,
                    child: ListView.builder(
                        itemCount: times.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              times[index],
                              style: TextStyle(color: Colors.white),
                            ),
                            leading: Radio(
                              value: times[index],
                              groupValue: gval,
                              onChanged: (value) {
                                setStateD(() {
                                  gval = value;
                                });
                                sharedPreferences.setString('lockAfter', value);
                                refreshData();
                              },
                            ),
                          );
                        }),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  void showBurnTimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selected = burnTime;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Color(0xff070738),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Default Burn Time",
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 25,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                    ),
                    DropDown<String>(
                      items: <String>["Minutes", "Days"],
                      customWidgets: <Widget>[
                        Container(
                            width: 100,
                            height: 30,
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                color: Colors.blue),
                            child: Center(
                                child: Text("Minutes",
                                    style: TextStyle(color: Colors.white)))),
                        Container(
                            width: 100,
                            height: 30,
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                color: Colors.blue),
                            child: Center(
                                child: Text("Days",
                                    style: TextStyle(color: Colors.white))))
                      ],
                      hint: Container(
                          width: 100,
                          height: 30,
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              color: Colors.blue),
                          child: Center(
                              child: Text(burnTime,
                                  style: TextStyle(color: Colors.white)))),
                      showUnderline: false,
                      onChanged: (val) {
                        selected = val;
                      },
                    ),
                    Spacer(),
                    Text(
                      "5",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22),
                    ),
                    SizedBox(
                      width: 20,
                    )
                  ],
                ),
                SizedBox(
                  height: 40,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    InkWell(
                      onTap: () {
                        sharedPreferences.setString("burnTime", selected);
                        refreshData();
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: Text(
                        "Done",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
