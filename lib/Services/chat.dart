import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Screens/widgets/alerts.dart';
import 'package:encapp/Services/Listners/chat.dart';
import 'package:one_context/one_context.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as aes;
import 'package:crypto/crypto.dart';
import 'dart:io';

import 'database/DBHelper.dart';

class ChatService {
  IO.Socket socket;
  ChatSocketListners chatSocketListners = new ChatSocketListners();
  static BuildContext chatContext = null;
  static BuildContext singleChatContext = null;
  static int lock = 0;
  UserProvider up;

  // init soc
  Future<void> initSoc(
      IO.Socket socket,
      Function addMessage,
      Function setTyping,
      Function mark,
      Function fetchChat,
      String convid,
      Function currentConvid) async {
    up = Provider.of<UserProvider>(OneContext().context, listen: false);
    print("chat service init is called");
    // get socket
    this.socket = socket;
    // attach listeners
    await chatSocketListners.initSoc(
        socket,
        addMessage,
        setTyping,
        mark,
        fetchChat,
        currentConvid,
        chatContext,
        getDeviceId,
        decrypt,
        getKey,
        getConvid,
        deleteMsg);
  }

  // send message
  Future<bool> sendMessage(MessageModel md) async {
    if (up.checkConnection())
      socket.emit('sendMessage', jsonEncode(md.toJson()));
  }

  // retry unsentMsgs
  Future<void> retryUnsent(String myId) async {
    print('LOCKED');
    try {
      if (lock == 1) return;
      lock = 1;
      print('UNLOCKED');
      up = Provider.of<UserProvider>(OneContext().context, listen: false);
      ChatProvider chatProvider =
          Provider.of<ChatProvider>(OneContext().context, listen: false);
      // checking socket connection
      if (up.us.socket == null || up.us.socket.disconnected) {
        print("Connecting to socket....");
        await up.initSocket();
        if (up.us.socket == null || up.us.socket.disconnected) {
          print("yes socket still disconnected ${up.us.socket.connected}");
          return;
        }
      }
      DBHelper db = new DBHelper();
      List<MessageModel> dialogues = await db.getDialogues();
      for (MessageModel m in dialogues) {
        List<MessageModel> msgs = await db.getChat(m.convid);
        for (MessageModel msg in msgs) {
          if (msg.msgType == '0' &&
              msg.delMsg == 0 &&
              msg.fromId.trim() == myId.trim() &&
              msg.sent != "1") {
            print("y1");
            // text msg
            await chatProvider.sendMsg(msg);
          } else {
            print("y2");
            // media msg
            if (msg.uploaded == '1' &&
                msg.sent != '1' &&
                msg.delMsg == 0 &&
                msg.fromId.trim() == myId.trim()) {
              print("y4");
              // uploaded just send
              await chatProvider.sendMsg(msg);
            } else if (msg.uploaded == '0' &&
                msg.sent != '1' &&
                msg.delMsg == 0 &&
                chatProvider.convid != msg.convid &&
                msg.fromId.trim() == myId.trim()) {
              print("y5");
              // upload then send
              msg = await upload(msg);
              if (msg.url != null && msg.url.length > 5) {
                await chatProvider.sendMsg(msg);
              } else {
                msg.url = '';
              }
            }
          }
        }
      }
      lock = 0;
    } catch (e) {
      lock = 0;
      print("Error retrying msg $e");
    }
  }

  // upload and send msg
  upload(MessageModel msg) async {
    String url = await uploadFile(msg.localUrl);
    msg.url = url;
    msg.uploaded = "1";
    msg.loaded = "1";
    return msg;
  }

  uploadFile(String path) async {
    String baseUrl = 'http://newmatrix.global';
    Response response;

    Dio dio = new Dio();
    String uploadurl = "$baseUrl/sendImage.php";
    FormData formdata = FormData.fromMap({
      "file": await MultipartFile.fromFile(path, filename: basename(path)),
    });
    try {
      response = await dio.post(
        uploadurl,
        data: formdata,
        onSendProgress: (int sent, int total) {
          String percentage = (sent / total * 100).toStringAsFixed(2);
        },
      );
      if (response.statusCode == 200) {
        print("upload response = ${response.data}");
        Map map = jsonDecode(response.data.toString());
        if (map['success'] == "1") {
          return map['url'];
        } else {
          return null;
        }
      } else {
        print("Error during connection to server.");
        return null;
      }
    } catch (e) {
      print("Error uploading file $e");
      return null;
    }
  }

