import 'package:flutter/cupertino.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Models/single_group_dialogues.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'chat.dart';
import 'group_chat.dart';

class HomeProvider extends ChangeNotifier {
  bool isConnected = true;

  void setConnected(bool val) {
    isConnected = val;
    notifyListeners();
  }

  bool getConnectionState() {
    return isConnected;
  }
}
