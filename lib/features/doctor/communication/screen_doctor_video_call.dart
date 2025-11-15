import 'package:flutter/material.dart';

class ScreenDoctorVideoCall extends StatelessWidget {
  const ScreenDoctorVideoCall({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: Text('Video Call Screen', style: TextStyle(color: Colors.white))),
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              color: Colors.grey,
              child: Center(child: Text('Self View', style: TextStyle(color: Colors.white))),
            ),
          ),
        ],
      ),
    );
  }
}
