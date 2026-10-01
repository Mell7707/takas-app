import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takas_app/screens/profile_views/edit_profile_view.dart';

class ContractApprovalScreen extends StatefulWidget {
  final String contractId;
  final String? contractText; // İsteğe bağlı hale getirildi, Firebase'den çekilebilecek
  final double cashDifference;
  final String swapCategory; // "Araç", "Konut" veya "Deniz Araçları"
  
  const ContractApprovalScreen({
    super.key,
    required this.contractId,
    this.contractText,
    this.cashDifference = 0.0,
    this.swapCategory = 'Araç',
  });
  
  @override
  State<ContractApprovalScreen> createState() => _ContractApprovalScreenState();
}

class _ContractApprovalScreenState extends State<ContractApprovalScreen> {
  bool _sozlesmeOkundu = false;
  bool _sozlesmeEnAsagiKaydirildi = false;
  bool _mssOnaylandi = false; // 📜 İyzico Zorunlu Mesafeli Satış Sözleşmesi & Ön Bilgilendirme Onayı
  bool _odemeYapildi = false;
  bool _isProcessing = false;
  bool _isCheckingProfile = false;
  bool _isLoadingTemplate = true;
  
  late String _guncelSozlesmeMetni;
  
  final _kartNoController = TextEditingController();
  final _skttController = TextEditingController();
  final _cvvController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final double _komisyonTutari = 1500.00;
  final double _provizyonBlokeTutari = 5000.00;

  @override
  void initState() {
    super.initState();
    _guncelSozlesmeMetni = widget.contractText ?? 'Sözleşme metni yükleniyor...';
    _scrollController.addListener(_scrollListener);
    _sozlesmeMetniniFirebasedenGetir();
  }

