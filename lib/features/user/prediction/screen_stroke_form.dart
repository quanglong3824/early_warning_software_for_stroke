import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/stroke_prediction_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/ai_stroke_prediction_service.dart';

class ScreenStrokeForm extends StatefulWidget {
  const ScreenStrokeForm({super.key});

  @override
  State<ScreenStrokeForm> createState() => _ScreenStrokeFormState();
}

class _ScreenStrokeFormState extends State<ScreenStrokeForm> {
  final _formKey = GlobalKey<FormState>();
  final _predictionService = StrokePredictionService();
  final _authService = AuthService();
  final _aiService = AIStrokePredictionService();

  // Controllers
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _systolicBPController = TextEditingController();
  final _diastolicBPController = TextEditingController();
  final _cholesterolController = TextEditingController();
  final _glucoseController = TextEditingController();

  // State
  String _gender = 'male';
  bool _hypertension = false;
  bool _heartDisease = false;
  bool _smoking = false;
  String _workType = 'moderate';
  bool _isLoading = false;
  double? _bmi;
  bool? _apiConnected; // null = checking, true = connected, false = disconnected

  @override
  void initState() {
    super.initState();
    _checkAPIConnection();
  }

  Future<void> _checkAPIConnection() async {
    final isConnected = await _aiService.checkHealth();
    if (mounted) {
      setState(() {
        _apiConnected = isConnected;
      });
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _systolicBPController.dispose();
    _diastolicBPController.dispose();
    _cholesterolController.dispose();
    _glucoseController.dispose();
    super.dispose();
  }

  void _calculateBMI() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    
    if (height != null && weight != null && height > 0) {
      setState(() {
        _bmi = _predictionService.calculateBMI(height, weight);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final inputData = {
        'age': int.parse(_ageController.text),
        'gender': _gender,
        'heightCm': double.parse(_heightController.text),
        'weightKg': double.parse(_weightController.text),
        'systolicBP': double.parse(_systolicBPController.text),
        'diastolicBP': double.parse(_diastolicBPController.text),
        'cholesterol': double.parse(_cholesterolController.text),
        'glucose': double.parse(_glucoseController.text),
        'hypertension': _hypertension,
        'heartDisease': _heartDisease,
        'smoking': _smoking,
        'workType': _workType,
      };

      final predictionResult = await _predictionService.predictStrokeRisk(
        age: inputData['age'] as int,
        gender: inputData['gender'] as String,
        heightCm: inputData['heightCm'] as double,
        weightKg: inputData['weightKg'] as double,
        systolicBP: inputData['systolicBP'] as double,
        diastolicBP: inputData['diastolicBP'] as double,
        cholesterol: inputData['cholesterol'] as double,
        glucose: inputData['glucose'] as double,
        hypertension: inputData['hypertension'] as bool,
        heartDisease: inputData['heartDisease'] as bool,
        smoking: inputData['smoking'] as bool,
        workType: inputData['workType'] as String,
      );

      await _predictionService.savePredictionResult(
        userId: userId,
        inputData: inputData,
        predictionResult: predictionResult,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/stroke-result',
        arguments: predictionResult,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        centerTitle: true,
        title: const Text(
          'Đánh giá Nguy cơ Đột quỵ',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Thông tin quan trọng',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Vui lòng nhập chính xác các thông tin để hệ thống đưa ra dự đoán chính xác về nguy cơ đột quỵ.',
                    style: TextStyle(color: Color(0xFF616F89)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // API Status Banner
            if (_apiConnected != null)
              Container(
                decoration: BoxDecoration(
                  color: _apiConnected! 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _apiConnected! ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _apiConnected! ? Icons.check_circle : Icons.info,
                      color: _apiConnected! ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _apiConnected!
                            ? '✓ API đã được kết nối thành công! Sử dụng AI prediction'
                            : 'Sử dụng dự đoán rule-based (API không khả dụng)',
                        style: TextStyle(
                          color: _apiConnected! ? Colors.green.shade800 : Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const _SectionTitle('Thông tin cá nhân'),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Tuổi',
                hintText: 'Nhập tuổi của bạn',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập tuổi';
                final age = int.tryParse(value);
                if (age == null || age < 1 || age > 120) return 'Tuổi không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 12),
            const _FieldLabel('Giới tính'),
            Row(
              children: [
                Expanded(
                  child: _RadioOption(
                    label: 'Nam',
                    value: 'male',
                    groupValue: _gender,
                    onChanged: (value) => setState(() => _gender = value!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RadioOption(
                    label: 'Nữ',
                    value: 'female',
                    groupValue: _gender,
                    onChanged: (value) => setState(() => _gender = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Chỉ số cơ thể'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Chiều cao (cm)',
                      hintText: '170',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => _calculateBMI(),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Bắt buộc';
                      final height = double.tryParse(value);
                      if (height == null || height < 50 || height > 250) return 'Không hợp lệ';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cân nặng (kg)',
                      hintText: '65',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => _calculateBMI(),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Bắt buộc';
                      final weight = double.tryParse(value);
                      if (weight == null || weight < 20 || weight > 300) return 'Không hợp lệ';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_bmi != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chỉ số BMI của bạn',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${_bmi!.toStringAsFixed(1)} kg/m²',
                      style: const TextStyle(
                        color: Color(0xFF135BEC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const _SectionTitle('Chỉ số sinh tồn'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _systolicBPController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Huyết áp tâm thu (mmHg)',
                      hintText: '120',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Bắt buộc';
                      final bp = double.tryParse(value);
                      if (bp == null || bp < 60 || bp > 250) return 'Không hợp lệ';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _diastolicBPController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Huyết áp tâm trương (mmHg)',
                      hintText: '80',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Bắt buộc';
                      final bp = double.tryParse(value);
                      if (bp == null || bp < 40 || bp > 150) return 'Không hợp lệ';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cholesterolController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Cholesterol (mg/dL)',
                hintText: 'Ví dụ: 200',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: 'Bình thường: < 200 mg/dL',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập cholesterol';
                final chol = double.tryParse(value);
                if (chol == null || chol < 100 || chol > 400) return 'Giá trị không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _glucoseController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Đường huyết (mg/dL)',
                hintText: 'Ví dụ: 95',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: 'Bình thường: 70-99 mg/dL',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập đường huyết';
                final glucose = double.tryParse(value);
                if (glucose == null || glucose < 40 || glucose > 400) return 'Giá trị không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Tiền sử bệnh lý'),
            _SwitchTile(
              title: 'Bị tăng huyết áp',
              value: _hypertension,
              onChanged: (value) => setState(() => _hypertension = value),
            ),
            const SizedBox(height: 8),
            _SwitchTile(
              title: 'Có tiền sử bệnh tim',
              value: _heartDisease,
              onChanged: (value) => setState(() => _heartDisease = value),
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Lối sống'),
            _SwitchTile(
              title: 'Hút thuốc',
              value: _smoking,
              onChanged: (value) => setState(() => _smoking = value),
            ),
            const SizedBox(height: 12),
            const _FieldLabel('Loại hình công việc'),
            DropdownButtonFormField<String>(
              value: _workType,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'sedentary', child: Text('Ít vận động (văn phòng)')),
                DropdownMenuItem(value: 'moderate', child: Text('Vừa phải')),
                DropdownMenuItem(value: 'active', child: Text('Năng động (thể lực)')),
              ],
              onChanged: (value) => setState(() => _workType = value!),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.lock, size: 16, color: Color(0xFF616F89)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thông tin của bạn được bảo mật và chỉ được sử dụng cho mục đích phân tích nguy cơ sức khỏe.',
                    style: TextStyle(color: Color(0xFF616F89), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Xem Kết quả Dự đoán',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _RadioOption<T> extends StatelessWidget {
  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? primary : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        height: 48,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? primary : const Color(0xFF111318),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primary,
          ),
        ],
      ),
    );
  }
}
