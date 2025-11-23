import 'package:flutter/material.dart';
import '../../../services/pharmacy_order_service.dart';
import '../../../services/auth_service.dart';
import 'screen_prescription_lookup.dart';
import 'screen_order_history.dart';

class ScreenPharmacy extends StatefulWidget {
  const ScreenPharmacy({super.key});

  @override
  State<ScreenPharmacy> createState() => _ScreenPharmacyState();
}

class _ScreenPharmacyState extends State<ScreenPharmacy> {
  final _orderService = PharmacyOrderService();
  final _authService = AuthService();
  String? _userId;
  int _orderCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = await _authService.getUserId();
    if (userId != null) {
      setState(() => _userId = userId);
      _loadOrderCount();
    }
  }

  void _loadOrderCount() {
    if (_userId == null) return;
    
    _orderService.getUserOrders(_userId!).listen((orders) {
      if (mounted) {
        setState(() {
          _orderCount = orders.where((o) => o.orderStatus != 'cancelled').length;
        });
      }
    });
  }

  void _navigateToPrescriptionLookup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScreenPrescriptionLookup()),
    );
  }

  void _navigateToOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScreenOrderHistory()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF616F89);

    final featured = [
      {
        'title': 'Nhà thuốc An Khang',
        'sub': '1.2 km - 4.5 ★',
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBPjPEjiFQlQkaUaTs_iNE8YAk1ffTNk07PFP91anbtk8idkjoty90oYT5_1dbsGI4Ooi188PGjZpGPmeAAD2sOVCExbTJKKPd0C1VUbJbQzxLYoP07ZevWNPCG96UG0AIWOP8hhd5vtgx2CuumZUYx--HtlcEDnKVetj8biPTZuzv-9ePyXd0MGXUlb_5b182-h6-uI1eeiqmzgVvXpciSAjvfvuEmYrTXQam3DEVsqMewGhIvGyV-U6kzRitj1_aQQkZmk0EKZ_8',
      },
      {
        'title': 'Nhà thuốc Pharmacity',
        'sub': '2.5 km - 4.8 ★',
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCX_pG93w5g-bg1aMkdn3_eWJhSGGbJaEkm_rYdvyZuIFi61ffmDiatX_i-y1OVLjX5q2Du0Fz9nOEtxENesR67kDfbviUdqIEJ6sbsujoEO5XF00CgqUDF_vuT3mDXInbtoEKS2wPJSCwH5QfE4aAMIgNRKSvATlsvWH4Ui-noYJjDLeO3n1448SpxiaS1BFnolpSoVCrMW3ny0XeukPK0zlHfL9SeiGlumMQ2dOw30KWqVwyKetcQ2ilBDp7Myr_4B5M1jWwT9bk',
      },
      {
        'title': 'Nhà thuốc Long Châu',
        'sub': '3.1 km - 4.7 ★',
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCEWi5TxGXwP0mSeODNh33sjOIQSx4iZZbh3Is0XPCi5gYhgHXpl7Mdgy8IM2wTASXwMHRe3YO8mbvJLcDkRYsziwO2wY1IoV8cu4wWZRykUWuROyN67SKAXfsqhjeihtU_6wkq_lBfVyr-RPSErNuKqw-dPFQkenr8MuN7qdGwUy84kf6a1N-UDVlEDsB5_vSZ2kx-LbY0KLM10B_mapOMZrHn2fDgEdS9QNDP6ilslswOeYTYA1Y2kSYWKldqLpmRsZL9WAkJ_dM',
      },
    ];

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
          'Nhà thuốc Online',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: _navigateToOrderHistory,
                icon: const Icon(Icons.shopping_cart, color: textPrimary),
              ),
              if (_orderCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _orderCount > 9 ? '9+' : '$_orderCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Expanded(
                child: InkWell(
                  onTap: _navigateToPrescriptionLookup,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 48,
                    child: Row(children: const [
                      Icon(Icons.search, color: textMuted),
                      SizedBox(width: 6),
                      Text(
                        'Tìm thuốc theo đơn...',
                        style: TextStyle(color: textMuted),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.tune, color: textPrimary),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Nhà thuốc nổi bật',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final item = featured[index];
                      return _FeaturedCard(
                        title: item['title']!,
                        subtitle: item['sub']!,
                        imageUrl: item['image']!,
                        onTap: _navigateToPrescriptionLookup,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: featured.length,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Danh mục sản phẩm',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _Category(
                        icon: Icons.medication,
                        label: 'Thuốc kê đơn',
                        onTap: _navigateToPrescriptionLookup,
                      ),
                      _Category(
                        icon: Icons.history,
                        label: 'Lịch sử đơn hàng',
                        onTap: _navigateToOrderHistory,
                      ),
                      _Category(
                        icon: Icons.health_and_safety,
                        label: 'Thực phẩm chức năng',
                        onTap: () => _showComingSoon(context),
                      ),
                      _Category(
                        icon: Icons.biotech,
                        label: 'Thiết bị y tế',
                        onTap: () => _showComingSoon(context),
                      ),
                      _Category(
                        icon: Icons.local_drink,
                        label: 'Vitamin',
                        onTap: () => _showComingSoon(context),
                      ),
                      _Category(
                        icon: Icons.local_hospital,
                        label: 'Giảm đau',
                        onTap: () => _showComingSoon(context),
                      ),
                      _Category(
                        icon: Icons.child_care,
                        label: 'Mẹ & Bé',
                        onTap: () => _showComingSoon(context),
                      ),
                      _Category(
                        icon: Icons.more_horiz,
                        label: 'Xem thêm',
                        onTap: () => _showComingSoon(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đang phát triển'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                width: 240,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF616F89),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Category extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _Category({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}