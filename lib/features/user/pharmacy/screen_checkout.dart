import 'package:flutter/material.dart';

class ScreenCheckout extends StatelessWidget {
  const ScreenCheckout({super.key});

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
        title: const Text('Giỏ Hàng Của Bạn', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: const [
          _CartItem(
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBlU7tsTW8TjQEioWHdOravazlBhfDG1hXFRbI4e-ne52AyeWp90zKKYFh3BjpRZ46RAjxdoxLY5B-2nR8zrrdycKoZSXpSBykeWSpCgxf54R51I_3y0Ni4dJffyZiAV91kImhoqJ1lx4pqVto9wnTGcXSi6pkTgjHvPd91Wyl1s1ULJnIaGOSI_5VgoIHPsOdtJLXnYDTL2WwCKh5DXJCYrXLTSW24d8_3Z3V88I1GYFzF0kfEwrx7veSTBBiciFQDdT7R2rgjdiw',
            name: 'Paracetamol 500mg',
            price: '125.000₫',
            type: 'Viên nén',
            quantity: 1,
          ),
          _CartItem(
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCbPIFIHDiKYogXtqxw7TXA7Y0U5bOat3WlN9wqmVieeENgkzpnPcmQlwWa6ylIdK_ln8GIHr7drtzjs9IMYVSOlIx33zCLwMoLTYhYbvPF3wYgVY6EurHnRoDZeAiL0FW4W_xhpFvazMtYgxRUtRhcCcllFK-0V1UvM1PjUbMsgZXDVOgsRlbiKLmT4L-vUMYbJTUQ1_M5RP11CsHQsVcRUUx3NBpqUHhNuiZyWQcN3LdGU2tdpLOO_ikx_qvnCmkjL_dH5kGBjQM',
            name: 'Aspirin 81mg',
            price: '89.000₫',
            type: 'Viên nén',
            quantity: 2,
          ),
          _PromoCode(),
          _OrderSummary(subtotal: '303.000₫', shipping: '15.000₫', total: '318.000₫'),
          _PaymentMethods(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {},
            child: const Text('Tiến Hành Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _CartItem extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String price;
  final String type;
  final int quantity;
  const _CartItem({required this.imageUrl, required this.name, required this.price, required this.type, required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))]),
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(price, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            Text(type, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.delete, color: Colors.red)),
            Row(children: [
              _QtyButton(label: '-'),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('$quantity')),
              _QtyButton(label: '+', primary: true),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final String label;
  final bool primary;
  const _QtyButton({required this.label, this.primary = false});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: primary.withOpacity(0.06), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
    );
  }
}

class _PromoCode extends StatelessWidget {
  const _PromoCode();
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: TextField(decoration: InputDecoration(hintText: 'Nhập mã giảm giá của bạn', border: OutlineInputBorder(borderSide: BorderSide(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12))))),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {},
              child: const Text('Áp dụng'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final String subtotal;
  final String shipping;
  final String total;
  const _OrderSummary({required this.subtotal, required this.shipping, required this.total});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          _SummaryRow(label: 'Tạm tính', value: subtotal),
          _SummaryRow(label: 'Phí giao hàng', value: shipping),
          const Divider(),
          _SummaryRow(label: 'Tổng cộng', value: total, bold: true, primary: true),
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool primary;
  const _SummaryRow({required this.label, required this.value, this.bold = false, this.primary = false});
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: primary ? const Color(0xFF135BEC) : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label),
        Text(value, style: style),
      ]),
    );
  }
}

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          _PaymentOption(icon: Icons.credit_card, label: 'Thẻ Tín dụng/Ghi nợ', selected: true),
          _PaymentOption(icon: Icons.account_balance_wallet, label: 'Ví điện tử'),
          _PaymentOption(icon: Icons.payments, label: 'Thanh toán khi nhận hàng (COD)'),
        ]),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _PaymentOption({required this.icon, required this.label, this.selected = false});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return Container(
      decoration: BoxDecoration(border: Border.all(color: selected ? primary : const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [Icon(icon, color: const Color(0xFF6B7280)), const SizedBox(width: 8), Text(label)]),
        Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? primary : const Color(0xFF6B7280)),
      ]),
    );
  }
}