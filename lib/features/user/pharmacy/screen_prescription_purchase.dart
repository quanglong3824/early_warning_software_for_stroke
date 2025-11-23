import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/prescription_models.dart';
import '../../../data/models/medication_models.dart';
import '../../../services/prescription_service.dart';
import '../../../services/pharmacy_order_service.dart';
import '../../../services/vnpay_service.dart';
import '../../../services/auth_service.dart';

class ScreenPrescriptionPurchase extends StatefulWidget {
  final PrescriptionModel prescription;

  const ScreenPrescriptionPurchase({
    super.key,
    required this.prescription,
  });

  @override
  State<ScreenPrescriptionPurchase> createState() => _ScreenPrescriptionPurchaseState();
}

class _ScreenPrescriptionPurchaseState extends State<ScreenPrescriptionPurchase> {
  final _prescriptionService = PrescriptionService();
  final _orderService = PharmacyOrderService();
  final _vnpayService = VNPayService();
  final _authService = AuthService();
  
  final _addressController = TextEditingController();
  String _paymentMethod = 'vnpay'; // vnpay or cod
  bool _isProcessing = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập địa chỉ giao hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      // Create order items from prescription medications
      final orderItems = widget.prescription.medications.map((med) {
        return OrderItemModel(
          medicationId: med.medicationId,
          medicationName: med.medicationName,
          quantity: med.quantity,
          price: med.price,
          totalPrice: med.totalPrice,
        );
      }).toList();

      // Create order
      final order = PharmacyOrderModel(
        orderId: '',
        userId: userId,
        prescriptionId: widget.prescription.prescriptionId,
        prescriptionCode: widget.prescription.prescriptionCode,
        items: orderItems,
        totalAmount: widget.prescription.totalAmount,
        paymentMethod: _paymentMethod,
        paymentStatus: 'pending',
        orderStatus: 'pending',
        shippingAddress: {
          'address': _addressController.text.trim(),
        },
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final orderId = await _orderService.createOrder(order);
      
      if (orderId == null) {
        throw Exception('Không thể tạo đơn hàng');
      }

      // Process payment based on method
      if (_paymentMethod == 'vnpay') {
        // VNPay payment (readonly mode)
        _vnpayService.showPaymentInfo(
          amount: widget.prescription.totalAmount,
          orderInfo: 'Thanh toán đơn thuốc ${widget.prescription.prescriptionCode}',
          orderId: orderId,
        );

        final paymentResult = await _vnpayService.initPayment(
          amount: widget.prescription.totalAmount,
          orderInfo: 'Đơn thuốc ${widget.prescription.prescriptionCode}',
          orderId: orderId,
        );

        if (paymentResult['success'] == true) {
          // Update payment status
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
            setState(() => _isProcessing = false);
            
            // Show success dialog
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 32),
                    SizedBox(width: 12),
                    Text('Thanh toán thành công'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Đơn hàng của bạn đã được thanh toán thành công!'),
                    const SizedBox(height: 16),
                    Text(
                      'Mã giao dịch: ${paymentResult['transactionId']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Mã đơn hàng: ${orderId.substring(0, 8)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context, true); // Return to previous screen
                    },
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
          }
        } else {
          throw Exception(paymentResult['message'] ?? 'Thanh toán thất bại');
        }
      } else {
        // COD payment
        await _orderService.updateOrderStatus(orderId, 'processing');
        
        // Mark prescription as purchased
        await _prescriptionService.markAsPurchased(
          widget.prescription.prescriptionId,
          orderId,
        );

        if (mounted) {
          setState(() => _isProcessing = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đặt hàng thành công! Thanh toán khi nhận hàng.'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          'Thanh toán đơn thuốc',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prescription Code
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary.withOpacity(0.1), primary.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code, color: primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mã đơn thuốc',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          widget.prescription.prescriptionCode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Medications Summary
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Danh sách thuốc',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.prescription.medications.map((med) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${med.medicationName} x${med.quantity}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          Text(
                            '${med.totalPrice.toStringAsFixed(0)}đ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Shipping Address
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Địa chỉ giao hàng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Nhập địa chỉ nhận hàng...',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: bgLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment Method
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phương thức thanh toán',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    value: 'vnpay',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() => _paymentMethod = value!);
                    },
                    title: const Text('VNPay (Demo mode)'),
                    subtitle: const Text('Thanh toán qua VNPay'),
                    secondary: const Icon(Icons.payment, color: primary),
                  ),
                  RadioListTile<String>(
                    value: 'cod',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() => _paymentMethod = value!);
                    },
                    title: const Text('Thanh toán khi nhận hàng'),
                    subtitle: const Text('Trả tiền mặt khi nhận thuốc'),
                    secondary: const Icon(Icons.money, color: primary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Total
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng tiền',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${widget.prescription.totalAmount.toStringAsFixed(0)}đ',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _paymentMethod == 'vnpay' ? 'Thanh toán VNPay' : 'Đặt hàng',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
