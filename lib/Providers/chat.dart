import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:encapp/Models/dialogues.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Services/Notifications/notifications.dart';
import 'package:encapp/Services/chat.dart';
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as aes;
import 'package:crypto/crypto.dart';
import 'dart:io';

import 'package:toast/toast.dart';

class ChatProvider extends ChangeNotifier {
  ChatService cs = new ChatService();
  DBHelper db = new DBHelper();
  BackgroundNotifications notifications = new BackgroundNotifications();
  List<Map<String, dynamic>> unreadMap = [];
  List<MessageModel> dialogues = [];
  List<MessageModel> msgs = [];
  List<MessageModel> favMsgs = [];
  Map allMsgs = new Map();
  String from_id, to_id;
  bool typing = false, selection = false;
  bool typingUpdated = false;
  String myName, peerName;
  String convid = null;
  int nosSelected = 0;
  MessageModel replyMsg = null;
  bool preview = false, snoozed = false;
  int block = 0;
  String myId;
  Timer t, t1;

  // init
  Future<void> initChat(
      String myId, String toId, String myName, String peerName) async {
    msgs = [];
    typingUpdated = false;
    typing = false;
    from_id = myId;
    this.myId = myId;
    this.myName = myName;
    this.peerName = peerName;
    to_id = toId;
    convid = cs.getConvid(myId, toId);
    block = await Provider.of<UserProvider>(OneContext().context, listen: false)
        .isUserBlock(toId);
    notifyListeners();
  }

  void setBlock(int val) {
    block = val;
    notifyListeners();
  }

  // get fresh convid
  String freshConvid() {
    return convid;
  }

  // set preview
  void setPreview(bool val) {
    preview = val;
    notifyListeners();
  }

  // add listeners
  Future<void> addChatListeners(IO.Socket socket) async {
    notifications.initLocal();
    await cs.initSoc(socket, addMessage, setTyping, markAsRead, fetchChat,
        convid, freshConvid);
  }

  // receive msg
  void addMessage(MessageModel m) async {
    await Future.delayed(Duration(seconds: 1));
    if (m.fromId != myId) {
      // msg i haven't sent
      if (convid == null || m.convid.trim() != convid.trim()) {
        // throw notification
        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        bool snoozed = sharedPreferences.containsKey('snooze${m.fromId}')
            ? sharedPreferences.getBool('snooze${m.fromId}')
            : false;
        if (!snoozed)
          notifications.createSimpleNotification(
              "You've new message", "Tap to view");
      } else {
        // msg i've sent
        fetchChat(convid);
      }
    } else {
      fetchChat(convid);
    }
    await Future.delayed(Duration(seconds: 1), () {
      fetchDialogues();
    });
    notifyListeners();
  }

  // init sender
  void msgSender() async {
    ChatService chatService = new ChatService();
    String myid = await chatService.getDeviceId();
    if (t != null) t.cancel();
    t = Timer.periodic(Duration(seconds: 3), (timer) async {
      print("Running  single chat message  sender.........");
      await chatService.retryUnsent(myid);
    });
    t1 = Timer.periodic(Duration(seconds: 12), (timer) {
      if (cs.socket == null || cs.socket.disconnected) {
        ChatService.lock = 0;
      }
    });
  }

  // send message
  Future<void> sendMsg(MessageModel m) async {
    await cs.sendMessage(m);
    cancelReply();
  }

  // send to local
  Future<void> sendToLocal(MessageModel m) async {
    await cs.sentToLocal(m);
    cancelReply();
    addMessage(m);
  }

  // send media msg
  Future<void> sendMediaMsg(
      String path, DateTime dt, String type, String msg) async {
    MessageModel m = new MessageModel(
        convid: convid,
        fromId: from_id,
        toId: to_id,
        read: 0,
        fromAlias: myName,
        toAlias: peerName,
        msg: msg,
        favourite: 0,
        datetime: DateTime.now(),
        delMsg: 0,
        msgType: type,
        localUrl: path,
        replyId: -1);
    m.datetime = DateTime.now();
    await cs.sentToLocal(m);
  }

  // share media msg
  Future<void> shareMediaMsg(MessageModel m) async {
    DBHelper db = new DBHelper();
    await db.saveMsg(m);
  }

