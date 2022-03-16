import 'dart:async';

import 'Otpscreen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Otploading extends StatefulWidget {
  const Otploading({Key? key}) : super(key: key);

  @override
  State<Otploading> createState() => _OtploadingState();
}

class _OtploadingState extends State<Otploading> {
  @override
  void initState() {
    Timer(
      const Duration(seconds: 2),
      (() => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const Otpscreen(),
            ),
          )),
    );
    super.initState();
  }

   @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child:Center(child: Lottie.asset("assets/otploading.json"))
    );
  }

}
