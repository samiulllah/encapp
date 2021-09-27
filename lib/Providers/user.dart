import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:encapp/Models/friends.dart';
import 'package:encapp/Providers/home.dart';
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:encapp/Services/user.dart';
import 'package:one_context/one_context.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:io';
import 'dart:io' as io;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'chat.dart';
import 'group_chat.dart';

class UserProvider extends ChangeNotifier {
  IO.Socket socket;
  List<FriendsModel> contacts = [];
  //state
  Map user = null;
  UserService us = new UserService();
  DBHelper db = new DBHelper();
  int noSelected = 0;

  // create user
  Future<bool> createUser(String password, String usr_alias) async {
    return await us.createUser(password, usr_alias);
  }

  // init socket
  Future<void> initSocket() async {
    await us.initSocket();
  }

  // init listener
  void initListener() {
    us.initUserAliasListener();
  }

  // dispose socket
  Future<void> disposeSocket() async {
    us.disposeSocket();
  }

  bool checkConnection() {
    if (us.checkConnection()) {
      return true;
    } else {
      // Provider.of<HomeProvider>(OneContext().context, listen: false)
      //     .setConnected(false);
      return false;
    }
  }

  // login
  Future<bool> loginUser(String entered_pass) async {
    return await us.loginUser(entered_pass);
  }

  // get user
  Future<Map> findUser(String cid) async {
    return await us.findUser(cid);
  }

  // check user set
  Future<bool> isUserSet() async {
    return await us.isUserSet();
  }

  // check for app udpate
  Future<bool> isUpdateAvailable() async {
    return await us.isUpdatable();
  }

  // get cid
  Future<String> getDeviceId() async {
    return await us.getDeviceId();
  }

  // add friend
  Future<int> addFriend(Map data) async {
    int insert = await db.addFriend(data['cid'], data['alias']);
    return insert;
  }

  // get my contacts
  Future<void> getContacts() async {
    print("getting contacts....");
    contacts = await db.getAllMyFirends();
    notifyListeners();
  }

  // update pid
  Future<bool> updatePid() async {
    return await us.updatePId();
  }

  // delete selected
  Future<void> deleteSelected() async {
    for (int i = 0; i < contacts.length; i++) {
      if (contacts[i].selected) {
        await deleteContact(contacts[i].cid);
      }
    }
    unselectAll();
    await Future.delayed(Duration(seconds: 1));
    await getContacts();
  }

  // select  contact
  void selectContact(String cid) {
    for (int i = 0; i < contacts.length; i++) {
      if (contacts[i].cid == cid) contacts[i].selected = !contacts[i].selected;
    }
    setNoSelected();
    print("nos selected = $noSelected");
    notifyListeners();
  }

  // get nos selected
  void setNoSelected() {
    int z = 0;
    for (int i = 0; i < contacts.length; i++) {
      if (contacts[i].selected) {
        z = z + 1;
      }
    }
    noSelected = z;
  }

  // unselect all contact
  void unselectAll() {
    for (int i = 0; i < contacts.length; i++) {
      contacts[i].selected = false;
    }
    noSelected = 0;
    notifyListeners();
  }

  // update alias
  Future<bool> updateAlias(String cid, String alias) async {
    return await us.updateAlias(cid, alias);
  }

  // check contact exsit
  Future<bool> doesContactExist(String cid) async {
    return await us.doesContactExist(cid);
  }

  //delete contact
  Future<int> deleteContact(String cid) async {
    return await us.deleteContact(cid);
  }

  //delete contact
  Future<int> blockContact(String cid, int val) async {
    return await us.blockContact(cid, val);
  }

  Future<void> destroyEverything() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    //drop db
    String path = join(documentsDirectory.path, "matrix.db");
    await ((await openDatabase(path)).close());
    await deleteDatabase(path);
    // drop prefs
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.clear();
    // exit app.
    io.exit(0);
  }

  // check burn time
  Future<void> checkBurnTime() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (!sharedPreferences.containsKey('lastBurnt')) {
      sharedPreferences.setString(
          'lastBurnt', DateTime.now().millisecondsSinceEpoch.toString());
      return;
    }
    String burnTime = sharedPreferences.containsKey('burnTime')
        ? sharedPreferences.getString('burnTime')
        : "Days";
    DateTime lastBurnt = DateTime.fromMillisecondsSinceEpoch(
        int.parse(sharedPreferences.getString('lastBurnt')));
    DateTime now = DateTime.now();
    int diffInDays = now.difference(lastBurnt).inDays;
    int diffInMins = now.difference(lastBurnt).inMinutes;
    print("diff in day = $diffInDays in minutes= $diffInMins");
    if (burnTime == 'Days') {
      // days
      if (diffInDays >= 5) {
        clearAll(sharedPreferences);
      }
    } else {
      // mins
      if (diffInMins >= 5) {
        clearAll(sharedPreferences);
      }
    }
  }

  // is user blocked
  Future<int> isUserBlock(String cid) async {
    return await us.isUserBlock(cid);
  }

  // tap to unblock
  Future<int> unblockUser(String cid, int val) async {
    return await us.unBlockContact(cid, val);
  }

  Future<void> clearAll(SharedPreferences sharedPreferences) async {
    await Provider.of<ChatProvider>(OneContext().context, listen: false)
        .deleteAllConversations();
    await Provider.of<GroupChatProvider>(OneContext().context, listen: false)
        .deleteAllConversations();
    sharedPreferences.setString(
        'lastBurnt', DateTime.now().millisecondsSinceEpoch.toString());
  }
}
