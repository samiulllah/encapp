import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encapp/Models/group_message.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/group_chat.dart';
import 'package:encapp/Screens/widgets/ChatImage/PhotoDetail.dart';
import 'package:encapp/Screens/widgets/GroupMediaMsgs/ChatAudio/MediaShare.dart';
import 'package:one_context/one_context.dart';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class ImageItem extends StatefulWidget {
  GroupMessageModel msg;
  bool iamSender;
  Function callback;
  ImageItem({this.msg, this.iamSender, this.callback});
  @override
  _ImageItemState createState() =>
      _ImageItemState(msg: msg, iamSender: iamSender);
}

class _ImageItemState extends State<ImageItem> {
  String baseUrl = 'http://newmatrix.global';
  GroupChatProvider chatProvider;
  GroupMessageModel msg;
  bool iamSender;
  bool dou = false;
  int attempts = 0;
  String progress;
  bool p = false;

  init() {
    chatProvider =
        Provider.of<GroupChatProvider>(OneContext().context, listen: false);
    if (iamSender) {
      if (msg.uploaded != "1") {
        upload();
      }
    } else {
      if (msg.loaded == "0") {
        download();
      }
    }
  }

  upload() async {
    if (attempts < 3) {
      setState(() {
        dou = true;
      });
      String url = await uploadFile(msg.localUrl);
      attempts++;
      // create msg to emit
      if (url != null) {
        setState(() {
          msg.url = url;
          msg.uploaded = "1";
          msg.loaded = "1";
        });
        // save to my local
        await chatProvider.updateMsg(msg);
      } else {
        upload();
      }
      if (mounted)
        setState(() {
          dou = false;
        });
    }
  }

