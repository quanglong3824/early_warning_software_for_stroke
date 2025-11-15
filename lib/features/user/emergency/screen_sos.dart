import 'package:flutter/material.dart';

class ScreenSOS extends StatefulWidget {
  const ScreenSOS({super.key});

  @override
  State<ScreenSOS> createState() => _ScreenSOSState();
}

class _ScreenSOSState extends State<ScreenSOS> with SingleTickerProviderStateMixin {
  bool _showConfirmation = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF8F6F6);
    const primary = Color(0xFFEC1313);
    const textPrimary = Color(0xFF181111);
    const textMuted = Color(0xFF71717A);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Cảnh báo khẩn cấp',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'KÍCH HOẠT SOS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Nhấn nút để gửi cảnh báo đến người thân và dịch vụ y tế.',
                    style: TextStyle(color: textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                // SOS Button with pulse animation
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showConfirmation = true;
                    });
                  },
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse effect
                          Container(
                            width: 224 + (_pulseController.value * 40),
                            height: 224 + (_pulseController.value * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withOpacity(0.3 * (1 - _pulseController.value)),
                            ),
                          ),
                          // Main button
                          Container(
                            width: 224,
                            height: 224,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary,
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'SOS',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Confirmation Modal
          if (_showConfirmation)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: bgLight,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Bạn chắc chắn muốn gửi tín hiệu SOS?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Một cảnh báo khẩn cấp cùng vị trí của bạn sẽ được gửi ngay lập tức.',
                        style: TextStyle(fontSize: 14, color: textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // Handle SOS send
                          setState(() {
                            _showConfirmation = false;
                          });
                        },
                        child: const Text(
                          'Gửi ngay',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _showConfirmation = false;
                          });
                        },
                        child: const Text(
                          'Hủy',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
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
}