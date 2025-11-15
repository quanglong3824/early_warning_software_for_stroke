import 'package:flutter/material.dart';

class ScreenSOSStatus extends StatelessWidget {
  const ScreenSOSStatus({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'TRẠNG THÁI SOS',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_hospital, size: 40, color: Colors.green),
                  ),
                ),
                const SizedBox(height: 24),
                // Status Text
                const Text(
                  'ĐỘI CỨU HỘ ĐANG ĐẾN',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dự kiến đến trong: 8 phút',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Map
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAFJcP_HS8ClkYW25k4fLE4GG_57x5YBkXhIx2ZrO1d7m02W1cr5dP7ft40YKdGmcHMLstTcx0rgZiuKvzfk4DG44QAMvC0PP48ejxv1zTOmB4qsbdVu92ivsA9KzD1MtjBWCUPxB72vqtz--bdM3JOg2ErKMx1CUx7kmjNaxgW_vSlweYQHvtPGnwM2SlU33-pSg96enNikAH6TnKG1yOZn6iVrHXDKXsD_Vl4QBRroJwaDsMQpAHrVPZAJRAVlRrSkzr676ySPLo'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Patient Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person, color: primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Nguyễn Văn A, 45 tuổi',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '123 Đường ABC, Phường X, Quận Y',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text('CHIA SẺ', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgLight.withOpacity(0.8),
              border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.call),
                  label: const Text('Gọi 115', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy Yêu Cầu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}