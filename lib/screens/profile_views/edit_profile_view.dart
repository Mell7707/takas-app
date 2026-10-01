import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _isimController = TextEditingController();
  final _epostaController = TextEditingController();
  final _telefonController = TextEditingController();
  final _adresController = TextEditingController();
  final _tcKimlikController = TextEditingController();
  
  String _secilenVarlikTuru = 'Araç';
  final _aracPlakaController = TextEditingController();
  final _konutAdresController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _kullaniciBilgileriniYukle();
  }

  Future<void> _kullaniciBilgileriniYukle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _isimController.text = user.displayName ?? '';
      _epostaController.text = user.email ?? '';

      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!mounted) return;
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _telefonController.text = (data['telefon'] ?? '').toString();
          _adresController.text = (data['adres'] ?? '').toString();
          _tcKimlikController.text = (data['tcKimlik'] ?? '').toString();
          _secilenVarlikTuru = (data['varlikTuru'] ?? 'Araç').toString();
          _aracPlakaController.text = (data['aracPlaka'] ?? '').toString();
          _konutAdresController.text = (data['takasKonutAdresi'] ?? '').toString();
        }
      } catch (_) {
        // Hata yoksaylır
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _isimController.dispose();
    _epostaController.dispose();
    _telefonController.dispose();
    _adresController.dispose();
    _tcKimlikController.dispose();
    _aracPlakaController.dispose();
    _konutAdresController.dispose();
    super.dispose();
  }

  Future<void> _bilgileriKaydet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_tcKimlikController.text.trim().isNotEmpty && _tcKimlikController.text.trim().length != 11) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('T.C. Kimlik Numarası eksiksiz 11 haneli olmalıdır! ⚠️'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'adSoyad': _isimController.text.trim(),
        'eposta': _epostaController.text.trim(),
        'telefon': _telefonController.text.trim(),
        'adres': _adresController.text.trim(),
        'tcKimlik': _tcKimlikController.text.trim(),
        'varlikTuru': _secilenVarlikTuru,
        'aracPlaka': _aracPlakaController.text.trim(),
        'takasKonutAdresi': _konutAdresController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yasal takas varlık bilgileriniz başarıyla kaydedildi! ⚡'),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt sırasında hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profili Düzenle', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 60.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Color(0xFF1E3A8A),
                          child: Icon(Icons.person, size: 60, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildEditField(label: 'Ad Soyad', controller: _isimController, icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildEditField(label: 'E-posta Adresi', controller: _epostaController, icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildEditField(label: 'Telefon Numarası', controller: _telefonController, icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildEditField(label: 'T.C. Kimlik Numarası (Sözleşme İçin Şart)', controller: _tcKimlikController, icon: Icons.badge_outlined, keyboardType: TextInputType.number, maxLength: 11),
                  const SizedBox(height: 16),
                  _buildEditField(label: 'Açık Adres / İlçe, İl', controller: _adresController, icon: Icons.location_on_outlined, maxLines: 2),
                  
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 12),

                  const Text(
                    'Sözleşme İçin Takas Edilecek Varlık Türü',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Seçtiğiniz kategoriye ait yasal bilgiler sözleşmenize otomatik işlenecektir.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: _secilenVarlikTuru,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Araç', child: Text('Araç 🚗')),
                      DropdownMenuItem(value: 'Konut', child: Text('Konut 🏠')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _secilenVarlikTuru = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_secilenVarlikTuru == 'Araç') ...[
                    _buildEditField(
                      label: 'Araç Plakası (Örn: 34 ABC 123)',
                      controller: _aracPlakaController,
                      icon: Icons.directions_car_rounded,
                    ),
                  ],

                  if (_secilenVarlikTuru == 'Konut') ...[
                    _buildEditField(
                      label: 'Takas Edilecek Konut Adresi / Tapu Detayı',
                      controller: _konutAdresController,
                      icon: Icons.home_rounded,
                      maxLines: 2,
                    ),
                  ],

                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _bilgileriKaydet,
                      child: const Text('Değişiklikleri Kaydet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditField({required String label, required TextEditingController controller, required IconData icon, TextInputType keyboardType = TextInputType.text, int maxLines = 1, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: maxLength == 11 ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A), size: 22),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5)),
          ),
        ),
      ],
    );
  }
}