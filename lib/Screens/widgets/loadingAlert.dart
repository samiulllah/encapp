import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:one_context/one_context.dart';

void showProgress(String title) {
  showDialog(
    context: OneContext().context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Color(0xff040d5a),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Center(
              child: SpinKitCircle(
                color: Colors.orange,
                size: 30,
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            "$title...",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontFamily: 'UbuntuTitling'),
          )
        ]),
      );
    },
  );
}