  download() async {
    if (attempts < 3) {
      setState(() {
        dou = true;
      });
      // update local msg on success
      String localPath = await downloadFile(msg.url);
      print("downloaded file is $localPath");
      if (localPath != null) {
        setState(() {
          msg.localUrl = localPath;
          msg.loaded = "1";
        });
        await chatProvider.updateMsg(msg);
      }
      setState(() {
        dou = false;
      });
      attempts++;
    }
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  _ImageItemState({this.msg, this.iamSender});
  @override
  Widget build(BuildContext context) {
    final cp = context.watch<GroupChatProvider>();
    return Material(
      color: msg.selected ? Colors.grey.withOpacity(.4) : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (msg.delMsg != 1) {
            if (chatProvider.selection) {
              chatProvider.selectMsg(int.parse(msg.id));
            }
          }
        },
        onLongPress: () {
          if (msg.delMsg != 1) {
            if (!chatProvider.selection) {
              chatProvider.selectMsg(int.parse(msg.id));
            }
          }
        },
        child: Container(
          margin: iamSender
              ? EdgeInsets.only(right: 10, top: 10)
              : EdgeInsets.only(left: 10, top: 10),
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              iamSender
                  ? Container(
                      margin: EdgeInsets.only(right: 5),
                      alignment: Alignment.centerRight,
                      child: Text(msg.fromAlias,
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold)),
                    )
                  : otherName(),
              SizedBox(
                height: 10,
              ),
              msg.delMsg == 1
                  ? Container(
                      margin: EdgeInsets.only(left: 20),
                      alignment: iamSender
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text(
                        'Picture removed',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  : Row(
                      children: [
                        if (iamSender) Spacer(),
                        Container(
                          width: MediaQuery.of(context).size.width * .75,
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          color: Colors.black.withOpacity(.4),
                          child: Row(
                            children: [
                              GestureDetector(
                                  onTap: () {
                                    if (msg.loaded == "1") {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => PhotoDetail(
                                                f: new File(msg.localUrl))),
                                      );
                                    }
                                  },
                                  child: msg.loaded == "1"
                                      ? imageHolder(Image.file(
                                          new File(msg.localUrl),
                                          fit: BoxFit.fill,
                                        ))
                                      : iconHolder(Icons.image_outlined)),
                              SizedBox(
                                width: 10,
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.white60,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (msg.loaded == "1") {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => PhotoDetail(
                                              f: new File(msg.localUrl))),
                                    );
                                  }
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      msg.loaded == "1"
                                          ? "Image"
                                          : iamSender
                                              ? "Image"
                                              : "Download image",
                                      style: TextStyle(color: Colors.white60),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      "15kb",
                                      style: TextStyle(color: Colors.white60),
                                    )
                                  ],
                                ),
                              ),
                              Spacer(),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.white60,
                              ),
                              SizedBox(
                                width: 15,
                              ),
                              !dou
                                  ? iamSender
                                      ? msg.uploaded == "1"
                                          ? GestureDetector(
                                              onTap: () async {
                                                widget.callback();
                                                await Navigator.of(context)
                                                    .push(
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          MediaShareWithScreen(
                                                            msg: msg,
                                                          )),
                                                )
                                                    .then((value) {
                                                  widget.callback();
                                                });
                                              },
                                              child: Icon(
                                                Icons.share_outlined,
                                                color: Colors.white,
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: () {
                                                attempts = 0;
                                                upload();
                                              },
                                              child: Icon(
                                                Icons.upload_outlined,
                                                color: Colors.white,
                                              ))
                                      : msg.loaded == "1"
                                          ? Icon(
                                              Icons.share_outlined,
                                              color: Colors.white,
                                            )
                                          : GestureDetector(
                                              onTap: () {
                                                attempts = 0;
                                                download();
                                              },
                                              child: Icon(
                                                Icons.download_outlined,
                                                color: Colors.white,
                                              ))
                                  : p
                                      ? Text(
                                          progress,
                                          style: TextStyle(
                                              color: Colors.cyan, fontSize: 11),
                                        )
                                      : SpinKitCircle(
                                          color: Colors.cyan,
                                          size: 15,
                                        ),
                              SizedBox(
                                width: 15,
                              )
                            ],
                          ),
                        ),
                        if (!iamSender) Spacer(),
                      ],
                    ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment:
                    iamSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    '5d',
                    style: TextStyle(color: Colors.blue, fontSize: 11),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(msg.getDateTimeClause()[1],
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                  SizedBox(
                    width: 5,
                  ),
                  if (iamSender)
                    Icon(
                      msg.sent == '1' ? Icons.check : Icons.access_time,
                      color: msg.read == 1 ? Colors.green : Colors.blue,
                      size: msg.sent == '1' ? 18 : 12,
                    ),
                  SizedBox(
                    width: 10,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget otherName() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 5,
        ),
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.cyan, width: 2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                bottomRight: Radius.circular(5),
              )),
        ),
        SizedBox(
          width: 10,
        ),
        Text(msg.fromAlias != null ? msg.fromAlias : msg.fromId,
            style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
        SizedBox(
          width: 10,
        ),
      ],
    );
  }

  Widget imageHolder(Image img) {
    return Container(
      width: 35,
      height: 35,
      child: ClipRRect(borderRadius: BorderRadius.circular(8.0), child: img),
    );
  }

  Widget iconHolder(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.grey.withOpacity(.3),
          borderRadius: BorderRadius.all(Radius.circular(10))),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }

  uploadFile(String path) async {
    try {
      Response response;

      Dio dio = new Dio();
      String uploadurl = "$baseUrl/sendImage.php";
      FormData formdata = FormData.fromMap({
        "file": await MultipartFile.fromFile(path, filename: basename(path)),
      });
      response = await dio.post(
        uploadurl,
        data: formdata,
        onSendProgress: (int sent, int total) {
          String percentage = (sent / total * 100).toStringAsFixed(2);
          if (!p)
            setState(() {
              p = true;
            });
          setState(() {
            progress = percentage + "%";
          });
        },
      );
      setState(() {
        p = false;
      });
      if (response.statusCode == 200) {
        print("upload response = ${response.data}");
        Map map = jsonDecode(response.data.toString());
        if (map['success'] == "1") {
          return map['url'];
        } else {
          return null;
        }
      } else {
        print("Error during connection to server.");
        return null;
      }
    } catch (e) {
      print("Error uploading file $e");
      return null;
    }
  }

  downloadFile(String urlOfFileToDownload) async {
    print("starting to downalod $urlOfFileToDownload ....");
    Dio dio = Dio();
    try {
      var tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      String filename =
          (DateTime.now().millisecondsSinceEpoch ~/ 10000).toString() +
              urlOfFileToDownload.split('.')[1];
      // print("path = ${'$tempPath/$filename'}");
      var res = await dio.download(urlOfFileToDownload, '$tempPath/$filename',
          onReceiveProgress: (received, total) {
        int percentage = ((received / total) * 100).floor();
        if (percentage > 0) {
          if (!p) {
            setState(() {
              p = true;
            });
          }
          setState(() {
            progress = "$percentage%";
          });
        }
      });
      setState(() {
        p = false;
      });
      // as file is downloaded
      //print("Downloaded file response = ${res.toString()}");
      return '$tempPath/$filename';
    } catch (e) {
      print("Error downloading file $e");
      setState(() {
        p = false;
      });
      return null;
    }
  }
}
