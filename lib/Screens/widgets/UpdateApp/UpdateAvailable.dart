import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:encapp/Services/user.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateAvailableScreen extends StatefulWidget {
  const UpdateAvailableScreen({Key key}) : super(key: key);

  @override
  _UpdateAvailableScreenState createState() => _UpdateAvailableScreenState();
}

class _UpdateAvailableScreenState extends State<UpdateAvailableScreen> {
  double w, h;
  String percent;
  bool started = false;
  double fraction = 0;

  init() async {
    UserService.unlockPage = context;
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    UserService.unlockPage = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: Color(0xff040d5a),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: h * .1,
            ),
            Center(
              child: Image.asset(
                'assets/update.png',
                width: w * .4,
                height: w * .4,
                fit: BoxFit.fill,
              ),
            ),
            SizedBox(
              height: h * .08,
            ),
            Center(
                child: Text(
              'Matrix',
              style: TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontFamily: 'UbuntuTitling'),
            )),
            SizedBox(
              height: h * .05,
            ),
            Center(
                child: Text(
              'Update Required!',
              style: TextStyle(
                  fontSize: 24,
                  color: Colors.deepOrangeAccent,
                  fontFamily: 'UbuntuTitling'),
            )),
            SizedBox(
              height: h * .05,
            ),
            Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Text(
                    'Please update app by clicking button below. By updating app you can enjoy new features and improved performance.',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 20,
                      wordSpacing: .1,
                      color: Colors.cyanAccent,
                    ),
                  ),
                )),
            SizedBox(
              height: h * .1,
            ),
            if (started)
              new CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 5.0,
                percent: fraction,
                center: new Text(
                  percent == null ? "0%" : "$percent",
                  style: TextStyle(color: Colors.white),
                ),
                progressColor: Colors.green,
              ),
            if (!started)
              GestureDetector(
                onTap: () async {
                  setState(() {
                    started = true;
                  });
                  String url = 'http://newmatrix.global/App/app-release.apk';
                  String filePath = await downloadFile(url);
                  if (filePath != null) {
                    await OpenFile.open(filePath);
                  } else {
                    setState(() {
                      started = false;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                  child: Text(
                    "Update",
                    style: TextStyle(
                      fontSize: 20,
                      wordSpacing: .1,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
          ],
        ));
  }

  downloadFile(String urlOfFileToDownload) async {
    Dio dio = Dio();
    try {
      var tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      String filename = 'app-release.apk';
      var res = await dio.download(urlOfFileToDownload, '$tempPath/$filename',
          onReceiveProgress: (received, total) {
        int percentage = ((received / total) * 100).floor();
        setState(() {
          fraction = (received / total);
        });
        if (percentage > 0) {
          if (!started) {
            setState(() {
              started = true;
            });
          }
          setState(() {
            percent = "$percentage%";
          });
        }
      });
      return '$tempPath/$filename';
    } catch (e) {
      print("Error downloading file $e");
      setState(() {
        started = false;
      });
      return null;
    }
  }
}
