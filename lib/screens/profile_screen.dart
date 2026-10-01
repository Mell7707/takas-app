import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:takas_app/screens/login_screen.dart';
import 'package:takas_app/screens/profile_views/edit_profile_view.dart';
import 'package:takas_app/screens/profile_views/security_view.dart';
import 'package:takas_app/screens/profile_views/preferences_view.dart';
import 'package:takas_app/screens/create_ad_screen.dart';

class ProfileScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? canliIlanlar;
  const ProfileScreen({super.key, this.canliIlanlar});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final double _toplamPuan = 4.8;
  int _toplamTakasSayisi = 12;
  final int _guvenilirSayisi = 8;
  final int _hizliDevirSayisi = 5;
  final int _temizKullaniciSayisi = 9;

  void _takasDegerlendirPenceriniAc({
    String karsiTarafAdi = 'Ahmet Yılmaz',
    String ilanBasligi = '2022 Volvo XC90 Takası',
    String kontratNo = 'TS-84219',
  }) {
    double secilenYildiz = 5.0;
    List<String> secilenRozetler = [];
    final yorumController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Takas Sürecini Değerlendir',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Karşı tarafın takas performansını ve memnuniyetinizi oylayın.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Takas Ortağı: $karsiTarafAdi',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'İşlem / İlan: $ilanBasligi (#$kontratNo)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Memnuniyet Puanı',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < secilenYildiz ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setModalState(() {
                            secilenYildiz = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hızlı Değerlendirme Rozetleri',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSelectableChip('🤝 Güvenilir Takasçı', secilenRozetler, setModalState),
                      _buildSelectableChip('⚡ Hızlı Devir / İşlem', secilenRozetler, setModalState),
                      _buildSelectableChip('✨ Temiz Kullanıcı', secilenRozetler, setModalState),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Detaylı Görüşünüz (İsteğe Bağlı)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: yorumController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Takas süreci nasıl geçti? Deneyiminizi yazın...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _toplamTakasSayisi += 1;
                        });
                        yorumController.dispose();
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Değerlendirmeniz başarıyla yayınlandı! 🎉'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Değerlendirmeyi Gönder',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableChip(
    String label,
    List<String> secilenler,
    StateSetter setModalState,
  ) {
    final bool isSelected = secilenler.contains(label);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF1E3A8A),
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      onSelected: (bool value) {
        setModalState(() {
          if (value) {
            secilenler.add(label);
          } else {
            secilenler.remove(label);
          }
        });
      },
    );
  }

  void _ilanlarimiYoneticiPaneliniAc() {
    final currentUser = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.80,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF1E3A8A),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Aktif İlanlarım ve Yönetim',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ilanlar')
                      .where('userId', isEqualTo: currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E3A8A),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Veriler yüklenirken hata oluştu: ${snapshot.error}',
                        ),
                      );
                    }
                    
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Yayında olan hiçbir ilanınız bulunmuyor.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        if (docs[index].data() == null) return const SizedBox.shrink();
                        final doc = docs[index];
                        final ilan = doc.data() as Map<String, dynamic>;
                        ilan['id'] = doc.id;
                        
                        final bool isAktif = ilan['isAktif'] ?? true;
                        final dynamic fotograflarRaw = ilan['fotograflar'];
                        final List fotograflar = fotograflarRaw is List ? fotograflarRaw : [];
                        
                        String gorselPath = '';
                        if (fotograflar.isNotEmpty && fotograflar.first != null) {
                          gorselPath = fotograflar.first.toString();
                        } else if (ilan['gorsel'] != null && ilan['gorsel'].toString().isNotEmpty) {
                          gorselPath = ilan['gorsel'].toString();
                        }
                        
                        final bool isNetworkImage = gorselPath.startsWith('http');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: gorselPath.isEmpty
                                        ? Container(
                                            width: 75,
                                            height: 75,
                                            color: Colors.grey.shade100,
                                            child: const Icon(Icons.image, color: Colors.grey),
                                          )
                                        : isNetworkImage
                                        ? Image.network(
                                            gorselPath,
                                            width: 75,
                                            height: 75,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                          )
                                        : Image.file(
                                            File(gorselPath),
                                            width: 75,
                                            height: 75,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (ilan['baslik'] ?? '${ilan['kategori'] ?? "Takas"} İlanı').toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (ilan['kategori'] ?? '').toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isAktif ? Colors.green.shade50 : Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isAktif ? '🟢 Havuzda Aktif' : '🟠 Takasta / Arşivde',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isAktif ? Colors.green.shade700 : Colors.orange.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isAktif ? Colors.orange.shade800 : Colors.green.shade700,
                                        side: BorderSide(color: isAktif ? Colors.orange.shade300 : Colors.green.shade300),
                                        backgroundColor: isAktif ? Colors.orange.shade50 : Colors.green.shade50,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () async {
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('ilanlar')
                                              .doc(ilan['id'])
                                              .update({'isAktif': !isAktif});
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  isAktif 
                                                      ? 'İlan havuzdan kaldırıldı, profilinizde saklanıyor. 📦' 
                                                      : 'İlan başarıyla tekrar takas havuzuna gönderildi! 🚀',
                                                ),
                                                backgroundColor: isAktif ? Colors.orange : Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Durum güncellenemedi: $e'), backgroundColor: Colors.red),
                                            );
                                          }
                                        }
                                      },
                                      icon: Icon(isAktif ? Icons.archive_outlined : Icons.unarchive_outlined, size: 16),
                                      label: Text(
                                        isAktif ? 'Arşivle' : 'Yayınla',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue.shade700,
                                        side: BorderSide(color: Colors.blue.shade300),
                                        backgroundColor: Colors.blue.shade50,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CreateAdScreen(
                                              varsayilanKategori: (ilan['kategori'] ?? 'Araç').toString(),
                                              onAdCreated: (Map<String, dynamic> mapVerisi) {},
                                              ilanVerisi: ilan,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      label: const Text(
                                        'Düzenle',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red.shade700,
                                        side: BorderSide(color: Colors.red.shade300),
                                        backgroundColor: Colors.red.shade50,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () async {
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('ilanlar')
                                              .doc(ilan['id'])
                                              .delete();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('İlanınız tamamen silindi! 🗑️'),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Silme hatası: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline, size: 16),
                                      label: const Text(
                                        'Sil',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String gosterilecekIsim = currentUser?.displayName ?? 'Kullanıcı';
    final String gosterilecekEposta = currentUser?.email ?? 'eposta@takasapp.com';
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFF1E3A8A),
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gosterilecekIsim,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gosterilecekEposta,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Onaylı Hesap',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Takas Geçmişim & Güven Skorum',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 6),
                          Text(
                            '$_toplamPuan',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' / 5',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$_toplamTakasSayisi Başarılı Takas',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  const Text(
                    'Kullanıcılardan Alınan Öne Çıkan Rozetler:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDisplayChip(
                        '🤝 Güvenilir ($_guvenilirSayisi)',
                        Colors.blue.shade50,
                        Colors.blue.shade700,
                      ),
                      _buildDisplayChip(
                        '⚡ Hızlı Devir ($_hizliDevirSayisi)',
                        Colors.orange.shade50,
                        Colors.orange.shade800,
                      ),
                      _buildDisplayChip(
                        '✨ Temiz Kullanıcı ($_temizKullaniciSayisi)',
                        Colors.green.shade50,
                        Colors.green.shade700,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.teal,
                      ),
                      title: const Text(
                        'Aktif İlanlarımı Yönet',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _ilanlarimiYoneticiPaneliniAc,
                    ),
                    const Divider(height: 1),
                    // 🗑️ Gelen Teklifler buradaydı, artık tamamen silindi!
                    ListTile(
                      leading: const Icon(
                        Icons.rate_review_outlined,
                        color: Colors.orange,
                      ),
                      title: const Text(
                        'Bir Takası Puanla',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _takasDegerlendirPenceriniAc(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF1E3A8A),
                      ),
                      title: const Text(
                        'Profil Bilgilerini Düzenle',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileView(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF1E3A8A),
                      ),
                      title: const Text(
                        'Güvenlik ve Hesap Ayarları',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecurityView(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.history_edu_rounded,
                        color: Colors.indigo,
                      ),
                      title: const Text(
                        'Takas Geçmişi Arşivi',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/swap-history'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.tune, color: Color(0xFF1E3A8A)),
                      title: const Text(
                        'Uygulama Tercihleri',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PreferencesView(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hesaptan güvenli çıkış yapıldı. 👋'),
                          backgroundColor: Colors.black87,
                        ),
                      );
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(
                            ilanlar: widget.canliIlanlar ?? [],
                            onIlanEkle: (Map<String, dynamic> mapVerisi) {},
                          ),
                        ),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Çıkış yapılırken bir sorun oluştu: $e'),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Güvenli Çıkış Yap',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: text,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}