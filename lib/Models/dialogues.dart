import 'package:encapp/Models/group_message.dart';

class DialoguesModel {
  String name;
  String lastMsg;
  int unread = -1;
  DateTime time;

  DialoguesModel({this.name, this.lastMsg, this.unread, this.time});
}

class GroupDialogueModel {
  int id;
  String grpId;
  String lastMsg;
  String lastUser;
  DateTime datetime;
  int delMsg;

  GroupDialogueModel({this.grpId, this.lastMsg, this.lastUser, this.datetime}) {
    delMsg = 0;
  }

  GroupDialogueModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    grpId = json['grpId'];
    lastMsg = json['lastMsg'];
    lastUser = json['lastUser'];
    delMsg = json['delMsg'];
    datetime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(json['datetime'].toString()),
            isUtc: true)
        .toLocal();
  }
  GroupDialogueModel.fromJsonDB(Map<String, dynamic> json) {
    id = json['id'];
    grpId = json['grpId'];
    lastMsg = json['lastMsg'];
    lastUser = json['lastUser'];
    delMsg = json['delMsg'];
    datetime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(json['datetime'].toString()),
            isUtc: true)
        .toLocal();
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['grpId'] = this.grpId;
    data['lastMsg'] = this.lastMsg;
    data['lastUser'] = this.lastUser;
    data['delMsg'] = this.delMsg;
    data['datetime'] = this.datetime.millisecondsSinceEpoch;
    return data;
  }

  GroupDialogueModel.fromGrpMessage(GroupMessageModel gm) {
    this.id = int.parse(gm.id);
    this.grpId = gm.grpId;
    this.lastMsg = gm.msg;
    this.lastUser = gm.fromAlias != null && gm.fromAlias.length > 0
        ? gm.fromAlias
        : gm.fromId;
    this.delMsg = 0;
    this.datetime = gm.datetime;
  }
}
