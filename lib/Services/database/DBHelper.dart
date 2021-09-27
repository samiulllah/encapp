import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:encapp/Models/dialogues.dart';
import 'package:encapp/Models/friends.dart';
import 'package:encapp/Models/group_message.dart';
import 'package:encapp/Models/message.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io' as io;
import 'package:path/path.dart';

class DBHelper {
  Database _db;

  Future<Database> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "matrix.db");
    var theDb = await openDatabase(path, version: 1, onCreate: _onCreate);
    return theDb;
  }

  void _onCreate(Database db, int version) async {
    // contacts
    await db.execute(
        "CREATE TABLE Friends (id INTEGER PRIMARY KEY AUTOINCREMENT, cid TEXT, alias TEXT,block INTEGER)");
    // dialogues
    await db.execute(
        "CREATE TABLE Dialogues (id INTEGER, convid TEXT, from_id TEXT, to_id TEXT,  msg TEXT"
        ", datetime TEXT,read INTEGER,from_alias TEXT,to_alias TEXT,favourite INTEGER,replyId INTEGER,delMsg INTEGER,"
        "msgType TEXT,url TEXT,localUrl TEXT,loaded TEXT,uploaded TEXT,sl_id INTEGER,sent TEXT)");
    // messages
    await db.execute(
        "CREATE TABLE Messages (id INTEGER, convid TEXT, from_id TEXT, to_id TEXT,  msg TEXT"
        ", datetime TEXT,read INTEGER,from_alias TEXT,to_alias TEXT,favourite INTEGER,replyId INTEGER,delMsg INTEGER,"
        "msgType TEXT,url TEXT,localUrl TEXT,loaded TEXT,uploaded TEXT,sl_id INTEGER,sent TEXT)");
    // group dialogue
    await db.execute(
        "CREATE TABLE GroupDialogue (id INTEGER, grpId TEXT, lastMsg TEXT,lastUser TEXT,datetime TEXT,delMsg INTEGER)");
    // group messages
    await db.execute(
        "CREATE TABLE GroupMessages (id INTEGER, grpId TEXT, from_id TEXT,  msg TEXT"
        ", datetime TEXT,read INTEGER,from_alias TEXT,favourite INTEGER,to_ppl TEXT ,replyId INTEGER,delMsg INTEGER,"
        "msgType TEXT,url TEXT,localUrl TEXT,loaded TEXT,uploaded TEXT,sl_id INTEGER,sent TEXT)");
    // groups
    await db.execute("CREATE TABLE Groups (grpId TEXT)");

    print("Created tables");
  }

  // add friend
  Future<int> addFriend(String cid, String alias) async {
    Database db = await this.db;
    int result = 0;
    List<Map> list =
        await db.rawQuery("SELECT * FROM Friends where cid=\'${cid}\'");
    if (list.length > 0) {
      result = 99; // already exist
    } else {
      result =
          await db.insert('Friends', {'cid': cid, 'alias': alias, 'block': 0});
    }
    return result;
  }

  // get friends list
  Future<List<FriendsModel>> getAllMyFirends() async {
    List<FriendsModel> myFriends = [];
    Database db = await this.db;
    List<Map> list = await db.rawQuery('SELECT * FROM Friends');
    for (int i = 0; i < list.length; i++) {
      myFriends.add(new FriendsModel(
          cid: list[i]['cid'],
          alias: list[i]['alias'],
          block: list[i]['block']));
    }
    return myFriends;
  }

  // get blocking
  Future<int> isUserBlock(String cid) async {
    int block = 0;
    Database db = await this.db;
    List<Map> list =
        await db.rawQuery('SELECT * FROM Friends where cid=\'${cid}\'');
    if (list.length > 0) {
      block = int.parse(list[0]['block'].toString());
    }
    return block;
  }

  // save msg
  Future<int> saveMsg(MessageModel md) async {
    print("local url = ${md.localUrl}");
    int result = 0;
    Database db = await this.db;
    await db.transaction((txn) async {
      result = await txn.insert('Messages', md.toJson());
    });
    result = await saveDialogue(md);
    return result;
  }

  // save dialog
  Future<int> saveDialogue(MessageModel md) async {
    int result = 0;
    Database db = await this.db;
    List<Map> list = await db.rawQuery(
        "SELECT * FROM Dialogues where convid=\'${md.convid.trim()}\'");
    try {
      await db.transaction((txn) async {
        if (list.length > 0) {
          // update existing dialogue
          result = await txn.update('Dialogues', md.toJson(),
              where: 'convid = ?', whereArgs: [md.convid.toString()]);
        } else {
          // create it
          result = await txn.insert('Dialogues', md.toJson());
        }
      });
    } catch (e) {
      print('Failed to insert dialogue');
      result = 0;
    }
    return result;
  }

  // get msgs list
  Future<List<MessageModel>> getChat(String convid) async {
    List<MessageModel> msgs = [];
    Database db = await this.db;
    List<Map> list =
        await db.rawQuery("SELECT * FROM Messages where convid=\'${convid}\'");
    for (int i = 0; i < list.length; i++) {
      msgs.add(MessageModel.fromJsonDB(list[i]));
    }
    return msgs;
  }

  // get dialogues list
  Future<List<MessageModel>> getDialogues() async {
    List<MessageModel> msgs = [];
    Database db = await this.db;
    List<Map> list = await db.rawQuery('SELECT * FROM Dialogues');
    for (int i = 0; i < list.length; i++) {
      msgs.add(MessageModel.fromJsonDB(list[i]));
    }
    return msgs;
  }

  // get device id
  Future<String> getDeviceId() async {
    String deviceIdentifier;
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    if (io.Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      deviceIdentifier = androidInfo.androidId;
    } else if (io.Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      deviceIdentifier = iosInfo.identifierForVendor;
    }
    deviceIdentifier = deviceIdentifier.substring(0, 8).toUpperCase();
    return deviceIdentifier;
  }

  // does contact exist
  Future<int> contactExist(String cid) async {
    Database db = await this.db;
    int result = 0;
    List<Map> list =
        await db.rawQuery("SELECT * FROM Friends where cid=\'${cid}\'");
    if (list.length > 0) {
      result = 99; // already exist
    }
    return result;
  }

  // delete contact
  Future<int> deleteContact(String cid) async {
    print("deleting $cid");
    Database db = await this.db;
    int res = await db.rawDelete('DELETE FROM Friends WHERE cid = ?', [cid]);
    return res;
  }

  // block contact
  Future<int> blockContact(String cid, int val) async {
    print("deleting $cid");
    Database db = await this.db;
    int res = await db
        .rawUpdate('UPDATE  Friends SET block=$val WHERE cid = ?', [cid]);
    return res;
  }

  // unblock contact
  Future<int> unBlockContact(String cid) async {
    print("deleting $cid");
    Database db = await this.db;
    int res =
        await db.rawUpdate('UPDATE  Friends SET block=0 WHERE cid = ?', [cid]);

    return res;
  }

  // read all chat for cid
  Future<void> readAll(String convid) async {
    print("Read all for convid $convid");
    String myId = await getDeviceId();
    Database db = await this.db;
    await db.transaction((txn) async {
      await txn.rawQuery(
          "UPDATE Messages SET read=1 where convid=\'${convid}\' AND from_id=\'$myId\'");
      await txn.rawQuery(
          "UPDATE Dialogues SET read=1 where convid=\'${convid}\' AND from_id=\'$myId\'");
    });
  }

  // read other msgs
  Future<void> readOthers(String convid, String otherId) async {
    Database db = await this.db;
    await db.rawQuery(
        "UPDATE Messages SET read=1 where convid=\'${convid}\' AND from_id=\'$otherId\'");
    await db.rawQuery(
        "UPDATE Dialogues SET read=1 where convid=\'${convid}\' AND from_id=\'$otherId\'");
  }

  // get all unread
  Future<int> getNoUnread(String convid) async {
    String myId = await getDeviceId();
    int unread = 0;
    Database db = await this.db;
    List<Map> list = await db.rawQuery(
        "SELECT * FROM Messages where convid=\'${convid}\' AND  read=0 AND to_id=\'$myId\'");
    unread = list.length;
    return unread;
  }

  // delete msg by id
  Future<int> deleteMsg(int id, String convid) async {
    print("deleting msgs");
    Database db = await this.db;
    await db.transaction((txn) async {
      await txn.rawQuery(
          "UPDATE Messages SET delMsg=1 where convid=\'${convid}\' AND id=${id}");
      await txn.rawQuery(
          "UPDATE Dialogues SET delMsg=1 where convid=\'${convid}\' AND id=${id}");
    });
    return 1;
  }

  // delete group msg by id
  Future<int> deleteGroupMsg(int id, String convid) async {
    print("deleting group msg for $id and $convid");
    Database db = await this.db;
    await db.transaction((txn) async {
      await txn.rawQuery(
          "UPDATE GroupMessages SET delMsg=1 where grpId=\'${convid}\' AND id=${id}");
      await txn.rawQuery(
          "UPDATE GroupDialogue SET delMsg=1 where grpId=\'${convid}\' AND id=${id}");
    });
    return 1;
  }

  // delete all msgs of convid
  Future<int> deleteAllMsgsOfChat(String convid) async {
    Database db = await this.db;
    // update dialogue to latest msg
    List<MessageModel> msgs = await getChat(convid);
    if (msgs.length > 0) {
      MessageModel messageModel = msgs[msgs.length - 1];
      messageModel.msg = '';
      if (messageModel.fromId == await getDeviceId()) {
        // if its my ms
        String toId = messageModel.toId;
        messageModel.toId = messageModel.fromId;
        messageModel.fromId = toId;
      }
      saveDialogue(messageModel);
    }
    // delete msg
    int res =
        await db.rawDelete('DELETE FROM Messages WHERE convid = ?', [convid]);
    return res;
  }

  // delete conversation
  Future<int> deleteConversation(String convid) async {
    Database db = await this.db;
    int res =
        await db.rawDelete('DELETE FROM Dialogues WHERE convid = ?', [convid]);
    await Future.delayed(Duration(seconds: 1));
    res = await db.rawDelete('DELETE FROM Messages WHERE convid = ?', [convid]);
    return res;
  }

  // make msg as favourite
  Future<void> addMsgToFavourite(int id) async {
    Database db = await this.db;
    await db.rawQuery("UPDATE Messages SET favourite=1 where id=$id");
  }

  // get all favourite msgs of convid
  Future<List<MessageModel>> getAllFavourite(String convid) async {
    List<MessageModel> msgs = [];
    Database db = await this.db;
    List<Map> list = await db.rawQuery(
        "SELECT * FROM Messages where convid=\'${convid}\' and favourite=1");
    for (int i = 0; i < list.length; i++) {
      msgs.add(MessageModel.fromJsonDB(list[i]));
    }
    return msgs;
  }

  // update alias
  Future<void> updateAlias(Map<String, dynamic> json) async {
    Database db = await this.db;
    // in friends
    int res = await db.rawUpdate(
        'UPDATE  Friends SET alias=\'${json['alias']}\' WHERE cid = ?',
        [json['cid'].toString()]);
    // in chat dialogue
    res = await db.rawUpdate(
        'UPDATE  Dialogues SET from_alias=\'${json['alias']}\' WHERE from_id = ?',
        [json['cid'].toString()]);
    res = await db.rawUpdate(
        'UPDATE  Dialogues SET to_alias=\'${json['alias']}\' WHERE to_id = ?',
        [json['cid'].toString()]);
    // in chats
    res = await db.rawUpdate(
        'UPDATE  Messages SET from_alias=\'${json['alias']}\' WHERE from_id = ?',
        [json['cid'].toString()]);
    res = await db.rawUpdate(
        'UPDATE  Messages SET to_alias=\'${json['alias']}\' WHERE to_id = ?',
        [json['cid'].toString()]);
    // in group
    res = await db.rawUpdate(
        'UPDATE  GroupMessages SET from_alias=\'${json['alias']}\' WHERE from_id = ?',
        [json['cid'].toString()]);
  }

  // update msg
  Future<void> updateMsg(MessageModel msg) async {
    Database db = await this.db;
    int res = await db.update('Dialogues', msg.toJson(),
        where: "id = ?", whereArgs: [msg.id]);
    res = await db
        .update('Messages', msg.toJson(), where: "id = ?", whereArgs: [msg.id]);
  }

  // update msg
  Future<void> updateMsg1(MessageModel msg, int id) async {
    print("updating msg ${msg.toJson()}");
    msg.uploaded = "1";
    Database db = await this.db;
    await db
        .update('Dialogues', msg.toJson(), where: "id = ?", whereArgs: [id]);
    await db.update('Messages', msg.toJson(), where: "id = ?", whereArgs: [id]);
  }

  // update group msg
  Future<void> updateGroupMsg1(GroupMessageModel msg, int id) async {
    print("updating msg  its sl_id = ${msg.sl_id}");
    Database db = await this.db;
    await db.update('GroupMessages', msg.toJsonLocal(),
        where: "id = ?", whereArgs: [msg.sl_id]);
    GroupDialogueModel gd = GroupDialogueModel.fromGrpMessage(msg);
    await db.update('GroupDialogue', gd.toJson(),
        where: "id = ?", whereArgs: [msg.sl_id]);
  }

  // update group msg
  Future<void> updateGroupMsg(GroupMessageModel msg) async {
    Database db = await this.db;
    int res = await db.update('GroupMessages', msg.toJsonLocal(),
        where: "id = ?", whereArgs: [msg.id]);
  }
}
