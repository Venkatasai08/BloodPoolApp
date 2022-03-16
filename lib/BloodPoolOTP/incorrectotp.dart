import 'dart:async';

import 'package:bloodpool/BloodPoolOTP/NumberLogin.dart';
import 'package:bloodpool/registration_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Incorrect extends StatefulWidget {
  const Incorrect({Key? key}) : super(key: key);

  @override
  State<Incorrect> createState() => _IncorrectState();
}

class _IncorrectState extends State<Incorrect> {
  @override
  void initState() {
    Timer(
      const Duration(seconds: 4),
      (() => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const RegisterScreen(),
            ),
          )),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment:MainAxisAlignment.center,
          children: [
            Lottie.asset("assets/otploading.json"),
            Text("Entered otp was wrong try to login with otherway")
          ],
        ),
      ),
    );
  }
}
