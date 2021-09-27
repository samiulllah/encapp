import 'dart:convert';
import 'dart:developer';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:encapp/Models/dialogues.dart';
import 'package:encapp/Models/group.dart';
import 'package:http/http.dart' as http;
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:encapp/Services/group_chat.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class GroupService {
  String baseUrl = 'http://newmatrix.global';

  // create group
  Future<bool> createGroup(GroupModel gm) async {
    try {
      var url = Uri.parse('$baseUrl/createGroup.php');
      var response =
          await http.post(url, body: {'group': jsonEncode(gm.toJson())});
      if (response.statusCode == 200) {
        Map res = jsonDecode(response.body.toString());
        if (res['op'] == '1') {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      print("failed to create group $e");
      return false;
    }
  }

  // destroy group
  Future<bool> destroyGroup(String id) async {
    try {
      var url = Uri.parse('$baseUrl/destroyGroup.php');
      var response = await http.post(url, body: {'grpId': id});
      if (response.statusCode == 200) {
        Map res = jsonDecode(response.body.toString());
        print("op ${res['op']}");
        if (res['op'] == '1') {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      print("failed to destroy group $e");
      return false;
    }
  }

  // remove member
  Future<bool> removeMember(
      String newMembers, String oldMembers, String grpId) async {
    try {
      var url = Uri.parse('$baseUrl/updateMembers.php');
      var response =
          await http.post(url, body: {'grpId': grpId, 'members': newMembers});
      if (response.statusCode == 200) {
        Map res = jsonDecode(response.body.toString());
        print("op ${res['op']}");
        if (res['op'] == '1') {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      print("failed to remove member $e");
      return false;
    }
  }

  // get all my groups
  Future<List<GroupModel>> getAllGroups(String mydId) async {
    List<String> localGroups = await getLocalGroups();
    GroupChatService cs = new GroupChatService();
    List<GroupDialogueModel> dialogues = await cs.getDialogues();
    List<GroupModel> groups = [];
    try {
      var url = Uri.parse('$baseUrl/getAllGroups.php?id=$mydId');
      var response = await http.get(url);
      Map res = jsonDecode(response.body.toString());
      if (res['op'] == '1') {
        for (Map m in res['groups']) {
          GroupDialogueModel d = getDialogue(m['grpId'], dialogues);
          GroupModel gm = GroupModel.fromJson(m, d);
          if (d != null) gm.datetime = d.datetime;
          if (mydId != gm.ownerId) {
            if (localGroups.contains(gm.grpId)) {
              gm.groupExist = true;
            } else {
              gm.groupExist = false;
            }
          } else {
            gm.groupExist = true;
          }
          groups.add(gm);
        }
      }
      return groups;
    } catch (e) {
      print("failed to create group $e");
      return groups;
    }
  }

  GroupDialogueModel getDialogue(
      String grpid, List<GroupDialogueModel> dialogues) {
    GroupDialogueModel d = null;
    for (GroupDialogueModel gd in dialogues) {
      if (gd.grpId == grpid) {
        d = gd;
      }
    }
    return d;
  }

  // get all local groups
  Future<List<String>> getLocalGroups() async {
    List<String> localIds = [];
    DBHelper dbHelper = new DBHelper();
    Database db = await dbHelper.db;
    List<Map> list = await db.rawQuery('SELECT * FROM Groups');
    for (int i = 0; i < list.length; i++) {
      localIds.add(list[i]['grpId']);
    }
    return localIds;
  }

  // get all unread
  Future<int> getNoUnread(String grpId) async {
    String myId = await getDeviceId();
    int unread = 0;
    DBHelper dbHelper = new DBHelper();
    Database db = await dbHelper.db;
    List<Map> list = await db.rawQuery(
        "SELECT * FROM GroupMessages where grpId=\'${grpId}\' AND  read=0 AND not from_id=\'$myId\'");
    unread = list.length;
    return unread;
  }

  // save group locally
  Future<int> insertLocally(String id) async {
    DBHelper dbHelper = new DBHelper();
    Database db = await dbHelper.db;
    int result = await db.insert('Groups', {'grpId': id});
    return result;
  }

  // delete group locally
  Future<int> deleteLocally(String id) async {
    DBHelper dbHelper = new DBHelper();
    Database db = await dbHelper.db;
    int res = await db.rawDelete('DELETE FROM Groups WHERE grpId = ?', [id]);
    return res;
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
