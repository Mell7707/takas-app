import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:takas_app/services/app_core_helper.dart'; // 🔑 MERKEZİ IMPORT MÜHÜRLENDİ

class CalendarMatchScreen extends StatelessWidget {
  final String activeAdId;
  final String category;
  final String baslangicTarihi;
  final String bitisTarihi;

  const CalendarMatchScreen({
    super.key,
    required this.activeAdId,
    required this.category,
    required this.baslangicTarihi,
    required this.bitisTarihi,
  });

  // Gün Bazlı Akıllı Takvim Eşleşme Algoritması
  int _calculateMatchScore({
    required DateTime userStart,
    required DateTime userEnd,
    required DateTime targetStart,
    required DateTime targetEnd,
  }) {
    final sA = DateTime(userStart.year, userStart.month, userStart.day);
    final eA = DateTime(userEnd.year, userEnd.month, userEnd.day);
    final sB = DateTime(targetStart.year, targetStart.month, targetStart.day);
    final eB = DateTime(targetEnd.year, targetEnd.month, targetEnd.day);
    
    // 1. Durum: Tam Çakışma Kontrolü
    bool isOverlapping =
        (sA.isBefore(eB) || sA.isAtSameMomentAs(eB)) &&
        (eA.isAfter(sB) || eA.isAtSameMomentAs(sB));
    if (isOverlapping) return 2;
    
    // 2. Durum: Yakın Tarih / Esnek Eşleşme Kontrolü (3 Gün Esneklik)
    int startDiff = sA.difference(eB).inDays.abs();
    int endDiff = eA.difference(sB).inDays.abs();
    if (startDiff <= 3 || endDiff <= 3) return 1;
    
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // 🧠 GÜVENLİ ALTYAPI: Tarih çözümleri artık tek bir merkezden besleniyor, çökme riski sıfırlandı!
    final DateTime userStart =
        AppCoreHelper.parseStringToDate(baslangicTarihi) ?? DateTime.now();
    final DateTime userEnd =
        AppCoreHelper.parseStringToDate(bitisTarihi) ?? DateTime.now();
        
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xff0f0f15),
      appBar: AppBar(
        title: const Text(
          'Akıllı Takvim Eşleşmeleri',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xff1a1a24),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Aktif Kullanıcı İlanının Takvim Mührü Özeti
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xff1a1a24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Senin İlanının Takvim Mührü ($category)',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.greenAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$baslangicTarihi / $bitisTarihi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Anlık Firestore Eşleşme Havuzu
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ilanlar')
                  .where('kategori', isEqualTo: category)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Veri akışı sağlanamadı.',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  );
                }
                
                final docs = snapshot.data?.docs ?? [];
                List<Map<String, dynamic>> matchedAds = [];
                
                for (var doc in docs) {
                  if (doc.id == activeAdId) continue;
                  if (doc.data() == null) continue;
                  
                  final data = doc.data() as Map<String, dynamic>;
                  if (currentUid != null && data['userId'] == currentUid) {
                    continue;
                  }
                  
                  final String targetStartStr = (
                      data['_baslangicTarihi'] ??
                      data['baslangicTarihi'] ??
                      data['baslangic'] ??
                      ''
                  ).toString();
                  
                  final String targetEndStr = (
                      data['_bitisTarihi'] ??
                      data['bitisTarihi'] ??
                      data['bitis'] ??
                      ''
                  ).toString();
                  
                  if (targetStartStr.isEmpty || targetEndStr.isEmpty) continue;
                  
                  final DateTime targetStart =
                      AppCoreHelper.parseStringToDate(targetStartStr) ??
                      DateTime.now();
                  final DateTime targetEnd =
                      AppCoreHelper.parseStringToDate(targetEndStr) ??
                      DateTime.now();
                      
                  int score = _calculateMatchScore(
                    userStart: userStart,
                    userEnd: userEnd,
                    targetStart: targetStart,
                    targetEnd: targetEnd,
                  );
                  
                  if (score > 0) {
                    data['id'] = doc.id;
                    data['matchScore'] = score;
                    matchedAds.add(data);
                  }
                }
                
                matchedAds.sort(
                  (a, b) => ((b['matchScore'] ?? 0) as int).compareTo(
                    (a['matchScore'] ?? 0) as int,
                  ),
                );
                
                if (matchedAds.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bu tarih aralığına uygun eşleşme bulunamadı.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: matchedAds.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemBuilder: (context, index) {
                    final ad = matchedAds[index];
                    final int score = ad['matchScore'] ?? 1;
                    final String gorselUrl = (ad['gorsel'] ?? '').toString();
                    final String ilanBaslik = (ad['baslik'] ?? 'Takas İlanı').toString();
                    final String ilanDetay = (ad['detay'] ?? 'Açıklama belirtilmedi').toString();
                    
                    final String tStart = (
                        ad['_baslangicTarihi'] ??
                        ad['baslangicTarihi'] ??
                        ad['baslangic'] ??
                        ''
                    ).toString();
                    
                    final String tEnd = (
                        ad['_bitisTarihi'] ??
                        ad['bitisTarihi'] ??
                        ad['bitis'] ??
                        ''
                    ).toString();
                    
                    final Color borderAndLabelColor = score == 2
                        ? Colors.greenAccent
                        : Colors.orangeAccent;
                    final Color backgroundBadgeColor = score == 2
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.15);
                        
                    return Card(
                      color: const Color(0xff1e1e2a),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: borderAndLabelColor,
                          width: 1.8,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (gorselUrl.isNotEmpty &&
                              gorselUrl != 'https://unsplash.com' &&
                              gorselUrl != 'unsplash.com')
                            gorselUrl.startsWith('http')
                                ? Image.network(
                                    gorselUrl,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(),
                                  )
                                : Image.file(
                                    File(gorselUrl),
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(),
                                  ),
                          ListTile(
                            contentPadding: const EdgeInsets.all(14),
                            title: Text(
                              ilanBaslik,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  ilanDetay,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.date_range,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$tStart -> $tEnd",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: backgroundBadgeColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        score == 2
                                            ? Icons.lock_outline
                                            : Icons.hourglass_empty_rounded,
                                        size: 12,
                                        color: borderAndLabelColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        score == 2
                                            ? 'TAM TAKVİM ÇAKIŞMASI'
                                            : 'ESNEK EŞLEŞME (+/-3 Gün)',
                                        style: TextStyle(
                                          color: borderAndLabelColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.white54,
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/ad-detail',
                                arguments: ad,
                              );
                            },
                          ),
                        ],
                      ),
                    );
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