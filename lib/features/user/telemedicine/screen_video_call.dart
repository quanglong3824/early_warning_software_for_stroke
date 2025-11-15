import 'package:flutter/material.dart';

class ScreenVideoCall extends StatefulWidget {
  const ScreenVideoCall({super.key});

  @override
  State<ScreenVideoCall> createState() => _ScreenVideoCallState();
}

class _ScreenVideoCallState extends State<ScreenVideoCall> {
  bool _isMicOn = true;
  bool _isCameraOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Doctor's video (full screen)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCC7InJy9elOn9jBfDYh76kUOD46xxM6HjdNK5PQDX_Ya_YVkNByLrWNFGPG76hAhOD0LnT4VkpeLA0TbvwAw53RNgXmPwJFA3Bhf5m3J6rArC4cowD1G5q3wkmtOXYjVU9r8Rvo0pF7ox5__3vSsDiHKpNAeZM49yFyac8sigRXvgXnm9PPYd0a4XTYGcf-SVvbRdspbErsc-c0xjcG0RXOW68vPdCosfYll7OnoaOLtTKvxkSG3agXyWH30QdTq-cBUHa02c1r9A'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Gradient overlays
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 192,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
          ),
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.wifi, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('10:25', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                  Column(
                    children: const [
                      Text('Dr. Minh Anh', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Neurologist', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                  const Text('02:35', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // User's video (PIP)
          Positioned(
            top: 112,
            right: 16,
            child: Container(
              width: 112,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                image: const DecorationImage(
                  image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCi4LQ3aq8J8hPY3yfbTyreJGFp9UF8Id4Fd4p_Jp7JlFQsMfcaULQgQQKVaze8op7Kb3DlMoeFaQAph5s5vK1FimRWtMWsCkwBDAsXO6JvixA6Y1aN195phjULzUh-XEthKrow3hOmiAkKaCycv98jARa3GaVF2aJCvZPCKLu-G_Ta-CvUAQ1m5q1vrOeB8O-0iWV3_D2Rbc0sX8uEhZi1DSCAMZYGzpJVJGn2VPYPBrDKMLCTkFipwBpe4xCm6uTDWYdATyGhFrI'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Control buttons
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildControlButton(
                      icon: _isMicOn ? Icons.mic : Icons.mic_off,
                      onTap: () => setState(() => _isMicOn = !_isMicOn),
                    ),
                    const SizedBox(width: 16),
                    _buildControlButton(
                      icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                      onTap: () => setState(() => _isCameraOn = !_isCameraOn),
                    ),
                    const SizedBox(width: 16),
                    _buildControlButton(
                      icon: Icons.call_end,
                      color: const Color(0xFFD9534F),
                      size: 64,
                      iconSize: 36,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    _buildControlButton(
                      icon: Icons.flip_camera_android,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    double size = 56,
    double iconSize = 28,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color ?? Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}