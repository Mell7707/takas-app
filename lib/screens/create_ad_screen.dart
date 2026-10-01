import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takas_app/services/app_core_helper.dart';

class CreateAdScreen extends StatefulWidget {
  final String varsayilanKategori;
  final Function(Map<String, dynamic>) onAdCreated;
  final Map<String, dynamic>? ilanVerisi;
  
  const CreateAdScreen({
    super.key,
    required this.varsayilanKategori,
    required this.onAdCreated,
    this.ilanVerisi,
  });
  
  @override
  State<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  late String _secilenAnaKategori;
  String? _secilenAltKategori;
  
  bool _isEditMode = false;
  bool _isLoading = false; // 🛡️ Kaydetme esnasında butonu kilitlemek için

  String? _secilenMarka;
  String? _secilenModel;
  String? _secilenYil;
  String? _secilenVites;
  String? _secilenYakitTipi;
  String? _secilenCekisTipi;
  String? _secilenSigaraDurumu;
  String? _secilenEvKatTipi;
  String? _secilenKonseptKullanim;
  String? _secilenSiteDurumu;

  final _aracPlakaController = TextEditingController(); // 🚗 Araç Plakası Kontrolcüsü

  String? _secilenSalonSayisi;
  String? _secilenOdaSayisi;
  String? _secilenBanyoSayisi;
  String? _secilenTuvaletSayisi;
  String? _secilenBalkonSayisi;
  String? _secilenKullanimAlani;
  String? _secilenHavuzDurumu; 
  String? _secilenBahceDurumu; 

  String? _secilenMevcutIl;
  String? _secilenMevcutIlce;
  
  String? _secilenHedefIl;
  String? _secilenHedefIlce;
  
  DateTime? _baslangicTarihi;
  DateTime? _bitisTarihi;
  bool _isDateFlexible = false;
  
  final List<String> _secilenFotograflar = [];
  final ImagePicker _picker = ImagePicker();
  final _aciklamaController = TextEditingController();

  final List<String> _salonSecenekleri = ['1', '2', '3'];
  final List<String> _odaSecenekleri = ['1', '2', '3', '4', '5', '6', '7'];
  final List<String> _banyoTuvaletSecenekleri = ['1', '2', '3', '4', '5'];
  final List<String> _balkonSecenekleri = ['Balkon Yok', '1', '2', '3', '4', '5+'];

  final List<String> _kullanimAlaniSecenekleri = List.generate(30, (i) => '${(i + 4) * 10}-${(i + 5) * 10} m2');

  Future<void> _tarihSecimiBaslat({required bool isBaslangic}) async {
    final DateTime? secilenTarih = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    // 🛡️ DEAD-CONTEXT KORUMASI
    if (!mounted) return;

    if (secilenTarih != null) {
      setState(() {
        if (isBaslangic) {
          _baslangicTarihi = secilenTarih;
          if (_bitisTarihi != null && _bitisTarihi!.isBefore(secilenTarih)) {
            _bitisTarihi = secilenTarih.add(const Duration(days: 1));
          }
        } else {
          _bitisTarihi = secilenTarih;
        }
      });
    }
  }

  void _onAnaKategoriTemizle(String yeniAnaKategori) {
    setState(() {
      _secilenAnaKategori = yeniAnaKategori;
      if (yeniAnaKategori == 'Araç') {
        _secilenAltKategori = 'Otomobil';
      } else if (yeniAnaKategori == 'Konut') {
        _secilenAltKategori = 'Daire';
      } else {
        _secilenAltKategori = null;
      }
      _secilenMarka = null;
      _secilenModel = null;
      _secilenYil = null;
      _secilenVites = null;
      _secilenYakitTipi = null;
      _secilenCekisTipi = null;
      _secilenSigaraDurumu = null;
      _secilenEvKatTipi = null;
      _secilenKonseptKullanim = null;
      _secilenSiteDurumu = null;
      _secilenSalonSayisi = null;
      _secilenOdaSayisi = null;
      _secilenBanyoSayisi = null;
      _secilenTuvaletSayisi = null;
      _secilenBalkonSayisi = null;
      _secilenKullanimAlani = null;
      _secilenHavuzDurumu = null;
      _secilenBahceDurumu = null;
    });
  }

