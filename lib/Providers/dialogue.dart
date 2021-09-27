import 'package:flutter/cupertino.dart';
import 'package:encapp/Models/group.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Models/single_group_dialogues.dart';
import 'package:encapp/Providers/group.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';

import 'chat.dart';
import 'group_chat.dart';

class DialogueProvider extends ChangeNotifier {
  List<SingleGroupDialogues> dls = [];
  int noSelected = 0;

  void combineBoth(List<MessageModel> msgs, List<GroupModel> grps) async {
    await Future.delayed(Duration(seconds: 1));
    List<SingleGroupDialogues> ds = [];
    if (noSelected > 0) {
      for (MessageModel m in msgs) {
        ds.add(new SingleGroupDialogues(
            i: 0,
            s: m,
            dateTime: m.datetime,
            convid: m.convid,
            selected: getItemSelection(m.convid)));
      }
      for (GroupModel g in grps) {
        ds.add(new SingleGroupDialogues(
            i: 1,
            g: g,
            dateTime: g.datetime,
            convid: g.grpId,
            selected: getItemSelection(g.grpId)));
      }
    } else {
      for (MessageModel m in msgs) {
        ds.add(new SingleGroupDialogues(
            i: 0,
            s: m,
            dateTime: m.datetime,
            convid: m.convid,
            selected: false));
      }
      for (GroupModel g in grps) {
        ds.add(new SingleGroupDialogues(
            i: 1,
            g: g,
            dateTime: g.datetime,
            convid: g.grpId,
            selected: false));
      }
    }
    ds.sort((SingleGroupDialogues a, SingleGroupDialogues b) =>
        a.dateTime.compareTo(b.dateTime));
    ds = ds.reversed.toList();
    dls = ds;
    notifyListeners();
  }

  // get item selection
  bool getItemSelection(String convid) {
    bool s = false;
    for (SingleGroupDialogues d in dls) {
      if (d.convid == convid) {
        s = d.selected;
        break;
      }
    }
    return s;
  }

  // select by convid
  void selectItem(String convid) {
    for (int i = 0; i < dls.length; i++) {
      if (dls[i].convid == convid) {
        dls[i].selected = !dls[i].selected;
        break;
      }
    }
    getNoSelected();
    notifyListeners();
  }

  // get nos selected
  void getNoSelected() {
    noSelected = 0;
    for (SingleGroupDialogues d in dls) {
      if (d.selected) {
        noSelected = noSelected + 1;
      }
    }
  }

  // un select all
  void unSelectAll() {
    for (int i = 0; i < dls.length; i++) {
      dls[i].selected = false;
    }
    getNoSelected();
    notifyListeners();
  }

  // delete selected
  Future<void> deleteSelected() async {
    for (SingleGroupDialogues d in dls) {
      if (d.selected) {
        print("Deleting ${d.convid}");
        // single dialogue
        if (d.i == 0) {
          await Provider.of<ChatProvider>(OneContext().context, listen: false)
              .deleteConversation(id: d.convid);
        } else {
          await Provider.of<GroupChatProvider>(OneContext().context,
                  listen: false)
              .deleteConversation(id: d.g.grpId);
        }
      }
    }
    getNoSelected();
    notifyListeners();
  }
}
