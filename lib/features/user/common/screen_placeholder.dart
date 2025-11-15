import 'package:flutter/material.dart';

class ScreenPlaceholder extends StatelessWidget {
  final String title;
  const ScreenPlaceholder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
    );
  }
}