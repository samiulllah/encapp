import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as aes;
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/group.dart';
import 'package:encapp/Providers/group_chat.dart';
import 'package:encapp/Providers/home.dart';
import 'package:encapp/Providers/user.dart';
import 'package:encapp/Screens/widgets/alerts.dart';
import 'package:encapp/Services/Listners/user.dart';
import 'package:encapp/Services/Notifications/notifications.dart';
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';
import 'chat.dart';
import 'group_chat.dart';

class UserService {
  static BuildContext homeContext = null;
  static BuildContext unlockPage = null;

  IO.Socket socket;
  UserListener userListener = new UserListener();
  List<IO.Socket> socks = [];
  String baseUrl = 'http://newmatrix.global';
  // String baseUrl = 'https://nationalism-millime.000webhostapp.com';
  String socUrl = 'http://newmatrix.global:3000';
  // String socUrl = 'https://matrixappserver.herokuapp.com/';

  // connect to socket server
  Future<void> initSocket() async {
    if (socket != null && socket.connected) return;
    print("connecting to socket.....");
    String id = await getDeviceId();
    checkDisconnection();
    await Future.delayed(Duration(seconds: 2));
    // make fresh connection
    IO.Socket sock = IO.io(
        socUrl,
        OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .disableReconnection()
            .setReconnectionAttempts(0)
            .setQuery({'id': id})
            .build());

    sock.onConnect((data) {
      ChatService.lock = 0;
      GroupChatService.lock = 0;
      ChatService.lock = 0;
      sock.sendBuffer = [];
      sock.emit('registerUser', id);
      sock.emit('connectionTest', jsonEncode({'id': id}));
      sock.on('connectionOkay', (data) async {
        Map map = jsonDecode(data.toString());
        print('res = $map');
        if (map['ok'] == '1' && map['id'] == id) {
          this.socket = sock;
          socks.add(sock);
          initOther();
          print(
              "CONNECTED....CONNECTED.....CONNECTED.......CONNECTED.......CONNECTED");
        } else {
          print("CONNECTING.....CONNECTING......CONNECTING");
          socketDisconnected();
        }
      });
      sock.onDisconnect((data) async {
        print("Error S:e0");
        await reconnectToServer();
      });
      // check for errors
      sock.onConnectTimeout((data) async {
        print("Error S:e1");
        await reconnectToServer();
      });
      sock.onError((data) async {
        print("Error S:e2");
        await reconnectToServer();
      });
      // check for errors
      sock.onConnectError((data) async {
        print("Error S:e3");
        await reconnectToServer();
      });
    });
  }

  void checkDisconnection() {
    if (this.socket != null) {
      this.socket.disconnect();
      this.socket.destroy();
      this.socket.dispose();
    }
  }

  // reconnect
  Future<void> reconnectToServer() async {
    // clear previous listeners
    await socketDisconnected();
  }

  // disconnected
  Future<void> socketDisconnected() async {
    if (socket == null || socket.disconnected) {
      ChatService.lock = 0;
      GroupChatService.lock = 0;
      print(
          "DISCONNECTED....DISCONNECTED.....DISCONNECTED.......DISCONNECTED.......DISCONNECTED");
      checkDisconnection();
    }
  }

  // init other listeners with fresh socket
  Future<void> initOther() async {
    if (OneContext.hasContext) {
      await Provider.of<GroupProvider>(OneContext().context, listen: false)
          .initListeners(this.socket);
      await Provider.of<ChatProvider>(OneContext().context, listen: false)
          .addChatListeners(this.socket);
      await Provider.of<GroupChatProvider>(OneContext().context, listen: false)
          .addChatListners(this.socket);
      Provider.of<UserProvider>(OneContext().context, listen: false)
          .initListener();
      Provider.of<HomeProvider>(OneContext().context, listen: false)
          .setConnected(true);
    }
  }

  // disconnect
  void disposeSocket() {
    print("DISCONNECTING...");
    if (socket != null && socket.connected) {
      socket.clearListeners();
      socket.close();
    }
  }

  // check socket connection
  bool checkConnection() {
    if (socket == null || socket.disconnected) {
      return false;
    } else {
      return true;
    }
  }

  // init listener
  void initUserAliasListener() {
    userListener.initListeners(this.socket);
  }

