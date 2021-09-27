import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/group.dart';
import 'package:encapp/Services/Notifications/notifications.dart';
import 'package:encapp/Services/database/DBHelper.dart';
import 'package:encapp/Services/user.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class UserListener {
  IO.Socket socket;

  Future<void> initListeners(IO.Socket socket) async {
    this.socket = socket;
    UserService us = new UserService();
    String myId = await us.getDeviceId();
    // alias update listener
    socket.on("aliasUpdate", (data) async {
      Map<String, dynamic> map = jsonDecode(data.toString());
      print("Alias update arrived...${map['cid']}");
      DBHelper dbHelper = new DBHelper();
      if (map['cid'] != myId) {
        dbHelper.updateAlias(map);
        if (OneContext.hasContext) {
          await Provider.of<GroupProvider>(OneContext().context, listen: false)
              .getAllGroups();
          Provider.of<ChatProvider>(OneContext().context, listen: false)
              .fetchDialogues();
        }
      }
    });
  }
}
