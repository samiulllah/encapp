import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Models/group_message.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/group.dart';
import 'package:encapp/Providers/group_chat.dart';
import 'package:encapp/Providers/home.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Screens/GroupProfile.dart';
import 'package:encapp/Screens/widgets/GroupMediaMsgs/ChatAudio/AudioItem.dart';
import 'package:encapp/Screens/widgets/GroupMediaMsgs/ChatAudio/RecordAudio.dart';
import 'package:encapp/Screens/widgets/GroupMediaMsgs/ChatImage/ImageItem.dart';
import 'package:encapp/Screens/widgets/GroupMediaMsgs/ChatImage/PickImage.dart';
import 'package:encapp/Screens/widgets/ShareWith.dart';
import 'package:encapp/Screens/widgets/add_contact.dart';
import 'package:encapp/Screens/widgets/drawer.dart';
import 'package:encapp/Screens/widgets/floating_action.dart';
import 'package:encapp/Screens/widgets/loadingAlert.dart';
import 'package:encapp/Services/chat.dart';
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:encapp/Services/group_chat.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:star_menu/star_menu.dart';
import 'package:toast/toast.dart';
import 'package:vibration/vibration.dart';
import 'ChatProfilePage.dart';

class GroupChatScreen extends StatefulWidget {
  GroupModel gm;
  String forMsg;

  GroupChatScreen({this.gm, this.forMsg});

  @override
  _GroupChatScreenState createState() =>
      _GroupChatScreenState(gm: gm, forMsg: forMsg);
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with WidgetsBindingObserver {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  bool highlight = false;
  int val = -1;
  int round = 0;
  String forMsg;

  double w, h;
  UserProvider userProvider;
  GroupChatProvider chatProvider;
  ScrollController _scrollController = new ScrollController();
  var keyboardVisibilityController = KeyboardVisibilityController();
  TextEditingController msgController = new TextEditingController();
  bool showDown = false, send = false, selection = false;
  bool loading = true;
  String myId;
  String toId;
  String myName;
  String peerName;
  int flag = -1; // me
  String convid;
  GroupModel gm;
  bool leaving = false;
  int lastLength = 0;

  SharedPreferences sharedPreferences;

  _GroupChatScreenState({this.gm, this.forMsg});

  init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (forMsg != null)
      setState(() {
        send = true;
        msgController = new TextEditingController(text: forMsg);
      });
    GroupChatService.groupChatContext = context;
    setState(() {
      loading = true;
    });
    userProvider = Provider.of<UserProvider>(context, listen: false);
    chatProvider = Provider.of<GroupChatProvider>(context, listen: false);
    String id = await userProvider.getDeviceId();
    convid = gm.grpId;
    String nam = sharedPreferences.getString('alias');
    chatProvider.initChat(id, gm.grpId, getPpls(), gm, nam);
    setState(() {
      myId = id;
      myName = nam;
      loading = false;
    });
    chatProvider.markAsRead();
  }

