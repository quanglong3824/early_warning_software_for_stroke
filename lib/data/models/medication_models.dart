class MedicationModel {
  final String medicationId;
  final String name;
  final String description;
  final double price;
  final String unit; // viên, chai, hộp, gói
  final String? imageUrl;
  final String category; // Kháng sinh, Giảm đau, Tim mạch, etc.
  final int stock;
  final bool isActive;
  final int createdAt;
  final int? updatedAt;

  MedicationModel({
    required this.medicationId,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    this.imageUrl,
    required this.category,
    required this.stock,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      medicationId: json['medicationId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'viên',
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String? ?? 'Khác',
      stock: json['stock'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicationId': medicationId,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'imageUrl': imageUrl,
      'category': category,
      'stock': stock,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  MedicationModel copyWith({
    String? medicationId,
    String? name,
    String? description,
    double? price,
    String? unit,
    String? imageUrl,
    String? category,
    int? stock,
    bool? isActive,
    int? createdAt,
    int? updatedAt,
  }) {
    return MedicationModel(
      medicationId: medicationId ?? this.medicationId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PrescriptionMedicationModel {
  final String medicationId;
  final String medicationName;
  final String dosage; // 1 viên
  final String frequency; // Sáng 1 viên, Trưa 1 viên, Tối 1 viên
  final String duration; // 30 ngày
  final String instructions; // Uống sau ăn
  final double price;
  final int quantity; // Số lượng cần mua

  PrescriptionMedicationModel({
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
    required this.price,
    required this.quantity,
  });

  factory PrescriptionMedicationModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedicationModel(
      medicationId: json['medicationId'] as String,
      medicationName: json['medicationName'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      duration: json['duration'] as String,
      instructions: json['instructions'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicationId': medicationId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'price': price,
      'quantity': quantity,
    };
  }

  double get totalPrice => price * quantity;

  PrescriptionMedicationModel copyWith({
    String? medicationId,
    String? medicationName,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
    double? price,
    int? quantity,
  }) {
    return PrescriptionMedicationModel(
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PrescriptionMedicationModel) return false;
    return medicationId == other.medicationId &&
        medicationName == other.medicationName &&
        dosage == other.dosage &&
        frequency == other.frequency &&
        duration == other.duration &&
        instructions == other.instructions &&
        price == other.price &&
        quantity == other.quantity;
  }

  @override
  int get hashCode => Object.hash(
    medicationId,
    medicationName,
    dosage,
    frequency,
    duration,
    instructions,
    price,
    quantity,
  );
}

class PharmacyOrderModel {
  final String orderId;
  final String userId;
  final String? prescriptionId;
  final String? prescriptionCode;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String paymentMethod; // vnpay, cod
  final String paymentStatus; // pending, paid, failed
  final String orderStatus; // pending, processing, completed, cancelled
  final Map<String, dynamic>? shippingAddress;
  final String? vnpayTransactionId;
  final int createdAt;
  final int? updatedAt;

  PharmacyOrderModel({
    required this.orderId,
    required this.userId,
    this.prescriptionId,
    this.prescriptionCode,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.orderStatus = 'pending',
    this.shippingAddress,
    this.vnpayTransactionId,
    required this.createdAt,
    this.updatedAt,
  });

  factory PharmacyOrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items = itemsList
        .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return PharmacyOrderModel(
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      prescriptionId: json['prescriptionId'] as String?,
      prescriptionCode: json['prescriptionCode'] as String?,
      items: items,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      orderStatus: json['orderStatus'] as String? ?? 'pending',
      shippingAddress: json['shippingAddress'] as Map<String, dynamic>?,
      vnpayTransactionId: json['vnpayTransactionId'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'prescriptionId': prescriptionId,
      'prescriptionCode': prescriptionCode,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'shippingAddress': shippingAddress,
      'vnpayTransactionId': vnpayTransactionId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class OrderItemModel {
  final String medicationId;
  final String medicationName;
  final int quantity;
  final double price;
  final double totalPrice;

  OrderItemModel({
    required this.medicationId,
    required this.medicationName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      medicationId: json['medicationId'] as String,
      medicationName: json['medicationName'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicationId': medicationId,
      'medicationName': medicationName,
      'quantity': quantity,
      'price': price,
      'totalPrice': totalPrice,
    };
  }
}

class PaymentResultModel {
  final bool success;
  final String? transactionId;
  final String? message;
  final Map<String, dynamic>? data;

  PaymentResultModel({
    required this.success,
    this.transactionId,
    this.message,
    this.data,
  });

  factory PaymentResultModel.fromJson(Map<String, dynamic> json) {
    return PaymentResultModel(
      success: json['success'] as bool,
      transactionId: json['transactionId'] as String?,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transactionId': transactionId,
      'message': message,
      'data': data,
    };
  }
}