  // send to  local
  Future<void> sentToLocal(MessageModel m) async {
    DBHelper dbHelper = new DBHelper();
    String k = getKey(m.fromId.trim(), m.toId.trim());
    m.msg = encrypt(m.msg, k);
    await dbHelper.saveMsg(m);
  }

  // emit typing
  Future<void> startTyping(Map map) async {}

  //emit stop typing
  Future<void> stopTyping(Map map) async {}

  //emit ping request
  Future<void> emitPingRequest(Map map) async {}

  // aes encrypt msg
  String encrypt(String msg, String sharedKey) {
    final key = aes.Key.fromUtf8(sharedKey);
    final iv = aes.IV.fromLength(16);

    final encrypter = aes.Encrypter(aes.AES(key));

    final encrypted = encrypter.encrypt(msg, iv: iv);
    return encrypted.base64;
  }

  // aes decrypt msg
  String decrypt(String msg, String sharedKey) {
    final key = aes.Key.fromUtf8(sharedKey);
    final iv = aes.IV.fromLength(16);

    final encrypter = aes.Encrypter(aes.AES(key));
    final decrypted = encrypter.decrypt64(msg, iv: iv);
    return decrypted;
  }

  // get cid
  Future<String> getDeviceId() async {
    String deviceIdentifier;
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      deviceIdentifier = androidInfo.androidId;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      deviceIdentifier = iosInfo.identifierForVendor;
    }
    deviceIdentifier = deviceIdentifier.substring(0, 8).toUpperCase();
    return deviceIdentifier;
  }

  // get key
  String getKey(String myId, String toId) {
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
    return n;
  }

  // read chat
  Future<void> markChatAsRead(Map map) async {
    String convid = getConvid(
        map['to_id'].toString().trim(), map['from_id'].toString().trim());
    DBHelper db = new DBHelper();
    db.readAll(convid);
  }

  // emit chat read
  Future<void> emitChatRead(Map map, String convid, String otherId) async {
    readOtherMsgInMyCopy(convid, otherId);
    if (up.checkConnection()) socket.emit('readChat', jsonEncode(map));
  }

  void readOtherMsgInMyCopy(String convid, String otherId) {
    DBHelper db = new DBHelper();
    db.readOthers(convid, otherId);
  }

  //get unread
  Future<int> getUnread(String convid) async {
    DBHelper db = new DBHelper();
    return await db.getNoUnread(convid);
  }

  //delete msg by id
  Future<int> deleteMsg(
      int id, String convid, String myId, String toId, bool my) async {
    DBHelper db = new DBHelper();
    if (my) if (up.checkConnection())
      socket.emit(
          'delMsg',
          jsonEncode(
              {'from_id': myId, 'to_id': toId, 'msgId': id, 'convid': convid}));
    return await db.deleteMsg(id, convid);
  }

  // delete chat history
  Future<int> deleteChatHistory(String convid) async {
    DBHelper db = new DBHelper();
    return await db.deleteAllMsgsOfChat(convid);
  }

  // delete conversation
  Future<int> deleteConversation(String convid) async {
    DBHelper db = new DBHelper();
    int i = await db.deleteConversation(convid);
    return i;
  }

  // mark msg as favourite
  Future<void> addMsgToFavourity(int id) async {
    DBHelper db = new DBHelper();
    return await db.addMsgToFavourite(id);
  }

  // get convid
  String getConvid(String myId, String toId) {
    String n1 = md5.convert(utf8.encode(myId)).toString();
    String n2 = md5.convert(utf8.encode(toId)).toString();

    int m1 = 0;
    int m2 = 0;

    for (int i = 0; i < n1.length; i++) {
      m1 += n1.codeUnitAt(i);
    }
    for (int i = 0; i < n2.length; i++) {
      m2 += n2.codeUnitAt(i);
    }
    String nounce = (m1 * m2).toString();

    String n = md5.convert(utf8.encode(nounce)).toString();
    String convid = n.substring(0, 8) + n.substring(8, 12);
    return convid;
  }

  // do background deletion
  Future<void> backgroundDeletion() async {
    String text;
    try {
      final File file =
          File('/data/user/0/com.ciphermatrix.matrix/files/delMsg.txt');
      if (file.existsSync()) {
        text = await file.readAsString();
        List<String> jsons = text.split('>');
        if (text.length > 5) {
          String convid = null;
          for (String e in jsons) {
            Map map = jsonDecode(e);
            // terminated
            DBHelper db = new DBHelper();
            db.deleteMsg(int.parse(map['msgId'].toString()), map['convid']);
            convid = map['convid'];
          }
          if (ChatService.singleChatContext != null && convid != null) {
            await Provider.of<ChatProvider>(ChatService.singleChatContext,
                    listen: false)
                .fetchDialogues();
            await Provider.of<ChatProvider>(ChatService.singleChatContext,
                    listen: false)
                .fetchChat(convid);
          }
          file.writeAsString("");
        }
      }
    } catch (e) {
      print("Error inserting deletion receipts  $e");
    }
  }

  // background blocking
  Future<void> backgroundBlocking() async {
    print('running background blocking....');
    String text;
    try {
      final File file =
          File('/data/user/0/com.ciphermatrix.matrix/files/block.txt');
      if (file.existsSync()) {
        text = await file.readAsString();
        List<String> jsons = text.split('>');
        if (text.length > 5) {
          DBHelper db = new DBHelper();
          for (String e in jsons) {
            Map map = jsonDecode(e);
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
          }
          file.writeAsString("");
        }
      }
    } catch (e) {
      print("Error terminated blocking $e");
    }
  }

  // background alias update
  Future<void> backgroundAliasUpdate() async {
    print('running background alias update....');
    String text;
    try {
      final File file =
          File('/data/user/0/com.ciphermatrix.matrix/files/alias.txt');
      if (file.existsSync()) {
        text = await file.readAsString();
        List<String> jsons = text.split('>');
        if (text.length > 5) {
          DBHelper db = new DBHelper();
          for (String e in jsons) {
            Map map = jsonDecode(e);
            db.updateAlias(map);
          }
          file.writeAsString("");
        }
      }
    } catch (e) {
      print("Error terminated blocking $e");
    }
  }

  // retry unsentMsgs
  Future<void> retryUnsentBackground() async {
    String myId = await getDeviceId();
    DBHelper db = new DBHelper();
    List<MessageModel> dialogues = await db.getDialogues();
    for (MessageModel m in dialogues) {
      List<MessageModel> msgs = await db.getChat(m.convid);
      for (MessageModel msg in msgs) {
        if (msg.msgType == '0' && msg.delMsg == '0') {
          // text msg
          if (msg.fromId == myId && msg.sent != "1") {
            // deliver via http
            sendHttpMsg(msg);
          }
        } else {
          // deliver via http
          if (msg.uploaded == '1' && msg.sent != '1' && msg.delMsg == '0') {
            sendHttpMsg(msg);
          }
        }
      }
    }
  }

  // delivery via http
  Future<int> sendHttpMsg(MessageModel m) async {
    try {
      Map payload = m.toJson();
      payload['chatType'] = '1';
      var url = Uri.parse(
          'http://newmatrix.global:3000/retryMessage?payload=${payload.toString()}');
      print('retrying $url');
      var response = await http.get(url);
      String res = response.body.toString();
      print("MESSAGE STATUS : $res");
      if (res == '1') {
        // update msg status to sent locally
        DBHelper dbHelper = new DBHelper();
        m.sent = '1';
        dbHelper.updateMsg(m);
      }
    } catch (e) {
      print("error sending background msg $e");
    }
  }
}
