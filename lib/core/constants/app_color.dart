import 'package:flutter/material.dart';

// ------------------------------------------
// TỔNG QUAN VỀ CÁC MÀU SẮC
// ------------------------------------------
//
// 1. PRIMARY (Màu chủ đạo):
//    - Màu Xanh dương (Blue) được chọn làm màu chính.
//    - Ý nghĩa: Tạo cảm giác tin cậy, an toàn, chuyên nghiệp và bình tĩnh.
//      Đây là màu phổ biến nhất cho các ứng dụng y tế và tài chính.
//
// 2. MÀU SẮC NGỮ NGHĨA (Semantic Colors):
//    - Các màu dùng để thể hiện các trạng thái cụ thể của hệ thống.
//    - Rất quan trọng cho việc hiển thị Cảnh báo Rủi ro.
//
// 3. MÀU TRUNG TÍNH (Neutral Colors):
//    - Dùng cho nền, văn bản, các đường viền và thẻ (Cards).
//    - Giúp giao diện "sạch sẽ", thoáng đãng và làm nổi bật các màu chính.
//
// ------------------------------------------

class AppColors {
  // --- MÀU CHỦ ĐẠO (PRIMARY) ---

  /// 🔵 Màu xanh dương chủ đạo - Dùng cho các nút bấm chính, tiêu đề, icon.
  /// (Mã HEX: #0D6EFD)
  static const Color primary = Color(0xFF0D6EFD);

  /// 🔵 Màu xanh dương nhạt hơn - Dùng cho các nền phụ, highlight.
  /// (Mã HEX: #E6F0FF)
  static const Color primaryLight = Color(0xFFE6F0FF);


  // --- MÀU SẮC NGỮ NGHĨA (SEMANTIC) - DÙNG CHO CẢNH BÁO RỦI RO ---

  /// 🔴 MÀU NGUY HIỂM (Danger/Critical Risk)
  /// Dùng cho mức rủi ro "RẤT CAO" (Critical) hoặc các cảnh báo khẩn cấp.
  /// (Mã HEX: #FF3B30)
  static const Color danger = Color(0xFFE53935); // Đậm hơn một chút

  /// 🟠 MÀU CẢNH BÁO (Warning/High Risk)
  /// Dùng cho mức rủi ro "CAO" (High).
  /// (Mã HEX: #FF9500)
  static const Color warning = Color(0xFFFB8C00);

  /// 🟡 MÀU THẬN TRỌNG (Caution/Medium Risk)
  /// Dùng cho mức rủi ro "TRUNG BÌNH" (Medium).
  /// (Mã HEX: #FFCC00)
  static const Color caution = Color(0xFFFFB300);

  /// 🟢 MÀU AN TOÀN / THÀNH CÔNG (Success/Low Risk)
  /// Dùng cho mức rủi ro "THẤP" (Low) hoặc các thao tác thành công.
  /// (Mã HEX: #34C759)
  static const Color success = Color(0xFF388E3C);


  // --- MÀU TRUNG TÍNH (NEUTRALS) ---

  /// ⚪ Màu nền chính của ứng dụng (Thường là màu trắng).
  /// (Mã HEX: #FFFFFF)
  static const Color background = Color(0xFFFFFFFF);

  /// ⚫ Màu văn bản chính (Dùng màu xám đen thay vì đen tuyền #000000).
  /// Giúp mắt dễ chịu hơn khi đọc lâu.
  /// (Mã HEX: #1C1C1E)
  static const Color textPrimary = Color(0xFF1C1C1E);

  /// ⚫ Màu văn bản phụ (Dùng cho các mô tả, ghi chú nhỏ).
  /// (Mã HEX: #8A8A8E)
  static const Color textSecondary = Color(0xFF8A8A8E);

  /// 🌫️ Màu xám nhạt (Light Gray)
  /// Dùng cho nền của các thẻ (Card), các đường viền (Divider, Border).
  /// (Mã HEX: #F2F2F7)
  static const Color lightGray = Color(0xFFF2F2F7);

  /// 🌫️ Màu xám viền (Border)
  /// Dùng cho viền của các ô input (TextField).
  /// (Mã HEX: #E0E0E0)
  static const Color border = Color(0xFFE0E0E0);
}