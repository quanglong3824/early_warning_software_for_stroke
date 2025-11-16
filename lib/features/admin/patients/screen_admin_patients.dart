import 'package:flutter/material.dart';

class ScreenAdminPatients extends StatefulWidget {
  const ScreenAdminPatients({super.key});

  @override
  State<ScreenAdminPatients> createState() => _ScreenAdminPatientsState();
}

class _ScreenAdminPatientsState extends State<ScreenAdminPatients> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Quản lý Bệnh nhân'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm bệnh nhân...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 15,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text('BN${index + 1}'),
                      ),
                      title: Text('Bệnh nhân ${index + 1}'),
                      subtitle: Text('Mã BN: BN00${index + 1} • Tuổi: ${30 + index}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(index % 2 == 0 ? 'Đang điều trị' : 'Đã khỏi',
                                style: const TextStyle(fontSize: 12)),
                            backgroundColor: index % 2 == 0
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
