import 'package:flutter/material.dart';

class ScreenRateDoctor extends StatefulWidget {
  const ScreenRateDoctor({super.key});

  @override
  State<ScreenRateDoctor> createState() => _ScreenRateDoctorState();
}

class _ScreenRateDoctorState extends State<ScreenRateDoctor> {
  int stars = 4;
  bool anonymous = false;

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF616F89);

    return Scaffold(
      backgroundColor: bgLight,
      body: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Color(0xFFDBDFE6), borderRadius: BorderRadius.circular(2))),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundImage: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDKVA6xcF0oAVJJ7kROK-duDLRPo9mHSeZtuBuFevcWN7b_31mWTtXxIEg3Ux_SC6IXi12ID6XnwJx9WzSCBqhHeSqhh7P8QrK_1x1HMhIzNYGmsO6NQDeoaGRGrRKqldPiLQOX9ahnUOj7wywwBAKNH42VVFUIXpBoj2MwJ9Ya1eBF74QDGf7bNeE2607Z8xRFI-_xSLMiYAriC3s9pdeUCO8wx_O3gRaAZttp9FwroI4tGABXmwBVMi6cQGFi9F7ZvJjV-lMYVUQ'),
                ),
                const SizedBox(height: 12),
                const Text('BS. Nguyễn Văn An', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 4),
                const Text('Chuyên khoa Tim mạch', style: TextStyle(color: textMuted)),
                const SizedBox(height: 12),
                const Text('Chia sẻ trải nghiệm của bạn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 4),
                const Text('Chạm vào sao để đánh giá', style: TextStyle(color: textMuted)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: List.generate(5, (i) {
                    final filled = i < stars;
                    return GestureDetector(
                      onTap: () => setState(() => stars = i + 1),
                      child: Icon(Icons.star, color: filled ? const Color(0xFFFFD700) : const Color(0xFFE0E0E0), size: 32),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Để lại bình luận (Không bắt buộc)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Bác sĩ tư vấn có tận tình không? Bạn có góp ý gì thêm?...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Checkbox(value: anonymous, onChanged: (v) => setState(() => anonymous = v ?? false), activeColor: primary),
                  const Text('Gửi đánh giá ẩn danh', style: TextStyle(color: Color(0xFF6B7280))),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {},
                    child: const Text('Gửi Đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: primary, side: BorderSide(color: primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Để sau', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}