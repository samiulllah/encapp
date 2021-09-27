import 'dart:math';

import 'package:intl/intl.dart';

class MessageModel {
  int id, sl_id;
  String convid;
  String fromId;
  String toId;
  String fromAlias;
  String toAlias;
  String msg;
  int read;
  bool selected;
  int favourite, replyId, delMsg;
  DateTime datetime;
  String msgType, url, loaded, uploaded, localUrl, sent;
  MessageModel(
      {this.fromId,
      this.toId,
      this.msg,
      this.datetime,
      this.read,
      this.convid,
      this.fromAlias,
      this.toAlias,
      this.favourite,
      this.replyId,
      this.delMsg,
      this.msgType,
      this.localUrl}) {
    this.url = '';
    this.sent = '0';
    this.loaded = "1";
    this.uploaded = "0";
    var rng = new Random();
    this.id = ((DateTime.now().millisecondsSinceEpoch ~/ 100) +
        (DateTime.now().add(Duration(days: rng.nextInt(100))).microsecond ~/
            1000));
    sl_id = id;
  }

  MessageModel.fromJsonDB(Map<String, dynamic> json) {
    id = json['id'];
    convid = json['convid'];
    fromId = json['from_id'];
    toId = json['to_id'];
    fromAlias = json['from_alias'];
    toAlias = json['to_alias'];
    toId = json['to_id'];
    msg = json['msg'];
    replyId = json['replyId'];
    delMsg = json['delMsg'];
    msgType = json['msgType'];
    url = json['url'];
    localUrl = json['localUrl'];
    uploaded = json['uploaded'];
    loaded = json['loaded'];
    sl_id = json['sl_id'];
    sent = json['sent'];
    favourite = int.parse(json['favourite'].toString());
    read = int.parse(json['read'].toString());
    datetime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(json['datetime'].toString()),
            isUtc: true)
        .toLocal();
    selected = false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['convid'] = this.convid;
    data['from_id'] = this.fromId;
    data['to_id'] = this.toId;
    data['msg'] = this.msg;
    data['datetime'] = this.datetime.millisecondsSinceEpoch;
    data['read'] = this.read;
    data['from_alias'] = this.fromAlias;
    data['to_alias'] = this.toAlias;
    data['favourite'] = this.favourite;
    data['replyId'] = this.replyId;
    data['delMsg'] = this.delMsg;
    data['msgType'] = this.msgType;
    data['url'] = this.url;
    data['localUrl'] = this.localUrl;
    data['uploaded'] = this.uploaded;
    data['loaded'] = this.loaded;
    data['sent'] = this.sent;
    data['sl_id'] = this.sl_id;
    return data;
  }

  List<String> getDateTimeClause() {
    List<String> clauses = [];
    DateTime dateTime = DateTime.now();
    int dayDiff = datetime.difference(dateTime).inDays;
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

  // from msg json
  MessageModel.fromJson(Map<String, dynamic> json) {
    id = int.parse(json['id'].toString());
    convid = json['convid'];
    fromId = json['from_id'];
    toId = json['to_id'];
    fromAlias = json['from_alias'];
    toAlias = json['to_alias'];
    toId = json['to_id'];
    msg = json['msg'];
    msgType = json['msgType'];
    url = json['url'];
    localUrl = json['localUrl'];
    uploaded = json['uploaded'];
    loaded = json['loaded'];
    sent = json['sent'];
    sl_id = int.parse(json['sl_id'].toString());
    replyId = int.parse(json['replyId'].toString());
    delMsg = int.parse(json['delMsg'].toString());
    favourite = int.parse(json['favourite'].toString());
    read = int.parse(json['read'].toString());
    datetime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(json['datetime'].toString()),
            isUtc: true)
        .toLocal();
    selected = false;
  }
}