  // update msg by
  Future<void> updateMsg(MessageModel msg) async {
    DBHelper db = new DBHelper();
    String key = cs.getKey(
        msg.toId.toString().trim(), msg.fromId.toString().trim()); // key
    msg.msg = cs.encrypt(msg.msg, key); // encrypt
    await db.updateMsg(msg);
  }

  DateTime dt = DateTime.now();
  // fetch dialogues
  Future<void> fetchDialogues() async {
    unreadMap = [];
    List<MessageModel> dl = [];
    // allMsgs = new Map();
    dl.add(new MessageModel(
        fromId: '1',
        toId: '2',
        fromAlias: 'Sami',
        toAlias: 'Qadir',
        msgType: '0',
        convid: '1',
        datetime: DateTime.now(),
        replyId: -1,
        favourite: 1,
        localUrl: '',
        msg: 'Hi! Buddy',
        read: 0));
    dl.add(new MessageModel(
        fromId: '1',
        toId: '2',
        fromAlias: 'Tom',
        toAlias: 'Jerry',
        msgType: '0',
        convid: '1',
        datetime: DateTime.now(),
        replyId: -1,
        favourite: 1,
        localUrl: '',
        msg: 'Fine',
        read: 0));
    dl.add(new MessageModel(
        fromId: '1',
        toId: '2',
        fromAlias: 'Andreas',
        toAlias: 'San',
        msgType: '0',
        convid: '1',
        datetime: DateTime.now(),
        replyId: -1,
        favourite: 1,
        localUrl: '',
        msg: 'In the bar',
        read: 0));
    // bulk fetch all chats
    for (int i = 0; i < dl.length; i++) {
      unreadMap.add({dl[i].convid: 2});
    }
    dl.sort(
        (MessageModel a, MessageModel b) => a.datetime.compareTo(b.datetime));
    dl = dl.reversed.toList();
    dialogues = dl;
    notifyListeners();
  }

  // fetch chat
  Future<void> fetchChat(String convid) async {
    print("Fetching chat 1-1 ......");
    List<MessageModel> m = [];
    m = await db.getChat(convid.toString());
    for (int i = 0; i < m.length; i++) {
      String k = cs.getKey(
          m[i].toId.toString().trim(), m[i].fromId.toString().trim()); // key
      m[i].msg = cs.decrypt(m[i].msg, k); // decrypt
    }
    m.sort(
        (MessageModel a, MessageModel b) => a.datetime.compareTo(b.datetime));
    // m = m.reversed.toList();
    allMsgs[convid] = m;
    notifyListeners();
  }

  // fetch favourite msgs
  Future<void> fetchFavouriteMsgs() async {
    favMsgs = [];
    List<MessageModel> m = [];
    m = await db.getAllFavourite(convid.toString());
    m.sort(
        (MessageModel a, MessageModel b) => a.datetime.compareTo(b.datetime));
    favMsgs = m;
    notifyListeners();
  }

  // dispose socket connection
  void disposeSocket() {
    emitStopTyping();
    typingUpdated = false;
    typing = false;
    convid = null;
    from_id = null;
    to_id = null;
  }

  // emit typing
  Future<void> emitTyping() async {
    if (!typingUpdated) {
      Map map = {'to_id': to_id, 'from_id': from_id, 'typing': 1};
      await cs.startTyping(map);
      typingUpdated = true;
    }
  }

  // emit stop typing
  Future<void> emitStopTyping() async {
    if (typingUpdated) {
      Map map = {'to_id': to_id, 'from_id': from_id, 'typing': 0};
      await cs.stopTyping(map);
      typingUpdated = false;
    }
  }

  // emit ping request
  Future<void> emitPingRequest(
      String toId, String fromId, String fromAlias) async {
    Map map = {'to_id': toId, 'from_id': fromId, 'from_alias': fromAlias};
    await cs.emitPingRequest(map);
  }

  // update typing
  void setTyping(Map map) {
    String cn = cs.getConvid(map['to_id'], map['from_id']);
    if (convid == cn) {
      if (map['typing'] == 0) {
        typing = false;
      } else if (map['typing'] == 1) {
        typing = true;
      }
    }
    notifyListeners();
  }

  // mark chat as read
  Future<void> markAsRead(Map map) async {
    await cs.markChatAsRead(map);
  }

  // emit chat reading
  Future<void> emitChatRead(Map map, String convid, String otherId) async {
    await cs.emitChatRead(map, convid, otherId);
  }

