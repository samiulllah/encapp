import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Services/chat.dart';
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:encapp/Screens/widgets/alerts.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:encapp/Providers/chat.dart';

class ChatSocketListners {
  IO.Socket socket;

  Future<void> initSoc(
      IO.Socket socket,
      Function addMessage,
      Function setTyping,
      Function mark,
      Function fetchChat,
      Function currentConvid,
      BuildContext chatContext,
      Function getDeviceId,
      Function decrypt,
      Function getKey,
      Function getConvid,
      Function deleteMsg) async {
    this.socket = socket;
    print("adding Chat listeners to socket.");

    // receive msg listener
    socket.on("receiveMessage", (data) async {
      String myId = await getDeviceId();
      String convid = currentConvid();
      Map<String, dynamic> map = jsonDecode(data.toString());
      map['uploaded'] = '1';
      map['sent'] = '1';
      if (map['to_id'] == myId) {
        MessageModel m = MessageModel.fromJson(map);
        if (convid != null) {
          if (m.convid == convid)
            m.read = 1;
          else
            m.read = 0;
        } else
          m.read = 0;
        m.loaded = "0";
        m.localUrl = "";
        DBHelper db = new DBHelper();
        await db.saveMsg(m);
        addMessage(m);
        setTyping(
            {"typing": 0, "from_id": map['from_id'], "to_id": map['to_id']});
        ChatService.lock = 0;
      }
    });

    // sent message listener
    socket.on("sent", (data) async {
      print("Received sent msg 1-1");
      String myId = await getDeviceId();
      Map<String, dynamic> map = jsonDecode(data.toString());
      map['uploaded'] = '1';
      if (map['from_id'] == myId) {
        MessageModel m = MessageModel.fromJson(map);
        DBHelper db = new DBHelper();
        print("updating sent msg");
        m.loaded = "1";
        m.uploaded = "1";
        m.sent = '1';
        await db.updateMsg1(m, map['sl_id']);
        addMessage(m);
      }
    });

    // start typing
    socket.on("typing", (data) async {
      Map<String, dynamic> map = jsonDecode(data.toString());
      print("started typing");
      setTyping(map);
    });

    // stop typing
    socket.on("notTyping", (data) async {
      print("stopped typing");
      Map<String, dynamic> map = jsonDecode(data.toString());
      setTyping(map);
    });

    // mark as read
    socket.on("markAsRead", (data) async {
      Map<String, dynamic> map = jsonDecode(data.toString());
      mark(map);
      String convid = getConvid(
          map['to_id'].toString().trim(), map['from_id'].toString().trim());
      await Future.delayed(Duration(seconds: 2));
      fetchChat(convid);
      Provider.of<ChatProvider>(OneContext().context, listen: false)
          .fetchDialogues();
    });
    // delete msg
    socket.on("msgDel", (data) async {
      Map<String, dynamic> map = jsonDecode(data.toString());
      DBHelper db = new DBHelper();
      db.deleteMsg(int.parse(map['msgId'].toString()), map['convid']);
      await Future.delayed(Duration(seconds: 1));
      if (OneContext.hasContext) {
        fetchChat(map['convid']);
        Provider.of<ChatProvider>(OneContext().context, listen: false)
            .fetchDialogues();
      }
    });
    // on ping by someone
    socket.on("replyPing", (data) async {
      // from_id would have pinged me
      Map<String, dynamic> map = jsonDecode(data.toString());
      if (OneContext.hasContext) {
        showPingAlert(OneContext().context, map['from_id'], map['from_alias']);
      }
    });
    // blocking
    socket.on("block", (data) async {
      print("block request $data");
      Map<String, dynamic> map = jsonDecode(data.toString());
      ChatProvider cp =
          Provider.of<ChatProvider>(OneContext().context, listen: false);
      UserProvider up =
          Provider.of<UserProvider>(OneContext().context, listen: false);

      if (map['block'] == "1") {
        // block the user
        up.blockContact(map['from_id'], 2);
      } else {
        // unblock it
        up.unblockUser(map['from_id'], 2);
      }
      if (ChatService.singleChatContext != null && map['from_id'] == cp.to_id) {
        if (map['block'] == "1") {
          // block the user
          cp.setBlock(2);
        } else {
          // unblock it
          cp.setBlock(0);
        }
      }
    });
  }
}
