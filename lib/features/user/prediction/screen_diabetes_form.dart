import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/diabetes_prediction_service.dart';
import '../../../services/auth_service.dart';

class ScreenDiabetesForm extends StatefulWidget {
  const ScreenDiabetesForm({super.key});

  @override
  State<ScreenDiabetesForm> createState() => _ScreenDiabetesFormState();
}

class _ScreenDiabetesFormState extends State<ScreenDiabetesForm> {
  final _formKey = GlobalKey<FormState>();
  final _predictionService = DiabetesPredictionService();
  final _authService = AuthService();

  // Controllers
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _bpController = TextEditingController();

  // State
  String _gender = 'male';
  bool _familyHistory = false;
  String _activityLevel = 'moderate';
  bool _isLoading = false;
  double? _bmi;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _glucoseController.dispose();
    _bpController.dispose();
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
        'fastingGlucose': double.parse(_glucoseController.text),
        'systolicBP': double.parse(_bpController.text),
        'familyHistory': _familyHistory,
        'activityLevel': _activityLevel,
      };

      final predictionResult = _predictionService.predictDiabetesRisk(
        age: inputData['age'] as int,
        gender: inputData['gender'] as String,
        heightCm: inputData['heightCm'] as double,
        weightKg: inputData['weightKg'] as double,
        fastingGlucose: inputData['fastingGlucose'] as double,
        systolicBP: inputData['systolicBP'] as double,
        familyHistory: inputData['familyHistory'] as bool,
        activityLevel: inputData['activityLevel'] as String,
      );

      await _predictionService.savePredictionResult(
        userId: userId,
        inputData: inputData,
        predictionResult: predictionResult,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/diabetes-result',
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
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: textPrimary), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: const Text('Đánh giá Nguy cơ Tiểu đường', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            const _InfoCard(),
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
              _BMIBox(value: '${_bmi!.toStringAsFixed(1)} kg/m²'),
            const SizedBox(height: 16),
            const _SectionTitle('Chỉ số y tế'),
            TextFormField(
              controller: _glucoseController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Mức đường huyết lúc đói (mg/dL)',
                hintText: 'Ví dụ: 95',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: 'Bình thường: 70-99 mg/dL',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập mức đường huyết';
                final glucose = double.tryParse(value);
                if (glucose == null || glucose < 40 || glucose > 400) return 'Giá trị không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Huyết áp tâm thu (mmHg)',
                hintText: 'Ví dụ: 120',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: 'Bình thường: < 120 mmHg',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập huyết áp';
                final bp = double.tryParse(value);
                if (bp == null || bp < 60 || bp > 250) return 'Giá trị không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Lối sống & Tiền sử'),
            const _FieldLabel('Tiền sử gia đình mắc bệnh tiểu đường'),
            Row(
              children: [
                Expanded(
                  child: _RadioOption(
                    label: 'Có',
                    value: true,
                    groupValue: _familyHistory,
                    onChanged: (value) => setState(() => _familyHistory = value!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RadioOption(
                    label: 'Không',
                    value: false,
                    groupValue: _familyHistory,
                    onChanged: (value) => setState(() => _familyHistory = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _FieldLabel('Mức độ hoạt động thể chất'),
            DropdownButtonFormField<String>(
              value: _activityLevel,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Ít vận động')),
                DropdownMenuItem(value: 'moderate', child: Text('Vừa phải')),
                DropdownMenuItem(value: 'high', child: Text('Năng động')),
              ],
              onChanged: (value) => setState(() => _activityLevel = value!),
            ),
            const SizedBox(height: 12),
            const _PrivacyNote(),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard();
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return Container(
      decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Thông tin quan trọng', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(height: 4),
        Text('Vui lòng nhập chính xác các thông tin dưới đây để hệ thống có thể đưa ra dự đoán chính xác nhất về nguy cơ tiểu đường của bạn.', style: TextStyle(color: Color(0xFF616F89))),
      ]),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double percent;
  const _ProgressBar({required this.label, required this.percent});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFDBDFE6), borderRadius: BorderRadius.circular(8)), child: FractionallySizedBox(widthFactor: percent, alignment: Alignment.centerLeft, child: Container(decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8))))),
      const SizedBox(height: 12),
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    return Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)));
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600))));
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  const _LabeledField({required this.label, required this.hint});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FieldLabel(label),
      TextField(decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    ]);
  }
}

class _TwoCols extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _TwoCols({required this.left, required this.right});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: left),
      const SizedBox(width: 12),
      Expanded(child: right),
    ]);
  }
}

class _BMIBox extends StatelessWidget {
  final String value;
  const _BMIBox({required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Chỉ số BMI của bạn', style: TextStyle(fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(color: Color(0xFF135BEC), fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _SegmentOptions extends StatelessWidget {
  final List<String> options;
  const _SegmentOptions({required this.options});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return Row(children: [
      for (var i = 0; i < options.length; i++)
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: i == 0 ? primary.withOpacity(0.1) : Colors.white, border: Border.all(color: i == 0 ? primary : const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            height: 48,
            child: Text(options[i], style: TextStyle(color: i == 0 ? primary : const Color(0xFF111318), fontWeight: FontWeight.w600)),
          ),
        ),
    ]);
  }
}

class _Dropdown extends StatelessWidget {
  final List<String> items;
  const _Dropdown({required this.items});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 48,
      alignment: Alignment.centerLeft,
      child: Text(items.first),
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

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Icon(Icons.lock, size: 16, color: Color(0xFF616F89)),
      SizedBox(width: 8),
      Expanded(child: Text('Thông tin của bạn được bảo mật và chỉ được sử dụng cho mục đích phân tích nguy cơ sức khỏe.', style: TextStyle(color: Color(0xFF616F89), fontSize: 12))),
    ]);
  }
}