  // get unread for a chat
  Future<int> getUnread(String convid) async {
    ChatService cs = new ChatService();
    return await cs.getUnread(convid);
  }

  // copy selected
  void copySelected(BuildContext context) async {
    String txt = null;
    for (int i = 0; i < allMsgs[convid].length; i++) {
      if (allMsgs[convid][i].selected) {
        if (txt == null) txt = '';
        txt += allMsgs[convid][i].msg + "\n";
      }
    }
    print("copying $txt");
    Clipboard.setData(ClipboardData(text: txt));
    unselectAll();
    Toast.show('Copied!', context);
  }

  // get selected text
  Future<String> getSelected() async {
    String txt = null;
    for (int i = 0; i < allMsgs[convid].length; i++) {
      if (allMsgs[convid][i].selected) {
        if (txt == null) txt = '';
        txt += allMsgs[convid][i].msg + "\n";
      }
    }
    unselectAll();
    return txt;
  }

  // delete selected
  Future<void> deleteSelected(BuildContext context) async {
    for (int i = 0; i < allMsgs[convid].length; i++) {
      if (allMsgs[convid][i].selected) {
        await cs.deleteMsg(allMsgs[convid][i].id, allMsgs[convid][i].convid,
            from_id, to_id, allMsgs[convid][i].fromId == from_id);
      }
    }
    unselectAll();
    fetchChat(convid);
    fetchDialogues();
    Toast.show('Deleted!', context);
  }

  // delete chat history
  Future<void> deleteChatHistory() async {
    await cs.deleteChatHistory(convid);
    fetchChat(convid);
    fetchDialogues();
  }

  // delete conversation
  Future<void> deleteConversation({String id}) async {
    await cs.deleteConversation(id != null ? id : convid);
    await Future.delayed(Duration(seconds: 3), () {
      fetchDialogues();
    });
  }

  // delete conversation
  Future<void> addMsgToFavourite(BuildContext context) async {
    for (int i = 0; i < allMsgs[convid].length; i++) {
      if (allMsgs[convid][i].selected) {
        await cs.addMsgToFavourity(allMsgs[convid][i].id);
      }
    }
    unselectAll();
    fetchChat(convid);
    fetchDialogues();
    Toast.show('Added!', context);
  }

  // select message
  void selectMsg(int id) {
    for (int i = 0; i < allMsgs[convid].length; i++) {
      if (allMsgs[convid][i].id == id) {
        allMsgs[convid][i].selected = !allMsgs[convid][i].selected;
      }
    }
    int nos = noOfSelected();
    nosSelected = nos;
    if (nos > 0) {
      selection = true;
    } else {
      selection = false;
    }
    notifyListeners();
  }

  // get total msgs selected
  int noOfSelected() {
    int nos = 0;
    for (int i = 0; i < allMsgs[convid].length; i++) {
      if (allMsgs[convid][i].selected) {
        nos++;
      }
    }
    return nos;
  }

  // unselect all
  void unselectAll() {
    if (allMsgs[convid] != null) {
      for (int i = 0; i < allMsgs[convid].length; i++) {
        allMsgs[convid][i].selected = false;
      }
      selection = false;
      nosSelected = 0;
      notifyListeners();
    }
  }

  // reply
  void reply() {
    if (nosSelected == 1) {
      for (int i = 0; i < allMsgs[convid].length; i++) {
        if (allMsgs[convid][i].selected) {
          replyMsg = allMsgs[convid][i];
        }
      }
    }
    notifyListeners();
  }

  // cancel reply
  void cancelReply() {
    replyMsg = null;
    notifyListeners();
  }

  // get msg with id
  MessageModel getMsgWithId(int id) {
    List<int> ids = [];
    MessageModel messageModel = null;
    if (allMsgs[convid] == null) {
      return null;
    }
    for (MessageModel msg in allMsgs[convid]) {
      ids.add(msg.id);
      if (id == msg.id) {
        messageModel = msg;
      }
    }
    return messageModel;
  }

  // find msg index by id
  int getIndex(int id) {
    int index = 0;
    for (int i = 0; i < allMsgs[convid].length; i++) {
      if (allMsgs[convid][i].id == id) {
        index = i;
        break;
      }
    }
    return index;
  }

  // delete all conversations
  Future<void> deleteAllConversations() async {
    for (MessageModel d in dialogues) {
      await cs.deleteConversation(d.convid);
    }
  }
}
