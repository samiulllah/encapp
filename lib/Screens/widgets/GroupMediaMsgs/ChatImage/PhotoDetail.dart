import 'package:flutter/material.dart';
import 'dart:io';

import 'package:photo_view/photo_view.dart';

class PhotoDetail extends StatefulWidget {
  File f;
  PhotoDetail({this.f});
  @override
  _PhotoDetailState createState() => _PhotoDetailState();
}

class _PhotoDetailState extends State<PhotoDetail> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: PhotoView(
      imageProvider: Image.file(widget.f).image,
    ));
  }
}
