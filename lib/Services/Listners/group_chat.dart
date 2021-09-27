import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:encapp/Models/group_message.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:encapp/Services/group_chat.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:encapp/Screens/widgets/alerts.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:encapp/Providers/chat.dart';

class GroupChatSocketListners {
  IO.Socket socket;

  Future<void> initSoc(
      IO.Socket socket,
      Function addMessage,
      Function setTyping,
      Function mark,
      Function fetchChat,
      Function getCurrentGrpId,
      BuildContext chatContext,
      Function getDeviceId,
      Function decrypt,
      Function getKey,
      Function saveMsg) async {
    print("group chat listener  init is called");
    this.socket = socket;
    // receive msg listener
    socket.on("receiveGroupMessage", (data) async {
      String currentGrpId = getCurrentGrpId();
      Map<String, dynamic> map = jsonDecode(data.toString());
      log("msg received ${map.toString()}");
      map['uploaded'] = '1';
      map['sent'] = '1';
      GroupMessageModel m = GroupMessageModel.fromJson(map);
      if (currentGrpId != null) {
        if (m.grpId == currentGrpId)
          m.read = 1;
        else
          m.read = 0;
      } else
        m.read = 0;
      m.loaded = "0";
      m.localUrl = "";
      saveMsg(m);
      addMessage(m);
      setTyping(
          {"typing": 0, "from_id": map['from_id'], "grpId": map['grpId']});
    });

    // sent message listener
    socket.on("sentGroupMessage", (data) async {
      String myId = await getDeviceId();
      Map<String, dynamic> map = jsonDecode(data.toString());
      log("msg sent received back  from id = ${map['from_id']} and myid = $myId");
      if (map['from_id'] == myId) {
        GroupMessageModel m = GroupMessageModel.fromJson(map);
        DBHelper db = new DBHelper();
        // media
        m.loaded = "1";
        m.uploaded = "1";
        m.sent = '1';
        await db.updateGroupMsg1(m, int.parse(map['sl_id']));
        addMessage(m);
        GroupChatService.lock = 0;
      }
    });

    // start typing
    socket.on("typingGroup", (data) async {
      Map<String, dynamic> map = jsonDecode(data.toString());
      print("started typing");
      setTyping(map);
    });

    // stop typing
    socket.on("notTypingGroup", (data) async {
      print("stopped typing");
      Map<String, dynamic> map = jsonDecode(data.toString());
      setTyping(map);
    });
    // delete msg
    socket.on("delGroup", (data) async {
      Map<String, dynamic> map = jsonDecode(data.toString());
      DBHelper db = new DBHelper();
      db.deleteGroupMsg(int.parse(map['id'].toString()), map['grpId']);
      await Future.delayed(Duration(seconds: 1));
      if (OneContext.hasContext) {
        fetchChat(map['grpId']);
        Provider.of<ChatProvider>(OneContext().context, listen: false)
            .fetchDialogues();
      }
    });
  }
}