  @override
  void initState() {
    super.initState();
    String initial = widget.varsayilanKategori;
    if (initial == 'Ev' || initial == 'Konut') {
      _secilenAnaKategori = 'Konut';
      _secilenAltKategori = 'Daire';
    } else {
      _secilenAnaKategori = 'Araç';
      _secilenAltKategori = 'Otomobil';
    }

    if (widget.ilanVerisi != null) {
      _isEditMode = true;
      final ilan = widget.ilanVerisi!;
      String cat = ilan['kategori'] ?? widget.varsayilanKategori;
      if (cat == 'Ev' || cat == 'Konut') {
        _secilenAnaKategori = 'Konut';
        const gecerliKonutTipleri = ['Daire', 'Rezidans', 'Müstakil Ev'];
        final gelenKonutTipi = ilan['altKategori']?.toString();
        _secilenAltKategori = (gecerliKonutTipleri.contains(gelenKonutTipi)) ? gelenKonutTipi : 'Daire';
      } else {
        _secilenAnaKategori = 'Araç';
        const gecerliAracTipleri = ['Otomobil', 'SUV', 'Pickup'];
        final gelenAracTipi = ilan['altKategori']?.toString();
        _secilenAltKategori = (gecerliAracTipleri.contains(gelenAracTipi)) ? gelenAracTipi : 'Otomobil';
      }

      _aracPlakaController.text = ilan['aracPlaka'] ?? ''; 

      final gelenMarka = ilan['marka']?.toString();
      final gelenModel = (ilan['model'] ?? ilan['yil'])?.toString();

      if (gelenMarka != null && gelenMarka.isNotEmpty) {
        if (AppCoreHelper.markaModelHaritasi.containsKey(gelenMarka)) {
          _secilenMarka = gelenMarka;
        } else {
          AppCoreHelper.markaModelHaritasi[gelenMarka] = [gelenModel ?? 'Standart'];
          _secilenMarka = gelenMarka;
        }
      }
      if (gelenModel != null && gelenModel.isNotEmpty) {
        if (_secilenMarka != null && AppCoreHelper.markaModelHaritasi.containsKey(_secilenMarka)) {
          if (!AppCoreHelper.markaModelHaritasi[_secilenMarka]!.contains(gelenModel)) {
            AppCoreHelper.markaModelHaritasi[_secilenMarka]!.add(gelenModel);
          }
        }
        _secilenModel = gelenModel;
      }

      _secilenYil = ilan['yil']?.toString();
      
      const gecerliVitesler = ['Otomatik', 'Yarı Otomatik', 'Manuel'];
      final gelenVites = ilan['vites']?.toString();
      _secilenVites = gecerliVitesler.contains(gelenVites) ? gelenVites : null;

      const gecerliYakitlar = ['Benzin', 'Dizel', 'LPG', 'Hibrit', 'Elektrikli'];
      final gelenYakit = ilan['yakitTipi']?.toString();
      _secilenYakitTipi = gecerliYakitlar.contains(gelenYakit) ? gelenYakit : null;

      const gecerliCekisler = ['4x2', '4x4'];
      final gelenCekis = ilan['cekisTipi']?.toString();
      _secilenCekisTipi = gecerliCekisler.contains(gelenCekis) ? gelenCekis : null;

      const gecerliSigara = ['İçilebilir', 'İçilemez (Kokuyor)'];
      final gelenSigara = ilan['sigara']?.toString();
      _secilenSigaraDurumu = gecerliSigara.contains(gelenSigara) ? gelenSigara : null;

      const gecerliKatTipleri = ['Tek Katlı', 'Dubleks', 'Tripleks'];
      final gelenKatTipi = ilan['evKatTipi']?.toString();
      _secilenEvKatTipi = gecerliKatTipleri.contains(gelenKatTipi) ? gelenKatTipi : null;

      const gecerliKonseptler = ['Yazlık', 'Villa'];
      final gelenKonsept = ilan['konseptKullanim']?.toString();
      _secilenKonseptKullanim = gecerliKonseptler.contains(gelenKonsept) ? gelenKonsept : null;

      const gecerliSiteDurumlari = ['Site İçi', 'Site Dışı / Bağımsız'];
      final gelenSite = ilan['siteDurumu']?.toString();
      _secilenSiteDurumu = gecerliSiteDurumlari.contains(gelenSite) ? gelenSite : null;

      final gelenSalon = ilan['salonSayisi']?.toString();
      _secilenSalonSayisi = _salonSecenekleri.contains(gelenSalon) ? gelenSalon : null;

      final gelenOda = ilan['odaSayisi']?.toString();
      _secilenOdaSayisi = _odaSecenekleri.contains(gelenOda) ? gelenOda : null;

      final gelenBanyo = ilan['banyoSayisi']?.toString();
      _secilenBanyoSayisi = _banyoTuvaletSecenekleri.contains(gelenBanyo) ? gelenBanyo : null;

      final gelenTuvalet = ilan['tuvaletSayisi']?.toString();
      _secilenTuvaletSayisi = _banyoTuvaletSecenekleri.contains(gelenTuvalet) ? gelenTuvalet : null;

      final gelenBalkon = ilan['balkonSayisi']?.toString();
      _secilenBalkonSayisi = _balkonSecenekleri.contains(gelenBalkon) ? gelenBalkon : null;

      final gelenKullanimAlani = ilan['kullanimAlani']?.toString();
      _secilenKullanimAlani = _kullanimAlaniSecenekleri.contains(gelenKullanimAlani) ? gelenKullanimAlani : null;

      const gecerliHavuzBahce = ['Havuz Var', 'Havuz Yok', 'Bahçe Var', 'Bahçe Yok'];
      final gelenHavuz = ilan['havuzDurumu']?.toString();
      _secilenHavuzDurumu = gecerliHavuzBahce.contains(gelenHavuz) ? gelenHavuz : null;

      final gelenBahce = ilan['bahceDurumu']?.toString();
      _secilenBahceDurumu = gecerliHavuzBahce.contains(gelenBahce) ? gelenBahce : null;
      
      final gelenMevcutIl = ilan['mevcutIl']?.toString();
      if (gelenMevcutIl != null && AppCoreHelper.lokasyonHaritasi.containsKey(gelenMevcutIl)) {
        _secilenMevcutIl = gelenMevcutIl;
        final gelenIlce = ilan['mevcutIlce']?.toString();
        if (gelenIlce != null && AppCoreHelper.lokasyonHaritasi[_secilenMevcutIl]!.contains(gelenIlce)) {
          _secilenMevcutIlce = gelenIlce;
        }
      }
      
      final gelenHedefIl = ilan['hedefIl']?.toString();
      if (gelenHedefIl != null && AppCoreHelper.lokasyonHaritasi.containsKey(gelenHedefIl)) {
        _secilenHedefIl = gelenHedefIl;
        final gelenHedefIlce = ilan['hedefIlce']?.toString();
        if (gelenHedefIlce != null && AppCoreHelper.lokasyonHaritasi[_secilenHedefIl]!.contains(gelenHedefIlce)) {
          _secilenHedefIlce = gelenHedefIlce;
        }
      }

      _aciklamaController.text = ilan['detay'] ?? '';
      _baslangicTarihi = AppCoreHelper.parseStringToDate(ilan['baslangicTarihi'] ?? ilan['baslangic']);
      _bitisTarihi = AppCoreHelper.parseStringToDate(ilan['bitisTarihi'] ?? ilan['bitis']);
      _isDateFlexible = ilan['isDateFlexible'] ?? false;
      if (ilan['fotograflar'] != null) {
        _secilenFotograflar.addAll(List<String>.from(ilan['fotograflar']));
      } else if (ilan['gorsel'] != null && (ilan['gorsel'] as String).isNotEmpty) {
        _secilenFotograflar.add(ilan['gorsel']);
      }
    }
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    _aracPlakaController.dispose();
    super.dispose();
  }

