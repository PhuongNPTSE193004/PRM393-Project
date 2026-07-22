import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SeedService {
  final FirebaseFirestore _firestore;

  SeedService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> seedInitialData({bool force = false}) async {
    final productsCollection = _firestore.collection('products');

    if (!force) {
      final existingDocs = await productsCollection.limit(1).get();
      if (existingDocs.docs.isNotEmpty) {
        debugPrint('Firestore already contains product data. Skipping seed.');
        return;
      }
    }

    final batch = _firestore.batch();

    final List<Map<String, dynamic>> productsData = [
      {
        'slug': 'm4a1-carbine',
        'name': 'M4A1 Carbine AEG',
        'price': 4500000.0,
        'discountPrice': 3950000.0,
        'rating': 4.7,
        'fps': 400,
        'stock': 8,
        'categorySlug': 'aeg',
        'brand': 'Tokyo Marui',
        'material': 'Polymer & Metal',
        'magazine': '300 rounds Hi-Cap',
        'battery': '9.6V NiMH / 7.4V LiPo',
        'fireMode': 'Safe/Semi/Full Auto',
        'powerSource': 'Electric (AEG)',
        'barrelLength': 363.0,
        'weight': 2.9,
        'warranty': '12 months',
        'description': 'Biểu tượng súng trường tấn công với gearbox v2 siêu bền từ Tokyo Marui. Độ chính xác tuyệt đối và độ ổn định cao.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/airsoft-mobile-store.appspot.com/o/products%2Fm4a1.jpg?alt=media',
        ],
      },
      {
        'slug': 'ak47-tactical',
        'name': 'AK-47 Tactical Steel Edition',
        'price': 3800000.0,
        'rating': 4.6,
        'fps': 420,
        'stock': 12,
        'categorySlug': 'aeg',
        'brand': 'CYMA',
        'material': 'Steel & Gỗ Thật',
        'magazine': '600 rounds Hi-Cap',
        'battery': '9.6V Stick Type',
        'fireMode': 'Safe/Semi/Full Auto',
        'powerSource': 'Electric (AEG)',
        'barrelLength': 455.0,
        'weight': 3.8,
        'warranty': '6 months',
        'description': 'Phiên bản AK-47 vỏ thép nguyên khối cùng ốp tay gỗ thật mang lại cảm giác chân thực và chắc chắn tuyệt đối.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/airsoft-mobile-store.appspot.com/o/products%2Fak47.jpg?alt=media',
        ],
      },
      {
        'slug': 'hk416-a5',
        'name': 'HK416 A5 Full Metal AEG',
        'price': 8500000.0,
        'rating': 4.9,
        'fps': 390,
        'stock': 4,
        'categorySlug': 'aeg',
        'brand': 'VFC',
        'material': 'Full Metal CNC',
        'magazine': '120 rounds Mid-Cap',
        'battery': '11.1V LiPo Ready',
        'fireMode': 'Safe/Semi/Full Auto',
        'powerSource': 'Electric (AEG)',
        'barrelLength': 410.0,
        'weight': 3.1,
        'warranty': '12 months',
        'description': 'Dòng HK416 khắc bản quyền Heckler & Koch chính hãng. Tích hợp sẵn MOSFET điều tốc và nòng chính xác 6.03mm.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/airsoft-mobile-store.appspot.com/o/products%2Fhk416.jpg?alt=media',
        ],
      },
      {
        'slug': 'glock19-gen4',
        'name': 'Glock 19 Gen 4 GBB',
        'price': 2500000.0,
        'discountPrice': 2100000.0,
        'rating': 4.8,
        'fps': 300,
        'stock': 15,
        'categorySlug': 'gbb',
        'brand': 'WE-Tech',
        'material': 'Kim Loại & Polymer',
        'magazine': '24 rounds Gas Mag',
        'battery': null,
        'fireMode': 'Safe/Semi',
        'powerSource': 'Green Gas (GBB)',
        'barrelLength': 97.0,
        'weight': 0.65,
        'warranty': '6 months',
        'description': 'Súng lục gas blowback nhỏ gọn với lực giật (recoil) mạnh mẽ, khoá slide kim loại khắc logo sắc nét.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/airsoft-mobile-store.appspot.com/o/products%2Fglock19.jpg?alt=media',
        ],
      },
      {
        'slug': 'colt-m1911a1',
        'name': 'Colt M1911 A1 Classic GBB',
        'price': 2700000.0,
        'rating': 4.5,
        'fps': 320,
        'stock': 6,
        'categorySlug': 'gbb',
        'brand': 'KJW',
        'material': 'Full Metal',
        'magazine': '26 rounds CO2/Gas',
        'battery': null,
        'fireMode': 'Safe/Semi',
        'powerSource': 'CO2 / Green Gas',
        'barrelLength': 128.0,
        'weight': 1.1,
        'warranty': '6 months',
        'description': 'Mẫu súng lục huyền thoại Thế chiến II làm hoàn toàn bằng kim loại, tương thích cả băng gas Green Gas và CO2.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/airsoft-mobile-store.appspot.com/o/products%2Fm1911.jpg?alt=media',
        ],
      },
      {
        'slug': 'hicapa-51-gold',
        'name': 'Hi-Capa 5.1 Gold Match GBB',
        'price': 4200000.0,
        'rating': 4.9,
        'fps': 310,
        'stock': 10,
        'categorySlug': 'gbb',
        'brand': 'Tokyo Marui',
        'material': 'Polymer Cao Cấp',
        'magazine': '31 rounds Double Stack',
        'battery': null,
        'fireMode': 'Safe/Semi',
        'powerSource': 'Green Gas (GBB)',
        'barrelLength': 112.0,
        'weight': 0.85,
        'warranty': '12 months',
        'description': 'Vua của các dòng súng lục Speedsoft với tốc độ xả đạn cực nhanh, các chi tiết mạ vàng sang trọng và chính xác tuyệt đỉnh.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/airsoft-mobile-store.appspot.com/o/products%2Fhicapa.jpg?alt=media',
        ],
      },
      {
        'slug': 'vsr10-pro-sniper',
        'name': 'VSR-10 Pro Sniper Bolt-Action',
        'price': 6000000.0,
        'rating': 4.9,
        'fps': 480,
        'stock': 0, // Set to 0 to test out-of-stock features
        'categorySlug': 'sniper',
        'brand': 'Tokyo Marui',
        'material': 'Polymer & Nòng Thép',
        'magazine': '30 rounds Box Mag',
        'battery': null,
        'fireMode': 'Safe/Single-Shot Bolt Action',
        'powerSource': 'Spring (Bolt Action)',
        'barrelLength': 430.0,
        'weight': 1.9,
        'warranty': '12 months',
        'description': 'Huyền thoại súng ngắm Airsoft. Nòng thép nguyên khối mạ đen cùng cơ chế kéo bolt êm ái, bóp cò cực nhạy.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/airsoft-mobile-store.appspot.com/o/products%2Fvsr10.jpg?alt=media',
        ],
      },
      {
        'slug': 'l96-aws-sniper',
        'name': 'L96 AWS Tactical Sniper Rifle',
        'price': 4200000.0,
        'rating': 4.6,
        'fps': 450,
        'stock': 5,
        'categorySlug': 'sniper',
        'brand': 'Well',
        'material': 'Kim Loại & Báng Nhựa ABS',
        'magazine': '40 rounds Mag',
        'battery': null,
        'description': 'Mẫu súng bắn đai bệ tì má điều chỉnh độ cao linh hoạt, đi kèm chân chống bipod và ống ngắm 3-9x40.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/airsoft-mobile-store.appspot.com/o/products%2Fl96.jpg?alt=media',
        ],
      },
      {
        'slug': 'tactical-vest-jpc',
        'name': 'Áo Giáp Tactical Vest JPC 2.0',
        'price': 1200000.0,
        'rating': 4.4,
        'fps': null,
        'stock': 20,
        'categorySlug': 'gear',
        'brand': 'EmersonGear',
        'material': 'Vải Cordura 500D',
        'magazine': null,
        'battery': null,
        'description': 'Áo giáp bảo vệ siêu nhẹ chống mài mòn, tích hợp hệ thống đỉa gài MOLLE và túi đựng 3 băng đạn M4 phía trước.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/airsoft-mobile-store.appspot.com/o/products%2Fvest.jpg?alt=media',
        ],
      },
      {
        'slug': 'fast-pj-helmet',
        'name': 'Mũ Bảo Hiểm Fast PJ Tactical',
        'price': 8500000.0,
        'rating': 4.3,
        'fps': null,
        'stock': 25,
        'categorySlug': 'gear',
        'brand': 'FMA',
        'material': 'ABS Polymer',
        'magazine': null,
        'battery': null,
        'description': 'Mũ bảo hiểm chiến thuật trang bị ray gài phụ kiện 2 bên và ngàm gắn kính nhìn đêm NVG chuyên nghiệp.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/airsoft-mobile-store.appspot.com/o/products%2Fhelmet.jpg?alt=media',
        ],
      },
      {
        'slug': 'dye-i5-mask',
        'name': 'Mặt Nạ Chống Sương Dye i5 Thermal',
        'price': 3500000.0,
        'rating': 4.9,
        'fps': null,
        'stock': 7,
        'categorySlug': 'gear',
        'brand': 'Dye Precision',
        'material': 'Polycarbonate Kính Đôi',
        'magazine': null,
        'battery': null,
        'description': 'Mặt nạ bảo hộ cao cấp nhất thế giới với tròng kính đôi chống đọng sương 100%, góc nhìn rộng 290 độ.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/airsoft-mobile-store.appspot.com/o/products%2Fmask.jpg?alt=media',
        ],
      },
    ];

    for (final p in productsData) {
      final docRef = productsCollection.doc(p['slug'] as String);
      batch.set(docRef, p, SetOptions(merge: true));
    }

    // Seed a global notification store announcement
    final notifRef = _firestore.collection('notifications').doc('welcome-promo');
    batch.set(notifRef, {
      'user_id': 'all',
      'title': 'Chào mừng đến với Airsoft Shop!',
      'body': 'Nhập mã TACTIC20 tại giỏ hàng để được giảm 20% cho đơn hàng đầu tiên của bạn.',
      'kind': 'promo',
      'created_at': FieldValue.serverTimestamp(),
      'read': false,
    }, SetOptions(merge: true));

    await batch.commit();
    debugPrint('Firestore seed data populated successfully!');
  }
}
