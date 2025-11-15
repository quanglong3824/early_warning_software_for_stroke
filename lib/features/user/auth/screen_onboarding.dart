import 'package:flutter/material.dart';

class ScreenOnboarding extends StatefulWidget {
  const ScreenOnboarding({super.key});

  @override
  State<ScreenOnboarding> createState() => _ScreenOnboardingState();
}

class _ScreenOnboardingState extends State<ScreenOnboarding> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Chào mừng đến với SEWS',
      description: 'Bảo vệ bạn và người thân khỏi nguy cơ đột quỵ.',
      image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCXk2-RcKjFNZf20Bx5o5R61qfwbxrkgdbYmd87oVXrHEagf2_AT3CPJVengK7ViMDqLWQkORQU_8inVMVfuPXuRtUzd_5zhYbhbHmpGaAoCxTJQlzXGdw2LKCkR-pdNqWxDZsdQgcFnOw3upc54QyXzdSjs9FjFs2hEk58KdiMEHDg7MTQrGZ7LXIMxdkuB-6xQfwzzvhAFiapIYXoXxn8umrGFx3pQraCbPpC8yFEdczLtQ1aViKD2oSSFn-c52CE9puqcRpa-OY',
    ),
    OnboardingPage(
      title: 'Theo dõi sức khỏe 24/7',
      description: 'Giám sát các chỉ số sức khỏe quan trọng mọi lúc mọi nơi.',
      image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCXk2-RcKjFNZf20Bx5o5R61qfwbxrkgdbYmd87oVXrHEagf2_AT3CPJVengK7ViMDqLWQkORQU_8inVMVfuPXuRtUzd_5zhYbhbHmpGaAoCxTJQlzXGdw2LKCkR-pdNqWxDZsdQgcFnOw3upc54QyXzdSjs9FjFs2hEk58KdiMEHDg7MTQrGZ7LXIMxdkuB-6xQfwzzvhAFiapIYXoXxn8umrGFx3pQraCbPpC8yFEdczLtQ1aViKD2oSSFn-c52CE9puqcRpa-OY',
    ),
    OnboardingPage(
      title: 'Cảnh báo sớm thông minh',
      description: 'AI phân tích và cảnh báo nguy cơ đột quỵ kịp thời.',
      image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCXk2-RcKjFNZf20Bx5o5R61qfwbxrkgdbYmd87oVXrHEagf2_AT3CPJVengK7ViMDqLWQkORQU_8inVMVfuPXuRtUzd_5zhYbhbHmpGaAoCxTJQlzXGdw2LKCkR-pdNqWxDZsdQgcFnOw3upc54QyXzdSjs9FjFs2hEk58KdiMEHDg7MTQrGZ7LXIMxdkuB-6xQfwzzvhAFiapIYXoXxn8umrGFx3pQraCbPpC8yFEdczLtQ1aViKD2oSSFn-c52CE9puqcRpa-OY',
    ),
    OnboardingPage(
      title: 'Kết nối với bác sĩ',
      description: 'Tư vấn trực tuyến với đội ngũ bác sĩ chuyên môn cao.',
      image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCXk2-RcKjFNZf20Bx5o5R61qfwbxrkgdbYmd87oVXrHEagf2_AT3CPJVengK7ViMDqLWQkORQU_8inVMVfuPXuRtUzd_5zhYbhbHmpGaAoCxTJQlzXGdw2LKCkR-pdNqWxDZsdQgcFnOw3upc54QyXzdSjs9FjFs2hEk58KdiMEHDg7MTQrGZ7LXIMxdkuB-6xQfwzzvhAFiapIYXoXxn8umrGFx3pQraCbPpC8yFEdczLtQ1aViKD2oSSFn-c52CE9puqcRpa-OY',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text(
                    'Bỏ qua',
                    style: TextStyle(color: textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image
                        Container(
                          height: 320,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: NetworkImage(_pages[index].image),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Title
                        Text(
                          _pages[index].title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          _pages[index].description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? primary : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (_currentPage == _pages.length - 1) {
                    Navigator.pushReplacementNamed(context, '/login');
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(
                  _currentPage == _pages.length - 1 ? 'Bắt đầu' : 'Tiếp tục',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });
}