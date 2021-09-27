import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:encapp/Models/dialogues.dart';
import 'package:encapp/Models/group_message.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/group_chat.dart';
import 'package:encapp/Providers/home.dart';
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
import 'package:sqflite/sqflite.dart';
import 'dart:io';

import 'Listners/group_chat.dart';
import 'database/DBHelper.dart';

class GroupChatService {
  IO.Socket socket;
  static BuildContext groupChatContext = null;
  static BuildContext singleChatContext = null;
  UserProvider up;
  static int lock = 0;
  GroupChatSocketListners groupChatSocketListners =
      new GroupChatSocketListners();

  // init soc
  Future<void> initSoc(
      IO.Socket socket,
      Function addMessage,
      Function setTyping,
      Function mark,
      Function fetchChat,
      Function freshGrpId) async {
    print("group chat service init is called");
    up = Provider.of<UserProvider>(OneContext().context, listen: false);
    // get socket
    this.socket = socket;
    // attach listeners
    await groupChatSocketListners.initSoc(
        this.socket,
        addMessage,
        setTyping,
        mark,
        fetchChat,
        freshGrpId,
        groupChatContext,
        getDeviceId,
        decrypt,
        getKey,
        saveMsg);
  }

  // send message
  Future<bool> sendMessage(GroupMessageModel gm) async {
    String key = getKey(gm.grpId);
    gm.msg = encrypt(gm.msg, key);
    Map m = gm.toJson();
    List<String> toIds = [];
    for (int i = 0; i < gm.toPpl.length; i++) {
      if (gm.toPpl[i].id != gm.fromId) {
        toIds.add(gm.toPpl[i].id);
      }
    }
    m['to_ids'] = toIds;

    if (up.checkConnection()) socket.emit('sendGroupMessage', jsonEncode(m));
  }

  // send to  local
  Future<void> sentToLocal(GroupMessageModel gm) async {
    String k = getKey(gm.grpId);
    gm.msg = encrypt(gm.msg, k);
    // save locally
    saveMsg(gm);
  }

  // save msg
  Future<int> saveMsg(GroupMessageModel gm) async {
    print("local url = ${gm.localUrl}");
    DBHelper dbHelper = new DBHelper();
    int result = 0;
    Database db = await dbHelper.db;
    result = await db.insert('GroupMessages', gm.toJsonLocal());
    result = await saveDialogue(GroupDialogueModel.fromGrpMessage(gm));
    return result;
  }

  Future<void> retryUnsent(String myId) async {
    try {
      if (lock == 1) return;
      lock = 1;
      up = Provider.of<UserProvider>(OneContext().context, listen: false);
      // checking socket connection
      if (up.us.socket == null || up.us.socket.disconnected) {
        print("Connecting to socket....");
        await up.initSocket();
        if (up.us.socket == null || up.us.socket.disconnected) {
          print("yes socket still disconnected ${up.us.socket.connected}");
          return;
        }
      }
      List<GroupDialogueModel> dialogues = await getDialogues();
      for (GroupDialogueModel m in dialogues) {
        List<GroupMessageModel> msgs = await getChat(m.grpId);
        for (GroupMessageModel msg in msgs) {
          if (msg.msgType.trim() == '0' && msg.delMsg == 0) {
            // text msg
            if (msg.fromId == myId && msg.sent != "1") {
              await Provider.of<GroupChatProvider>(OneContext().context,
                      listen: false)
                  .sendMsg(msg);
            }
          } else {
            // media msg
            if (msg.uploaded == '1' &&
                msg.sent != '1' &&
                msg.delMsg == 0 &&
                msg.fromId == myId) {
              // uploaded so just send
              await Provider.of<GroupChatProvider>(OneContext().context,
                      listen: false)
                  .sendMsg(msg);
            } else if (msg.uploaded == '0' &&
                msg.sent != '1' &&
                msg.delMsg == 0 &&
                Provider.of<GroupChatProvider>(OneContext().context,
                            listen: false)
                        .grpId !=
                    msg.grpId &&
                msg.fromId == myId) {
              // upload then send
              msg = await upload(msg);
              if (msg.url != null && msg.url.length > 5) {
                await Provider.of<GroupChatProvider>(OneContext().context,
                        listen: false)
                    .sendMsg(msg);
              } else {
                msg.url = '';
              }
            }
          }
        }
      }
      lock = 0;
    } catch (e) {
      print("Error retrying gorup msg $e");
      lock = 0;
    }
  }

