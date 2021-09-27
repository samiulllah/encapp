import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:encapp/Models/dialogues.dart';
import 'package:encapp/Models/group_message.dart';

class GroupModel {
  String grpId;
  String grpName;
  String desc;
  String ownerId;
  List<Members> members;
  DateTime datetime;
  bool groupExist;
  GroupDialogueModel gdm;
  String lastMsg;
  String lastSender;

  GroupModel({this.grpName, this.ownerId, this.members, this.desc}) {
    this.grpId = ((DateTime.now().millisecondsSinceEpoch) ~/ 10000).toString();
    datetime = DateTime.now();
  }

  GroupModel.fromJson(Map<String, dynamic> json, GroupDialogueModel d) {
    grpId = json['grpId'];
    grpName = json['grpName'];
    desc = json['desc'];
    ownerId = json['ownerId'];
    datetime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(json['datetime'].toString()))
        .toLocal();
    if (json['members'] != null) {
      members = new List<Members>();
      json['members'].forEach((v) {
        members.add(new Members.fromJson(v));
      });
    }
    gdm = d;
    getLastMsg();
    getlastSender();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['grpId'] = this.grpId;
    data['grpName'] = this.grpName;
    data['desc'] = this.desc;
    data['ownerId'] = this.ownerId;
    data['datetime'] = this.datetime.toUtc().millisecondsSinceEpoch.toString();
    if (this.members != null) {
      data['members'] = this.members.map((v) => v.toJson()).toList();
    }
    return data;
  }

  String getLastMsg() {
    if (gdm != null) {
      lastMsg = gdm.delMsg == 1 ? "message removed" : gdm.lastMsg;
    } else {
      lastMsg = ownerId;
    }
  }

  String getlastSender() {
    if (gdm != null) {
      lastSender = gdm.lastUser;
    } else {
      lastSender = 'Created by: ';
    }
  }

  List<String> getDateTimeClause() {
    List<String> clauses = [];
    DateTime dateTime = DateTime.now();
    int dayDiff = dateTime.difference(datetime).inDays;
    final f = new DateFormat('MM/dd/yyyy');
    final t = new DateFormat('hh:mma');
    if (dayDiff == 0) {
      clauses.insert(0, 'Today');
    } else if (dayDiff == 1) {
      clauses.insert(0, 'Yesterday');
    } else {
      clauses.insert(0, f.format(datetime));
    }
    clauses.insert(1, t.format(datetime));
    return clauses;
  }
}

class Members {
  String id;
  String alias;

  Members({this.id, this.alias});

  Members.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    alias = json['alias'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['alias'] = this.alias;
    return data;
  }
}
