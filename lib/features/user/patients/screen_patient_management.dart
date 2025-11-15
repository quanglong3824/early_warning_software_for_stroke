import 'package:flutter/material.dart';

class ScreenPatientManagement extends StatelessWidget {
  const ScreenPatientManagement({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF1C1C1E);
    const textMuted = Color(0xFF8E8E93);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0.5,
        title: const Text(
          'Quản lý Hồ sơ',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: textPrimary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PatientCard(
            name: 'Nguyễn Văn An',
            info: 'DOB: 15/08/1965',
            riskLevel: RiskLevel.high,
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDMNHp1rK0mWE5VbuwCRetmYVS-Am3kYdAb2aFM1ljydOK8yONHrItHeBSXdx_4DdlIjHeweRAvpZATiMQs2H8bQO6sBbJkTbnSCCCq_Qumjarsrfz7xUuj5-565fVAW1zGzqWkwCP4GBZJGJ8zeVd5Ijl815Kv_Pn5IrO9g9gxFTXCHtw4AsZpzBndyjCpALdc0_CoGue4zrqA7X6artAn8b3rHmidNwr7IsGUGSIB2Qk74AMPI-rgZ4rFbsVTHoMKbyFyNj3kWNk',
          ),
          const SizedBox(height: 12),
          _PatientCard(
            name: 'Trần Thị Bích',
            info: 'ID: 789123',
            riskLevel: RiskLevel.medium,
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB7SsGkoOaRW8NCtzTfdCFxOptV53UmK2S20KdVVIQ_PYajdEILDmd4UlGNvgDoMvuBK25nrZ0XRts8g8sxnkLfv4JfaJUsDFbIfbIFoG0yL5yX51VxfFXSSBDcrcRo5hCqhPcEVTlTJqSG8F2LzINqLlpu-M2JusbOMU2MKMO1R_8HKbN5_72m97EH3uxsTQth2iuQXYN1ZgR1Ay1ZDzXYnaaJtsoOcscaR4UfcgG5x46ONFaI4OK2P8QKd6brklm6G6qYQLNFBRQ',
          ),
          const SizedBox(height: 12),
          _PatientCard(
            name: 'Lê Hoàng Cường',
            info: 'DOB: 22/11/1980',
            riskLevel: RiskLevel.low,
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBzS2oi5TRTjUlqtjcgq5uV39gFJo2GxWiKMLAmQZlyQyrVH603qFXca-CVRG8CTeHhNnCfAXk2oMn2QPshyr_ztvObxXvMGKyAri2Cw78bOxZ8yWrh1ME5Ny8PSeuBL_h6Q0kRSvtYFIiIOpk3fdBxWvrtquFnCBV2suGW8enNIZ4PS9_Q9g2ONJYeY-7R2K5kl6v_1mTzFgMtec-woV0qAlXn4OUfuzD9bxhxFt9wR6CQkYtR-fYLB9-3ZXe1EkQdDrgpnfFeukY',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primary,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}

enum RiskLevel { high, medium, low }

class _PatientCard extends StatelessWidget {
  final String name;
  final String info;
  final RiskLevel riskLevel;
  final String imageUrl;

  const _PatientCard({
    required this.name,
    required this.info,
    required this.riskLevel,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1C1C1E);
    const textMuted = Color(0xFF8E8E93);

    Color getRiskColor() {
      switch (riskLevel) {
        case RiskLevel.high:
          return const Color(0xFFFF3B30);
        case RiskLevel.medium:
          return const Color(0xFFFFCC00);
        case RiskLevel.low:
          return const Color(0xFF34C759);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: getRiskColor(),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}