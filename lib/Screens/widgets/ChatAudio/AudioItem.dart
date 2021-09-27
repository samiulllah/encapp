import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encapp/Models/message.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Screens/widgets/ChatAudio/MediaShare.dart';
import 'package:media_info/media_info.dart';
import 'package:one_context/one_context.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../ShareWith.dart';

typedef _Fn = void Function();
int duration = 0;

class AudioItem extends StatefulWidget {
  MessageModel msg;
  bool iamSender;
  AudioItem({this.msg, this.iamSender});

  @override
  _AudioItemState createState() =>
      _AudioItemState(msg: msg, iamSender: iamSender);
}

class _AudioItemState extends State<AudioItem> {
  // item data  ****************************
  ChatProvider chatProvider;
  String baseUrl = 'http://newmatrix.global';
  final MediaInfo _mediaInfo = MediaInfo();
  MessageModel msg;
  bool playing = false;
  bool lastPlay = false;
  bool iamSender;
  bool dou = false;
  int attempts = 0;
  String progress;
  bool p = false;
  // player data ****************************
  int pos = 0;
  int seconds = 0;
  int min = 0;
  int rmin = 0, rsec = 0;
  bool submit = false, uploadInProg = false;
  String filePath = null;
  AudioPlayer audioPlayer;
  // constructor
  _AudioItemState({this.msg, this.iamSender});

  init() {
    audioPlayer = new AudioPlayer();
    chatProvider =
        Provider.of<ChatProvider>(OneContext().context, listen: false);
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
        uploadInProg = true;
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
        // save to my local that it's uploaded
        await Provider.of<ChatProvider>(OneContext().context, listen: false)
            .updateMsg(msg);
      } else {
        upload();
      }
      setState(() {
        uploadInProg = false;
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
        await Provider.of<ChatProvider>(OneContext().context, listen: false)
            .updateMsg(msg);
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
    if (msg.localUrl != null && msg.localUrl.length > 5) getDuration();
    super.initState();
  }

  @override
  void dispose() {
    audioPlayer.stop();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ChatProvider>();
    return Material(
      color: msg.selected ? Colors.grey.withOpacity(.4) : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (msg.delMsg != 1) {
            if (chatProvider.selection) {
              chatProvider.selectMsg(msg.id);
            }
          }
        },
        onLongPress: () {
          if (msg.delMsg != 1) {
            if (!chatProvider.selection) {
              chatProvider.selectMsg(msg.id);
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
                        'voice removed',
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
                              msg.loaded == "1"
                                  ? playButton()
                                  : iconHolder(Icons.mic_none_outlined),
                              SizedBox(
                                width: 5,
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.white60,
                              ),
                              msg.loaded == "1"
                                  ? Column(
                                      children: [
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              .4,
                                          height: 25,
                                          child: Slider(
                                            value: pos + 0.0,
                                            min: 0.0,
                                            max: duration + 0.0,
                                            onChanged: seek,
                                            //divisions: 100
                                          ),
                                        ),
                                        Text(
                                          '${rmin.toString().padLeft(2, '0')}:${rsec.toString().padLeft(2, '0')}/${min.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 11),
                                        )
                                      ],
                                    )
                                  : Container(
                                      width: MediaQuery.of(context).size.width *
                                          .4,
                                      child: Column(
                                        children: [
                                          Text(
                                            msg.loaded == "1"
                                                ? "Audio"
                                                : iamSender
                                                    ? "Audio"
                                                    : "Download audio",
                                            style: TextStyle(
                                                color: Colors.white60),
                                          ),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            "15kb",
                                            style: TextStyle(
                                                color: Colors.white60),
                                          )
                                        ],
                                      ),
                                    ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.white60,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                child: Center(
                                  child: !dou
                                      ? iamSender
                                          ? msg.uploaded == "1"
                                              ? GestureDetector(
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                          builder: (_) =>
                                                              MediaShareWithScreen(
                                                                msg: msg,
                                                              )),
                                                    );
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
                                                  color: Colors.cyan,
                                                  fontSize: 11),
                                            )
                                          : SpinKitCircle(
                                              color: Colors.cyan,
                                              size: 15,
                                            ),
                                ),
                              ),
                              SizedBox(
                                width: 5,
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
                      color: msg.sent == '1' && msg.read == 1
                          ? Colors.green
                          : Colors.blue,
                      size: msg.uploaded == '1' ? 18 : 14,
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

  getDuration() async {
    try {
      print("local usrl = ${msg.localUrl}");
      final Map<String, dynamic> mediaInfo =
          await _mediaInfo.getMediaInfo(msg.localUrl);
      int millis = mediaInfo['durationMs'];
      millis = millis ~/ 1000;
      int s = millis % 60;
      millis ~/= 60;
      int m = millis % 60;
      setState(() {
        min = m;
        seconds = s;
      });
    } catch (e) {
      print('Error getting media info');
    }
  }

  Future<void> setPos(int d) async {
    if (d > duration) {
      d = duration;
    }
    setState(() {
      pos = d;
      rmin = Duration(milliseconds: d).inMinutes;
      rsec = Duration(milliseconds: d).inSeconds;
    });
  }

  Future<void> seek(double d) async {
    await audioPlayer.seek(Duration(milliseconds: d.floor()));
    await setPos(d.floor());
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

  Widget playButton() {
    return GestureDetector(
        onTap: () async {
          if (!playing && !lastPlay) {
            // play
            await audioPlayer.play(msg.localUrl,
                isLocal: true,
                volume: 1.0,
                respectSilence: false,
                stayAwake: true);
            print('duration is ${await audioPlayer.onDurationChanged.first}');
            audioPlayer.onDurationChanged.listen((event) {
              Duration d = Duration(milliseconds: event.inMilliseconds);
              setState(() {
                duration = d.inMilliseconds;
                min = d.inMinutes;
                seconds = d.inSeconds;
                rmin = 0;
                rsec = 0;
              });
            });
            audioPlayer.onAudioPositionChanged.listen((event) {
              setPos(event.inMilliseconds);
            });
            audioPlayer.onPlayerCompletion.listen((event) {
              setState(() {
                playing = false;
                lastPlay = false;
              });
            });
            setState(() {
              playing = true;
              lastPlay = true;
            });
          } else if (playing && lastPlay) {
            // already playing just stop it
            audioPlayer.pause();
            setState(() {
              playing = false;
              lastPlay = true;
            });
          } else if (!playing && lastPlay) {
            audioPlayer.resume();
            setState(() {
              playing = true;
              lastPlay = true;
            });
          }
        },
        child: Icon(
          playing ? Icons.pause_circle_outline : Icons.play_circle_outline,
          size: 40,
          color: Colors.cyan,
        ));
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
    print("starting to download audio $urlOfFileToDownload ....");
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
