import 'dart:async';
import 'package:flutter/foundation.dart';

class VNPayService {
  static final VNPayService _instance = VNPayService._internal();
  factory VNPayService() => _instance;
  VNPayService._internal();

  // VNPay configuration (readonly mode - for demo only)
  static const String _tmnCode = 'DEMO_MERCHANT';
  static const String _hashSecret = 'DEMO_SECRET_KEY';
  static const String _returnUrl = 'myapp://payment-return';

  /// Initialize payment (Readonly mode - just logs and returns mock result)
  Future<Map<String, dynamic>> initPayment({
    required double amount,
    required String orderInfo,
    required String orderId,
  }) async {
    try {
      print('🔵 [VNPay Readonly] Initializing payment...');
      print('   Amount: ${amount.toStringAsFixed(0)} VND');
      print('   Order: $orderInfo');
      print('   Order ID: $orderId');

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 1));

      // In readonly mode, we just return a mock success response
      final mockTransactionId = 'VNP${DateTime.now().millisecondsSinceEpoch}';
      
      print('✅ [VNPay Readonly] Payment simulated successfully');
      print('   Transaction ID: $mockTransactionId');

      return {
        'success': true,
        'transactionId': mockTransactionId,
        'message': 'Thanh toán thành công (Demo mode)',
        'amount': amount,
        'orderId': orderId,
        'paymentTime': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('❌ [VNPay Readonly] Payment simulation failed: $e');
      return {
        'success': false,
        'message': 'Lỗi thanh toán: $e',
      };
    }
  }

  /// Process payment result (Readonly mode)
  Future<Map<String, dynamic>> processPaymentResult(Map<String, dynamic> result) async {
    try {
      print('🔵 [VNPay Readonly] Processing payment result...');
      
      // In a real implementation, you would:
      // 1. Verify the signature
      // 2. Check transaction status with VNPay
      // 3. Update order status
      
      // For readonly mode, we just validate the structure
      if (result.containsKey('transactionId') && result.containsKey('orderId')) {
        print('✅ [VNPay Readonly] Payment result validated');
        return {
          'success': true,
          'verified': true,
          'transactionId': result['transactionId'],
          'orderId': result['orderId'],
        };
      } else {
        print('⚠️ [VNPay Readonly] Invalid payment result structure');
        return {
          'success': false,
          'verified': false,
          'message': 'Dữ liệu thanh toán không hợp lệ',
        };
      }
    } catch (e) {
      print('❌ [VNPay Readonly] Error processing payment result: $e');
      return {
        'success': false,
        'message': 'Lỗi xử lý kết quả thanh toán: $e',
      };
    }
  }

  /// Cancel payment (Readonly mode)
  Future<bool> cancelPayment(String orderId) async {
    print('🔵 [VNPay Readonly] Payment cancelled for order: $orderId');
    return true;
  }

  /// Get payment status (Readonly mode)
  Future<Map<String, dynamic>> getPaymentStatus(String transactionId) async {
    print('🔵 [VNPay Readonly] Getting payment status for: $transactionId');
    
    // Mock response
    return {
      'transactionId': transactionId,
      'status': 'success',
      'message': 'Giao dịch thành công (Demo)',
    };
  }

  /// Format amount for VNPay (must be integer, in VND)
  int formatAmount(double amount) {
    return amount.toInt();
  }

  /// Create payment URL (Readonly mode - returns mock URL)
  String createPaymentUrl({
    required double amount,
    required String orderInfo,
    required String orderId,
  }) {
    print('🔵 [VNPay Readonly] Creating payment URL...');
    
    // In readonly mode, return a mock URL
    final mockUrl = 'vnpay://payment?'
        'amount=${formatAmount(amount)}'
        '&orderInfo=${Uri.encodeComponent(orderInfo)}'
        '&orderId=$orderId'
        '&returnUrl=${Uri.encodeComponent(_returnUrl)}';
    
    print('   Mock URL: $mockUrl');
    return mockUrl;
  }

  /// Show payment info (for debugging in readonly mode)
  void showPaymentInfo({
    required double amount,
    required String orderInfo,
    required String orderId,
  }) {
    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📱 VNPay Payment Info (Readonly Mode)');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('💰 Amount: ${amount.toStringAsFixed(0)} VND');
      print('📝 Order Info: $orderInfo');
      print('🔢 Order ID: $orderId');
      print('🏪 Merchant: $_tmnCode');
      print('🔙 Return URL: $_returnUrl');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }
}
