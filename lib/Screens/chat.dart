import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/home.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Screens/widgets/ChatAudio/AudioItem.dart';
import 'package:encapp/Screens/widgets/ChatAudio/RecordAudio.dart';
import 'package:encapp/Screens/widgets/ChatImage/ImageItem.dart';
import 'package:encapp/Screens/widgets/ChatImage/PickImage.dart';
import 'package:encapp/Screens/widgets/ShareWith.dart';
import 'package:encapp/Screens/widgets/add_contact.dart';
import 'package:encapp/Screens/widgets/drawer.dart';
import 'package:encapp/Screens/widgets/floating_action.dart';
import 'package:encapp/Services/chat.dart';
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:star_menu/star_menu.dart';
import 'package:toast/toast.dart';
import 'package:vibration/vibration.dart';
import 'ChatProfilePage.dart';

class ChatScreen extends StatefulWidget {
  String peerName;
  String toId;
  String forMsg;
  String convid;
  MessageModel md;
  ChatScreen({this.peerName, this.toId, this.forMsg, this.convid, this.md});

  @override
  _ChatScreenState createState() => _ChatScreenState(
      peerName: peerName, toId: toId, forMsg: forMsg, convid: convid);
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  bool highlight = false;
  int val = -1;
  int round = 0;
  String forMsg;
  double w, h;
  UserProvider userProvider;
  ChatProvider chatProvider;
  ScrollController _scrollController = new ScrollController();
  var keyboardVisibilityController = KeyboardVisibilityController();
  TextEditingController msgController = new TextEditingController();
  bool showDown = false, send = false, selection = false;
  bool loading = true;
  bool contactExist = false;
  String myId, toId, convid, myName, peerName;
  int flag = -1; // me
  int lastLength = 0;
  bool leaving = false;

  SharedPreferences sharedPreferences;

  _ChatScreenState({this.peerName, this.toId, this.forMsg, this.convid});
  shareMsg() async {
    if (widget.md != null) {
      ChatProvider chatProvider =
          Provider.of<ChatProvider>(OneContext().context, listen: false);
      await chatProvider.shareMediaMsg(widget.md);
      chatProvider.fetchChat(convid);
    }
  }

  init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (forMsg != null)
      setState(() {
        send = true;
        msgController = new TextEditingController(text: forMsg);
      });
    setState(() {
      loading = true;
    });

