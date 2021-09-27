import 'dart:async';
import 'dart:developer';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Providers/group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:encapp/Models/dialogues.dart';
import 'package:encapp/Models/group_message.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Services/Notifications/notifications.dart';
import 'package:encapp/Services/chat.dart';
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:encapp/Services/group_chat.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as aes;
import 'package:crypto/crypto.dart';
import 'dart:io';

import 'package:toast/toast.dart';

class GroupChatProvider extends ChangeNotifier {
  GroupChatService cs = new GroupChatService();
  DBHelper db = new DBHelper();
  BackgroundNotifications notifications = new BackgroundNotifications();
  GroupModel gm = null;
  List<Map<String, dynamic>> unreadMap = [];
  List<GroupDialogueModel> dialogues = [];
  List<GroupMessageModel> msgs = [];
  Map allMsgs = new Map();
  List<GroupMessageModel> favMsgs = [];
  String from_id;
  bool typing = false, selection = false;
  bool typingUpdated = false;
  String grpId = null, myName;
  int nosSelected = 0;
  List<String> ppls = [];
  GroupMessageModel replyMsg = null;
  String myId;
  Timer t, t1;

  // init
  void initChat(String myId, String grpId, List<String> ppls, GroupModel gm,
      String myName) {
    msgs = [];
    typingUpdated = false;
    typing = false;
    from_id = myId;
    this.myId = myId;
    this.grpId = grpId;
    ppls.removeWhere((element) => element == myId);
    this.ppls = ppls;
    this.gm = gm;
    this.myName = myName;
  }

  // get fresh convid
  String freshGrpId() {
    return grpId;
  }

  // add listners
  Future<void> addChatListners(IO.Socket socket) async {
    notifications.initLocal();
    await cs.initSoc(
        socket, addMessage, setTyping, markAsRead, fetchChat, freshGrpId);
  }

  // receive msg
  void addMessage(GroupMessageModel m) async {
    if (m.fromId != myId) {
      if (grpId == null || m.grpId != grpId) {
        // throw notification
        if (from_id == null || m.fromId.trim() != from_id.trim()) {
          print("alerting....");
          notifications.createSimpleNotification(
              "You've new group message", "Tap to view");
        }
      } else {
        fetchChat(grpId);
      }
    } else {
      fetchChat(grpId);
    }
    await Provider.of<GroupProvider>(OneContext().context, listen: false)
        .getAllGroups();
    notifyListeners();
  }

  // send message
  void sendMsg(GroupMessageModel m) {
    cs.sendMessage(m);
  }

  // send to local
  Future<void> sendToLocal(GroupMessageModel m) async {
    await cs.sentToLocal(m);
    cancelReply();
    addMessage(m);
  }

  // init sender
  void msgSender() async {
    GroupChatService chatService = new GroupChatService();
    String myid = await chatService.getDeviceId();
    if (t != null) t.cancel();
    t = Timer.periodic(Duration(seconds: 3), (timer) async {
      print("Running  group message sender.........");
      await chatService.retryUnsent(myid);
    });
    t1 = Timer.periodic(Duration(seconds: 12), (timer) {
      if (cs.socket == null || cs.socket.disconnected)
        GroupChatService.lock = 0;
    });
  }

  // send media msg
  Future<void> sendMediaMsg(
      String path, DateTime dt, String type, String msg) async {
    List<ToPpl> ppls = [];
    for (Members m in gm.members) {
      ppls.add(new ToPpl(id: m.id, alias: m.alias));
    }
    GroupMessageModel m = new GroupMessageModel(
        grpId: grpId,
        fromId: from_id,
        read: 0,
        fromAlias: myName,
        msg: msg,
        favourite: 0,
        msgType: type,
        localUrl: path,
        replyId: -1,
        toPpl: ppls);
    m.datetime = DateTime.now();
    await cs.sentToLocal(m);
  }

  // update msg by
  Future<void> updateMsg(GroupMessageModel msg) async {
    DBHelper db = new DBHelper();
    String key = cs.getKey(msg.grpId); // key
    msg.msg = cs.encrypt(msg.msg, key); //
    await db.updateGroupMsg(msg);
  }

  // fetch dialogues
  Future<void> fetchDialogues() async {
    unreadMap = [];
    List<GroupDialogueModel> dl = [];
    dl = await cs.getDialogues();
    for (GroupDialogueModel d in dl) {
      int noUnread = await getUnread(d.grpId);
      if (noUnread > 0) {
        unreadMap.add({d.grpId: noUnread});
      }
    }
    dl.sort((GroupDialogueModel a, GroupDialogueModel b) =>
        a.datetime.compareTo(b.datetime));
    dl = dl.reversed.toList();
    dialogues = dl;
    notifyListeners();
  }

  Future<void> bulkFetch(List<GroupModel> grps) async {
    print('Starting bulk fetching....');
    for (GroupModel gp in grps) {
      if (gp.grpId != null) {
        //print("fetching for ${gp.grpId}");
        List<GroupMessageModel> m = [];
        m = await cs.getChat(gp.grpId);
        m.sort((GroupMessageModel a, GroupMessageModel b) =>
            a.datetime.compareTo(b.datetime));
        //print("Fetched ${m.length} no's msgs for ${gp.grpId}");
        allMsgs[gp.grpId] = m;
      }
    }
    notifyListeners();
  }

  // fetch chat
  Future<void> fetchChat(String grpId) async {
    print('FETCHING GROUP CHAT');
    Map map = new Map();
    map = allMsgs;
    List<GroupMessageModel> m = [];
    m = await cs.getChat(grpId);
    m.sort((GroupMessageModel a, GroupMessageModel b) =>
        a.datetime.compareTo(b.datetime));
    allMsgs = null;
    map.remove(grpId);
    map[grpId] = m;
    allMsgs = map;
    m = allMsgs[grpId] as List;
    notifyListeners();
  }

