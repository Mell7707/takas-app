import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import '../models/contract_model.dart';
import 'contract_approval_screen.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> ilanVerisi;
  const ChatScreen({super.key, required this.ilanVerisi});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _mesajController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _teklifDurumu = 'Beklemede';
  late String _chatId;
  late String _currentUserId;
  
  // 💰 FINTECH INTEGRATION & DYNAMIC BUTTON STATE VARIABLES
  double _nakitFarkiBedeli = 0.0;
  bool _karsiTarafOnayladi = false; 
  bool _karsiTarafTeklifiOnayladi = false; 

  // Lojistik Değişkenleri
  bool _lojistikGirildi = false;
  String _secilenKonumTuru = 'Havalimanı Otoparkı';
  String _teslimEdecekKisi = 'Bizzat Kendim';
  final _kisiIletisimController = TextEditingController();
  final _lokasyonTarifiController = TextEditingController();
  double _secilenLat = 36.8841;
  double _secilenLng = 30.7056;
  String? _imzalananSozlesmeId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid ?? "alici";

    // 🚀 GERÇEK VERİTABANI BAĞLANTISI
    final String ilanId = (widget.ilanVerisi['id'] ?? "antalya_ilan_123").toString();
    _chatId = widget.ilanVerisi['gercekChatId'] ?? "chat_${ilanId}_to_istanbul_456";
    
    _firestore.collection('chats').doc(_chatId).snapshots().listen((doc) {
      if (!mounted) return;
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _teklifDurumu = (data['status'] ?? 'Beklemede').toString();
          _nakitFarkiBedeli = double.tryParse((data['cashDifference'] ?? 0.0).toString()) ?? 0.0;
          _karsiTarafOnayladi = data['karsiTarafNakitOnayi'] ?? false;
          _karsiTarafTeklifiOnayladi = data['karsiTarafTeklifiOnayladi'] ?? false;
          _lojistikGirildi = data['lojistikGirildi'] ?? false;
          if (_lojistikGirildi) {
            _secilenKonumTuru = (data['secilenKonumTuru'] ?? 'Havalimanı Otoparkı').toString();
            _teslimEdecekKisi = (data['teslimEdecekKisi'] ?? 'Bizzat Kendim').toString();
            _kisiIletisimController.text = (data['kisiIletisim'] ?? '').toString();
            _lokasyonTarifiController.text = (data['lokasyonTarifi'] ?? '').toString();
            _secilenLat = double.tryParse((data['secilenLat'] ?? 36.8841).toString()) ?? 36.8841;
            _secilenLng = double.tryParse((data['secilenLng'] ?? 30.7056).toString()) ?? 30.7056;
          }
        });
      }
    });

    _firestore.collection('chats').doc(_chatId).collection('messages')
        .where('contractId', isNull: false)
        .limit(1)
        .get()
        .then((snapshot) {
      if (!mounted) return;
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _imzalananSozlesmeId = snapshot.docs.first.data()['contractId']?.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _mesajController.dispose();
    _kisiIletisimController.dispose();
    _lokasyonTarifiController.dispose();
    super.dispose();
  }
  
  Future<void> _haritadaAc(double lat, double lng) async {
    final Uri googleMapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Harita uygulaması açılamadı ⚠️'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Harita açma hatası: $e');
    }
  }

  Future<void> _sozlesmeDetayGoster(String contractId) async {
    var doc = await _firestore.collection('contracts').doc(contractId).get();
    if (!mounted) return;
    
    if (doc.exists && doc.data() != null) {
      final contractData = doc.data() as Map<String, dynamic>;
      final String metinIcerigi = (contractData['contractText'] ?? 'Sözleşme metni bulunamadı.').toString();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sözleşme: #$contractId', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Text(
                metinIcerigi,
                style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sözleşme detayları bulunamadı ⚠️'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Map<String, String> _getVarlikBilgileri() {
    final String kategori = (widget.ilanVerisi['kategori'] ?? '').toString().trim();
    final String altKategori = (widget.ilanVerisi['altKategori'] ?? '').toString().trim();

    if (kategori.contains('Deniz') || kategori.contains('Tekne') || altKategori.contains('Yat') || altKategori.contains('Jetski')) {
      return {
        'sahipUnvani': 'deniz aracı sahibine',
        'segmentMetni': 'Deniz Aracı Donanım Farkı / Nakit Talep Et',
        'kategoriAdi': 'Deniz Araçları',
        'templateId': 'marine_swap_template',
      };
    } else if (kategori.contains('Konut') || kategori.contains('Ev') || altKategori.contains('Yazlık') || altKategori.contains('Daire')) {
      return {
        'sahipUnvani': 'ev sahibine',
        'segmentMetni': 'Mülk / Konum Segment Farkı / Nakit Talep Et',
        'kategoriAdi': 'Konut',
        'templateId': 'house_swap_template',
      };
    } else {
      return {
        'sahipUnvani': 'araç sahibine',
        'segmentMetni': 'Araç Segment Farkı / Nakit Talep Et',
        'kategoriAdi': 'Araç',
        'templateId': 'car_swap_template',
      };
    }
  }

  void _nakitFarkiGirisDialogunuAc() {
    final varlik = _getVarlikBilgileri();
    final String baslangicDegeri = _nakitFarkiBedeli > 0
        ? _formatMoneyString(_nakitFarkiBedeli.toStringAsFixed(0))
        : '';
    final txtController = TextEditingController(text: baslangicDegeri);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.price_change_rounded, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text(
              'Nakit Farkı Talebi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Karşı tarafın ${varlik['kategoriAdi']?.toLowerCase()} mülk/değer farkına mahsuben ödemesini istediğiniz nakit dengeleme tutarını giriniz.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: txtController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CanliParaFormatlayici(),
              ],
              decoration: InputDecoration(
                hintText: 'Örn: 300.000',
                prefixText: '₺ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
            ),
            onPressed: () async {
              final String safMetin = txtController.text.replaceAll('.', '').trim();
              final double enteredVal = double.tryParse(safMetin) ?? 0.0;
              Navigator.pop(context);
              
              await _firestore.collection('chats').doc(_chatId).set({
                'cashDifference': enteredVal,
                'karsiTarafNakitOnayi': false,
              }, SetOptions(merge: true));
              
              if (enteredVal > 0) {
                _sohbetIciPazarlikSistemMesajiGonder(enteredVal);
              }
            },
            child: const Text(
              'Talebi İlet',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMoneyString(String safRakam) {
    if (safRakam.isEmpty) return '';
    final buffer = StringBuffer();
    int counter = 0;
    for (int i = safRakam.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(safRakam[i]);
      counter++;
    }
    return buffer.toString().split('').reversed.join('');
  }

  void _sohbetIciPazarlikSistemMesajiGonder(double bedel) async {
    final String partyAName = (widget.ilanVerisi['sahipIsmi'] ?? "Kullanıcı").toString();
    await _firestore.collection('chats').doc(_chatId).collection('messages').add({
      'gonderen': 'system',
      'metin': '💰 PAZARLIK GÜNCELLEMESİ: $partyAName, mülk/değer farkı nedeniyle üste ₺${_formatMoneyString(bedel.toStringAsFixed(0))} nakit ödeme talep etti.',
      'timestamp': FieldValue.serverTimestamp(),
      'isSystem': true,
    });
  }

  void _takasIptalEt() async {
    setState(() {
      _teklifDurumu = 'İptal Edildi';
    });
    
    await _firestore.collection('chats').doc(_chatId).set({
      'status': 'İptal Edildi',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection('chats').doc(_chatId).collection('messages').add({
      'gonderen': 'system',
      'metin': '❌ Takas talebiniz iptal edilmiştir.',
      'timestamp': FieldValue.serverTimestamp(),
      'isSystem': true,
      'isSimpleNotice': true,
    });
  }

  void _mesajGonder() async {
    final String metin = _mesajController.text.trim();
    if (metin.isEmpty) return;
    _mesajController.clear();
    
    final mesajVerisi = {
      'gonderen': _currentUserId,
      'metin': metin,
      'timestamp': FieldValue.serverTimestamp(),
      'isSystem': false,
    };
    
    try {
      await _firestore.collection('chats').doc(_chatId).collection('messages').add(mesajVerisi);
      // Geliştirici ortamı simülasyonları kaldırıldı. Artık mesajlar sadece kullanıcının kendisi tarafından gönderiliyor.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gönderilemedi: $e ⚠️'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _otomatikSistemMesajiGonder(String contractId) async {
    if (!mounted) return;
    setState(() {
      _imzalananSozlesmeId = contractId;
    });
    
    final sistemMesajVerisi = {
      'gonderen': 'system',
      'metin': '📜 Geçici Takas Sözleşmeniz İmzalandı! #$contractId numaralı dijital mukavele tarafların biyometrik onayıyla güvenli bir şekilde imzalanmış ve takas süreci resmi olarak başlamıştır. ✔️',
      'timestamp': FieldValue.serverTimestamp(),
      'isSystem': true,
      'contractId': contractId,
    };
    await _firestore.collection('chats').doc(_chatId).collection('messages').add(sistemMesajVerisi);
  }

  void _handleTakasOnaylamaAndSok() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      ),
    );
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      String dbAdSoyad = (widget.ilanVerisi['sahipIsmi'] ?? "Kullanıcı").toString();
      String dbTcKimlik = "Belirtilmedi";
      String dbTelefon = "Belirtilmedi";
      String dbAdres = "Adres Belirtilmedi";
      String dbAracPlaka = "Belirtilmedi"; 

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          dbAdSoyad = (userData['adSoyad'] ?? dbAdSoyad).toString();
          dbTcKimlik = (userData['tcKimlik'] ?? "Belirtilmedi").toString();
          dbTelefon = (userData['telefon'] ?? "Belirtilmedi").toString();
          dbAdres = (userData['adres'] ?? "Belirtilmedi").toString();
          dbAracPlaka = (userData['aracPlaka'] ?? "Belirtilmedi").toString(); 
        }
      }

      String karsiTarafIsim = "Takas Ortağı";
      String karsiTarafPlaka = (widget.ilanVerisi['aracPlaka'] ?? "Belirtilmedi").toString(); 
      String karsiTarafTc = "Belirtilmedi";
      String karsiTarafTel = "Belirtilmedi";
      String karsiTarafAdres = "Belirtilmedi";

      final String? karsiTarafId = widget.ilanVerisi['userId'] ?? widget.ilanVerisi['sahipId'];
      
      if (karsiTarafId != null && karsiTarafId.isNotEmpty) {
        final karsiDoc = await _firestore.collection('users').doc(karsiTarafId).get();
        if (karsiDoc.exists && karsiDoc.data() != null) {
          final karsiData = karsiDoc.data()!;
          karsiTarafIsim = (karsiData['adSoyad'] ?? karsiTarafIsim).toString();
          karsiTarafPlaka = (karsiData['aracPlaka'] ?? karsiTarafPlaka).toString();
          karsiTarafTc = (karsiData['tcKimlik'] ?? karsiTarafTc).toString();
          karsiTarafTel = (karsiData['telefon'] ?? karsiTarafTel).toString();
          karsiTarafAdres = (karsiData['adres'] ?? karsiTarafAdres).toString();
        }
      } else {
        karsiTarafPlaka = karsiTarafPlaka == "Belirtilmedi" ? "Plaka Bulunamadı" : karsiTarafPlaka;
      }

      final varlik = _getVarlikBilgileri();
      final String templateDocId = varlik['templateId']!;
      final String resolvedCategoryName = varlik['kategoriAdi']!;

      DocumentSnapshot templateSnapshot = await _firestore
          .collection('swap_templates')
          .doc(templateDocId)
          .get();
          
      if (!mounted) return;
      
      if (!templateSnapshot.exists) {
        templateSnapshot = await _firestore.collection('swap_templates').doc('car_swap_template').get();
      }

      Navigator.pop(context); 
      
      if (!templateSnapshot.exists) {
        throw Exception("Sözleşme şablonu ($templateDocId) bulutta bulunamadı!");
      }
      
      String hamSablonMetni = (templateSnapshot.get('text') ?? "").toString();
      final String generatedContractId = 'TS-${Random().nextInt(90000) + 10000}';
          
      final String partyAName = "\n$dbAdSoyad\n  • Araç Plakası: $dbAracPlaka\n  • T.C. Kimlik No: $dbTcKimlik\n  • İletişim Telefonu: $dbTelefon\n  • İkamet Adresi: $dbAdres";
      final String partyBName = "\n$karsiTarafIsim\n  • Araç Plakası: $karsiTarafPlaka\n  • T.C. Kimlik No: $karsiTarafTc\n  • İletişim Telefonu: $karsiTarafTel\n  • İkamet Adresi: $karsiTarafAdres";
      
      final String detayBilgi = (widget.ilanVerisi['baslik'] ?? 'İlan Mülkü').toString();
      final String partyAVehicle = "$detayBilgi ($resolvedCategoryName)";
      const String partyBVehicle = "Karşı Tarafın İlanı / Varlık";
      final String bugununTarihi = "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";
      
      final String nakitMaddesiMetni = _nakitFarkiBedeli > 0
          ? "MADDE 9: Taraflar kafa kafaya mülk takasına ek olarak, segment ve değer mutabakatı gereği $karsiTarafIsim tarafından $dbAdSoyad tarafına ₺${_formatMoneyString(_nakitFarkiBedeli.toStringAsFixed(0))} nakit farkı ödenmesini biyometrik imzalarıyla kabul ve taahhüt etmiştir."
          : "MADDE 9: İşbu takas sözleşmesi barter (kafa kafaya) modelinde kurgulanmış olup, taraflar birbirlerinden ek nakit farkı talep etmeyecektir.";
          
      String dinamikSozlesmeMetni = hamSablonMetni
          .replaceAll('{CONTRACT_ID}', generatedContractId)
          .replaceAll('{DATE}', bugununTarihi)
          .replaceAll('{PARTY_A_NAME}', partyAName)
          .replaceAll('{PARTY_B_NAME}', partyBName)
          .replaceAll('{PARTY_A_VEHICLE}', partyAVehicle)
          .replaceAll('{PARTY_B_VEHICLE}', partyBVehicle)
          .replaceAll('{CASH_DIFFERENCE_CLAUSE}', nakitMaddesiMetni);
          
      final ContractModel yeniSozlesme = ContractModel(
        contractId: generatedContractId,
        adIdFromAntalya: (widget.ilanVerisi['id'] ?? "ilan_1").toString(),
        adIdFromIstanbul: "ilan_2",
        partyAName: partyAName,
        partyAVehicleDetails: partyAVehicle,
        partyBName: partyBName,
        partyBVehicleDetails: partyBVehicle,
        contractText: dinamikSozlesmeMetni,
        createdAt: DateTime.now(),
        cashDifference: _nakitFarkiBedeli,
        cashReceiverName: dbAdSoyad,
      );
      
      await _firestore.collection('contracts').doc(generatedContractId).set(yeniSozlesme.toMap());
      
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContractApprovalScreen(
            contractId: yeniSozlesme.contractId,
            contractText: yeniSozlesme.contractText,
            cashDifference: yeniSozlesme.cashDifference,
            swapCategory: resolvedCategoryName,
          ),
        ),
      );
      
      if (mounted && result == true) {
        await _firestore.collection('chats').doc(_chatId).set({
          'status': 'Onaylandı',
          'cashDifference': _nakitFarkiBedeli,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        setState(() {
          _teklifDurumu = 'Onaylandı';
        });
        
        _otomatikSistemMesajiGonder(yeniSozlesme.contractId);
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _lojistikPaneliniGoster();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sözleşme yüklenemedi: $e ⚠️'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _lojistikPaneliniGoster() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          child: _LojistikBottomSheet(
            secilenKonumTuru: _secilenKonumTuru,
            teslimEdecekKisi: _teslimEdecekKisi,
            kisiIletisimController: _kisiIletisimController,
            lokasyonTarifiController: _lokasyonTarifiController,
            secilenLat: _secilenLat,
            secilenLng: _secilenLng,
            onMuhurle: (konumTuru, teslimKisi, lat, lng) async {
              final Map<String, dynamic> lojistikVerisi = {
                'status': 'Onaylandı',
                'lojistikGirildi': true,
                'secilenKonumTuru': konumTuru,
                'teslimEdecekKisi': teslimKisi,
                'kisiIletisim': _kisiIletisimController.text,
                'lokasyonTarifi': _lokasyonTarifiController.text,
                'secilenLat': lat,
                'secilenLng': lng,
              };
              await _firestore.collection('chats').doc(_chatId).set(lojistikVerisi, SetOptions(merge: true));
              if (mounted) {
                setState(() {
                  _secilenKonumTuru = konumTuru;
                  _teslimEdecekKisi = teslimKisi;
                  _secilenLat = lat;
                  _secilenLng = lng;
                  _lojistikGirildi = true;
                });
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final varlik = _getVarlikBilgileri();
    final bool isNakitKilidiAktif = _nakitFarkiBedeli > 0 && !_karsiTarafOnayladi;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF1E3A8A),
              child: Icon(Icons.swap_horiz, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Takas Sohbet Odası',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  Text(
                    (widget.ilanVerisi['baslik'] ?? 'Takas İlanı').toString(),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _teklifDurumu == 'Beklemede'
                              ? Icons.hourglass_empty
                              : (_teklifDurumu == 'Onaylandı'
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined),
                          color: _teklifDurumu == 'Beklemede'
                              ? Colors.amber.shade800
                              : (_teklifDurumu == 'Onaylandı'
                                    ? Colors.green
                                    : Colors.red),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Takas Durumu: $_teklifDurumu',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _teklifDurumu == 'Beklemede'
                                ? Colors.amber.shade900
                                : (_teklifDurumu == 'Onaylandı'
                                      ? Colors.green.shade800
                                      : Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                    if (_teklifDurumu == 'Beklemede')
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade600, width: 2.0),
                              backgroundColor: Colors.red.shade50,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _takasIptalEt,
                            child: const Text(
                              'İptal Et',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _karsiTarafTeklifiOnayladi ? Colors.green : Colors.grey.shade300,
                              foregroundColor: _karsiTarafTeklifiOnayladi ? Colors.white : Colors.grey.shade600,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _karsiTarafTeklifiOnayladi ? _handleTakasOnaylamaAndSok : null,
                            child: const Text(
                              'Onayla',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_teklifDurumu == 'Onaylandı') ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Anahtar teslim adresi ve konumu karşı tarafa iletildi. Size hayırlı yolculuklar diliyoruz.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
                if (_teklifDurumu == 'Beklemede') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_karsiTarafTeklifiOnayladi
                            ? Colors.grey.shade200
                            : (_nakitFarkiBedeli > 0 ? Colors.teal : const Color(0xFF1E3A8A)),
                        foregroundColor: !_karsiTarafTeklifiOnayladi ? Colors.grey.shade500 : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        Icons.price_change_rounded,
                        color: !_karsiTarafTeklifiOnayladi ? Colors.grey.shade500 : Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        _nakitFarkiBedeli > 0
                            ? 'Talep Edilen Nakit Farkı: ₺${_formatMoneyString(_nakitFarkiBedeli.toStringAsFixed(0))} (Düzenle)'
                            : varlik['segmentMetni']!,
                        style: TextStyle(
                          color: !_karsiTarafTeklifiOnayladi ? Colors.grey.shade600 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                      onPressed: _karsiTarafTeklifiOnayladi ? _nakitFarkiGirisDialogunuAc : null,
                    ),
                  ),
                  if (isNakitKilidiAktif) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade900,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Üste talep ettiğiniz ₺${_formatMoneyString(_nakitFarkiBedeli.toStringAsFixed(0))} nakit farkı karşı tarafça onaylanana kadar sözleşme imzalama süreci kilitlidir.',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length + (_lojistikGirildi ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_lojistikGirildi && index == docs.length) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.teal.shade300, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.vpn_key_rounded, color: Colors.teal, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Anahtar Teslim Adresi Ve Konumu',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.map_rounded, color: Color(0xFF1E3A8A), size: 24),
                                  tooltip: 'Haritada Aç',
                                  onPressed: () => _haritadaAc(_secilenLat, _secilenLng),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.teal),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                children: [
                                  const TextSpan(
                                    text: '• Anahtar Konumu: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: _secilenKonumTuru,
                                    style: const TextStyle(fontWeight: FontWeight.normal),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                children: [
                                  const TextSpan(
                                    text: '• Teslim Edecek: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: _teslimEdecekKisi,
                                    style: const TextStyle(fontWeight: FontWeight.normal),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                children: [
                                  const TextSpan(
                                    text: '• İletişim: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: _kisiIletisimController.text,
                                    style: const TextStyle(fontWeight: FontWeight.normal),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                children: [
                                  const TextSpan(
                                    text: '• Adres / Tarif: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: _lokasyonTarifiController.text,
                                    style: const TextStyle(fontWeight: FontWeight.normal),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_imzalananSozlesmeId != null) ...[
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E3A8A),
                                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _sozlesmeDetayGoster(_imzalananSozlesmeId!),
                                  icon: const Icon(Icons.description_rounded, size: 16),
                                  label: const Text('İmzalanan Sözleşmeyi Görüntüle 📜', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _haritadaAc(_secilenLat, _secilenLng),
                                icon: const Icon(Icons.navigation_rounded, size: 16, color: Colors.white),
                                label: const Text('Google Haritalar ile Yol Tarifi Al 🗺️', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['gonderen'] == _currentUserId;
                    final bool isSystem = data['isSystem'] ?? false;
                    final bool isSimpleNotice = data['isSimpleNotice'] ?? false;
                    
                    return _mesajBalonuGorunumu(
                      (data['metin'] ?? '').toString(),
                      isMe,
                      isSystem,
                      isSimpleNotice,
                      contractId: data['contractId']?.toString(),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mesajController,
                      decoration: InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF1E3A8A)),
                    onPressed: _mesajGonder,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mesajBalonuGorunumu(String metin, bool isMe, bool isSystem, bool isSimpleNotice, {String? contractId}) {
    if (isSystem && isSimpleNotice) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200, width: 1),
          ),
          child: Text(
            metin,
            style: TextStyle(
              color: Colors.red.shade800,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (isSystem) {
      return Center(
        child: InkWell(
          onTap: () async {
            if (contractId != null && contractId.isNotEmpty) {
              await _sozlesmeDetayGoster(contractId);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade300, width: 1.5),
              color: Colors.green.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SİSTEM MÜHÜRÜ & BİLDİRİMİ (İncelemek için dokun 📜)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  metin,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade900,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          metin,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _LojistikBottomSheet extends StatefulWidget {
  final String secilenKonumTuru;
  final String teslimEdecekKisi;
  final TextEditingController kisiIletisimController;
  final TextEditingController lokasyonTarifiController;
  final double secilenLat;
  final double secilenLng;
  final Function(String konumTuru, String teslimKisi, double lat, double lng) onMuhurle;
  
  const _LojistikBottomSheet({
    required this.secilenKonumTuru,
    required this.teslimEdecekKisi,
    required this.kisiIletisimController,
    required this.lokasyonTarifiController,
    required this.secilenLat,
    required this.secilenLng,
    required this.onMuhurle,
  });

  @override
  State<_LojistikBottomSheet> createState() => _LojistikBottomSheetState();
}

class _LojistikBottomSheetState extends State<_LojistikBottomSheet> {
  late String _currentKonumTuru;
  late String _currentTeslimkisi;
  late double _currentLat;
  late double _currentLng;
  late TextEditingController _localIletisimController;
  late TextEditingController _localTarifController;
  bool _konumTiklandi = false;

  @override
  void initState() {
    super.initState();
    _currentKonumTuru = widget.secilenKonumTuru;
    _currentTeslimkisi = widget.teslimEdecekKisi;
    _currentLat = widget.secilenLat;
    _currentLng = widget.secilenLng;
    _localIletisimController = TextEditingController(text: widget.kisiIletisimController.text);
    _localTarifController = TextEditingController(text: widget.lokasyonTarifiController.text);
  }

  @override
  void dispose() {
    _localIletisimController.dispose();
    _localTarifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double klavyeYuksekligi = MediaQuery.of(context).viewInsets.bottom;
    final bool isKlavyeAcik = klavyeYuksekligi > 0;
    
    return Container(
      padding: EdgeInsets.only(bottom: klavyeYuksekligi),
      height: MediaQuery.of(context).size.height * 0.86,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔑 Anahtar Teslim Adresi Ve Konumu',
                      style: TextStyle(
                        fontSize: isKlavyeAcik ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!isKlavyeAcik)
                      Text(
                        'Karşı tarafın varlığa hatasız ulaşması için bilgileri girin.',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    Divider(height: isKlavyeAcik ? 12 : 24),
                    const Text(
                      'Varlık Şu An Nerede?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        'Havalimanı Otoparkı',
                        'Ev/İşyeri Önü',
                        'Özel Otopark',
                        'Emanet Kasa',
                      ].map((komun) {
                        final bool isSecili = _currentKonumTuru == komun;
                        return ChoiceChip(
                          label: Text(
                            komun,
                            style: TextStyle(
                              color: isSecili ? Colors.white : Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSecili,
                          selectedColor: const Color(0xFF1E3A8A),
                          backgroundColor: Colors.grey.shade50,
                          onSelected: (val) => setState(() => _currentKonumTuru = komun),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Anahtarı / Teslimi Kim Yapacak?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _currentTeslimkisi,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        'Bizzat Kendim',
                        'Eşim / Çocuğum',
                        'Arkadaşım',
                        'Otopark Görevlisi / Güvenlik',
                        'Şifreli KeyLock Kasası',
                      ].map((kisi) {
                        return DropdownMenuItem(
                          value: kisi,
                          child: Text(kisi, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _currentTeslimkisi = val ?? 'Bizzat Kendim'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Teslim Edecek Kişi İletişim Bilgisi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _localIletisimController,
                      decoration: InputDecoration(
                        hintText: 'İsim ve telefon numarası girin...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Teslim Alınacak Net Adres & Tarif',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _localTarifController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Blok, kat, kapı numarası veya açık adres tarifi...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _konumTiklandi ? Colors.green.shade50 : Colors.white,
                          side: BorderSide(
                            color: _konumTiklandi ? Colors.green : Colors.red.shade400,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _konumTiklandi = true;
                            _currentLat = 40.9782;
                            _currentLng = 28.8239;
                          });
                        },
                        icon: Icon(
                          _konumTiklandi ? Icons.check_circle : Icons.location_on,
                          color: _konumTiklandi ? Colors.green : Colors.red.shade600,
                          size: 18,
                        ),
                        label: Text(
                          _konumTiklandi ? '✔ Konum Başarıyla Eklendi ✔️' : 'Teslim Alınacak Konumu İşaretle 📍',
                          style: TextStyle(
                            color: _konumTiklandi ? Colors.green.shade800 : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: isKlavyeAcik ? 8.0 : 16.0,
                top: 8.0,
              ),
              child: SizedBox(
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
                    widget.kisiIletisimController.text = _localIletisimController.text;
                    widget.lokasyonTarifiController.text = _localTarifController.text;
                    widget.onMuhurle(
                      _currentKonumTuru,
                      _currentTeslimkisi,
                      _currentLat,
                      _currentLng,
                    );
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    'Adres ve Konumu Gönder',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CanliParaFormatlayici extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final String safRakam = newValue.text.replaceAll('.', '');
    final buffer = StringBuffer();
    int counter = 0;
    for (int i = safRakam.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(safRakam[i]);
      counter++;
    }
    final String formatliMetin = buffer.toString().split('').reversed.join('');
    return TextEditingValue(
      text: formatliMetin,
      selection: TextSelection.collapsed(offset: formatliMetin.length),
    );
  }
}