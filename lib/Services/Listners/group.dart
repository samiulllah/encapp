import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Services/Notifications/notifications.dart';
import 'package:one_context/one_context.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class GroupListeners {
  IO.Socket socket;
  Future<void> initListeners() async {
    this.socket = socket;
    String id = await getDeviceId();
    // create group
    socket.on("groupUpdates", (data) async {
      Map<String, dynamic> map = jsonDecode(data.toString());
      print("group updates arrived...");
    });
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