  // creating user
  Future<bool> createUser(String password, String usr_alias) async {
    String cid = await getDeviceId();
    NotificationService ns = new NotificationService();
    String token = await ns.getFreshToken();
    try {
      var url = Uri.parse(
          '$baseUrl/createUser.php?cid=$cid&alias=$usr_alias&pid=$token');
      var response = await http.get(url);
      Map data = jsonDecode(response.body);
      if (data['save'] == '1') {
        await saveLocal(cid, usr_alias);
        await saveUserPassword(password, cid);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error:Creating User: $e");
      return false;
    }
  }

  // login user
  Future<bool> loginUser(String entered_pass) async {
    String orig_pass = await getPassword();
    print('saved= $orig_pass and entered = $entered_pass');
    if (orig_pass == entered_pass) {
      return true;
    } else {
      return false;
    }
  }

  // save user password
  Future<void> saveUserPassword(String password, String cid) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String sharedKey = md5.convert(utf8.encode(cid)).toString();
    final key = aes.Key.fromUtf8(sharedKey);
    final iv = aes.IV.fromLength(16);

    final encrypter = aes.Encrypter(aes.AES(key));

    final encrypted = encrypter.encrypt(password, iv: iv);
    String p = encrypted.base64;
    sharedPreferences.setString('password', p);
  }

  // get password
  Future<String> getPassword() async {
    String cid = await getDeviceId();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String password = sharedPreferences.getString('password');
    String sharedKey = md5.convert(utf8.encode(cid)).toString();
    final key = aes.Key.fromUtf8(sharedKey);
    final iv = aes.IV.fromLength(16);

    final encrypter = aes.Encrypter(aes.AES(key));
    final decrypted = encrypter.decrypt64(password, iv: iv);
    return decrypted;
  }