  // fetch favourite msgs
  Future<void> fetchFavouriteMsgs() async {
    favMsgs = [];
    List<GroupMessageModel> m = [];
    m = await cs.getAllFavourite(grpId);
    m.sort((GroupMessageModel a, GroupMessageModel b) =>
        a.datetime.compareTo(b.datetime));
    favMsgs = m;
    notifyListeners();
  }

  // dispose socket connection
  void disposeSocket() {
    emitStopTyping();
    typingUpdated = false;
    typing = false;
    grpId = null;
    from_id = null;
  }

  // emit typing
  Future<void> emitTyping() async {
    if (!typingUpdated) {
      Map map = {
        'grpId': grpId,
        'from_id': from_id,
        'typing': 1,
        'to_ids': ppls
      };
      await cs.startTyping(map);
      typingUpdated = true;
    }
  }

  // emit stop typing
  Future<void> emitStopTyping() async {
    if (typingUpdated) {
      Map map = {
        'grpId': grpId,
        'from_id': from_id,
        'typing': 0,
        'to_ids': ppls
      };
      await cs.stopTyping(map);
      typingUpdated = false;
    }
  }

  // update typing
  void setTyping(Map map) {
    if (map['grpId'] == grpId) {
      if (map['typing'] == 0) {
        typing = false;
      } else if (map['typing'] == 1) {
        typing = true;
      }
    }
    notifyListeners();
  }

  // mark chat as read
  Future<void> markAsRead() async {
    await cs.markChatAsRead(grpId);
  }

  // get unread for a chat
  Future<int> getUnread(String grpId) async {
    GroupChatService cs = new GroupChatService();
    return await cs.getUnread(grpId);
  }

  // copy selected
  void copySelected(BuildContext context) async {
    String txt = null;
    for (int i = 0; i < allMsgs[grpId].length; i++) {
      if (allMsgs[grpId][i].selected) {
        if (txt == null) txt = '';
        txt += allMsgs[grpId][i].msg + "\n";
      }
    }
    print("copying $txt");
    Clipboard.setData(ClipboardData(text: txt));
    unselectAll();
    Toast.show('Copied!', context);
  }

  // delete selected
  Future<void> deleteSelected(BuildContext context) async {
    for (int i = 0; i < allMsgs[grpId].length; i++) {
      if (allMsgs[grpId][i].selected) {
        List<String> ppls = [];
        for (ToPpl p in allMsgs[grpId][i].toPpl) {
          if (p.id != from_id) {
            ppls.add(p.id);
          }
        }
        await cs.deleteMsg(
            int.parse(allMsgs[grpId][i].id),
            allMsgs[grpId][i].grpId,
            from_id,
            allMsgs[grpId][i].fromId == from_id,
            ppls);
      }
    }
    unselectAll();
    fetchChat(grpId);
    fetchDialogues();
    Toast.show('Deleted!', context);
  }

  // delete chat history
  Future<void> deleteChatHistory() async {
    await cs.deleteChatHistory(grpId);
    fetchChat(grpId);
    fetchDialogues();
  }

  // delete conversation
  Future<void> deleteConversation({String id}) async {
    await cs.deleteConversation(id != null ? id : grpId);
    await Future.delayed(Duration(seconds: 2), () {
      fetchDialogues();
    });
  }

  // delete conversation
  Future<void> addMsgToFavourite(BuildContext context) async {
    for (int i = 0; i < allMsgs[grpId].length; i++) {
      if (allMsgs[grpId][i].selected) {
        await cs.addMsgToFavourity(allMsgs[grpId][i].id);
      }
    }
    unselectAll();
    fetchChat(grpId);
    fetchDialogues();
    Toast.show('Added!', context);
  }

  // select message
  void selectMsg(int id) {
    for (int i = 0; i < allMsgs[grpId].length; i++) {
      if (allMsgs[grpId][i].id == id.toString()) {
        print("yes");
        allMsgs[grpId][i].selected = !allMsgs[grpId][i].selected;
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
    for (int i = 0; i < allMsgs[grpId].length; i++) {
      if (allMsgs[grpId][i].selected) {
        nos++;
      }
    }
    return nos;
  }

  // unselect all
  void unselectAll() {
    for (int i = 0; i < allMsgs[grpId].length; i++) {
      allMsgs[grpId][i].selected = false;
    }
    selection = false;
    nosSelected = 0;
    replyMsg = null;
    notifyListeners();
  }

  // reply
  void reply() {
    if (nosSelected == 1) {
      for (int i = 0; i < allMsgs[grpId].length; i++) {
        if (allMsgs[grpId][i].selected) {
          replyMsg = allMsgs[grpId][i];
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
  GroupMessageModel getMsgWithId(int id) {
    GroupMessageModel messageModel = null;
    for (GroupMessageModel msg in allMsgs[grpId]) {
      if (id.toString() == msg.id) {
        messageModel = msg;
      }
    }
    return messageModel;
  }

  // find msg index by id
  int getIndex(int id) {
    int index = 0;
    for (int i = 0; i < allMsgs[grpId].length; i++) {
      if (allMsgs[grpId][i].id == id.toString()) {
        index = i;
        break;
      }
    }
    return index;
  }

  // delete all conversations
  Future<void> deleteAllConversations() async {
    await fetchDialogues();
    for (GroupDialogueModel d in dialogues) {
      print("deleting ${d.grpId}");
      await cs.deleteConversation(d.grpId);
    }
    return;
  }
}
