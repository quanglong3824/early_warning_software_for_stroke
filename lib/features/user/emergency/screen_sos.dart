import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/sos_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/location_service.dart';

class ScreenSOS extends StatefulWidget {
  const ScreenSOS({super.key});

  @override
  State<ScreenSOS> createState() => _ScreenSOSState();
}

class _ScreenSOSState extends State<ScreenSOS> with SingleTickerProviderStateMixin {
  bool _showConfirmation = false;
  bool _isLoading = false;
  late AnimationController _pulseController;
  
  final _sosService = SOSService();
  final _authService = AuthService();
  final _locationService = LocationService();
  
  String? _currentAddress;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  Future<void> _checkLocationPermission() async {
    final permission = await _locationService.checkPermission();
    setState(() {
      _locationPermissionGranted = permission == LocationPermission.always || 
                                   permission == LocationPermission.whileInUse;
    });
    
    if (_locationPermissionGranted) {
      _getCurrentAddress();
    }
  }
  
  Future<void> _getCurrentAddress() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _currentAddress = address;
      });
    }
  }
  
  Future<void> _requestLocationPermission() async {
    final permission = await _locationService.requestPermission();
    setState(() {
      _locationPermissionGranted = permission == LocationPermission.always || 
                                   permission == LocationPermission.whileInUse;
    });
    
    if (_locationPermissionGranted) {
      _getCurrentAddress();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cần cấp quyền vị trí để sử dụng tính năng SOS'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _sendSOS() async {
    if (!_locationPermissionGranted) {
      await _requestLocationPermission();
      return;
    }
    
    setState(() {
      _isLoading = true;
      _showConfirmation = false;
    });
    
    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');
      
      // Create SOS request
      final sosId = await _sosService.createSOSRequest(
        patientId: userId,
        patientName: await _authService.getUserName(),
        notes: 'Yêu cầu cấp cứu khẩn cấp',
      );
      
      if (sosId != null) {
        // Navigate to SOS status screen
        Navigator.pushReplacementNamed(
          context,
          '/sos-status',
          arguments: {'sosId': sosId},
        );
      } else {
        throw Exception('Không thể tạo yêu cầu SOS');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF8F6F6);
    const primary = Color(0xFFEC1313);
    const textPrimary = Color(0xFF181111);
    const textMuted = Color(0xFF71717A);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Cảnh báo khẩn cấp',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'KÍCH HOẠT SOS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Text(
                        'Nhấn nút để gửi cảnh báo đến người thân và dịch vụ y tế.',
                        style: TextStyle(color: textMuted),
                        textAlign: TextAlign.center,
                      ),
                      if (_currentAddress != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentAddress!,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!_locationPermissionGranted) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Cần cấp quyền vị trí',
                                  style: TextStyle(fontSize: 12, color: Colors.orange),
                                ),
                              ),
                              TextButton(
                                onPressed: _requestLocationPermission,
                                child: const Text('Cấp quyền'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // SOS Button with pulse animation
                GestureDetector(
                  onTap: _isLoading ? null : () {
                    setState(() {
                      _showConfirmation = true;
                    });
                  },
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse effect
                          Container(
                            width: 224 + (_pulseController.value * 40),
                            height: 224 + (_pulseController.value * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withOpacity(0.3 * (1 - _pulseController.value)),
                            ),
                          ),
                          // Main button
                          Container(
                            width: 224,
                            height: 224,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isLoading ? Colors.grey : primary,
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'SOS',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 8,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '☎️ Hoặc gọi 115',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Confirmation Modal
          if (_showConfirmation)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: bgLight,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Bạn chắc chắn muốn gửi tín hiệu SOS?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Một cảnh báo khẩn cấp cùng vị trí của bạn sẽ được gửi ngay lập tức.',
                        style: TextStyle(fontSize: 14, color: textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _sendSOS,
                        child: const Text(
                          'Gửi ngay',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _showConfirmation = false;
                          });
                        },
                        child: const Text(
                          'Hủy',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}