  @override
  void initState() {
    listener();
    init();
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Color(0xff040d5a)));
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    keyboardVisibilityController.onChange.listen((bool visible) {
      if (_scrollController.hasClients)
        _scrollController.animateTo(
          0.0,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
    });
  }

  List<String> getPpls() {
    List<String> ppls = [];
    for (Members m in gm.members) {
      ppls.add(m.id);
    }
    return ppls;
  }

  @override
  Future<void> didChangeAppLifecycleState(final AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      init();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void scrollTo0() {
    if (chatProvider.allMsgs[convid] != null &&
        chatProvider.allMsgs[convid].length > 0)
      itemScrollController.scrollTo(
          index: chatProvider.allMsgs[convid].length,
          duration: Duration(seconds: 1),
          curve: Curves.easeInOutCubic);
  }

  void listener() {
    itemPositionsListener.itemPositions.addListener(() {
      highlighter();
    });
  }

  void highlighter() {
    if (itemPositionsListener.itemPositions.value != null &&
        itemPositionsListener.itemPositions.value.length > 0) {
      if (itemPositionsListener.itemPositions.value.first.index == val &&
          round == 0) {
        setState(() {
          highlight = true;
        });
        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            highlight = false;
          });
          round = 1;
        });
      }
    }
  }

  sendMessage() {
    print("txt ${msgController.text}");
    scrollTo0();
    if (msgController.text.isNotEmpty) {
      print("yes");
      List<ToPpl> ppls = [];
      for (Members m in gm.members) {
        ppls.add(new ToPpl(id: m.id, alias: m.alias));
      }
      GroupMessageModel m = new GroupMessageModel(
          grpId: gm.grpId,
          fromId: myId,
          read: 0,
          fromAlias: myName,
          msg: msgController.text,
          favourite: 0,
          replyId: chatProvider.replyMsg != null
              ? int.parse(chatProvider.replyMsg.id)
              : -1,
          msgType: "0",
          localUrl: "",
          toPpl: ppls);
      m.sent = '1';
      chatProvider.sendToLocal(m);
      msgController.clear();
      setState(() {
        send = false;
      });
      chatProvider.unselectAll();
    }
    print("yes1");
  }

  Widget renderMsgs(List<GroupMessageModel> msgs1) {
    Widget l = msgs1 != null
        ? ScrollablePositionedList.builder(
            itemCount: msgs1.length,
            addAutomaticKeepAlives: false,
            initialScrollIndex: msgs1.length,
            itemBuilder: (context, index) {
              bool iamSender = msgs1[index].fromId == myId;
              return msgs1[index].msgType == "1"
                  ? Container(
                      key: new Key(msgs1[msgs1.length - 1].id + 'img'),
                      child: new ImageItem(
                          msg: msgs1[index],
                          iamSender: iamSender,
                          callback: () {
                            setState(() {
                              leaving = !leaving;
                            });
                          }),
                    )
                  : msgs1[index].msgType == "2"
                      ? Container(
                          key: new Key(msgs1[msgs1.length - 1].id + 'aud'),
                          child: new AudioItem(
                            msg: msgs1[index],
                            iamSender: iamSender,
                          ),
                        )
                      : iamSender
                          ? myMsg(msgs1[index], index, () {
                              setState(() {
                                val =
                                    chatProvider.getIndex(msgs1[index].replyId);
                              });
                              scrollToIndex(val);
                            })
                          : otherMsg(msgs1[index], index, () {
                              setState(() {
                                val =
                                    chatProvider.getIndex(msgs1[index].replyId);
                              });
                              scrollToIndex(val);
                            });
            },
            itemScrollController: itemScrollController,
            itemPositionsListener: itemPositionsListener,
          )
        : Container();
    Future.delayed(Duration(seconds: 1), () {
      if (lastLength != chatProvider.allMsgs[convid].length) {
        scrollTo0();
      }
      lastLength = msgs1.length;
    });
    return l;
  }

  creator(String msg) {
    return Center(
      child: Text(
        msg,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void scrollToIndex(int index) {
    round = 0;
    itemScrollController.scrollTo(
        index: index,
        duration: Duration(seconds: 1),
        curve: Curves.easeInOutCubic);
    highlighter();
  }

  Future<bool> _willPopCallback() async {
    if (chatProvider.selection) {
      chatProvider.unselectAll();
      return false;
    }
    return true; // return true if the route to be popped
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<GroupChatProvider>();
    final hp = context.watch<HomeProvider>();

    ChatService.chatContext = context;
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;
    return hp.isConnected
        ? WillPopScope(
            onWillPop: _willPopCallback,
            child: GestureDetector(
              onTap: () {
                bool dismiss = sharedPreferences.containsKey('dismissOnTouch')
                    ? sharedPreferences.getBool('dismissOnTouch')
                    : false;
                if (dismiss) {
                  FocusManager.instance.primaryFocus?.unfocus();
                }
              },
              child: Scaffold(
                backgroundColor: Color(0xff040d5a),
                appBar: AppBar(
                  brightness: Brightness.dark,
                  backgroundColor: Color(0xff040d5a),
                  elevation: 0,
                  actions: [
                    if (!cp.selection)
                      Builder(
                        builder: (context) => IconButton(
                          icon: Icon(
                            Icons.dashboard_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                          tooltip: MaterialLocalizations.of(context)
                              .openAppDrawerTooltip,
                        ),
                      )
                  ],
                  title: cp.selection ? copyHeader(cp.nosSelected) : header(),
                ),
                endDrawer: getEndDrawerForGroupChat(context, gm, myId),
                body: Container(
                  color: Color(0xff040d5a),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      drawLine(),
                      SizedBox(
                        height: h * .02,
                      ),
                      if (!loading)
                        Expanded(
                          child: renderMsgs(cp.allMsgs[gm.grpId]),
                        ),
                      SizedBox(
                        height: 10,
                      ),
                      if (cp.typing)
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            margin: const EdgeInsets.only(left: 15, bottom: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Typing",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 5),
                                  child: SpinKitThreeBounce(
                                    color: Colors.grey,
                                    size: 10,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      if (cp.replyMsg != null) replyBox(cp.replyMsg),
                      if (!loading)
                        input((value) async {
                          setState(() {
                            send = value.length > 0;
                          });
                          if (value.length > 0) {
                            // started typing
                            await chatProvider.emitTyping();
                          } else {
                            // stopped typing
                            await chatProvider.emitStopTyping();
                          }
                        }),
                    ],
                  ),
                ),
              ),
            ),
          )
        : noConnection(w, h);
  }

  Widget copyHeader(int totalSelected) {
    return Container(
      height: h * .1,
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 10,
            ),
            GestureDetector(
              onTap: () {
                chatProvider.unselectAll();
              },
              child: Icon(
                Icons.keyboard_backspace_rounded,
                color: Colors.white,
              ),
            ),
            Spacer(),
            Text(
              '$totalSelected',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: 30,
            ),
            if (totalSelected == 1)
              GestureDetector(
                onTap: () {
                  chatProvider.reply();
                },
                child: Icon(
                  Icons.reply,
                  color: Colors.white,
                ),
              ),
            Spacer(),
            GestureDetector(
              onTap: () {
                chatProvider.copySelected(context);
              },
              child: Icon(
                Icons.copy,
                color: Colors.white,
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () async {
                await chatProvider.deleteSelected(context);
              },
              child: Icon(
                Icons.delete_outline,
                color: Colors.white,
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () async {
                await chatProvider.addMsgToFavourite(context);
              },
              child: Icon(
                Icons.star_border_outlined,
                color: Colors.white,
              ),
            ),
            // GestureDetector(
            //   onTap: () {
            //     Navigator.of(context)
            //         .push(
            //       MaterialPageRoute(builder: (_) => ShareWithScreen()),
            //     )
            //         .then((value) {
            //       init();
            //     });
            //   },
            //   child: Icon(
            //     Icons.share_outlined,
            //     color: Colors.white,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget header() {
    return Container(
      height: h * .1,
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 10,
            ),
            GestureDetector(
              onTap: () {
                Provider.of<GroupChatProvider>(context, listen: false)
                    .disposeSocket();
                OneContext().pop();
              },
              child: Icon(
                Icons.keyboard_backspace_rounded,
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: 20,
            ),
            InkWell(
              onTap: () {
                OneContext()
                    .push(
                  MaterialPageRoute(
                      builder: (_) => GroupProfileScreen(
                            gm: gm,
                            myId: myId,
                          )),
                )
                    .then((value) async {
                  Provider.of<GroupChatProvider>(context, listen: false)
                      .disposeSocket();
                  init();
                });
              },
              child: Text(
                gm.grpName,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Spacer(),
            SizedBox(
              width: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget drawLine() {
    return Container(
      width: w,
      height: 1,
      color: Colors.grey,
    );
  }

  Widget input(Function callback) {
    return Container(
      height: h * .08,
      width: w,
      margin: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          StarMenu(
            params: StarMenuParameters(
                shape: MenuShape.linear,
                linearShapeParams: LinearShapeParams(
                    angle: 270, space: 4, alignment: LinearAlignment.top),
                backgroundParams: BackgroundParams(
                  backgroundColor: Colors.transparent,
                  animatedBackgroundColor: false,
                  animatedBlur: false,
                ),
                onItemTapped: (index, controller) {
                  controller.closeMenu();
                }),
            items: [
              GestureDetector(
                onTap: () async {
                  showImagePicker(context);
                },
                child: Container(
                  height: 45,
                  child: FloatingActionButton(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 5,
              ),
              GestureDetector(
                onTap: () {
                  showRecorder(context);
                },
                child: Container(
                  height: 45,
                  child: FloatingActionButton(
                    child: Icon(
                      Icons.medical_services_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 60,
                width: 10,
              ),
            ],
            child: Container(
              height: 45,
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: Colors.grey.withOpacity(.3),
                child: Icon(Icons.more),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Color(0xff100630),
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              child: TextField(
                onChanged: (value) {
                  callback(value);
                },
                keyboardType: TextInputType.multiline,
                maxLines: null,
                controller: msgController,
                textInputAction: sharedPreferences.containsKey('hideSendBtn')
                    ? sharedPreferences.getBool('hideSendBtn')
                        ? TextInputAction.send
                        : sharedPreferences.containsKey('enterSendsMsg')
                            ? sharedPreferences.getBool('enterSendsMsg')
                                ? TextInputAction.send
                                : TextInputAction.newline
                            : TextInputAction.newline
                    : TextInputAction.newline,
                onSubmitted: (value) {
                  chatProvider.emitStopTyping();
                  sendMessage();
                },
                style: TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    border: InputBorder.none,
                    hintText: "Send secure message",
                    hintStyle: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
          SizedBox(
            width: 5,
          ),
          GestureDetector(
            onTap: sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                color: Colors.grey.withOpacity(.3),
              ),
              child: Icon(
                Icons.send,
                color: send ? Colors.blue : Colors.grey,
              ),
            ),
          ),
          SizedBox(
            width: 10,
          )
        ],
      ),
    );
  }

  Widget iconText(IconData icon, String title) {
    return Container(
      height: 22,
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.lightBlue,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      child: Center(
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 15,
            ),
            SizedBox(
              width: 2,
            ),
            Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // reply box
  Widget replyBox(GroupMessageModel msg) {
    return Container(
      height: h * .13,
      width: w,
      color: Colors.grey.withOpacity(.3),
      child: Row(
        children: [
          Container(
            height: h * .2,
            width: 5,
            color: Colors.blue,
          ),
          SizedBox(
            width: w * .05,
          ),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: h * .02,
                ),
                Row(
                  children: [
                    Text(
                      msg.fromAlias != null ? msg.fromAlias : msg.fromId,
                      style: TextStyle(color: Colors.cyan),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      msg.getDateTimeClause()[1],
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    )
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  msg.msg.trim(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "5m",
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
          SizedBox(
            width: w * .1,
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                GestureDetector(
                    onTap: () {
                      chatProvider.cancelReply();
                    },
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                    ))
              ],
            ),
          ),
          SizedBox(
            width: w * .03,
          )
        ],
      ),
    );
  }

  Widget myMsg(GroupMessageModel msg, int index, Function callback) {
    String burnTime = '5d';
    return Material(
      color: index == val && highlight
          ? Colors.grey.withOpacity(.3)
          : msg.selected
              ? Colors.grey.withOpacity(.4)
              : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (msg.delMsg != 1) {
            if (chatProvider.selection) {
              chatProvider.selectMsg(int.parse(msg.id));
            }
          }
        },
        onLongPress: () {
          if (msg.delMsg != 1) {
            if (!chatProvider.selection)
              chatProvider.selectMsg(int.parse(msg.id));
          }
        },
        child: Container(
          margin: EdgeInsets.only(top: 10),
          width: w,
          child: Column(children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 10,
                ),
                Text('X-Ray', style: TextStyle(color: Colors.grey[500])),
                SizedBox(
                  width: 10,
                ),
                if (msg.replyId != null && msg.replyId != -1)
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 2),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        )),
                  ),
                SizedBox(
                  width: 10,
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            if (msg.delMsg != 1 && msg.replyId != null && msg.replyId != -1)
              Container(
                  padding: EdgeInsets.only(right: 10),
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                      onTap: callback, child: replyItem(msg.replyId))),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: w * .3,
                ),
                Flexible(
                  child: Text(
                    msg.delMsg == 1 ? "message removed" : msg.msg,
                    style: TextStyle(
                        color: msg.delMsg == 1 ? Colors.grey : Colors.white),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
              ],
            ),
            SizedBox(
              height: 5,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  burnTime,
                  style: TextStyle(color: Colors.blue, fontSize: 11),
                ),
                SizedBox(
                  width: 10,
                ),
                Text(msg.getDateTimeClause()[1],
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
                SizedBox(
                  width: 10,
                ),
                Icon(
                  msg.sent == '1' ? Icons.check : Icons.access_time,
                  color: msg.read == 1 ? Colors.green : Colors.blue,
                  size: msg.sent == '1' ? 18 : 14,
                ),
                SizedBox(
                  width: 20,
                ),
              ],
            )
          ]),
        ),
      ),
    );
  }

  Widget otherMsg(GroupMessageModel msg, int index, Function callback) {
    String burnTime = '5d';
    return Material(
      color: index == val && highlight
          ? Colors.grey.withOpacity(.3)
          : msg.selected
              ? Colors.grey.withOpacity(.4)
              : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (msg.delMsg != 1) {
            if (chatProvider.selection) {
              chatProvider.selectMsg(int.parse(msg.id));
            }
          }
        },
        onLongPress: () {
          if (msg.delMsg != 1) {
            if (!chatProvider.selection) {
              chatProvider.selectMsg(int.parse(msg.id));
            }
          }
        },
        child: Container(
          margin: EdgeInsets.only(top: 10),
          width: w,
          child: Column(children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 10,
                ),
                if (msg.replyId != null && msg.replyId != -1)
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.cyan, width: 2),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        )),
                  ),
                SizedBox(
                  width: 10,
                ),
                Text(msg.fromAlias != null ? msg.fromAlias : msg.fromId,
                    style: TextStyle(color: Colors.cyan)),
                SizedBox(
                  width: 10,
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            if (msg.delMsg != 1 && msg.replyId != null && msg.replyId != -1)
              Container(
                  padding: EdgeInsets.only(left: 10),
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                      onTap: callback, child: replyItem(msg.replyId))),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 10,
                ),
                Flexible(
                  child: Text(
                    msg.delMsg == 1 ? "message removed" : msg.msg,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                        color: msg.delMsg == 1 ? Colors.grey : Colors.white),
                  ),
                ),
                SizedBox(
                  width: w * .2,
                )
              ],
            ),
            SizedBox(
              height: 5,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 10,
                ),
                Text(
                  msg.getDateTimeClause()[1],
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                SizedBox(
                  width: 10,
                ),
                Text(burnTime,
                    style: TextStyle(color: Colors.blue, fontSize: 11)),
              ],
            )
          ]),
        ),
      ),
    );
  }

  Widget addGroupPage(BuildContext context, double w, double h, GroupModel gm) {
    return Container(
      width: w,
      height: h * .15,
      color: Colors.blue,
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "You were added to this group",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Do you want to accept or decline this request?",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () async {
                  showProgress("Declining...");
                  bool f =
                      await Provider.of<GroupProvider>(context, listen: false)
                          .declineGroupRequest(gm);
                  if (f) {
                    Toast.show("Declined!", context);
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).pop();
                  } else {
                    Toast.show("Failed to decline!", context);
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
                child: Text(
                  "Decline",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              SizedBox(
                width: 15,
              ),
              InkWell(
                onTap: () async {
                  showProgress("Accepting...");
                  bool f =
                      await Provider.of<GroupProvider>(context, listen: false)
                          .acceptGroup(gm.grpId);
                  if (f) {
                    setState(() {
                      gm.groupExist = true;
                    });
                    Toast.show("Accepted!", context);
                    Navigator.of(context, rootNavigator: true).pop();
                  } else {
                    Toast.show("Failed to accept", context);
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
                child: Text(
                  "Accept",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              SizedBox(
                width: 15,
              ),
            ],
          )
        ],
      ),
    );
  }

  // reply item
  Widget replyItem(int id) {
    GroupMessageModel msg = chatProvider.getMsgWithId(id);
    if (msg == null) {
      return Container();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: h * .1,
          width: w * .55,
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(.3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              )),
          child: Row(
            children: [
              Container(
                height: h * .1,
                width: 8,
                decoration: BoxDecoration(
                    color: Colors.lightBlue.withOpacity(.6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    )),
              ),
              SizedBox(width: w * .03),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          msg.fromAlias != null ? msg.fromAlias : msg.fromId,
                          style: TextStyle(color: Colors.cyan, fontSize: 12),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          msg.getDateTimeClause()[1],
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        msg.delMsg == 1 ? "message removed" : msg.msg.trim(),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                            color: msg.delMsg == 1 ? Colors.grey : Colors.white,
                            fontSize: 11),
                      ),
                    ),
                    Spacer(),
                    Text(
                      "5m",
                      style: TextStyle(color: Colors.blue, fontSize: 11),
                    ),
                    SizedBox(
                      height: 10,
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          "Replied",
          style: TextStyle(color: Colors.grey, fontSize: 11),
        )
      ],
    );
  }
}
