import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String ilkTarihTercihi;
  final String ilkAltKategori;

  const FilterBottomSheet({
    super.key,
    this.ilkTarihTercihi = 'Tümü',
    this.ilkAltKategori = 'Tümü',
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // 🎨 KURUMSAL RENK MÜHRÜ (Tek Noktadan Yönetim)
  static const Color _primaryBlue = Color(0xFF1E3A8A);

  late String _secilenTarihTercihi;
  late String _secilenAltKategori;
  
  String _secilenZaman = 'Tümü';
  String _secilenSaticiPuani = 'Tümü';

  @override
  void initState() {
    super.initState();
    _secilenTarihTercihi = widget.ilkTarihTercihi;
    _secilenAltKategori = widget.ilkAltKategori;
  }

  // 🧠 AKILLI SEÇİM GRUBU OLUŞTURUCU (Fail-Safe eklendi)
  Widget _buildWrapChipGroup(List<String>? secenekler, String grupAdi) {
    if (secenekler == null || secenekler.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: secenekler.map((altKat) {
        // Çakışmayı önleyen akıllı "Tümü" kontrolü
        final bool isTumu = altKat == 'Tümü';
        final bool isSelected = _secilenAltKategori == altKat || 
                               (isTumu && _secilenAltKategori == 'Tümü');

        return ChoiceChip(
          showCheckmark: false,
          label: Text(
            altKat,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          selectedColor: _primaryBlue,
          backgroundColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
          onSelected: (selected) {
            setState(() {
              _secilenAltKategori = altKat;
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88, // %88 ekran sınırı korundu
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // 🛡️ GÜVENLİK ADIMI: SafeArea ile cihazların alt çentik sorunları engellendi
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune, color: _primaryBlue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Detaylı İlan Filtreleme',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 4),

                    // 🚗 Araç Alt Kategorileri
                    const Text('🚗 Araç', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _primaryBlue)),
                    const SizedBox(height: 6),
                    _buildWrapChipGroup(const ['Tümü', 'Otomobil', 'SUV', 'Pickup'], 'Araç'),
                    const SizedBox(height: 12),

                    // 🏠 Konut Alt Kategorileri
                    const Text('🏠 Konut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _primaryBlue)),
                    const SizedBox(height: 6),
                    _buildWrapChipGroup(const ['Tümü', 'Daire', 'Rezidans', 'Müstakil Ev'], 'Konut'),
                    const SizedBox(height: 16),

                    const Text('Tarih Eşleşme Tercihi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 8),
                    _buildStandardChips(const ['Tümü', 'Tam Eşleşme', 'Takas Tarihi Esnek'], _secilenTarihTercihi, (val) {
                      setState(() => _secilenTarihTercihi = val);
                    }),
                    const SizedBox(height: 16),

                    const Text('İlan Yayınlanma Zamanı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 8),
                    _buildStandardChips(const ['Tümü', 'Son 24 Saat', 'Son 1 Hafta'], _secilenZaman, (val) {
                      setState(() => _secilenZaman = val);
                    }),
                    const SizedBox(height: 16),

                    const Text('Satıcı Profili Güven Puanı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 8),
                    _buildStandardChips(const ['Tümü', '4★ ve Üzeri', 'Sadece Rozetliler'], _secilenSaticiPuani, (val) {
                      setState(() => _secilenSaticiPuani = val);
                    }),
                  ],
                ),
              ),
            ),
            
            // Alt Buton Alanı
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final Map<String, String> filtreSonuclari = {
                      'tarihTercihi': _secilenTarihTercihi,
                      'zaman': _secilenZaman,
                      'saticiPuani': _secilenSaticiPuani,
                      'altKategori': _secilenAltKategori,
                    };
                    if (mounted) Navigator.pop(context, filtreSonuclari);
                  },
                  child: const Text('Sonuçları Göster / Uygula', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧩 Kod tekrarını önlemek için standart çip üretici (Fail-Safe eklendi)
  Widget _buildStandardChips(List<String>? items, String currentValue, Function(String) onSelect) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      children: items.map((tercih) {
        final isSelected = currentValue == tercih;
        return ChoiceChip(
          showCheckmark: false,
          label: Text(tercih, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
          selected: isSelected,
          selectedColor: _primaryBlue,
          backgroundColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
          onSelected: (selected) {
            if (selected) onSelect(tercih);
          },
        );
      }).toList(),
    );
  }
}