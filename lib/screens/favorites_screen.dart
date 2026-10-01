import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takas_app/screens/ad_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> canliIlanlar;
  const FavoritesScreen({super.key, required this.canliIlanlar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Favorilerim & Kaydedilenler',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ilanlar')
            .where('isFavorite', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Favoriler yüklenirken hata oluştu: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          
          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz favori ilanınız yok.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Beğendiğiniz ilanları kaydederek burada listeleyebilirsiniz.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          
          final favoriIlanlar = docs.map((doc) {
            if (doc.data() == null) return <String, dynamic>{};
            final data = doc.data() as Map<String, dynamic>;
            final Map<String, dynamic> mutableData = Map<String, dynamic>.from(data);
            mutableData['id'] = doc.id;
            return mutableData;
          }).where((map) => map.isNotEmpty).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriIlanlar.length,
            itemBuilder: (context, index) {
              final ilan = favoriIlanlar[index];
              final dynamic fotograflarRaw = ilan['fotograflar'];
              final List fotograflar = fotograflarRaw is List ? fotograflarRaw : [];
              
              String gorselYolu = '';
              if (fotograflar.isNotEmpty && fotograflar.first != null) {
                gorselYolu = fotograflar.first.toString();
              } else if (ilan['gorsel'] != null && ilan['gorsel'].toString().isNotEmpty) {
                gorselYolu = ilan['gorsel'].toString();
              }
              
              final bool isNetworkImage = gorselYolu.startsWith('http');
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdDetailScreen(ilanVerisi: ilan),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                        child: gorselYolu.isEmpty
                            ? Container(
                                width: 110,
                                height: 110,
                                color: Colors.blue.shade50,
                                child: const Icon(Icons.image, color: Colors.grey),
                              )
                            : isNetworkImage
                            ? Image.network(
                                gorselYolu,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 110,
                                      height: 110,
                                      color: Colors.blue.shade50,
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                              )
                            : Image.file(
                                File(gorselYolu),
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 110,
                                      height: 110,
                                      color: Colors.blue.shade50,
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    (ilan['kategori'] ?? 'Araç').toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        style: IconButton.styleFrom(
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.black45,
                                          size: 20,
                                        ),
                                        onPressed: () async {
                                          try {
                                            final String ilanId = (ilan['id'] ?? '').toString();
                                            if (ilanId.isNotEmpty) {
                                              await FirebaseFirestore.instance
                                                  .collection('ilanlar')
                                                  .doc(ilanId)
                                                  .update({'isFavorite': false});
                                                  
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('İlan favorilerinizden başarıyla kaldırıldı! 🗑️'),
                                                    backgroundColor: Color(0xFF1E3A8A),
                                                    duration: Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (ilan['baslik'] ?? '${ilan['kategori'] ?? "Takas"} İlanı').toString(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (ilan['detay'] ?? 'Açıklama belirtilmedi.').toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}