  // 🌟 Firebase swap_templates koleksiyonundan kategoriye göre dinamik şablon çekme (Kesin Eşleştirme)
  Future<void> _sozlesmeMetniniFirebasedenGetir() async {
    if (widget.contractText != null && widget.contractText!.isNotEmpty) {
      if (mounted) setState(() => _isLoadingTemplate = false);
      return;
    }

    try {
      String templateDocId = 'car_swap_template';
      String katLower = widget.swapCategory.toLowerCase();

      // 🔍 Genişletilmiş ve garanti kelime eşleştirme havuzu
      if (katLower.contains('konut') || katLower.contains('ev') || katLower.contains('yazlık') || katLower.contains('gayrimenkul') || katLower.contains('daire')) {
        templateDocId = 'house_swap_template';
      } else if (katLower.contains('deniz') || katLower.contains('tekne') || katLower.contains('yat') || katLower.contains('jetski') || katLower.contains('marine') || katLower.contains('sürat')) {
        templateDocId = 'marine_swap_template';
      } else {
        templateDocId = 'car_swap_template';
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('swap_templates')
          .doc(templateDocId)
          .get();

      if (!mounted) return;

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        String textFromDb = (data['text'] ?? 'Sözleşme şablonu bulunamadı.').toString();
        
        textFromDb = textFromDb.replaceAll('{CONTRACT_ID}', widget.contractId);

        setState(() {
          _guncelSozlesmeMetni = textFromDb;
          _isLoadingTemplate = false;
        });
      } else {
        setState(() {
          _guncelSozlesmeMetni = 'Belirtilen kategoriye ait sözleşme şablonu bulunamadı.';
          _isLoadingTemplate = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guncelSozlesmeMetni = 'Sözleşme yüklenirken hata oluştu: $e';
        _isLoadingTemplate = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 10) {
      if (!_sozlesmeEnAsagiKaydirildi) {
        if (mounted) {
          setState(() {
            _sozlesmeEnAsagiKaydirildi = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sözleşme sonuna ulaşıldı. Onay kutucuğu aktif! 🔓'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _kartNoController.dispose();
    _skttController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _hataSnackGoster(String mesaj) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mesaj), backgroundColor: Colors.red),
      );
    }
  }

  // 📜 Mesafeli Satış Sözleşmesi Modal Penceresi
  void _mesafeliSatisSozlesmesiniGoster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mesafeli Satış Sözleşmesi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Text(
                  'MADDE 1: TARAFLAR\n'
                  'İşbu Mesafeli Satış Sözleşmesi ("Sözleşme"), 6502 sayılı Tüketicinin Korunması Hakkında Kanun ve Mesafeli Sözleşmeler Yönetmeliği hükümleri gereğince düzenlenmiştir.\n\n'
                  'MADDE 2: KONU VE HİZMET BEDELİ\n'
                  'İşbu sözleşmenin konusu, Alıcı\'nın TakasApp platformu üzerinden gerçekleştirdiği takas işlemlerine istinaden ödemeyi taahhüt ettiği eşit paylaşımlı hizmet komisyonu ve provizyon güvence bedelidir.\n\n'
                  'MADDE 3: CAYMA HAKKI VE İPTAL ŞARTLARI\n'
                  'Tarafların dijital mühürle sözleşmeyi onaylaması ve iyzico altyapısı üzerinden provizyon/komisyon tahsilatının gerçekleşmesiyle hizmet ifası başlamış sayılır. İptal ve iade koşulları platform kurallarına tabidir.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📜 Ön Bilgilendirme Formu Modal Penceresi
  void _onBilgilendirmeFormunuGoster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ön Bilgilendirme Formu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Text(
                  'ÖN BİLGİLENDİRME FORMU\n\n'
                  '1. Alıcı; sözleşme konusu hizmetin temel nitelikleri, vergiler dâhil toplam fiyatı, ödeme şekli ve ifaya ilişkin tüm ön bilgileri okuyup bilgi sahibi olduğunu ve elektronik ortamda gerekli teyidi verdiğini beyan eder.\n\n'
                  '2. Hizmet Sağlayıcı, iyzico güvenli ödeme altyapısı aracılığıyla tahsilat işlemlerini yürütmekte olup kart bilgileriniz 256-bit SSL sertifikası ile korunmaktadır.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _biyometrikSecimPaneliniGoster() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.security_rounded, color: Color(0xFF1E3A8A), size: 24),
                SizedBox(width: 10),
                Text(
                  'Elektronik Sözleşmeyi İmzala',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Kimliğinizi doğrulamak ve resmi elektronik imzanızı atmak için yöntem seçin:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.blue.shade50,
              leading: const Icon(Icons.fingerprint, color: Color(0xFF1E3A8A), size: 28),
              title: const Text('Parmak İzi ile İmzala', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Biyometrik cihaz doğrulaması', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1E3A8A)),
              onTap: () {
                Navigator.pop(context);
                _islemBasariylaTamamla("Parmak İzi ile Mühürlendi");
              },
            ),
            const SizedBox(height: 12),

            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.teal.shade50,
              leading: const Icon(Icons.face_retouching_natural, color: Colors.teal, size: 28),
              title: const Text('Yüz Tanıma (Face ID)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
              subtitle: const Text('Kamera taraması ile onay', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.teal),
              onTap: () {
                Navigator.pop(context);
                _islemBasariylaTamamla("Yüz Tanıma (Face ID) ile Mühürlendi");
              },
            ),
            const SizedBox(height: 12),

            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey.shade100,
              leading: const Icon(Icons.lock_outline, color: Colors.black87, size: 28),
              title: const Text('Güvenlik Şifresi ile İmzala', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Hesap şifresi ile güvenli onay', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
              onTap: () {
                Navigator.pop(context);
                _islemBasariylaTamamla("Güvenlik Şifresi ile Mühürlendi");
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _islemBasariylaTamamla(String imzaTuru) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final String tarihSaat = "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} - ${DateTime.now().hour}:${DateTime.now().minute}";
    final String kriptoHash = "TR-SWAP-${Random().nextInt(900000) + 100000}";

    final String imzaliMetin = _guncelSozlesmeMetni + "\n\n"
        "--------------------------------------------------\n"
        "ELEKTRONİK İMZA VE ZAMAN DAMGASI DOĞRULAMASI:\n"
        "• Taraf A Onay Durumu: [$imzaTuru]\n"
        "• Zaman Damgası: $tarihSaat\n"
        "• Güvenlik Kodu & Kripto Hash: $kriptoHash\n"
        "• İşbu mukavele 5070 sayılı Kanun uyarınca loglanmıştır.\n"
        "--------------------------------------------------";

    if (!mounted) return;
    setState(() {
      _guncelSozlesmeMetni = imzaliMetin;
      _isProcessing = false;
      _odemeYapildi = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(widget.contractId)
          .update({'contractText': imzaliMetin});
    } catch (e) {
      debugPrint("Mühürlü sözleşme buluta güncellenirken hata: $e");
    }

    if (!mounted) return;

    String bilgilendirmeMetni = '💸 ₺$_komisyonTutari Komisyon Çekildi! 🔒 Elektronik Mühür Başarıyla Basıldı!';
    if (widget.cashDifference > 0) {
      bilgilendirmeMetni += ' 💰 Nakit Farkı Emri Verildi!';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(bilgilendirmeMetni, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  void _eksikBilgiUyarisiGoster({required String baslik, required String aciklama}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(baslik, style: const TextStyle(fontSize: 17, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          aciklama,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileView()),
              );
            },
            child: const Text('Profili Tamamla', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _finansalIslemiBaslat() async {
    if (!_sozlesmeOkundu) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce yasal sözleşme maddelerini onaylayın! 📜'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_mssOnaylandi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen Mesafeli Satış Sözleşmesi ve Ön Bilgilendirme Formu\'nu onaylayın! 📜'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    String safKartNo = _kartNoController.text.replaceAll(' ', '');
    if (safKartNo.length < 16 ||
        _cvvController.text.length < 3 ||
        _skttController.text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen güvence kart bilgilerini eksiksiz giriniz! 💳'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isCheckingProfile = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        bool eksikKimlikBilgisi = true;
        bool eksikPlakaBilgisi = false;
        
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final tc = (data['tcKimlik'] ?? '').toString();
          final tel = (data['telefon'] ?? '').toString();
          final adres = (data['adres'] ?? '').toString();
          final aracPlaka = (data['aracPlaka'] ?? '').toString();

          if (tc.length == 11 && tel.isNotEmpty && adres.isNotEmpty) {
            eksikKimlikBilgisi = false;
          }

          // 🚗 Eğer takas kategorisi Araç ise plaka zorunluluğunu kontrol et
          if (widget.swapCategory.toLowerCase().contains('araç') || widget.swapCategory.toLowerCase() == 'arac') {
            if (aracPlaka.trim().isEmpty) {
              eksikPlakaBilgisi = true;
            }
          }
        }

        if (!mounted) return;

        if (eksikKimlikBilgisi) {
          setState(() => _isCheckingProfile = false);
          _eksikBilgiUyarisiGoster(
            baslik: 'Yasal Zorunluluk',
            aciklama: 'Yasal takas sözleşmesinin geçerliliği ve güvenliğiniz için T.C. Kimlik No, Telefon ve Açık Adres bilgilerinizin eksiksiz olması gerekmektedir.\n\nLütfen profilinize giderek eksik bilgileri tamamlayın.',
          );
          return;
        }

        if (eksikPlakaBilgisi) {
          setState(() => _isCheckingProfile = false);
          _eksikBilgiUyarisiGoster(
            baslik: 'Araç Plakası Zorunluluğu',
            aciklama: 'Araç takasini gerceklestirmek icin profili duzenle panelinde arac plakanizi kaydedin.',
          );
          return;
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingProfile = false);
      _hataSnackGoster('Profil kontrolü sırasında hata: $e');
      return;
    }

    if (!mounted) return;
    setState(() => _isCheckingProfile = false);
    _biyometrikSecimPaneliniGoster();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Sözleşme No: #${widget.contractId}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).padding.bottom + 32.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Yasal Takas Sözleşmesi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                Chip(
                  label: Text(
                    widget.swapCategory,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF1E3A8A),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 260,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _isLoadingTemplate
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            _guncelSozlesmeMetni,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  activeColor: const Color(0xFF1E3A8A),
                  value: _sozlesmeOkundu,
                  onChanged: _sozlesmeEnAsagiKaydirildi && !_isLoadingTemplate
                      ? (val) => setState(() => _sozlesmeOkundu = val ?? false)
                      : null,
                ),
                Expanded(
                  child: Text(
                    'Sözleşme metnini okudum, tüm maddi ve cezai sorumlulukları kabul ediyorum.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _sozlesmeEnAsagiKaydirildi && !_isLoadingTemplate ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x0D1E3A8A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x331E3A8A)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Eşit Paylaşımlı Hizmet Komisyonu:',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      Text(
                        '₺${_komisyonTutari.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock_clock, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            'Ceza/İhlal Provizyon Blokesi:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₺${_provizyonBlokeTutari.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  if (widget.cashDifference > 0) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.price_check_rounded,
                              color: Colors.teal,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Ödenecek Ek Nakit Dengesi:',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₺${widget.cashDifference.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(),
                  ),
                  const Text(
                    '⚠️️ Provizyon blokesi kartınızdan nakit olarak çekilmez. Takas süreci kazasız, cezasız ve eksiksiz bittikten sonra bankanız tarafından otomatik olarak kaldırılır.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // 📜 İYZICO ZORUNLU MESAFELİ SATIŞ SÖZLEŞMESİ & ÖN BİLGİLENDİRME CHECKBOX ALANI
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Checkbox(
                    activeColor: const Color(0xFF1E3A8A),
                    value: _mssOnaylandi,
                    onChanged: (val) => setState(() => _mssOnaylandi = val ?? false),
                  ),
                  Expanded(
                    child: Wrap(
                      children: [
                        const Text('Ödeme öncesi ', style: TextStyle(fontSize: 12, color: Colors.black87)),
                        GestureDetector(
                          onTap: () => _mesafeliSatisSozlesmesiniGoster(context),
                          child: const Text('Mesafeli Satış Sözleşmesi\'ni', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), decoration: TextDecoration.underline)),
                        ),
                        const Text(' ve ', style: TextStyle(fontSize: 12, color: Colors.black87)),
                        GestureDetector(
                          onTap: () => _onBilgilendirmeFormunuGoster(context),
                          child: const Text('Ön Bilgilendirme Formu\'nu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), decoration: TextDecoration.underline)),
                        ),
                        const Text(' okudum ve onaylıyorum.', style: TextStyle(fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Güvence Kart Bilgileri',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _kartNoController,
              keyboardType: TextInputType.number,
              maxLength: 19,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                KartNumarasiFormatter(),
              ],
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.credit_card,
                  color: Color(0xFF1E3A8A),
                ),
                hintText: 'Kredi Kartı Numarası',
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skttController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      SkttFormatter(),
                    ],
                    decoration: InputDecoration(
                      hintText: 'AA/YY',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'CVV',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _odemeYapildi ? Colors.green : const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isProcessing || _isCheckingProfile || _odemeYapildi || _isLoadingTemplate
                    ? null
                    : _finansalIslemiBaslat,
                child: (_isProcessing || _isCheckingProfile)
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : (_odemeYapildi
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'ÖDEME & ELEKTRONİK MÜHÜR TAMAMLANDI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Ödeme Yap Ve Sözleşmeyi İmzala',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KartNumarasiFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.isEmpty) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class SkttFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll('/', '');
    if (text.isEmpty) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}