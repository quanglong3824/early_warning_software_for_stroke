import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../data/models/medication_models.dart';

class PharmacyOrderService {
  static final PharmacyOrderService _instance = PharmacyOrderService._internal();
  factory PharmacyOrderService() => _instance;
  PharmacyOrderService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Create new order
  Future<String?> createOrder(PharmacyOrderModel order) async {
    try {
      final orderRef = _db.child('pharmacy_orders').push();
      final orderId = orderRef.key!;
      
      final orderWithId = PharmacyOrderModel(
        orderId: orderId,
        userId: order.userId,
        prescriptionId: order.prescriptionId,
        prescriptionCode: order.prescriptionCode,
        items: order.items,
        totalAmount: order.totalAmount,
        paymentMethod: order.paymentMethod,
        paymentStatus: order.paymentStatus,
        orderStatus: order.orderStatus,
        shippingAddress: order.shippingAddress,
        vnpayTransactionId: order.vnpayTransactionId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await orderRef.set(orderWithId.toJson());
      print('✅ Order created: $orderId');
      return orderId;
    } catch (e) {
      print('❌ Error creating order: $e');
      return null;
    }
  }

  /// Get user orders
  Stream<List<PharmacyOrderModel>> getUserOrders(String userId) {
    return _db
        .child('pharmacy_orders')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final List<PharmacyOrderModel> orders = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final dynamic value = event.snapshot.value;
        Map<dynamic, dynamic> data = {};
        
        if (value is Map) {
          data = value;
        } else if (value is List) {
           for (int i = 0; i < value.length; i++) {
             if (value[i] != null) {
               data[i.toString()] = value[i];
             }
           }
        }

        data.forEach((key, value) {
          if (value == null) return;
          if (value is Map) {
             final orderData = Map<String, dynamic>.from(value);
             orderData['orderId'] = key;
             orders.add(PharmacyOrderModel.fromJson(orderData));
          }
        });
      }
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Get order by ID
  Future<PharmacyOrderModel?> getOrderById(String orderId) async {
    try {
      final snapshot = await _db.child('pharmacy_orders').child(orderId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data['orderId'] = orderId;
        return PharmacyOrderModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error getting order: $e');
      return null;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _db.child('pharmacy_orders').child(orderId).update({
        'orderStatus': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Order status updated: $orderId -> $status');
      return true;
    } catch (e) {
      print('❌ Error updating order status: $e');
      return false;
    }
  }

  /// Update payment status
  Future<bool> updatePaymentStatus(
    String orderId,
    String paymentStatus, {
    String? transactionId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'paymentStatus': paymentStatus,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      if (transactionId != null) {
        updates['vnpayTransactionId'] = transactionId;
      }

      await _db.child('pharmacy_orders').child(orderId).update(updates);
      print('✅ Payment status updated: $orderId -> $paymentStatus');
      return true;
    } catch (e) {
      print('❌ Error updating payment status: $e');
      return false;
    }
  }

  /// Get orders by prescription
  Future<List<PharmacyOrderModel>> getOrdersByPrescription(String prescriptionId) async {
    try {
      final snapshot = await _db
          .child('pharmacy_orders')
          .orderByChild('prescriptionId')
          .equalTo(prescriptionId)
          .get();

      final List<PharmacyOrderModel> orders = [];
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((key, value) {
          final orderData = Map<String, dynamic>.from(value as Map);
          orderData['orderId'] = key;
          orders.add(PharmacyOrderModel.fromJson(orderData));
        });
      }
      
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      print('❌ Error getting orders by prescription: $e');
      return [];
    }
  }

  /// Cancel order
  Future<bool> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId, 'cancelled');
  }

  /// Get order statistics for user
  Future<Map<String, dynamic>> getUserOrderStats(String userId) async {
    try {
      final snapshot = await _db
          .child('pharmacy_orders')
          .orderByChild('userId')
          .equalTo(userId)
          .get();

      int totalOrders = 0;
      int completedOrders = 0;
      int pendingOrders = 0;
      double totalSpent = 0;

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((key, value) {
          final orderData = Map<String, dynamic>.from(value as Map);
          totalOrders++;
          
          final status = orderData['orderStatus'] as String?;
          if (status == 'completed') {
            completedOrders++;
          } else if (status == 'pending' || status == 'processing') {
            pendingOrders++;
          }
          
          if (orderData['paymentStatus'] == 'paid') {
            totalSpent += (orderData['totalAmount'] as num?)?.toDouble() ?? 0;
          }
        });
      }

      return {
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'pendingOrders': pendingOrders,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      print('❌ Error getting order stats: $e');
      return {
        'totalOrders': 0,
        'completedOrders': 0,
        'pendingOrders': 0,
        'totalSpent': 0.0,
      };
    }
  }
}