  upload(GroupMessageModel msg) async {
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

  String getKey(String id) {
    return md5.convert(utf8.encode(id)).toString();
  }

  // emit typing
  Future<void> startTyping(Map map) async {
    if (up.checkConnection()) socket.emit('startTypingGroup', jsonEncode(map));
  }

  //emit stop typing
  Future<void> stopTyping(Map map) async {
    if (up.checkConnection()) socket.emit('endTypingGroup', jsonEncode(map));
  }

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

  // read chat
  Future<void> markChatAsRead(String grpId) async {
    DBHelper dbHelper = new DBHelper();
    Database db = await dbHelper.db;
    await db
        .rawQuery("UPDATE GroupMessages SET read=1 where grpId=\'${grpId}\'");
  }

  //get unread
  Future<int> getUnread(String grpId) async {
    DBHelper dbHelper = new DBHelper();
    String myId = await getDeviceId();
    int unread = 0;
    Database db = await dbHelper.db;
    List<Map> list = await db.rawQuery(
        "SELECT * FROM GroupMessages where grpId=\'${grpId}\' AND  read=0 AND NOT from_id=\'$myId\'");
    unread = list.length;
    return unread;
  }

  //delete msg by id
  Future<int> deleteMsg(
      int id, String convid, String myId, bool my, List<String> toIds) async {
    DBHelper db = new DBHelper();
    if (my) if (up.checkConnection())
      socket.emit(
          'groupDel',
          jsonEncode(
              {'id': id, 'from_id': myId, 'to_ids': toIds, 'grpId': convid}));
    return await db.deleteGroupMsg(id, convid);
  }

  // get all chat of group
  Future<List<GroupMessageModel>> getChat(String grpId) async {
    DBHelper dbHelper = new DBHelper();
    List<GroupMessageModel> msgs = [];
    Database db = await dbHelper.db;
    List<Map> list = await db
        .rawQuery("SELECT * FROM GroupMessages where grpId=\'${grpId}\'");
    for (int i = 0; i < list.length; i++) {
      GroupMessageModel gm = GroupMessageModel.fromJsonDB(list[i]);
      String key = getKey(gm.grpId);
      gm.msg = decrypt(gm.msg, key);
      msgs.add(gm);
    }
    //print("db fetch for $grpId is ${msgs.length}");
    return msgs;
  }

  // get dialogues list
  Future<List<GroupDialogueModel>> getDialogues() async {
    DBHelper dbHelper = new DBHelper();
    List<GroupDialogueModel> msgs = [];
    Database db = await dbHelper.db;
    List<Map> list = await db.rawQuery('SELECT * FROM GroupDialogue');
    for (int i = 0; i < list.length; i++) {
      GroupDialogueModel gd = GroupDialogueModel.fromJsonDB(list[i]);
      String key = getKey(gd.grpId);
      gd.lastMsg = decrypt(gd.lastMsg, key);
      msgs.add(gd);
    }
    return msgs;
  }

  // delete chat history
  Future<int> deleteChatHistory(String grpId) async {
    DBHelper dbHelper = new DBHelper();
    Database db = await dbHelper.db;
    // update dialogue to latest msg
    List<GroupMessageModel> msgs = await getChat(grpId);
    if (msgs.length > 0) {
      GroupMessageModel messageModel = msgs[msgs.length - 1];
      messageModel.msg = '';
      GroupDialogueModel groupDialogueModel =
          GroupDialogueModel.fromGrpMessage(messageModel);
      saveDialogue(groupDialogueModel);
    }
    // delete msg
    int res = await db
        .rawDelete('DELETE FROM GroupMessages WHERE grpId = ?', [grpId]);
    return res;
  }

  // delete conversation
  Future<int> deleteConversation(String grpId) async {
    DBHelper dbHelper = new DBHelper();
    Database db = await dbHelper.db;
    int res = await db
        .rawDelete('DELETE FROM GroupDialogue WHERE grpId = ?', [grpId]);
    await Future.delayed(Duration(seconds: 1));
    res = await db
        .rawDelete('DELETE FROM GroupMessages WHERE grpId = ?', [grpId]);
    return res;
  }

  // mark msg as favourite
  Future<void> addMsgToFavourity(String msgId) async {
    DBHelper dbHelper = new DBHelper();
    Database db = await dbHelper.db;
    await db.rawQuery("UPDATE GroupMessages SET favourite=1 where id=$msgId");
  }

  // save dialog
  Future<int> saveDialogue(GroupDialogueModel md) async {
    DBHelper dbHelper = new DBHelper();
    int result = 0;
    Database db = await dbHelper.db;
    await db.transaction((txn) async {
      List<Map> list = await txn.rawQuery(
          "SELECT * FROM GroupDialogue where grpId=\'${md.grpId.trim()}\'");
      if (list.length > 0) {
        // update existing dialogue
        result = await txn.update('GroupDialogue', md.toJson(),
            where: 'grpId = ?', whereArgs: [md.grpId.toString()]);
      } else {
        // create it
        result = await txn.insert('GroupDialogue', md.toJson());
      }
    });
    return result;
  }

  // get all favourite msgs of grpid
  Future<List<GroupMessageModel>> getAllFavourite(String grpId) async {
    List<GroupMessageModel> msgs = [];
    DBHelper dbHelper = new DBHelper();
    Database db = await dbHelper.db;
    List<Map> list = await db.rawQuery(
        "SELECT * FROM GroupMessages where grpId=\'${grpId}\' and favourite=1");
    for (int i = 0; i < list.length; i++) {
      msgs.add(GroupMessageModel.fromJsonDB(list[i]));
    }
    return msgs;
  }

  // insert background msgs
  Future<void> insertBackgroundSavedChat() async {
    String text;
    try {
      final File file =
          File('/data/user/0/com.ciphermatrix.matrix/files/groupMsg.txt');
      if (file.existsSync()) {
        text = await file.readAsString();
        List<String> jsons = text.split('>');
        if (text.length > 5) {
          for (String e in jsons) {
            Map map = jsonDecode(e);
            map['msg'] = map['msg'].replaceAll(' ', '+');
            GroupMessageModel md = GroupMessageModel.fromJsonDB(map);
            md.loaded = "0";
            md.localUrl = "";
            await saveMsg(md);
            await Future.delayed(Duration(seconds: 1));
          }
          file.writeAsString("");
          await Future.delayed(Duration(seconds: 2));
          if (OneContext.hasContext) {
            await Provider.of<GroupChatProvider>(OneContext().context,
                    listen: false)
                .fetchDialogues();
          }
        }
      }
    } catch (e) {
      print("Error inserting group msgs $e");
    }
  }

  // background deletion
  Future<void> backgroundDeletion() async {
    String text;
    try {
      final File file =
          File('/data/user/0/com.ciphermatrix.matrix/files/delMsgGroup.txt');
      if (file.existsSync()) {
        text = await file.readAsString();
        List<String> jsons = text.split('>');
        if (text.length > 5) {
          String convid = null;
          for (String e in jsons) {
            Map map = jsonDecode(e);
            // terminated
            DBHelper db = new DBHelper();
            db.deleteGroupMsg(int.parse(map['id'].toString()), map['grpId']);
            convid = map['grpId'];
          }
          if (OneContext.hasContext != null && convid != null) {
            await Provider.of<GroupChatProvider>(OneContext().context,
                    listen: false)
                .fetchDialogues();
            await Provider.of<GroupChatProvider>(OneContext().context,
                    listen: false)
                .fetchChat(convid);
          }
          file.writeAsString("");
        }
      }
    } catch (e) {
      print("Error inserting deletion for group chat  $e");
    }
  }
}
