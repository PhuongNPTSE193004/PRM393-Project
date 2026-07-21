import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openMap(BuildContext context) async {
    const address = "171 Lê Thánh Tôn, Bến Thành, Hồ Chí Minh, Vietnam";
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở bản đồ')),
        );
      }
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    const email = 'contact@airsoftshop.vn';
    final Uri emailLaunchUri = Uri(
      scheme: 'mail to',
      path: email,
      query: 'subject=${Uri.encodeComponent('Hỏi về trang bị Airsoft')}',
    );

    // Copy to clipboard as a reliable fallback
    await Clipboard.setData(const ClipboardData(text: email));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép email vào bộ nhớ tạm: $email'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
      // Try to launch the email app
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch email app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        foregroundColor: kNeon,
        title: const Text(
          'THÔNG TIN CỬA HÀNG',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AIRSOFT SHOP',
              style: TextStyle(
                color: kNeon,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ĐAM MÊ - KỸ NĂNG - TRẢI NGHIỆM',
              style: TextStyle(
                color: kNeon,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chào mừng bạn đến với Airsoft Shop - điểm đến hàng đầu cho cộng đồng yêu thích bộ môn bắn súng mô hình tại Việt Nam. Chúng tôi tự hào cung cấp các dòng sản phẩm AEG, GBB và Sniper chính hãng từ những thương hiệu nổi tiếng thế giới.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tại đây, chúng tôi không chỉ bán sản phẩm, chúng tôi chia sẻ đam mê. Từ trang bị bảo hộ đến các phụ kiện nâng cấp tối tân, Airsoft Shop cam kết mang lại trải nghiệm chuyên nghiệp và an toàn nhất cho mọi "chiến binh".',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Text(
                'LƯU Ý: Tất cả sản phẩm tại cửa hàng đều là mô hình giải trí, không phải vũ khí và không có khả năng gây thương tích. Vui lòng sử dụng đúng mục đích và tuân thủ pháp luật.',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'GIỜ HOẠT ĐỘNG',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.access_time, color: kNeon),
              title: Text(
                '8:00 AM - 9:00 PM (Thứ 2 - Chủ Nhật)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'ĐỊA CHỈ',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: kNeon.withOpacity(0.5)),
                color: kBackground,
              ),
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(10.7725, 106.6980),
                  initialZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.airsoft_shop',
                  ),
                  const MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(10.7725, 106.6980),
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _openMap(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: kNeon.withOpacity(0.5)),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: kNeon, size: 24),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        '171 Lê Thánh Tôn, Bến Thành, Quận 1, Hồ Chí Minh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.open_in_new, color: Colors.white38, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'LIÊN HỆ',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.phone, color: kNeon),
              title: Text(
                '0123 456 789',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              onTap: () => _sendEmail(context),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email, color: kNeon),
              title: const Text(
                'contact@airsoftshop.vn',
                style: TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
              trailing: const Icon(Icons.send, color: Colors.white38, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