  // save user locally
  Future<void> saveLocal(String cid, String alias) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString('cid', cid);
    sharedPreferences.setString('alias', alias);
  }

  // get user locally
  Future<bool> isUserSet() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (!sharedPreferences.containsKey('hideSendBtn'))
      sharedPreferences.setBool('hideSendBtn', false);
    await doSavedUpdates();
    String u = sharedPreferences.getString('cid');
    return u != null;
  }

  Future<void> doSavedUpdates({String type}) async {
    await updateChat(); // update chat
  }

  // update Chat
  Future<void> updateChat() async {
    await Future.delayed(Duration(seconds: 1), () async {
      await insertBackgroundSavedChat();
      await insertReadReceipt();
      ChatService cs = new ChatService();
      await cs.backgroundDeletion();
    });
  }

  // background saved chat
  Future<void> insertBackgroundSavedChat() async {
    String text;
    try {
      final File file =
          File('/data/user/0/com.ciphermatrix.matrix/files/msg.txt');
      if (file.existsSync()) {
        text = await file.readAsString();
        List<String> jsons = text.split('>');
        if (text.length > 5) {
          DBHelper db = new DBHelper();
          for (String e in jsons) {
            Map map = jsonDecode(e);
            map['msg'] = map['msg'].replaceAll(' ', '+');
            MessageModel md = MessageModel.fromJson(map);
            md.loaded = "0";
            md.localUrl = "";
            await db.saveMsg(md);
            await Future.delayed(Duration(seconds: 1));
          }
          file.writeAsString("");
          await Future.delayed(Duration(seconds: 2));
          if (ChatService.singleChatContext != null) {
            await Provider.of<ChatProvider>(ChatService.singleChatContext,
                    listen: false)
                .fetchDialogues();
          }
        }
      }
    } catch (e) {
      print("Error single chat inserting msgs $e");
    }
  }

  // update read receipts
  Future<void> insertReadReceipt() async {
    String text;
    try {
      final File file =
          File('/data/user/0/com.ciphermatrix.matrix/files/msgRead.txt');
      if (file.existsSync()) {
        text = await file.readAsString();
        List<String> jsons = text.split('>');
        if (text.length > 5) {
          for (String e in jsons) {
            Map map = jsonDecode(e);
            if (ChatService.singleChatContext != null) {
              // if in foreground
              await Provider.of<ChatProvider>(ChatService.singleChatContext,
                      listen: false)
                  .markAsRead(map);
            } else {
              // terminated
              ChatService cs = new ChatService();
              cs.markChatAsRead(map);
            }
          }
          file.writeAsString("");
        }
      }
    } catch (e) {
      print("Error inserting read receipts  $e");
    }
  }

  // update about pings
  Future<void> updateAboutPings() async {
    String text;
    try {
      final File file =
          File('/data/user/0/com.ciphermatrix.matrix/files/ping.txt');
      if (file.existsSync()) {
        text = await file.readAsString();
        print("Pings text is = $text");
        List<String> jsons = text.split('>');
        if (text.length > 5) {
          List<Map> maps = [];
          for (String e in jsons) {
            Map map = jsonDecode(e);
            maps.add(map);
          }
          print('pings length = ${maps.length}');
          if (maps.length > 1) {
            if (OneContext.hasContext) {
              showPingMultiAlert(OneContext().context, maps);
            }
          } else if (maps.length == 1) {
            if (OneContext.hasContext) {
              showPingAlert(OneContext().context, maps[0]['from_id'],
                  maps[0]['from_alias']);
            }
          }
          file.writeAsString("");
        }
      }
    } catch (e) {
      print("Error updating pings $e");
    }
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

  // find user
  Future<Map> findUser(String cid) async {
    Map res = null;
    try {
      var url = Uri.parse('$baseUrl/getUser.php?cid=$cid');
      var response = await http.get(url);
      Map data = jsonDecode(response.body);
      log('res = ${response.body}');
      if (data['found'] == '1') {
        res = data;
        return res;
      } else {
        return res;
      }
    } catch (e) {
      print("Error:Creating User: $e");
      return res;
    }
  }

  // update pid
  Future<bool> updatePId() async {
    print('updating pid...');
    String cid = await getDeviceId();
    NotificationService ns = new NotificationService();
    String token = await ns.getFreshToken();
    try {
      var url = Uri.parse('$baseUrl/updatePid.php?cid=$cid&pid=$token');
      var response = await http.get(url);
      print('updated pid...');
      return true;
    } catch (e) {
      print("Error:updating pid: $e");
      return false;
    }
  }

  // update available
  Future<bool> isUpdatable() async {
    int currentVersion = 8;
    print('updating pid...');
    try {
      var url = Uri.parse('$baseUrl/forceUpdate.php');
      var response = await http.get(url);
      int version = int.parse(response.body.toString());
      return currentVersion < version;
    } catch (e) {
      print("Error: app updatable : $e");
      return false;
    }
  }

  // update alias
  Future<bool> updateAlias(String cid, String alias) async {
    print('updating alias...');
    try {
      var url = Uri.parse('$baseUrl/updateAlias.php?cid=$cid&alias=$alias');
      var response = await http.get(url);
      Map json = jsonDecode(response.body.toString());
      print('updated alias...');
      bool f = json['save'] == '1';
      if (f) {
        List<String> toids = await getAllUserIds();
        Map map = new Map();
        map['to_ids'] = toids;
        map['cid'] = cid;
        map['alias'] = alias;
        print("emitting $map");
        socket.emit('aliasUpdate', jsonEncode(map));
      }
      return f;
    } catch (e) {
      print("Error:updating pid: $e");
      return false;
    }
  }

  // get all user
  Future<List<String>> getAllUserIds() async {
    List<String> users = [];
    try {
      var url = Uri.parse('$baseUrl/getAllUsers.php');
      var response = await http.get(url);
      Map json = jsonDecode(response.body.toString());
      if (json['usrs'].length > 0) {
        for (String s in json['usrs']) {
          users.add(s);
        }
      }
      return users;
    } catch (e) {
      print("Error $e");
      return [];
    }
  }

  // does user exist in my contact list
  Future<bool> doesContactExist(String cid) async {
    DBHelper db = new DBHelper();
    int res = await db.contactExist(cid);
    return res == 99;
  }

  /// delete contact
  Future<int> deleteContact(String cid) async {
    DBHelper db = new DBHelper();
    return await db.deleteContact(cid);
  }

  // block
  Future<int> blockContact(String cid, int val) async {
    print("I'm unblocking user with CID : $cid");
    DBHelper db = new DBHelper();
    String myId = await getDeviceId();
    if (val != 2)
      socket.emit(
          "block", jsonEncode({"uid": cid, "block": "1", 'from_id': myId}));
    return await db.blockContact(cid, val);
  }

  // unblock
  Future<int> unBlockContact(String cid, int val) async {
    print("I'm blocking user with CID : $cid");
    DBHelper db = new DBHelper();
    String myId = await getDeviceId();
    if (val != 2)
      socket.emit(
          "block", jsonEncode({"uid": cid, "block": "0", 'from_id': myId}));
    return await db.unBlockContact(cid);
  }

  // is user block
  Future<int> isUserBlock(String cid) async {
    DBHelper db = new DBHelper();
    return await db.isUserBlock(cid);
  }
}
