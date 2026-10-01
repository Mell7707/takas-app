import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:takas_app/screens/chat_screen.dart';

class AdDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ilanVerisi;
  const AdDetailScreen({super.key, required this.ilanVerisi});
  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  late String _baslangicTarihiStr;
  late String _bitisTarihiStr;

  @override
  void initState() {
    super.initState();
    _baslangicTarihiStr = (widget.ilanVerisi['baslangicTarihi'] ?? widget.ilanVerisi['baslangic'] ?? 'Seçilmedi').toString();
    _bitisTarihiStr = (widget.ilanVerisi['bitisTarihi'] ?? widget.ilanVerisi['bitis'] ?? 'Seçilmedi').toString();
  }

  // 🚀 KUSURSUZ MANTIK: Kategori Eşleştirmesi ve Otomatik Teklif
  Future<void> _takasTeklifEtKontrol(BuildContext context, String baslik, String kategori, String altKategori) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen önce giriş yapın.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
    );

    try {
      // SADECE bakılan ilanın kategorisiyle (Araç ise Araç, Konut ise Konut) eşleşen ilanları getir!
      final userIlanlar = await FirebaseFirestore.instance
          .collection('ilanlar')
          .where('userId', isEqualTo: user.uid)
          .where('kategori', isEqualTo: kategori) // SIKI KATEGORİ FİLTRESİ
          .get();

      if (!context.mounted) return;
      Navigator.pop(context); // Yükleme ekranını kapat

      if (userIlanlar.docs.isEmpty) {
        // Kullanıcının "BU KATEGORİDE" ilanı yoksa uyarı göster
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: const Row(
              children: [
                Text(
                  '⚠️ Uygun İlan Bulunamadı!',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Text(
              'Araca karşılık araç, konuta karşılık konut takas edilebilir.\n\nBu $kategori ilanına teklif verebilmek için sizin de aktif bir "$kategori" ilanınız olması gerekmektedir. Lütfen önce uygun kategoride bir ilan verin. 🚀',
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Vazgeç', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/create-ad');
                      },
                      child: const Text('İlan Ver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        // 🔥 OTOMATİK EŞLEŞTİRME: Aynı kategorideki ilanı otomatik bul ve teklifi arka planda at!
        final eslesenIlan = userIlanlar.docs.first;
        final ilanId = eslesenIlan.id;
        final ilanBaslik = (eslesenIlan.data()['baslik'] ?? 'İlanım').toString();
        
        await _gercekTeklifiFirebaseeYaz(context, ilanId, ilanBaslik, user.uid);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Hata durumunda da kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kontrol sırasında hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🚀 ADIM 3: Firebase 'chats' Koleksiyonuna Gerçek Teklif (Belge) Oluşturma
  Future<void> _gercekTeklifiFirebaseeYaz(BuildContext context, String teklifEdenIlanId, String teklifEdenIlanBaslik, String currentUserId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
    );

    try {
      String hedefIlanId = (widget.ilanVerisi['id'] ?? 'bilinmeyen_ilan').toString();
      String hedefSahipId = (widget.ilanVerisi['userId'] ?? widget.ilanVerisi['sahipId'] ?? 'bilinmeyen_sahip').toString();
      String hedefIlanBaslik = (widget.ilanVerisi['baslik'] ?? 'Takas İlanı').toString();

      // Sadece bu iki ilan arasında tek bir sohbet odası (chat) olsun diye ID'yi birleştiriyoruz
      String gercekChatId = "${currentUserId}_to_$hedefIlanId";

      await FirebaseFirestore.instance.collection('chats').doc(gercekChatId).set({
        'id': gercekChatId,
        'status': 'Beklemede',
        'teklifEdenId': currentUserId,
        'teklifEdenIlanId': teklifEdenIlanId,
        'teklifEdenArac': teklifEdenIlanBaslik, // Geriye dönük uyumluluk için
        'hedefSahipId': hedefSahipId,
        'hedefIlanId': hedefIlanId,
        'hedefArac': hedefIlanBaslik, // Geriye dönük uyumluluk için
        'cashDifference': 0.0,
        'karsiTarafNakitOnayi': false,
        'karsiTarafTeklifiOnayladi': false,
        'lojistikGirildi': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;
      Navigator.pop(context); // Yükleme diyaloğunu kapat

      // Sohbet ekranına aktarım
      final Map<String, dynamic> geciciIlanVerisi = {
        'id': widget.ilanVerisi['id'] ?? 'test_id',
        'baslik': widget.ilanVerisi['baslik'],
        'kategori': widget.ilanVerisi['kategori'],
        'altKategori': widget.ilanVerisi['altKategori'],
        'sahipIsmi': widget.ilanVerisi['sahipIsmi'] ?? 'İlan Sahibi',
        'userId': widget.ilanVerisi['userId'] ?? 'test_user_satici',
        'gercekChatId': gercekChatId, // Sonraki adıma hazırlık olarak ID'yi gönderiyoruz
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(ilanVerisi: geciciIlanVerisi),
        ),
      );

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Teklif iletilemedi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ TİP GÜVENLİĞİ VE NULL KONTROLLERİ ZIRHLANDI
    final String kategori = (widget.ilanVerisi['kategori'] ?? 'Diğer').toString();
    final String altKategori = (widget.ilanVerisi['altKategori'] ?? '').toString();
    final String konutTipiDegeri = (widget.ilanVerisi['konutTipi'] ?? altKategori).toString();
    
    final String detayAciklama =
        (widget.ilanVerisi['detay'] ?? widget.ilanVerisi['aciklama'] ?? 'Açıklama belirtilmedi').toString();
    
    final String baslik =
        (kategori == 'Araç' &&
            widget.ilanVerisi['marka'] != null &&
            widget.ilanVerisi['model'] != null)
        ? '${widget.ilanVerisi['marka']}-${widget.ilanVerisi['model']}  ${widget.ilanVerisi['modelYili'] ?? widget.ilanVerisi['yil'] ?? ''}'
        : (widget.ilanVerisi['baslik'] ?? 'Takas İlanı').toString();

    final String mevcutIl = (widget.ilanVerisi['mevcutIl'] ?? '').toString();
    final String mevcutIlce = (widget.ilanVerisi['mevcutIlce'] ?? '').toString();
    final String mevcutKonumMetni =
        (mevcutIl.isNotEmpty && mevcutIlce.isNotEmpty)
        ? '$mevcutIl / $mevcutIlce'
        : (widget.ilanVerisi['mevcutKonum'] ?? 'Belirtilmedi')
              .toString()
              .replaceAll('Mevcut: ', '');
              
    final String hedefIl = (widget.ilanVerisi['hedefIl'] ?? '').toString();
    final String hedefIlce = (widget.ilanVerisi['hedefIlce'] ?? '').toString();
    final String hedefKonumMetni = (hedefIl.isNotEmpty && hedefIlce.isNotEmpty)
        ? '$hedefIl / $hedefIlce'
        : (widget.ilanVerisi['hedefKonum'] ??
                  widget.ilanVerisi['hedef'] ??
                  'Belirtilmedi')
              .toString()
              .replaceAll('Takas Kriteri: ', '')
              .replaceAll('Hedef Kriteri: ', '');

    final bool isDateFlexible = (widget.ilanVerisi['isDateFlexible'] ?? false) as bool;

    final bool isKaraAraci = kategori == 'Araç';
    final bool isEvVeyaYazlik = kategori == 'Konut' || kategori == 'Ev' || kategori == 'Yazlık';

    final dynamic rawFotograflar = widget.ilanVerisi['fotograflar'];
    final List<dynamic> yuklenenFotograflar = (rawFotograflar is List) ? rawFotograflar : [];
    
    final List<String> tumGorseller = [];
    if (yuklenenFotograflar.isNotEmpty) {
      for (var foto in yuklenenFotograflar) {
        if (foto != null && foto.toString().isNotEmpty) tumGorseller.add(foto.toString());
      }
    } else {
      final String tekGorsel = (widget.ilanVerisi['gorsel'] ?? '').toString();
      if (tekGorsel.isNotEmpty) tumGorseller.add(tekGorsel);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'İlan Detayı',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 240,
                color: Colors.grey.shade100,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: tumGorseller.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                            )
                          : PageView.builder(
                              itemCount: tumGorseller.length,
                              itemBuilder: (context, index) {
                                final String gorselUrl = tumGorseller[index];
                                if (gorselUrl.isEmpty) {
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  );
                                }
                                return gorselUrl.startsWith('http')
                                    ? Image.network(
                                        gorselUrl,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                        errorBuilder: (_, __, ___) => const Center(
                                          child: Icon(Icons.image_not_supported, color: Colors.grey),
                                        ),
                                      )
                                    : (File(gorselUrl).existsSync()
                                        ? Image.file(
                                            File(gorselUrl),
                                            fit: BoxFit.cover,
                                            alignment: Alignment.center,
                                          )
                                        : Container(
                                            color: Colors.grey.shade100,
                                            child: const Center(
                                              child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                            ),
                                          ));
                              },
                            ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          altKategori.isNotEmpty ? '$kategori / $altKategori' : kategori,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: StatefulBuilder(
                        builder: (context, setDetailFavState) {
                          bool isFav = widget.ilanVerisi['isFavorite'] ?? false;
                          final String ilanId = (widget.ilanVerisi['id'] ?? '').toString();
                          return GestureDetector(
                            onTap: () async {
                              // 🛡️ DEAD-CONTEXT KORUMASI VE GÜVENLİ DURUM YÖNETİMİ
                              if (!mounted) return;
                              setDetailFavState(() {
                                isFav = !isFav;
                                widget.ilanVerisi['isFavorite'] = isFav;
                              });
                              if (ilanId.isNotEmpty) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('ilanlar')
                                      .doc(ilanId)
                                      .update({'isFavorite': isFav});
                                } catch (e) {
                                  debugPrint(
                                    'Favori bulut senkronizasyon hatası: $e',
                                  );
                                }
                              }
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white.withValues(alpha: 0.9),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav
                                    ? Colors.red
                                    : Colors.grey.shade700,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            baslik,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLocationCard(
                            icon: Icons.location_on,
                            title: 'Bulunduğu Konum',
                            value: mevcutKonumMetni,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildLocationCard(
                            icon: Icons.track_changes,
                            title: 'Takas İstenen Bölge',
                            value: hedefKonumMetni,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade300, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: Color(0xFF1E3A8A), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'İlan Sahibinin Belirttiği Takas Tarihi',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$_baslangicTarihiStr  ➔  $_bitisTarihiStr',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDateFlexible ? Colors.green.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDateFlexible ? Colors.green.shade400 : Colors.grey.shade400,
                              ),
                            ),
                            child: Text(
                              isDateFlexible ? 'Esnek 🟢' : 'Sabit 🔴',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDateFlexible ? Colors.green.shade800 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      '📋 Teknik Detaylar ve Özellikler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildSpecificationRow('Kategori', kategori),
                          if (isKaraAraci && altKategori.isNotEmpty) ...[
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildSpecificationRow('Araç / Taşıt Türü', altKategori),
                          ],
                          if (isEvVeyaYazlik && konutTipiDegeri.isNotEmpty) ...[
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildSpecificationRow('Konut Tipi', konutTipiDegeri),
                          ],
                          if (isKaraAraci) ...[
                            if (widget.ilanVerisi['marka'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow('Marka', widget.ilanVerisi['marka'].toString()),
                            ],
                            if (widget.ilanVerisi['model'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow('Model', widget.ilanVerisi['model'].toString()),
                            ],
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildSpecificationRow(
                              'Model Yılı',
                              (widget.ilanVerisi['modelYili'] ??
                                      widget.ilanVerisi['yil'] ??
                                      'Belirtilmedi')
                                  .toString(),
                            ),
                            if (widget.ilanVerisi['vites'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow('Vites Tipi', widget.ilanVerisi['vites'].toString()),
                            ],
                            if (widget.ilanVerisi['yakitTipi'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow('Yakıt Tipi', widget.ilanVerisi['yakitTipi'].toString()),
                            ],
                            if (widget.ilanVerisi['cekisTipi'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow('Çekis Tipi', widget.ilanVerisi['cekisTipi'].toString()),
                            ],
                            if (widget.ilanVerisi['sigara'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow(
                                'Sigara Kullanımı',
                                widget.ilanVerisi['sigara'].toString(),
                              ),
                            ],
                          ],
                          if (isEvVeyaYazlik) ...[
                            if (widget.ilanVerisi['evKatTipi'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow('Kat Mimarisi', widget.ilanVerisi['evKatTipi'].toString()),
                            ],
                            if (widget.ilanVerisi['siteDurumu'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow('Site Durumu', widget.ilanVerisi['siteDurumu'].toString()),
                            ],
                            if (widget.ilanVerisi['salonSayisi'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow(
                                'Salon Sayısı',
                                '${widget.ilanVerisi['salonSayisi']} Salon',
                              ),
                            ],
                            if (widget.ilanVerisi['odaSayisi'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow(
                                'Oda Sayısı',
                                '${widget.ilanVerisi['odaSayisi']} Oda',
                              ),
                            ],
                            if (widget.ilanVerisi['banyoSayisi'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow(
                                'Banyo Sayısı',
                                '${widget.ilanVerisi['banyoSayisi']} Banyo',
                              ),
                            ],
                            if (widget.ilanVerisi['tuvaletSayisi'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow(
                                'Tuvalet Sayısı',
                                '${widget.ilanVerisi['tuvaletSayisi']} Tuvalet',
                              ),
                            ],
                            if (widget.ilanVerisi['balkonSayisi'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow(
                                'Balkon Sayısı',
                                '${widget.ilanVerisi['balkonSayisi']} Balkon',
                              ),
                            ],
                            if (widget.ilanVerisi['kullanimAlani'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow(
                                'Kullanım Alanı',
                                widget.ilanVerisi['kullanimAlani'].toString(),
                              ),
                            ],
                            if (widget.ilanVerisi['havuzDurumu'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow(
                                'Havuz Durumu',
                                widget.ilanVerisi['havuzDurumu'].toString(),
                              ),
                            ],
                            if (widget.ilanVerisi['bahceDurumu'] != null) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              _buildSpecificationRow(
                                'Bahçe Durumu',
                                widget.ilanVerisi['bahceDurumu'].toString(),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '🗒️ İlan Açıklaması',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detayAciklama,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () => _takasTeklifEtKontrol(context, baslik, kategori, altKategori),
                        icon: const Icon(
                          Icons.swap_horizontal_circle,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Takas Teklif Et',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
  }

  Widget _buildLocationCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}