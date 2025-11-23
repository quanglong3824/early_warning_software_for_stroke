import 'package:flutter/material.dart';
import '../../../services/doctor_service.dart';
import '../../../data/models/doctor_models.dart';

class ScreenDoctorList extends StatefulWidget {
  const ScreenDoctorList({super.key});

  @override
  State<ScreenDoctorList> createState() => _ScreenDoctorListState();
}

class _ScreenDoctorListState extends State<ScreenDoctorList> {
  final _doctorService = DoctorService();
  String _selectedSpecialty = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Danh sách Bác sĩ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bác sĩ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: bgLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  isSelected: _selectedSpecialty == 'all',
                  onSelected: (val) => setState(() => _selectedSpecialty = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tim mạch',
                  isSelected: _selectedSpecialty == 'Tim mạch',
                  onSelected: (val) => setState(() => _selectedSpecialty = 'Tim mạch'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Thần kinh',
                  isSelected: _selectedSpecialty == 'Thần kinh',
                  onSelected: (val) => setState(() => _selectedSpecialty = 'Thần kinh'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Huyết áp',
                  isSelected: _selectedSpecialty == 'Huyết áp',
                  onSelected: (val) => setState(() => _selectedSpecialty = 'Huyết áp'),
                ),
              ],
            ),
          ),

          // Doctor List
          Expanded(
            child: StreamBuilder<List<DoctorModel>>(
              stream: _doctorService.getAllDoctors(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var doctors = snapshot.data ?? [];

                // Filter by specialty
                if (_selectedSpecialty != 'all') {
                  doctors = doctors.where((d) => d.specialization == _selectedSpecialty).toList();
                }

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  doctors = doctors.where((d) => 
                    d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (d.specialization?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                  ).toList();
                }

                if (doctors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy bác sĩ nào',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    return _DoctorCard(doctor: doctors[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF135BEC),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;

  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/doctor-detail',
            arguments: doctor,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  doctor.photoURL ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(doctor.name)}&background=random',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111318),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialization ?? 'Chưa cập nhật',
                      style: const TextStyle(
                        color: Color(0xFF135BEC),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.work, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor.yearsOfExperience ?? 0} năm kinh nghiệm',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (doctor.hospital != null)
                      Text(
                        doctor.hospital!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
