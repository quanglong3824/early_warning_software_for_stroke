import 'package:flutter/material.dart';
import '../../../data/models/prescription_models.dart';
import '../../../data/models/medication_models.dart';
import '../../../services/pharmacy_order_service.dart';
import '../../../services/prescription_service.dart';
import '../../../services/vnpay_service.dart';
import '../../../services/auth_service.dart';

class ScreenPrescriptionPharmacy extends StatefulWidget {
  final PrescriptionModel prescription;

  const ScreenPrescriptionPharmacy({
    super.key,
    required this.prescription,
  });

  @override
  State<ScreenPrescriptionPharmacy> createState() => _ScreenPrescriptionPharmacyState();
}

class _ScreenPrescriptionPharmacyState extends State<ScreenPrescriptionPharmacy> {
  final _orderService = PharmacyOrderService();
  final _prescriptionService = PrescriptionService();
  final _vnpayService = VNPayService();
  final _authService = AuthService();

  final Map<int, bool> _selectedItems = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Select all items by default
    for (int i = 0; i < widget.prescription.medications.length; i++) {
      _selectedItems[i] = true;
    }
  }

  double get _totalAmount {
    double total = 0;
    widget.prescription.medications.asMap().forEach((index, med) {
      if (_selectedItems[index] == true) {
        total += med.totalPrice;
      }
    });
    return total;
  }

  int get _selectedCount {
    return _selectedItems.values.where((selected) => selected).length;
  }

  Future<void> _checkout() async {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 loại thuốc')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('Chưa đăng nhập');

      // Create order items
      final orderItems = <OrderItemModel>[];
      widget.prescription.medications.asMap().forEach((index, med) {
        if (_selectedItems[index] == true) {
          orderItems.add(OrderItemModel(
            medicationId: med.medicationId,
            medicationName: med.medicationName,
            quantity: med.quantity,
            price: med.price,
            totalPrice: med.totalPrice,
          ));
        }
      });

      // Create order
      final order = PharmacyOrderModel(
        orderId: '',
        userId: userId,
        prescriptionId: widget.prescription.prescriptionId,
        prescriptionCode: widget.prescription.prescriptionCode,
        items: orderItems,
        totalAmount: _totalAmount,
        paymentMethod: 'vnpay',
        paymentStatus: 'pending',
        orderStatus: 'pending',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final orderId = await _orderService.createOrder(order);
      if (orderId == null) throw Exception('Không thể tạo đơn hàng');

      // Process VNPay payment (readonly mode)
      final paymentResult = await _vnpayService.initPayment(
        amount: _totalAmount,
        orderInfo: 'Thanh toán đơn thuốc ${widget.prescription.prescriptionCode}',
        orderId: orderId,
      );

      if (paymentResult['success'] == true) {
        // Update order payment status
        await _orderService.updatePaymentStatus(
          orderId,
          'paid',
          transactionId: paymentResult['transactionId'],
        );

        // Update order status
        await _orderService.updateOrderStatus(orderId, 'processing');

        // Mark prescription as purchased
        await _prescriptionService.markAsPurchased(
          widget.prescription.prescriptionId,
          orderId,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thanh toán thành công! Đơn hàng đang được xử lý'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(paymentResult['message'] ?? 'Thanh toán thất bại');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mua thuốc theo đơn',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Prescription info header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.medical_services, color: primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đơn thuốc',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            widget.prescription.prescriptionCode,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        'Bác sĩ: ${widget.prescription.doctorName ?? "N/A"}',
                        Icons.person,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Medications list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.prescription.medications.length,
              itemBuilder: (context, index) {
                final med = widget.prescription.medications[index];
                final isSelected = _selectedItems[index] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? primary : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        _selectedItems[index] = value ?? false;
                      });
                    },
                    title: Text(
                      med.medicationName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Liều lượng: ${med.dosage}'),
                        Text('Tần suất: ${med.frequency}'),
                        Text('Thời gian: ${med.duration}'),
                        if (med.instructions.isNotEmpty)
                          Text('Hướng dẫn: ${med.instructions}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Số lượng: ${med.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Text(
                              '${med.totalPrice.toStringAsFixed(0)}đ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: primary,
                  ),
                );
              },
            ),
          ),

          // Bottom checkout bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng tiền',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '${_totalAmount.toStringAsFixed(0)}đ',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '$_selectedCount loại thuốc',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _checkout,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.payment),
                        label: Text(_isProcessing ? 'Đang xử lý...' : 'Thanh toán'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Thanh toán an toàn qua VNPay',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
