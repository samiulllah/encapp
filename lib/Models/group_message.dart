import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';

class GroupMessageModel {
  String id, sl_id;
  String grpId;
  String msg;
  String fromId;
  String fromAlias;
  int favourite;
  DateTime datetime;
  List<ToPpl> toPpl;
  int read;
  bool selected;
  int replyId, delMsg;
  int type = 0;
  String msgType, url, loaded, uploaded, localUrl, sent;

  GroupMessageModel(
      {this.grpId,
      this.msg,
      this.fromId,
      this.fromAlias,
      this.favourite,
      this.toPpl,
      this.read,
      this.replyId,
      this.msgType,
      this.localUrl}) {
    delMsg = 0;
    this.url = '';
    this.sent = '0';
    this.loaded = "1";
    this.uploaded = "0";
    var rng = new Random();
    this.id = ((DateTime.now().millisecondsSinceEpoch ~/ 100) +
            (DateTime.now().add(Duration(days: rng.nextInt(100))).microsecond ~/
                1000))
        .toString();
    this.datetime = DateTime.now();
    sl_id = id;
  }

  GroupMessageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    grpId = json['grpId'];
    msg = json['msg'];
    fromId = json['from_id'];
    fromAlias = json['from_alias'];
    replyId = json['replyId'];
    favourite = int.parse(json['favourite'].toString());
    read = int.parse(json['read'].toString());
    delMsg = int.parse(json['delMsg'].toString());
    msgType = json['msgType'];
    url = json['url'];
    localUrl = json['localUrl'];
    uploaded = json['uploaded'];
    loaded = json['loaded'];
    sent = json['sent'];
    sl_id = json['sl_id'].toString();
    datetime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(json['datetime'].toString()),
            isUtc: true)
        .toLocal();
    if (json['to_ppl'] != null) {
      toPpl = new List<ToPpl>();
      json['to_ppl'].forEach((v) {
        toPpl.add(new ToPpl.fromJson(v));
      });
    }

    selected = false;
  }
  GroupMessageModel.fromJsonDB(Map<String, dynamic> json) {
    id = json['id'].toString();
    grpId = json['grpId'];
    msg = json['msg'];
    fromId = json['from_id'];
    fromAlias = json['from_alias'];
    replyId = int.parse(json['replyId'].toString());
    favourite = int.parse(json['favourite'].toString());
    read = int.parse(json['read'].toString());
    delMsg = int.parse(json['delMsg'].toString());
    msgType = json['msgType'];
    url = json['url'];
    localUrl = json['localUrl'];
    uploaded = json['uploaded'];
    loaded = json['loaded'];
    sent = json['sent'];
    sl_id = json['sl_id'].toString();
    datetime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(json['datetime'].toString()),
            isUtc: true)
        .toLocal();
    if (json['to_ppl'] != null) {
      toPpl = new List<ToPpl>();
      var li = jsonDecode(json['to_ppl'].toString());
      li.forEach((v) {
        toPpl.add(new ToPpl.fromJson(v as Map));
      });
    }
    selected = false;
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['grpId'] = this.grpId;
    data['msg'] = this.msg;
    data['from_id'] = this.fromId;
    data['from_alias'] = this.fromAlias;
    data['favourite'] = this.favourite;
    data['replyId'] = this.replyId;
    data['datetime'] = this.datetime.millisecondsSinceEpoch;
    data['read'] = this.read;
    data['delMsg'] = this.delMsg;
    data['sent'] = this.sent;
    if (this.toPpl != null) {
      data['to_ppl'] = this.toPpl.map((v) => v.toJson()).toList();
    }
    data['msgType'] = this.msgType;
    data['url'] = this.url;
    data['localUrl'] = this.localUrl;
    data['uploaded'] = this.uploaded;
    data['loaded'] = this.loaded;
    data['sl_id'] = this.sl_id;
    return data;
  }

  Map<String, dynamic> toJsonLocal() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['grpId'] = this.grpId;
    data['msg'] = this.msg;
    data['from_id'] = this.fromId;
    data['from_alias'] = this.fromAlias;
    data['favourite'] = this.favourite;
    data['replyId'] = this.replyId;
    data['datetime'] = this.datetime.millisecondsSinceEpoch;
    data['read'] = this.read;
    data['sent'] = this.sent;
    data['delMsg'] = this.delMsg;
    if (this.toPpl != null) {
      data['to_ppl'] = this.toPpl.map((v) => v.toJson()).toList();
      data['to_ppl'] = jsonEncode(data['to_ppl']);
    }
    data['msgType'] = this.msgType;
    data['url'] = this.url;
    data['localUrl'] = this.localUrl;
    data['uploaded'] = this.uploaded;
    data['loaded'] = this.loaded;
    data['sl_id'] = this.sl_id.toString();
    return data;
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

class ToPpl {
  String id;
  String alias;

  ToPpl({this.id, this.alias});

  ToPpl.fromJson(Map<String, dynamic> json) {
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
