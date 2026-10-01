import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class IncomingOffersScreen extends StatefulWidget {
  const IncomingOffersScreen({super.key});

  @override
  State<IncomingOffersScreen> createState() => _IncomingOffersScreenState();
}

class _IncomingOffersScreenState extends State<IncomingOffersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Lütfen giriş yapın")),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text(
            'Takas Tekliflerim',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
          bottom: const TabBar(
            labelColor: Color(0xFF1E3A8A),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF1E3A8A),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Gelen Teklifler'),
              Tab(text: 'Gönderdiklerim'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGelenTekliflerTab(),
            _buildGonderilenTekliflerTab(),
          ],
        ),
      ),
    );
  }

  // 📥 1. SEKME: SANA GELEN TEKLİFLER (Gerçek Veri)
  Widget _buildGelenTekliflerTab() {
    return StreamBuilder<QuerySnapshot>(
      // 🔥 Firebase Sorgusu: Hedef (ilan sahibi) SEN olan ve Beklemede olan teklifleri getir
      stream: _firestore
          .collection('chats')
          .where('hedefSahipId', isEqualTo: _currentUser!.uid)
          .where('status', isEqualTo: 'Beklemede')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'Henüz gelen aktif bir takas teklifi yok.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            if (docs[index].data() == null) return const SizedBox.shrink();
            final data = docs[index].data() as Map<String, dynamic>;
            final chatId = docs[index].id;

            final String teklifEdenArac = (data['teklifEdenArac'] ?? 'İlan Bilgisi Yok').toString();
            final String hedefArac = (data['hedefArac'] ?? 'İlan Bilgisi Yok').toString();
            final double cashDiff = double.tryParse((data['cashDifference'] ?? 0.0).toString()) ?? 0.0;
            
            final String fiyatFarki = cashDiff > 0
                ? 'Üste ₺$cashDiff Nakit Talep Ediliyor'
                : 'Kafa Kafaya Takas';

            return GestureDetector(
              onTap: () {
                // Sohbet ekranına yönlendirme
                final Map<String, dynamic> sohbetVerisi = {
                  'id': data['hedefIlanId'] ?? 'bilinmeyen_ilan',
                  'baslik': hedefArac,
                  'kategori': 'Araç', 
                  'gercekChatId': chatId,
                };
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(ilanVerisi: sohbetVerisi),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bookmark_border, size: 16, color: Color(0xFF1E3A8A)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Hedef İlanınız: $hedefArac',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                              // İleride teklif eden aracın gerçek fotosunu buraya bağlayabilirsin
                              image: const DecorationImage(
                                image: NetworkImage('https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=500'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teklifEdenArac,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fiyatFarki,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Gelen Yeni Bir Teklifiniz Var',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade400, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                await _firestore.collection('chats').doc(chatId).set({
                                  'status': 'Reddedildi',
                                  'reddedilenArac': teklifEdenArac,
                                  'lastUpdated': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));

                                await _firestore.collection('chats').doc(chatId).collection('messages').add({
                                  'gonderen': 'system',
                                  'metin': '❌ "$teklifEdenArac" için yapılan takas teklifi araç sahibi tarafından reddedildi.',
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'isSystem': true,
                                  'isSimpleNotice': true,
                                });

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Teklif reddedildi ve listeden kaldırıldı.')),
                                  );
                                }
                              },
                              child: const Text('Reddet', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final Map<String, dynamic> sohbetVerisi = {
                                  'id': data['hedefIlanId'] ?? 'bilinmeyen_ilan',
                                  'baslik': hedefArac,
                                  'kategori': 'Araç', 
                                  'gercekChatId': chatId,
                                };
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(ilanVerisi: sohbetVerisi),
                                  ),
                                );
                              },
                              child: const Text('Sohbete Git', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 📤 2. SEKME: SENİN GÖNDERDİĞİN TEKLİFLER (Gerçek Veri)
  Widget _buildGonderilenTekliflerTab() {
    return StreamBuilder<QuerySnapshot>(
      // 🔥 Firebase Sorgusu: Teklifi SENİN attığın (teklifEdenId) ve Beklemede olan teklifleri getir
      stream: _firestore
          .collection('chats')
          .where('teklifEdenId', isEqualTo: _currentUser!.uid)
          .where('status', isEqualTo: 'Beklemede')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'Henüz başka bir ilana takas teklifi göndermediniz.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    // Keşfet sekmesine (0. index) gitmek için Navigator kullanıyoruz
                    Navigator.popUntil(context, (route) => route.isFirst); 
                  },
                  icon: const Icon(Icons.explore, color: Colors.white, size: 18),
                  label: const Text('Havuzu Keşfet', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            if (docs[index].data() == null) return const SizedBox.shrink();
            final data = docs[index].data() as Map<String, dynamic>;
            final chatId = docs[index].id;

            final String teklifEdenArac = (data['teklifEdenArac'] ?? 'İlan Bilgisi Yok').toString();
            final String hedefArac = (data['hedefArac'] ?? 'İlan Bilgisi Yok').toString();
            
            return GestureDetector(
              onTap: () {
                final Map<String, dynamic> sohbetVerisi = {
                  'id': data['hedefIlanId'] ?? 'bilinmeyen_ilan',
                  'baslik': hedefArac,
                  'kategori': 'Araç', 
                  'gercekChatId': chatId,
                };
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(ilanVerisi: sohbetVerisi),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.send, size: 16, color: Colors.teal),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sizin İlanınız: $teklifEdenArac',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                              image: const DecorationImage(
                                image: NetworkImage('https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=500'), // Hedef araç fotosu
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hedefArac,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Karşı Tarafın Cevabı Bekleniyor...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade400, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await _firestore.collection('chats').doc(chatId).set({
                              'status': 'İptal Edildi',
                              'lastUpdated': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                            await _firestore.collection('chats').doc(chatId).collection('messages').add({
                              'gonderen': 'system',
                              'metin': '❌ Takas teklifinizi geri çektiniz.',
                              'timestamp': FieldValue.serverTimestamp(),
                              'isSystem': true,
                              'isSimpleNotice': true,
                            });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Teklif başarıyla iptal edildi ve geri çekildi.')),
                              );
                            }
                          },
                          child: const Text('Teklifi Geri Çek (İptal)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}