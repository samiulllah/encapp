import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:encapp/Providers/user.dart';
import 'package:one_context/one_context.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';

typedef _Fn = void Function();
const theSource = AudioSource.microphone;
int duration = 0;

class RecordAudio extends StatefulWidget {
  const RecordAudio({Key key}) : super(key: key);

  @override
  _RecordAudioState createState() => _RecordAudioState();
}

class _RecordAudioState extends State<RecordAudio> {
  String baseUrl = 'http://newmatrix.global';
  Codec _codec = Codec.aacMP4;
  String _mPath;
  FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mplaybackReady = false;
  StreamSubscription _mPlayerSubscription;
  int pos = 0;
  int seconds = 0;
  int min = 0;
  int rmin = 0, rsec = 0;
  Timer t;
  bool submit = false;
  String filePath = null;
  bool preparing = true;

  @override
  void initState() {
    _mPlayer.openAudioSession().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
        preparing = false;
      });
    });
    t = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        if (seconds == 60) {
          setState(() {
            min++;
            seconds = 0;
          });
        } else {
          setState(() {
            seconds++;
          });
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _mPlayer.closeAudioSession();
    _mPlayer = null;
    cancelPlayerSubscriptions();
    _mRecorder.closeAudioSession();
    _mRecorder = null;
    t.cancel();
    super.dispose();
  }

  void cancelPlayerSubscriptions() {
    if (_mPlayerSubscription != null) {
      _mPlayerSubscription.cancel();
      _mPlayerSubscription = null;
    }
  }

  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await _mRecorder.openAudioSession();
    await _mPlayer.setSubscriptionDuration(Duration(milliseconds: 50));
    _mPlayerSubscription = _mPlayer.onProgress.listen((e) {
      setPos(e.position.inMilliseconds);
      setState(() {});
    });
    if (!await _mRecorder.isEncoderSupported(_codec) && kIsWeb) {
      _codec = Codec.opusWebM;
      _mPath = 'tau_file.webm';
      if (!await _mRecorder.isEncoderSupported(_codec) && kIsWeb) {
        _mRecorderIsInited = true;
        return;
      }
    }
    _mRecorderIsInited = true;
    record();
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
    await _mPlayer.seekToPlayer(Duration(milliseconds: d.floor()));
    await setPos(d.floor());
  }

  // ----------------------  Here is the code for recording and playback -------
  void record() {
    _mPath = '${DateTime.now().millisecondsSinceEpoch}tau_file.mp4';
    _mRecorder
        .startRecorder(
      toFile: _mPath,
      codec: _codec,
      audioSource: theSource,
    )
        .then((value) {
      setState(() {});
    });
  }

  void stopRecorder() async {
    await _mRecorder.stopRecorder().then((value) {
      setState(() {
        //var url = value;
        filePath = value;
        _mplaybackReady = true;
        if (t.isActive) t.cancel();
      });
    });
  }

  void play() async {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder.isStopped &&
        _mPlayer.isStopped);
    Duration d = await _mPlayer.startPlayer(
        fromURI: _mPath,
        //codec: kIsWeb ? Codec.opusWebM : Codec.aacADTS,
        whenFinished: () {
          setState(() {});
        });
    setState(() {
      duration = d.inMilliseconds;
      min = d.inMinutes;
      seconds = d.inSeconds;
      rmin = 0;
      rsec = 0;
    });
  }

  void stopPlayer() {
    _mPlayer.stopPlayer().then((value) {
      setState(() {});
    });
  }

  _Fn getRecorderFn() {
    if (!_mRecorderIsInited || !_mPlayer.isStopped) {
      return null;
    }
    return stopRecorder;
  }

  _Fn getPlaybackFn() {
    if (!_mPlayerIsInited || !_mplaybackReady || !_mRecorder.isStopped) {
      return null;
    }
    return _mPlayer.isStopped ? play : stopPlayer;
  }

  @override
  Widget build(BuildContext context) {
    Widget makeBody() {
      return preparing
          ? Center(
              child: Text(
              "Please wait....Starting shortly",
              style: TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 10,
                ),
                if (!preparing)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      !_mRecorder.isRecording
                          ? GestureDetector(
                              onTap: getPlaybackFn(),
                              child: Icon(
                                _mPlayer.isPlaying
                                    ? Icons.pause_circle_outline
                                    : Icons.play_circle_outline,
                                size: 40,
                                color: Colors.cyan,
                              ))
                          : Text(
                              '${min.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                              style: TextStyle(color: Colors.white60),
                            ),
                      SizedBox(
                        width: 10,
                      ),
                      _mRecorder.isStopped
                          ? Slider(
                              value: pos + 0.0,
                              min: 0.0,
                              max: duration + 0.0,
                              onChanged: seek,
                              //divisions: 100
                            )
                          : Expanded(
                              child: Center(
                                child: Text(
                                  "Recording...",
                                  style: TextStyle(
                                      color: Colors.cyan, fontSize: 15),
                                ),
                              ),
                            ),
                      Spacer(),
                      if (_mRecorder.isStopped && !submit)
                        GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Icon(
                              Icons.delete,
                              size: 30,
                              color: Colors.red,
                            )),
                      SizedBox(
                        width: 15,
                      ),
                      !submit
                          ? GestureDetector(
                              onTap: () async {
                                if (_mRecorder.isStopped) {
                                  setState(() {
                                    submit = true;
                                  });
                                  ChatProvider cp = Provider.of<ChatProvider>(
                                      OneContext().context,
                                      listen: false);
                                  DateTime dt = await getCurrentTimeStamp();
                                  await cp.sendMediaMsg(
                                      filePath, dt, "2", "sent voice");
                                  await cp.fetchChat(cp.convid);
                                  setState(() {
                                    submit = false;
                                  });
                                  Navigator.of(context).pop();
                                } else {
                                  getRecorderFn()();
                                }
                              },
                              child: Icon(
                                _mRecorder.isRecording
                                    ? Icons.stop_circle_outlined
                                    : Icons.send,
                                size: _mRecorder.isStopped ? 30 : 45,
                                color: Colors.blue,
                              ))
                          : SpinKitCircle(
                              color: Colors.cyan,
                              size: 25,
                            ),
                      SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                if (_mRecorder.isStopped)
                  Center(
                    child: Text(
                      '${rmin.toString().padLeft(2, '0')}:${rsec.toString().padLeft(2, '0')}/${min.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  )
              ],
            );
    }

    return Scaffold(
      backgroundColor: Color(0xff040d5a),
      body: makeBody(),
    );
  }

  getCurrentTimeStamp() async {
    DateTime dt = null;
    try {
      var response = await Dio().get('$baseUrl/serverTime.php');
      Map json = jsonDecode(response.data.toString());
      dt = DateTime.fromMillisecondsSinceEpoch(
              int.parse(json['tstamp'].toString()))
          .toLocal();
      return dt;
    } catch (e) {
      print("Error getting server datetime");
      return dt;
    }
  }
}

void showRecorder(BuildContext context) async {
  await showModalBottomSheet(
      backgroundColor: Color(0xff040d5a),
      context: OneContext().context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                  title: Container(
                      height: 80,
                      width: MediaQuery.of(context).size.width,
                      child: RecordAudio()),
                ),
              ],
            ),
          ),
        );
      });
}
