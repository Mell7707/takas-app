import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TestHelper {
  static void logError(String alan, dynamic hata) {
    debugPrint('🚨 [MockDataEngine Error] $alan: $hata');
  }

  // 🚀 SADECE ARAÇ VE KONUT KATEGORİLERİ İÇİN 50 ADET TEST İLANI MOTORU
  static Future<void> simulasyonVerileriniYukle({
    required Function(Map<String, dynamic>) onIlanEkleYerel,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? 'test_user_global';

    // 🚗 Araç Havuzu
    final List<Map<String, dynamic>> aracHavuzu = [
      {'marka': 'Mercedes', 'model': 'E200', 'yil': '2024', 'vites': 'Otomatik', 'km': '15.000', 'foto': 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?auto=format&fit=crop&w=800&q=80'},
      {'marka': 'BMW', 'model': '520i', 'yil': '2023', 'vites': 'Otomatik', 'km': '28.000', 'foto': 'https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&w=800&q=80'},
      {'marka': 'Audi', 'model': 'A6', 'yil': '2024', 'vites': 'Otomatik', 'km': '10.000', 'foto': 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?auto=format&fit=crop&w=800&q=80'},
      {'marka': 'Volvo', 'model': 'XC90', 'yil': '2022', 'vites': 'Otomatik', 'km': '45.000', 'foto': 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=800&q=80'},
      {'marka': 'Porsche', 'model': 'Macan', 'yil': '2023', 'vites': 'Otomatik', 'km': '20.000', 'foto': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&q=80'},
    ];

    // 🏠 Ev / Konut Havuzu
    final List<Map<String, dynamic>> evHavuzu = [
      {'konutTipi': 'Lüks Daire', 'oda': '3+1', 'm2': '160', 'detay': 'Kadıköy merkezde deniz manzaralı, full yapılı lüks daire.', 'foto': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80'},
      {'konutTipi': 'Müstakil Villa', 'oda': '5+2', 'm2': '350', 'detay': 'Gölbaşı kıyısında özel havuzlu müstakil villa.', 'foto': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80'},
      {'konutTipi': 'Rezidans', 'oda': '2+1', 'm2': '110', 'detay': 'Levent iş merkezine yakın, güvenlikli ve havuzlu rezidans.', 'foto': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80'},
      {'konutTipi': 'Dubleks', 'oda': '4+1', 'm2': '220', 'detay': 'Bornova çamlık altında teraslı, ferah dubleks daire.', 'foto': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80'},
    ];

    final iller = ['İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Muğla'];
    final ilceler = {
      'İstanbul': ['Kadıköy', 'Beşiktaş', 'Şişli', 'Üsküdar'],
      'Ankara': ['Çankaya', 'Ümitköy', 'Gölbaşı'],
      'İzmir': ['Çeşme', 'Alsancak', 'Urla'],
      'Bursa': ['Nilüfer', 'Mudanya'],
      'Antalya': ['Muratpaşa', 'Konyaaltı'],
      'Muğla': ['Bodrum', 'Fethiye'],
    };

    int basariliSayac = 0;
    final random = Random();

    for (int i = 1; i <= 50; i++) {
      try {
        String kategori;
        Map<String, dynamic> kategoriKriterleri = {};
        String detay = '';
        String secilenFoto = '';

        if (i % 2 == 0) {
          kategori = 'Araç';
          final item = aracHavuzu[i % aracHavuzu.length];
          secilenFoto = item['foto'];
          kategoriKriterleri = {
            'marka': item['marka'],
            'model': item['model'],
            'yil': item['yil'],
            'vites': item['vites'],
            'kilometre': item['km'],
          };
          detay = '${item['yil']} model ${item['marka']} ${item['model']} (${item['km']} km). Masrafsız, hatasız takaslık araç.';
        } else {
          kategori = 'Konut';
          final item = evHavuzu[i % evHavuzu.length];
          secilenFoto = item['foto'];
          kategoriKriterleri = {
            'konutTipi': item['konutTipi'],
            'odaSayisi': item['oda'],
            'metrekare': item['m2'],
          };
          detay = item['detay'];
        }

        // 🛡️ GÜVENLİK: İlçe dizisinin null veya boyut aşımı olma ihtimaline karşı fallback eklendi
        final String rastgeleIl = iller.isNotEmpty ? iller[i % iller.length] : 'İstanbul';
        final List<String> ilceListesi = ilceler[rastgeleIl] ?? ['Merkez'];
        final String rastgeleIlce = ilceListesi.isNotEmpty ? ilceListesi[i % ilceListesi.length] : 'Merkez';

        final String hedefIl = iller.isNotEmpty ? iller[(i + 1) % iller.length] : 'Ankara';
        final List<String> hedefIlceListesi = ilceler[hedefIl] ?? ['Merkez'];
        final String hedefIlce = hedefIlceListesi.isNotEmpty ? hedefIlceListesi[i % hedefIlceListesi.length] : 'Merkez';

        // 🛡️ TİP GÜVENLİĞİ: Çökmeyi engellemek için kesim çift noktalı sayı (double) garantisi
        final double talepEdilenNakitFarki = (i % 4 == 0) ? ((random.nextInt(5) + 1) * 30000).toDouble() : 0.0;

        final Map<String, dynamic> yeniSimulasyonIlani = {
          'kategori': kategori,
          'detay': detay,
          'mevcutIl': rastgeleIl,
          'mevcutIlce': rastgeleIlce,
          'hedefIl': hedefIl,
          'hedefIlce': hedefIlce,
          'baslangicTarihi': '16/9/2026',
          'bitisTarihi': '30/10/2026',
          'isDateFlexible': (i % 2 == 0),
          'userId': currentUserUid,
          'createdAt': FieldValue.serverTimestamp(),
          'fotograflar': [secilenFoto],
          'cashDifference': talepEdilenNakitFarki,
          'sahipIsmi': 'Kullanıcı #$i',
          ...kategoriKriterleri
        };

        await firestore.collection('ilanlar').add(yeniSimulasyonIlani);
        // Hata almamak için güvenli kopya gönderilir
        onIlanEkleYerel(Map<String, dynamic>.from(yeniSimulasyonIlani));
        basariliSayac++;
      } catch (e) {
        logError('Ekleme Hatası ($i)', e);
      }
    }
    debugPrint('🟩 $basariliSayac adet araç ve konut simülasyon ilanı başarıyla yüklendi.');
  }
}