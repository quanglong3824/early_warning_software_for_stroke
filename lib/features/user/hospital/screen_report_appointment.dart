import 'package:flutter/material.dart';

class ScreenReportAppointment extends StatelessWidget {
  const ScreenReportAppointment({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: textPrimary), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: const Text('Báo cáo & Đặt hẹn', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.call, color: textPrimary))],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: const [
          _Segmented(),
          _Headline('Gửi Báo cáo Sức khỏe Hàng ngày'),
          _TwoCols(left: _LabeledField(label: 'Huyết áp tâm thu', hint: 'mmHg'), right: _LabeledField(label: 'Huyết áp tâm trương', hint: 'mmHg')),
          SizedBox(height: 12),
          _LabeledField(label: 'Nhịp tim', hint: 'bpm'),
          _Symptoms(),
          _Notes(),
          _UploadButton(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {},
            child: const Text('Gửi Báo cáo', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented();
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(child: Container(height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 3)]), alignment: Alignment.center, child: const Text('Báo cáo Sức khỏe', style: TextStyle(fontWeight: FontWeight.w600)))),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 40, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: const Text('Đặt lịch hẹn', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)))),
      ]),
    );
  }
}

class _Headline extends StatelessWidget {
  final String text;
  const _Headline(this.text);
  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    return Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)));
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  const _LabeledField({required this.label, required this.hint});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      ]),
    );
  }
}

class _TwoCols extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _TwoCols({required this.left, required this.right});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ]),
    );
  }
}

class _Symptoms extends StatelessWidget {
  const _Symptoms();
  @override
  Widget build(BuildContext context) {
    const border = BorderSide(color: Color(0xFFE5E7EB));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Các triệu chứng thường gặp', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _SymptomItem('Đau đầu, chóng mặt'),
        const SizedBox(height: 8),
        _SymptomItem('Yếu hoặc tê liệt tay/chân'),
        const SizedBox(height: 8),
        _SymptomItem('Khó nói, nói ngọng'),
      ]),
    );
  }
}

class _SymptomItem extends StatelessWidget {
  final String label;
  const _SymptomItem(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        const Icon(Icons.check_box_outline_blank, color: Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ]),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ghi chú khác', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(maxLines: 4, decoration: InputDecoration(hintText: 'Mô tả chi tiết các triệu chứng khác của bạn...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))
      ]),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton();
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 56,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE5E7EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () {},
          child: const Text('Đính kèm tệp', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}