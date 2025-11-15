import 'package:flutter/material.dart';

class ScreenStrokeForm extends StatelessWidget {
  const ScreenStrokeForm({super.key});

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
        title: const Text('Nhập Chỉ Số', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Nhập Dữ Liệu Phân Tích Đột Quỵ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary)),
          ),
          _Section(title: 'Thông tin cơ bản', children: const [
            _FieldLabel('Giới tính'),
            _SegmentOptions(options: ['Nam', 'Nữ', 'Khác']),
            SizedBox(height: 12),
            _FieldLabel('Tuổi'),
            _TextField(hint: 'Nhập tuổi của bạn'),
          ]),
          _Section(title: 'Chỉ số sinh tồn', children: const [
            _TwoCols(left: _LabeledField(label: 'Huyết áp SYS', hint: 'mmHg'), right: _LabeledField(label: 'Huyết áp DIA', hint: 'mmHg')),
            SizedBox(height: 12),
            _LabeledField(label: 'Nhịp tim', hint: 'Nhịp/phút'),
            SizedBox(height: 12),
            _LabeledField(label: 'Nồng độ Glucose trong máu', hint: 'mg/dL'),
          ]),
          _Section(title: 'Tiền sử bệnh lý', children: const [
            _ToggleRow('Bị tăng huyết áp?'),
            SizedBox(height: 8),
            _ToggleRow('Có tiền sử bệnh tim?'),
            SizedBox(height: 12),
            _FieldLabel('Tình trạng hôn nhân'),
            _Dropdown(items: ['Đã kết hôn', 'Chưa kết hôn']),
          ]),
          _Section(title: 'Lối sống', children: const [
            _FieldLabel('Tình trạng hút thuốc'),
            _Dropdown(items: ['Chưa bao giờ hút', 'Từng hút', 'Đang hút']),
            SizedBox(height: 12),
            _FieldLabel('Khu vực sinh sống'),
            _Dropdown(items: ['Thành thị', 'Nông thôn']),
            SizedBox(height: 12),
            _FieldLabel('Loại hình công việc'),
            _Dropdown(items: ['Tư nhân', 'Tự kinh doanh', 'Nhà nước', 'Trẻ em', 'Chưa từng làm việc']),
          ]),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {},
            child: const Text('Dự Đoán Nguy Cơ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
      ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: children)),
      const SizedBox(height: 8),
    ]);
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600))),
    );
  }
}

class _TextField extends StatelessWidget {
  final String hint;
  const _TextField({required this.hint});
  @override
  Widget build(BuildContext context) {
    return TextField(decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
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
      _TextField(hint: hint),
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
      child: Text(items.first, style: const TextStyle(color: Color(0xFF6B7280))),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String text;
  const _ToggleRow(this.text);
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
        Switch(
          value: false,
          onChanged: (value) {},
          activeColor: primary,
        ),
      ],
    );
  }
}