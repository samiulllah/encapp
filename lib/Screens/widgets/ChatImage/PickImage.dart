import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:encapp/Providers/chat.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';

class PickImage extends StatefulWidget {
  File img;
  PickImage({this.img});

  @override
  _PickImageState createState() => _PickImageState();
}

class _PickImageState extends State<PickImage> {
  bool submit = false;
  String baseUrl = 'http://newmatrix.global';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xff040d5a),
        body: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).size.height * .2,
                  child: Image.file(
                    widget.img,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 2,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                Positioned(
                    bottom: 30,
                    right: 20,
                    child: GestureDetector(
                      onTap: () async {
                        setState(() {
                          submit = true;
                        });
                        DateTime dt = await getCurrentTimeStamp();
                        print("got server tstamp as $dt");
                        await Provider.of<ChatProvider>(OneContext().context,
                                listen: false)
                            .sendMediaMsg(
                                widget.img.path, dt, "1", "sent image");
                        await Provider.of<ChatProvider>(OneContext().context,
                                listen: false)
                            .fetchChat(await Provider.of<ChatProvider>(
                                    OneContext().context,
                                    listen: false)
                                .convid);
                        setState(() {
                          submit = false;
                        });
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        child: Center(
                          child: Icon(
                            Icons.send,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    )),
                if (submit)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.black.withOpacity(.7),
                    child: Center(
                      child: SpinKitCircle(
                        color: Colors.cyanAccent,
                      ),
                    ),
                  )
              ],
            )));
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

_imgFromCamera(_picker) async {
  XFile image =
      await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
  return image != null ? new File(image.path) : null;
}

_imgFromGallery(_picker) async {
  XFile image =
      await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
  return image != null ? new File(image.path) : null;
}

void showImagePicker(BuildContext context) async {
  File _image = null;
  final ImagePicker _picker = ImagePicker();
  await showModalBottomSheet(
      backgroundColor: Color(0xff040d5a),
      context: OneContext().context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                    leading: new Icon(
                      Icons.photo_library,
                      color: Colors.white,
                    ),
                    title: new Text(
                      'Photo Library',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      _image = await _imgFromGallery(_picker);
                      Navigator.of(context, rootNavigator: true).pop();
                      if (_image != null) {
                        await Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                              builder: (_) => PickImage(img: _image)),
                        )
                            .then((value) async {
                          ChatProvider chatProvider =
                              Provider.of<ChatProvider>(context, listen: false);
                          await chatProvider.fetchChat(chatProvider.convid);
                        });
                      }
                    }),
                new ListTile(
                  leading: new Icon(
                    Icons.photo_camera,
                    color: Colors.white,
                  ),
                  title: new Text(
                    'Camera',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    _image = await _imgFromCamera(_picker);
                    Navigator.of(context, rootNavigator: true).pop();
                    if (_image != null) {
                      await Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                            builder: (_) => PickImage(img: _image)),
                      )
                          .then((value) async {
                        ChatProvider chatProvider =
                            Provider.of<ChatProvider>(context, listen: false);
                        await chatProvider.fetchChat(chatProvider.convid);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      });
}
