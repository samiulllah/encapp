import 'dart:convert';
import 'package:encapp/Providers/group_chat.dart';
import 'package:encapp/Providers/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:one_context/one_context.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:encapp/Models/friends.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:encapp/Services/group.dart';
import 'dart:io';
import 'package:provider/provider.dart';

class GroupProvider extends ChangeNotifier {
  GroupService gs = new GroupService();
  List<GroupModel> groups = [];
  List<FriendsModel> friends = [];
  int nosSelected = 0;
  String myId;
  IO.Socket socket;
  List<Map<String, dynamic>> unreadMap = [];

  Future<void> initListeners(IO.Socket socket) async {
    this.socket = socket;
    // create group
    socket.on("groupUpdates", (data) async {
      print("group updates arrived....");
      getAllGroups();
    });
  }

  // create group
  Future<bool> createGroup(GroupModel gm) async {
    bool f = await gs.createGroup(gm);
    if (f) {
      await notifyUsers(gm.members);
    }
    return f;
  }

  // destroy group
  Future<bool> destroyGroup(GroupModel gm) async {
    bool f = await gs.destroyGroup(gm.grpId);
    if (f) {
      await notifyUsers(gm.members);
      groups.removeWhere((element) => element.grpId == gm.grpId);
      notifyListeners();
    }
    return f;
  }

  //notify users
  Future<void> notifyUsers(List<Members> n) async {
    List<String> notify_members = [];
    for (Members m in n) {
      notify_members.add(m.id);
    }
    if (Provider.of<UserProvider>(OneContext().context, listen: false)
        .checkConnection())
      this.socket.emit('groupsUpdated', jsonEncode({'to_ids': notify_members}));
  }

  // update group
  Future<bool> addMember(GroupModel gm) async {
    List<Map> newMembers = [];
    List<Map> oldMembers = [];
    List<String> oldIds = [];
    List<Members> newLocalMembers = null;
    for (Members m in gm.members) {
      oldIds.add(m.id);
      oldMembers.add(m.toJson());
    }
    for (FriendsModel f in friends) {
      if (f.selected && (!oldIds.contains(f.cid))) {
        gm.members.add(new Members(id: f.cid, alias: f.alias));
      }
    }
    for (Members m in gm.members) {
      newMembers.add(m.toJson());
    }
    bool f = await gs.removeMember(
        jsonEncode(newMembers), jsonEncode(oldMembers), gm.grpId);
    if (f) {
      newLocalMembers = gm.members;
      await notifyUsers(newLocalMembers);
      updateLocally(newLocalMembers, gm.grpId);
    }
    return f;
  }

  // get refresh group
  GroupModel getFresh(String id) {
    GroupModel g = null;
    for (GroupModel gm in groups) {
      if (gm.grpId == id) {
        g = gm;
      }
    }
    return g;
  }

  // remove member
  Future<bool> removeMember(GroupModel gm, String id) async {
    List<Map> newMembers = [];
    List<Map> oldMembers = [];
    List<Members> newLocalMembers = [];
    for (Members m in gm.members) {
      oldMembers.add(m.toJson());
      if (!(m.id != gm.ownerId && m.id == id)) {
        newMembers.add(m.toJson());
        newLocalMembers.add(m);
      }
    }
    bool f = await gs.removeMember(
        jsonEncode(newMembers), jsonEncode(oldMembers), gm.grpId);
    if (f) {
      await notifyUsers(gm.members);
      updateLocally(newLocalMembers, gm.grpId);
    }
    return f;
  }

  // update members locally
  void updateLocally(List<Members> newMembers, String gid) {
    for (int i = 0; i < groups.length; i++) {
      if (groups[i].grpId == gid) {
        groups[i].members = newMembers;
      }
    }
    notifyListeners();
  }

  // leave group
  Future<bool> leaveGroup(GroupModel gm) async {
    myId = await getDeviceId();
    List<Map> newMembers = [];
    List<Map> oldMembers = [];
    List<Members> newLocalMembers = [];
    for (Members m in gm.members) {
      oldMembers.add(m.toJson());
      if (!(m.id != gm.ownerId && m.id == myId)) {
        newMembers.add(m.toJson());
        newLocalMembers.add(m);
      }
    }
    bool f = await gs.removeMember(
        jsonEncode(newMembers), jsonEncode(oldMembers), gm.grpId);
    if (f) {
      await notifyUsers(gm.members);
      groups.removeWhere((element) => element.grpId == gm.grpId);
      notifyListeners();
    }
    return f;
  }

  Future<void> getAllGroups() async {
    List<GroupModel> g = await gs.getAllGroups(await getDeviceId());
    GroupModel gm = new GroupModel(
        grpName: 'Bunty',
        ownerId: '1',
        members: [
          new Members(id: '1', alias: 'Tony'),
          new Members(id: '2', alias: 'Plank')
        ],
        desc: 'nothing');
    gm.lastSender = 'Tony';
    gm.lastMsg = 'Hi, Guys';
    g.add(gm);
    GroupModel gm1 = new GroupModel(
        grpName: 'Xharp',
        ownerId: '2',
        members: [
          new Members(id: '1', alias: 'Tony'),
          new Members(id: '2', alias: 'Plank')
        ],
        desc: 'nothing');
    gm1.lastMsg = 'Good Morning';
    gm1.lastSender = 'Wolker';
    g.add(gm1);
    groups = g;
    unreadMap = [];
    for (GroupModel gm in groups) {
      unreadMap.add({gm.grpId: 2});
    }
    groups
        .sort((GroupModel a, GroupModel b) => a.datetime.compareTo(b.datetime));
    groups = groups.reversed.toList();
    notifyListeners();
  }

  // get my contacts
  Future<void> getContacts() async {
    DBHelper db = new DBHelper();
    friends = await db.getAllMyFirends();
    notifyListeners();
  }

  // select contact
  void selectContact(String id) {
    for (int i = 0; i < friends.length; i++) {
      if (friends[i].cid == id) {
        friends[i].selected = !friends[i].selected;
      }
    }
    refreshSelected();
  }

  // get nos selected
  void refreshSelected() {
    nosSelected = 0;
    for (FriendsModel contact in friends) {
      if (contact.selected) {
        nosSelected++;
      }
    }
    notifyListeners();
  }

  // accept group request
  Future<bool> acceptGroup(String id) async {
    int i = await gs.insertLocally(id);
    if (i != 0) {
      for (int i = 0; i < groups.length; i++) {
        if (groups[i].grpId == id) {
          groups[i].groupExist = true;
        }
      }
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  // decline group request
  Future<bool> declineGroupRequest(GroupModel gm) async {
    bool f = await leaveGroup(gm);
    if (f) {
      // remove locally
      await gs.deleteLocally(gm.grpId);
    }
    return f;
  }

  // get device id
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
}