  String _dinamikBaslikHesapla() {
    if (_secilenAnaKategori == 'Araç' && _secilenMarka != null) {
      String markaModel = _secilenMarka!;
      if (_secilenModel != null) markaModel += ' $_secilenModel';
      if (_secilenYil != null) markaModel = '$_secilenYil $markaModel';
      if (_secilenYakitTipi != null) markaModel += ' ($_secilenYakitTipi)';
      return '$markaModel Takası';
    } else if (_secilenAltKategori != null) {
      return '$_secilenAltKategori Takası';
    }
    return '${_secilenAnaKategori} Takası';
  }

  Future<void> _fotografEkle() async {
    if (_secilenFotograflar.length >= 10) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En fazla 10 adet fotoğraf yükleyebilirsiniz! 📸'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    try {
      final XFile? secilenDosya = await _picker.pickImage(source: ImageSource.gallery);
      if (secilenDosya != null && mounted) {
        setState(() => _secilenFotograflar.add(secilenDosya.path));
      }
    } catch (e) {
      // Hata yoksay
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isKonut = _secilenAnaKategori == 'Konut';
    bool isArac = _secilenAnaKategori == 'Araç';
    bool isMustakilEv = _secilenAltKategori == 'Müstakil Ev';
    
    bool isKapaliKabinArac = isArac && (_secilenAltKategori == 'Otomobil' || _secilenAltKategori == 'SUV' || _secilenAltKategori == 'Pickup');

    final String baslangicStr = _baslangicTarihi != null ? "${_baslangicTarihi!.day}/${_baslangicTarihi!.month}/${_baslangicTarihi!.year}" : 'Seçiniz';
    final String bitisStr = _bitisTarihi != null ? "${_bitisTarihi!.day}/${_bitisTarihi!.month}/${_bitisTarihi!.year}" : 'Seçiniz';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? 'İlanı Düzenle' : 'Yeni İlan Yayınla'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isEditMode ? 'Mevcut İlanı Güncelle' : _dinamikBaslikHesapla(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 🌟 KATEGORİ SEÇİMİ VE TAŞIT TÜRÜ YAN YANA
            if (isArac) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kategori Seçimi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _secilenAnaKategori,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Araç', child: Text('Araç 🚗')),
                            DropdownMenuItem(value: 'Konut', child: Text('Konut 🏠')),
                          ],
                          onChanged: _isEditMode ? null : (String? value) {
                            if (value != null) {
                              _onAnaKategoriTemizle(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Araç / Taşıt Türü', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _secilenAltKategori,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Otomobil', child: Text('Otomobil')),
                            DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                            DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
                          ],
                          onChanged: (String? value) {
                            setState(() {
                              _secilenAltKategori = value;
                              if (value != 'SUV' && value != 'Pickup') _secilenCekisTipi = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 🚗 ZORUNLU ARAÇ PLAKASI ALANI VE UYARI NOTU
              TextField(
                controller: _aracPlakaController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Araç Plakası (Zorunlu)',
                  hintText: 'Örn: 34 ABC 123',
                  prefixIcon: const Icon(Icons.directions_car_filled_outlined, color: Color(0xFF1E3A8A)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    'Araç plakanız ilan sayfasında gösterilmeyecektir.',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Text('Kategori Seçimi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _secilenAnaKategori,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Araç', child: Text('Araç 🚗')),
                  DropdownMenuItem(value: 'Konut', child: Text('Konut 🏠')),
                ],
                onChanged: _isEditMode ? null : (String? value) {
                  if (value != null) {
                    _onAnaKategoriTemizle(value);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],

            if (isKonut) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Konut Tipi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _secilenAltKategori,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Daire', child: Text('Daire')),
                            DropdownMenuItem(value: 'Rezidans', child: Text('Rezidans')),
                            DropdownMenuItem(value: 'Müstakil Ev', child: Text('Müstakil Ev')),
                          ],
                          onChanged: (String? value) {
                            setState(() {
                              _secilenAltKategori = value;
                              if (value != 'Müstakil Ev') {
                                _secilenEvKatTipi = null;
                                _secilenKonseptKullanim = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (isMustakilEv) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Konsept / Kullanım Amacı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _secilenKonseptKullanim,
                            hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Yazlık', child: Text('Yazlık')),
                              DropdownMenuItem(value: 'Villa', child: Text('Villa')),
                            ],
                            onChanged: (val) => setState(() => _secilenKonseptKullanim = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],

            const Text('📍 Geçici Takas Edilecek İlanın Bulunduğu Konum', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 15)),
            const Divider(color: Colors.orange),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bulunduğu İl', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField(
                        isExpanded: true,
                        value: _secilenMevcutIl,
                        hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                        decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        items: AppCoreHelper.lokasyonHaritasi.keys.map((il) => DropdownMenuItem(value: il, child: Text(il))).toList(),
                        onChanged: (val) => setState(() { _secilenMevcutIl = val; _secilenMevcutIlce = null; }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bulunduğu İlçe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField(
                        isExpanded: true,
                        value: (_secilenMevcutIl != null && AppCoreHelper.lokasyonHaritasi[_secilenMevcutIl]!.contains(_secilenMevcutIlce)) ? _secilenMevcutIlce : null,
                        hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                        decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        items: _secilenMevcutIl == null ? null : AppCoreHelper.lokasyonHaritasi[_secilenMevcutIl]!.map((ilce) => DropdownMenuItem(value: ilce, child: Text(ilce))).toList(),
                        onChanged: (val) => setState(() => _secilenMevcutIlce = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (isKonut) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kat Mimarisi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _secilenEvKatTipi,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Tek Katlı', child: Text('Tek Katlı')),
                            DropdownMenuItem(value: 'Dubleks', child: Text('Dubleks')),
                            DropdownMenuItem(value: 'Tripleks', child: Text('Tripleks')),
                          ],
                          onChanged: (val) => setState(() => _secilenEvKatTipi = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Site Durumu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _secilenSiteDurumu,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Site İçi', child: Text('Site İçi 🟢')),
                            DropdownMenuItem(value: 'Site Dışı / Bağımsız', child: Text('Site Dışı / Bağımsız 🔴')),
                          ],
                          onChanged: (val) => setState(() => _secilenSiteDurumu = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Salon Sayısı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField(
                          isExpanded: true,
                          value: _secilenSalonSayisi,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: _salonSecenekleri.map((val) => DropdownMenuItem(value: val, child: Text('$val Salon'))).toList(),
                          onChanged: (val) => setState(() => _secilenSalonSayisi = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Oda Sayısı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField(
                          isExpanded: true,
                          value: _secilenOdaSayisi,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: _odaSecenekleri.map((val) => DropdownMenuItem(value: val, child: Text('$val Oda'))).toList(),
                          onChanged: (val) => setState(() => _secilenOdaSayisi = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Banyo Sayısı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField(
                          isExpanded: true,
                          value: _secilenBanyoSayisi,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: _banyoTuvaletSecenekleri.map((val) => DropdownMenuItem(value: val, child: Text('$val Banyo'))).toList(),
                          onChanged: (val) => setState(() => _secilenBanyoSayisi = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tuvalet Sayısı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField(
                          isExpanded: true,
                          value: _secilenTuvaletSayisi,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: _banyoTuvaletSecenekleri.map((val) => DropdownMenuItem(value: val, child: Text('$val Tuvalet'))).toList(),
                          onChanged: (val) => setState(() => _secilenTuvaletSayisi = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Balkon Sayısı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField(
                          isExpanded: true,
                          value: _secilenBalkonSayisi,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: _balkonSecenekleri.map((val) => DropdownMenuItem(
                            value: val,
                            child: Text(val == 'Balkon Yok' || val == '5+' ? val : '$val Balkon'),
                          )).toList(),
                          onChanged: (val) => setState(() => _secilenBalkonSayisi = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kullanım Alanı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField(
                          isExpanded: true,
                          value: _secilenKullanimAlani,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: _kullanimAlaniSecenekleri.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                          onChanged: (val) => setState(() => _secilenKullanimAlani = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isMustakilEv) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Havuz Durumu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _secilenHavuzDurumu,
                            hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                            items: const [
                              DropdownMenuItem(value: 'Havuz Var', child: Text('Havuz Var 🏊‍♂️')),
                              DropdownMenuItem(value: 'Havuz Yok', child: Text('Havuz Yok')),
                            ],
                            onChanged: (val) => setState(() => _secilenHavuzDurumu = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bahçe Durumu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _secilenBahceDurumu,
                            hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                            items: const [
                              DropdownMenuItem(value: 'Bahçe Var', child: Text('Bahçe Var 🌳')),
                              DropdownMenuItem(value: 'Bahçe Yok', child: Text('Bahçe Yok')),
                            ],
                            onChanged: (val) => setState(() => _secilenBahceDurumu = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],

            if (isArac) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Marka', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField(
                          isExpanded: true,
                          value: _secilenMarka,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: AppCoreHelper.markaModelHaritasi.keys.map((marka) => DropdownMenuItem(value: marka, child: Text(marka))).toList(),
                          onChanged: (val) => setState(() { _secilenMarka = val; _secilenModel = null; }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Model', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField(
                          isExpanded: true,
                          value: (_secilenMarka != null && AppCoreHelper.markaModelHaritasi[_secilenMarka]!.contains(_secilenModel)) ? _secilenModel : null,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          disabledHint: const Text('Önce Marka', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: _secilenMarka == null ? null : AppCoreHelper.markaModelHaritasi[_secilenMarka]!.map((model) => DropdownMenuItem(value: model, child: Text(model))).toList(),
                          onChanged: (val) => setState(() => _secilenModel = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Model Yılı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField(
                          isExpanded: true,
                          value: _secilenYil,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: List.generate(17, (index) => (2026 - index).toString()).map((yil) => DropdownMenuItem(value: yil, child: Text(yil))).toList(),
                          onChanged: (val) => setState(() => _secilenYil = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vites Tipi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField(
                          isExpanded: true,
                          value: _secilenVites,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: const [
                            DropdownMenuItem(value: 'Otomatik', child: Text('Otomatik')),
                            DropdownMenuItem(value: 'Yarı Otomatik', child: Text('Yarı Otomatik')),
                            DropdownMenuItem(value: 'Manuel', child: Text('Manuel')),
                          ],
                          onChanged: (val) => setState(() => _secilenVites = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Yakıt Tipi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _secilenYakitTipi,
                          hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: const [
                            DropdownMenuItem(value: 'Benzin', child: Text('Benzin')),
                            DropdownMenuItem(value: 'Dizel', child: Text('Dizel')),
                            DropdownMenuItem(value: 'LPG', child: Text('LPG')),
                            DropdownMenuItem(value: 'Hibrit', child: Text('Hibrit')),
                            DropdownMenuItem(value: 'Elektrikli', child: Text('Elektrikli')),
                          ],
                          onChanged: (val) => setState(() => _secilenYakitTipi = val),
                        ),
                      ],
                    ),
                  ),
                  if (isKapaliKabinArac) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sigara Kullanımı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField(
                            isExpanded: true,
                            value: _secilenSigaraDurumu,
                            hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                            items: const [
                              DropdownMenuItem(
                                value: 'İçilebilir',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                                    SizedBox(width: 8),
                                    Text('İçilebilir', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'İçilemez (Kokuyor)',
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel_rounded, color: Colors.red, size: 18),
                                    SizedBox(width: 8),
                                    Text('İçilemez', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (val) => setState(() => _secilenSigaraDurumu = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // 🗓️ TAKAS BAŞLANGIÇ VE BİTİŞ TARİHLERİ
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Takas Başlangıç', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _tarihSecimiBaslat(isBaslangic: true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(baslangicStr, style: TextStyle(fontSize: 13, color: _baslangicTarihi != null ? Colors.black87 : Colors.grey)),
                              const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF1E3A8A)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Takas Bitiş', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _tarihSecimiBaslat(isBaslangic: false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(bitisStr, style: TextStyle(fontSize: 13, color: _bitisTarihi != null ? Colors.black87 : Colors.grey)),
                              const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF1E3A8A)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 🎛️ ESNEKLİK ALANI
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB3DFD7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Takas Tarih Aralığı Esnektir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    subtitle: const Text('Algoritmanın 1-2 günlük farklar yüzünden harika eşleşmeleri kaçırmayın.', style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.3)),
                    value: _isDateFlexible,
                    activeThumbColor: const Color(0xFF0F766E),
                    activeColor: const Color(0xFF0F766E).withOpacity(0.5),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isDateFlexible = val),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0, bottom: 4.0),
                    child: Divider(color: Color(0xFFB3DFD7), height: 1),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✨ ', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Text(
                          'Sohbet penceresinde karşı tarafla esnek tarihler üzerinde konuşmaya açık olduğunuz belirtilecektir. Eşleşme oranınız maksimuma çıkarılır! 📈',
                          style: TextStyle(fontSize: 11, color: Colors.teal.shade900, fontWeight: FontWeight.w600, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text('🎯 Geçici Takas Edilmek İstenen Hedef Lokasyon', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
            const Divider(color: Colors.green),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hedef İl', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField(
                        isExpanded: true,
                        value: _secilenHedefIl,
                        hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                        decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        items: AppCoreHelper.lokasyonHaritasi.keys.map((il) => DropdownMenuItem(value: il, child: Text(il))).toList(),
                        onChanged: (val) => setState(() { _secilenHedefIl = val; _secilenHedefIlce = null; }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hedef İlçe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField(
                        isExpanded: true,
                        value: (_secilenHedefIl != null && AppCoreHelper.lokasyonHaritasi[_secilenHedefIl]!.contains(_secilenHedefIlce)) ? _secilenHedefIlce : null,
                        hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
                        disabledHint: const Text('Önce İl Seçin', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        items: _secilenHedefIl == null ? null : AppCoreHelper.lokasyonHaritasi[_secilenHedefIl]!.map((ilce) => DropdownMenuItem(value: ilce, child: Text(ilce))).toList(),
                        onChanged: (val) => setState(() => _secilenHedefIlce = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text('İlan Fotoğrafları (Maks. 10 Adet)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _secilenFotograflar.length + 1,
                itemBuilder: (context, index) {
                  if (index == _secilenFotograflar.length) {
                    return InkWell(
                      onTap: _fotografEkle,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                        child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF1E3A8A), size: 28),
                      ),
                    );
                  }
                  final String gorselYolu = _secilenFotograflar[index];
                  final bool isNetworkImage = gorselYolu.startsWith('http');
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: isNetworkImage ? NetworkImage(gorselYolu) as ImageProvider : FileImage(File(gorselYolu)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 10,
                        child: InkWell(
                          onTap: () => setState(() => _secilenFotograflar.removeAt(index)),
                          child: CircleAvatar(radius: 10, backgroundColor: Colors.black.withOpacity(0.6), child: const Icon(Icons.close, size: 12, color: Colors.white)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text('İlan Detaylı Açıklaması', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 6),
            TextField(
              controller: _aciklamaController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'İlanınıza ait detayları buraya yazın...',
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : () async {
                  // 🚗 Araç ilanı ise plaka zorunluluğu kontrolü
                  if (_secilenAnaKategori == 'Araç' && _aracPlakaController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Araç takasını gerçekleştirmek için profili düzenle panelinde araç plakanızı kaydedin veya ilana plaka girin! ⚠️'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    final ilanData = {
                      'baslik': _dinamikBaslikHesapla(),
                      'kategori': _secilenAnaKategori,
                      'altKategori': _secilenAltKategori,
                      'aracPlaka': _aracPlakaController.text.trim(), // 🚗 Plaka verisi ilana işlendi
                      'detay': _aciklamaController.text,
                      'evKatTipi': _secilenEvKatTipi,
                      'konseptKullanim': _secilenKonseptKullanim,
                      'siteDurumu': _secilenSiteDurumu,
                      'salonSayisi': _secilenSalonSayisi,
                      'odaSayisi': _secilenOdaSayisi,
                      'banyoSayisi': _secilenBanyoSayisi,
                      'tuvaletSayisi': _secilenTuvaletSayisi,
                      'balkonSayisi': _secilenBalkonSayisi,
                      'kullanimAlani': _secilenKullanimAlani,
                      'havuzDurumu': _secilenHavuzDurumu,
                      'bahceDurumu': _secilenBahceDurumu,
                      'vites': _secilenVites,
                      'yakitTipi': _secilenYakitTipi,
                      'yil': _secilenYil,
                      'marka': _secilenMarka,
                      'model': _secilenModel,
                      'cekisTipi': _secilenCekisTipi,
                      'sigara': _secilenSigaraDurumu,
                      'fotograflar': _secilenFotograflar,
                      'mevcutIl': _secilenMevcutIl,
                      'mevcutIlce': _secilenMevcutIlce,
                      'hedefIl': _secilenHedefIl,
                      'hedefIlce': _secilenHedefIlce,
                      'baslangicTarihi': baslangicStr,
                      'bitisTarihi': bitisStr,
                      'isDateFlexible': _isDateFlexible,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (_isEditMode) {
                      await FirebaseFirestore.instance.collection('ilanlar').doc(widget.ilanVerisi!['id']).update(ilanData);
                    } else {
                      ilanData['createdAt'] = FieldValue.serverTimestamp();
                      widget.onAdCreated(ilanData);
                    }
                    if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Kayıt başarısız: $e'), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(_isEditMode ? 'Değişiklikleri Kaydet' : 'İlanı Yayınla', style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}