import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:takas_app/screens/ad_detail_screen.dart';

class MapExplorerScreen extends StatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _secilenKategori = 'Hepsi';

  // 🗺️ Türkiye İlleri İçin Coğrafi Koordinat Matrisi
  final Map<String, LatLng> _ilKoordinatlari = {
    'İstanbul': const LatLng(41.0082, 28.9784),
    'Ankara': const LatLng(39.9334, 32.8597),
    'İzmir': const LatLng(38.4192, 27.1287),
    'Bursa': const LatLng(40.1828, 29.0665),
    'Antalya': const LatLng(36.8841, 30.7056),
    'Muğla': const LatLng(37.2153, 28.3636),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📍 Canlı Takas Haritası (Ücretsiz)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            Text(
              'İlanları OpenStreetMap üzerinden keşfedin',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('ilanlar').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Harita verileri yüklenirken hata oluştu: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          List<Marker> markers = [];

          for (var doc in docs) {
            // 🛡️ DEAD-REFERENCE KORUMASI: null kontrolleri eklendi
            if (doc.data() == null) continue;
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;

            final String kategori = (data['kategori'] ?? 'Araç').toString();
            
            if (_secilenKategori != 'Hepsi') {
              if (_secilenKategori == 'Araç' && kategori != 'Araç') continue;
              if (_secilenKategori == 'Konut' && kategori != 'Konut' && kategori != 'Ev' && kategori != 'Yazlık') continue;
            }

            final String mevcutIl = (data['mevcutIl'] ?? 'Antalya').toString();
            LatLng bazKonum = _ilKoordinatlari.containsKey(mevcutIl) 
                ? _ilKoordinatlari[mevcutIl]! 
                : const LatLng(36.8841, 30.7056);

            // 🛡️️ Çarpışma ve Null-Pointer koruması: HashCode üzerinden güvenli ofset üretimi
            int idHash = doc.id.hashCode.abs();
            double latOffset = (idHash % 7) * 0.008;
            double lngOffset = ((idHash ~/ 7) % 7) * 0.008;
            LatLng finalKonum = LatLng(bazKonum.latitude + latOffset, bazKonum.longitude + lngOffset);

            Color pinColor = const Color(0xFF1E3A8A);
            if (kategori == 'Konut' || kategori == 'Ev' || kategori == 'Yazlık') {
              pinColor = Colors.green.shade700;
            }

            markers.add(
              Marker(
                point: finalKonum,
                width: 45,
                height: 45,
                child: GestureDetector(
                  onTap: () => _ilanDetayPaneliGoster(context, data, kategori),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                      border: Border.all(color: pinColor, width: 2),
                    ),
                    child: Icon(Icons.location_on_rounded, color: pinColor, size: 26),
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(39.1667, 35.6668),
                    initialZoom: 6.2,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.takas_app.app',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: ['Hepsi', 'Araç', 'Konut'].map((kat) {
                      final bool isSelected = _secilenKategori == kat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            kat,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF1E3A8A),
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.white,
                          onSelected: (val) {
                            if (val) setState(() => _secilenKategori = kat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🌟 AIRBNB TARZI KALP VE X BUTONLU ÖZEL HARİTA PİN KARTI
  void _ilanDetayPaneliGoster(
    BuildContext context,
    Map<String, dynamic> ilan,
    String kategori,
  ) {
    String gorselUrl = '';
    final dynamic fotograflarRaw = ilan['fotograflar'];
    if (fotograflarRaw is List && fotograflarRaw.isNotEmpty && fotograflarRaw.first != null) {
      gorselUrl = fotograflarRaw.first.toString();
    } else if (ilan['gorsel'] != null && ilan['gorsel'].toString().isNotEmpty) {
      gorselUrl = ilan['gorsel'].toString();
    }

    final String ilanBaslik = (ilan['kategori'] == 'Araç' && ilan['marka'] != null && ilan['model'] != null)
        ? '${ilan['marka']}-${ilan['model']} ${ilan['modelYili'] ?? ilan['yil'] ?? ''}'
        : (ilan['baslik'] ?? '${ilan['kategori'] ?? "Takas"} İlanı').toString();

    final String il = (ilan['mevcutIl'] ?? 'Belirtilmedi').toString();
    final String ilce = (ilan['mevcutIlce'] ?? '').toString();
    final String konumMetni = ilce.isNotEmpty ? '$il / $ilce' : il;
    final String altKat = (ilan['altKategori'] ?? kategori).toString();
    final String ilanId = (ilan['id'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isFav = ilan['isFavorite'] ?? false;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
            ),
            child: Container(
              margin: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📸 Üst Kısım: Fotoğraf ve Üzerinde Airbnb Tarzı Kalp & X Butonları
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: gorselUrl.isEmpty
                                ? Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                    ),
                                  )
                                : gorselUrl.startsWith('http')
                                    ? Image.network(
                                        gorselUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                      )
                                    : (File(gorselUrl).existsSync()
                                        ? Image.file(File(gorselUrl), fit: BoxFit.cover)
                                        : Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.broken_image, color: Colors.grey),
                                          )),
                          ),
                        ),
                        // 🤍 Kalp (Favori) Butonu (Sağ Üst)
                        Positioned(
                          top: 12,
                          right: 56,
                          child: GestureDetector(
                            onTap: () async {
                              setModalState(() {
                                isFav = !isFav;
                                ilan['isFavorite'] = isFav;
                              });
                              if (ilanId.isNotEmpty) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('ilanlar')
                                      .doc(ilanId)
                                      .update({'isFavorite': isFav});
                                } catch (e) {
                                  debugPrint('Favori bulut senkronizasyon hatası: $e');
                                }
                              }
                            },
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white.withOpacity(0.9),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.grey.shade700,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        // ❌ Kapatma (X) Butonu (Sağ Üst)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white.withOpacity(0.9),
                              child: const Icon(
                                Icons.close,
                                color: Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$kategori / $altKat'.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Takas Havuzunda',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ilanBaslik,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                'Konum: $konumMetni',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdDetailScreen(ilanVerisi: ilan),
                                  ),
                                );
                              },
                              child: const Text(
                                'İlan Detayına Git & İncele',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}