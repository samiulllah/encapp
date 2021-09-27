import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:encapp/main.dart';

import 'SetPasswordPage.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final introKey = GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SetPasswordPage()),
    );
  }

  Widget _buildImage(String assetName, [double width = 350]) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Image.asset(
        'assets/$assetName',
        width: MediaQuery.of(context).size.width,
        height: 300,
        fit: BoxFit.contain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 16.0, color: Colors.white);

    const pageDecoration = const PageDecoration(
      titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700, color: Colors.white, fontSize: 22),
      bodyTextStyle: bodyStyle,
      descriptionPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Color(0xff040d5a),
      imagePadding: EdgeInsets.zero,
    );
    return Scaffold(
      backgroundColor: Color(0xff040d5a),
      body: IntroductionScreen(
        key: introKey,
        globalBackgroundColor: Color(0xff040d5a),

        pages: [
          PageViewModel(
            title: "AES Encryption",
            body:
                "Protect your message & call data from attacks by using AES encryption standard.",
            image: _buildImage('encryption.png'),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Brute Force Protection",
            body: "Safeguard against online and offline brute-force attacks.",
            image: _buildImage('security.png'),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Perfect Forward Secrecy",
            body:
                "Each message and call is uniquely encrypted with rolling encryption keys.",
            image: _buildImage('peer_to_peer1.png'),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Encrypted Calls & Voice Notes",
            body:
                "Self-Destructing Messages.\nRedact Sent Messages\nSend Encrypted Photos.",
            image: _buildImage('lock8.png'),
            decoration: pageDecoration,
          ),
        ],
        onDone: () => _onIntroEnd(context),
        onSkip: () => _onIntroEnd(context), // You can override onSkip callback
        showSkipButton: true,
        skipFlex: 0,
        nextFlex: 0,
        //rtl: true, // Display as right-to-left
        skip: const Text('Skip'),
        next: const Icon(Icons.arrow_forward),
        done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
        curve: Curves.fastLinearToSlowEaseIn,
        controlsMargin: const EdgeInsets.all(16),
        controlsPadding: kIsWeb
            ? const EdgeInsets.all(12.0)
            : const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
        dotsDecorator: const DotsDecorator(
          size: Size(10.0, 10.0),
          color: Color(0xFFBDBDBD),
          activeSize: Size(22.0, 10.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
        ),
        dotsContainerDecorator: const ShapeDecoration(
          color: Color(0xff0e1145),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
        ),
      ),
    );
  }
}
