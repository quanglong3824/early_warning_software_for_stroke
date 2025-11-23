import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/doctor_service.dart';
import '../../../data/models/doctor_models.dart';

class ScreenRateDoctor extends StatefulWidget {
  final DoctorModel doctor;

  const ScreenRateDoctor({super.key, required this.doctor});

  @override
  State<ScreenRateDoctor> createState() => _ScreenRateDoctorState();
}

class _ScreenRateDoctorState extends State<ScreenRateDoctor> {
  final _authService = AuthService();
  final _doctorService = DoctorService();
  
  int stars = 5;
  bool anonymous = false;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Vui lòng đăng nhập để đánh giá');
      }

      await _doctorService.submitReview(
        doctorId: widget.doctor.doctorId,
        userId: userId,
        rating: stars.toDouble(),
        comment: _commentController.text.trim(),
        isAnonymous: anonymous,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!'), backgroundColor: Colors.green),
      );
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF616F89);

    return Scaffold(
      backgroundColor: Colors.black54, // Transparent background effect
      body: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFDBDFE6), borderRadius: BorderRadius.circular(2))),
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
                CircleAvatar(
                  radius: 36,
                  backgroundImage: NetworkImage(widget.doctor.photoURL ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.doctor.name)}&background=random'),
                  onBackgroundImageError: (_, __) => const Icon(Icons.person, size: 36),
                ),
                const SizedBox(height: 12),
                Text(widget.doctor.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 4),
                Text(widget.doctor.specialization ?? 'Bác sĩ', style: const TextStyle(color: textMuted)),
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
                      controller: _commentController,
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
                    onPressed: _isSubmitting ? null : _submitReview,
                    child: _isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Gửi Đánh giá', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: primary, side: const BorderSide(color: primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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