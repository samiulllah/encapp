import 'dart:math';

import 'package:encapp/Models/group.dart';
import 'package:encapp/Models/message.dart';

class SingleGroupDialogues {
  int i;
  String convid;
  GroupModel g;
  MessageModel s;
  DateTime dateTime;
  bool selected;
  SingleGroupDialogues(
      {this.i, this.s, this.g, this.dateTime, this.convid, this.selected});
}