    userProvider = Provider.of<UserProvider>(context, listen: false);
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    shareMsg();
    String id = await userProvider.getDeviceId();
    chatProvider.initChat(id, toId, 'Plank', peerName);
    bool e = await userProvider.doesContactExist(toId);
    convid = chatProvider.convid;
    setState(() {
      contactExist = e;
      myId = id;
      myName = 'Palak';
      loading = false;
    });
    // send chat read event
    //chatProvider.emitChatRead({'from_id': myId, 'to_id': toId}, convid, toId);
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
          duration: Duration(milliseconds: 1),
          curve: Curves.linear);
  }

  sendMessage() {
    scrollTo0();
    if (msgController.text.isNotEmpty) {
      MessageModel m = new MessageModel(
          convid: convid,
          fromId: myId,
          toId: toId,
          read: 0,
          fromAlias: myName,
          toAlias: peerName,
          msg: msgController.text,
          favourite: 0,
          datetime: DateTime.now(),
          delMsg: 0,
          msgType: "0",
          localUrl: "",
          replyId:
              chatProvider.replyMsg != null ? chatProvider.replyMsg.id : -1);
      m.sent = '1';
      chatProvider.sendToLocal(m);
      msgController.clear();
      setState(() {
        send = false;
      });
      chatProvider.unselectAll();
    }
  }

  Widget renderMsgs(List<MessageModel> msgs1) {
    Widget l = msgs1 != null && msgs1.length > 0
        ? ScrollablePositionedList.builder(
            itemCount: msgs1.length,
            addAutomaticKeepAlives: true,
            initialScrollIndex: msgs1.length,
            itemBuilder: (context, index) {
              bool iamSender = msgs1[index].fromId == myId;
              return msgs1[index].msgType == "1"
                  ? Container(
                      key: new Key(
                          msgs1[msgs1.length - 1].id.toString() + 'img'),
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
                          key: new Key(
                              msgs1[msgs1.length - 1].id.toString() + 'aud'),
                          child: new AudioItem(
                            msg: msgs1[index],
                            iamSender: iamSender,
                          ),
                        )
                      : iamSender
                          ? myReply(msgs1[index], index, () {
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
      if (chatProvider.allMsgs[convid] != null &&
          lastLength != chatProvider.allMsgs[convid].length) {
        scrollTo0();
      }
      if (chatProvider.allMsgs[convid] != null && msgs1 != null)
        lastLength = msgs1.length;
    });
    return l;
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
    print("Willpop");
    if (chatProvider.selection) {
      chatProvider.unselectAll();
      return false;
    }
    Provider.of<ChatProvider>(context, listen: false).disposeSocket();
    Provider.of<ChatProvider>(context, listen: false).fetchDialogues();
    return true; // return true if the route to be popped
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ChatProvider>();
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
                            onPressed: () =>
                                Scaffold.of(context).openEndDrawer(),
                            tooltip: MaterialLocalizations.of(context)
                                .openAppDrawerTooltip,
                          ),
                        )
                    ],
                    title: cp.selection
                        ? copyHeader(cp.nosSelected)
                        : header(cp.block),
                  ),
                  endDrawer: getEndDrawer(context, peerName, toId, () async {
                    bool e = await userProvider.doesContactExist(toId);
                    setState(() {
                      contactExist = e;
                    });
                    Provider.of<ChatProvider>(context, listen: false)
                        .disposeSocket();
                    init();
                  }),
                  body: Container(
                    color: Color(0xff040d5a),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        if (cp.block != 2) drawLine(),
                        if (cp.block == 2) blocked(),
                        SizedBox(
                          height: h * .02,
                        ),
                        if (!loading && !leaving)
                          Expanded(
                            child: renderMsgs(cp.allMsgs[convid]),
                          ),
                        SizedBox(
                          height: 10,
                        ),
                        if (cp.typing)
                          Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              margin:
                                  const EdgeInsets.only(left: 15, bottom: 5),
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
                  )),
            ),
          )
        : noConnection(w, h);
  }

  Widget blocked() {
    return Container(
        height: h * .08,
        color: Colors.blueGrey.withOpacity(.6),
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                "You have been blocked",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          ],
        ));
  }

  Widget unBlocK() {
    return InkWell(
      onTap: () async {
        int unblock = await Provider.of<UserProvider>(context, listen: false)
            .unblockUser(widget.toId, 1);
        if (unblock == 1) {
          chatProvider.setBlock(0);
        }
      },
      child: Container(
          height: h * .08,
          alignment: Alignment.bottomCenter,
          color: Colors.grey.withOpacity(.3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  "TAP TO UNBLOCK",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              )
            ],
          )),
    );
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
            Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(builder: (_) => ShareWithScreen()),
                )
                    .then((value) {
                  init();
                });
              },
              child: Icon(
                Icons.share_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // reply box
  Widget replyBox(MessageModel msg) {
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

  Widget header(int block) {
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
                Provider.of<ChatProvider>(context, listen: false)
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
                if (block != 2) {
                  OneContext()
                      .push(
                    MaterialPageRoute(
                        builder: (_) => ChatProfilePage(
                            alias: peerName, cid: toId, add: false)),
                  )
                      .then((value) async {
                    bool e = await userProvider.doesContactExist(toId);
                    setState(() {
                      contactExist = e;
                    });
                    Provider.of<ChatProvider>(context, listen: false)
                        .disposeSocket();
                    init();
                  });
                }
              },
              child: Container(
                width: w * .3,
                child: Text(
                  peerName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
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
                  //showRecorder(context);
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

  Widget otherMsg(MessageModel msg, int index, Function callback) {
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
              chatProvider.selectMsg(msg.id);
            }
          }
        },
        onLongPress: () {
          if (msg.delMsg != 1) {
            if (!chatProvider.selection) {
              chatProvider.selectMsg(msg.id);
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
                    style: TextStyle(
                        color: Colors.cyan, fontWeight: FontWeight.bold)),
                SizedBox(
                  width: 10,
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            if (msg.replyId != null && msg.replyId != -1)
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
                        color: msg.delMsg == 1 ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.bold),
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

  String getConvid(String myId, String toId) {
    int m1 = 0;
    int m2 = 0;

    for (int i = 0; i < myId.length; i++) {
      m1 += myId.codeUnitAt(i);
    }
    for (int i = 0; i < toId.length; i++) {
      m2 += toId.codeUnitAt(i);
    }
    String nounce = (m1 * m2).toString();
    String n = md5.convert(utf8.encode(nounce)).toString();
    String convid = n.substring(0, 8);
    print("id1 = $myId and id2 = $toId and convid = $convid");
    return convid;
  }

  // my reply
  Widget myReply(MessageModel msg, int index, Function callback) {
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
              chatProvider.selectMsg(msg.id);
            }
          }
        },
        onLongPress: () {
          if (msg.delMsg != 1) {
            if (!chatProvider.selection) chatProvider.selectMsg(msg.id);
          }
        },
        child: Container(
          margin: EdgeInsets.only(top: 10),
          width: w * .6,
          child: Column(children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 10,
                ),
                Text(myName,
                    style: TextStyle(
                        color: Colors.grey[500], fontWeight: FontWeight.bold)),
                SizedBox(
                  width: 10,
                ),
                if (msg.delMsg != 1 && msg.replyId != null && msg.replyId != -1)
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
                  child: Container(
                    padding: EdgeInsets.only(right: 5),
                    child: Text(
                      msg.delMsg == 1 ? "message removed" : msg.msg,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: msg.delMsg == 1 ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  width: 5,
                ),
                Icon(
                  msg.sent == '1' ? Icons.check : Icons.access_time,
                  color: msg.read == 1 ? Colors.green : Colors.blue,
                  size: msg.uploaded == '1' ? 18 : 14,
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

  // reply item
  Widget replyItem(int id) {
    MessageModel msg = chatProvider.getMsgWithId(id);
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
