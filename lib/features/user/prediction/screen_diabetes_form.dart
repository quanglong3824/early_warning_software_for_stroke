import 'package:flutter/material.dart';

class ScreenDiabetesForm extends StatelessWidget {
  const ScreenDiabetesForm({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: textPrimary), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: const Text('Đánh giá Nguy cơ Tiểu đường', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: const [
          _InfoCard(),
          _ProgressBar(label: 'Tiến trình (1/3)', percent: 0.33),
          _SectionTitle('Thông tin cá nhân'),
          _LabeledField(label: 'Tuổi', hint: 'Nhập tuổi của bạn'),
          SizedBox(height: 12),
          _SegmentOptions(options: ['Nam', 'Nữ']),
          SizedBox(height: 16),
          _SectionTitle('Chỉ số cơ thể'),
          _TwoCols(left: _LabeledField(label: 'Chiều cao (cm)', hint: '170'), right: _LabeledField(label: 'Cân nặng (kg)', hint: '65')),
          SizedBox(height: 8),
          _BMIBox(value: '22.5 kg/m²'),
          SizedBox(height: 16),
          _SectionTitle('Chỉ số y tế'),
          _LabeledField(label: 'Mức đường huyết lúc đói (mg/dL)', hint: 'Nhập mức đường huyết của bạn'),
          SizedBox(height: 12),
          _LabeledField(label: 'Huyết áp tâm thu (mmHg)', hint: 'Nhập chỉ số huyết áp tâm thu'),
          SizedBox(height: 16),
          _SectionTitle('Lối sống & Tiền sử'),
          _FieldLabel('Tiền sử gia đình mắc bệnh tiểu đường'),
          _SegmentOptions(options: ['Có', 'Không']),
          SizedBox(height: 12),
          _FieldLabel('Mức độ hoạt động thể chất'),
          _Dropdown(items: ['Ít vận động', 'Vừa phải', 'Năng động']),
          SizedBox(height: 12),
          _PrivacyNote(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {},
            child: const Text('Xem Kết quả Dự đoán', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return Container(
      decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Thông tin quan trọng', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(height: 4),
        Text('Vui lòng nhập chính xác các thông tin dưới đây để hệ thống có thể đưa ra dự đoán chính xác nhất về nguy cơ tiểu đường của bạn.', style: TextStyle(color: Color(0xFF616F89))),
      ]),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double percent;
  const _ProgressBar({required this.label, required this.percent});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFDBDFE6), borderRadius: BorderRadius.circular(8)), child: FractionallySizedBox(widthFactor: percent, alignment: Alignment.centerLeft, child: Container(decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8))))),
      const SizedBox(height: 12),
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    return Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)));
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600))));
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  const _LabeledField({required this.label, required this.hint});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FieldLabel(label),
      TextField(decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    ]);
  }
}

class _TwoCols extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _TwoCols({required this.left, required this.right});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: left),
      const SizedBox(width: 12),
      Expanded(child: right),
    ]);
  }
}

class _BMIBox extends StatelessWidget {
  final String value;
  const _BMIBox({required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Chỉ số BMI của bạn', style: TextStyle(fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(color: Color(0xFF135BEC), fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _SegmentOptions extends StatelessWidget {
  final List<String> options;
  const _SegmentOptions({required this.options});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return Row(children: [
      for (var i = 0; i < options.length; i++)
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: i == 0 ? primary.withOpacity(0.1) : Colors.white, border: Border.all(color: i == 0 ? primary : const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            height: 48,
            child: Text(options[i], style: TextStyle(color: i == 0 ? primary : const Color(0xFF111318), fontWeight: FontWeight.w600)),
          ),
        ),
    ]);
  }
}

class _Dropdown extends StatelessWidget {
  final List<String> items;
  const _Dropdown({required this.items});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 48,
      alignment: Alignment.centerLeft,
      child: Text(items.first),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Icon(Icons.lock, size: 16, color: Color(0xFF616F89)),
      SizedBox(width: 8),
      Expanded(child: Text('Thông tin của bạn được bảo mật và chỉ được sử dụng cho mục đích phân tích nguy cơ sức khỏe.', style: TextStyle(color: Color(0xFF616F89), fontSize: 12))),
    ]);
  }
}