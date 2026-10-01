// lib/screens/profile_views/preferences_view.dart
import 'package:flutter/material.dart';

class PreferencesView extends StatefulWidget {
  const PreferencesView({super.key});

  @override
  State<PreferencesView> createState() => _PreferencesViewState();
}

class _PreferencesViewState extends State<PreferencesView> {
  bool _anlikBildirim = true;
  bool _epostaAydinlatma = true;
  bool _geceModu = false;
  bool _titresimSesi = true;

  String _secilenDil = 'Türkçe (TR)';
  String _secilenParaBirimi = 'TRY (₺)';

  final List<String> _diller = ['Türkçe (TR)', 'English (EN)', 'Deutsch (DE)'];
  // Dolar işaretinin önüne \ eklenerek Dart derleyicisi hatası giderildi
  final List<String> _paraBirimleri = ['TRY (₺)', 'USD (\$)', 'EUR (€)'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Uygulama Tercihleri',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bölgesel ve Küresel Ayarlar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.language_outlined,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'Uygulama Dili',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: DropdownButton<String>(
                      value: _secilenDil,
                      underline: const SizedBox(),
                      items: _diller.map((String dil) {
                        return DropdownMenuItem<String>(
                          value: dil,
                          child: Text(
                            dil,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? yeniDeger) {
                        if (yeniDeger != null) {
                          setState(() => _secilenDil = yeniDeger);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Dil $_secilenDil olarak güncellendi. 🌍',
                              ),
                              backgroundColor: Colors.indigo,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.attach_money_rounded,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'Varsayılan Para Birimi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: DropdownButton<String>(
                      value: _secilenParaBirimi,
                      underline: const SizedBox(),
                      items: _paraBirimleri.map((String para) {
                        return DropdownMenuItem<String>(
                          value: para,
                          child: Text(
                            para,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? yeniDeger) {
                        if (yeniDeger != null) {
                          setState(() => _secilenParaBirimi = yeniDeger);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Para birimi $_secilenParaBirimi olarak ayarlandı. 💵',
                              ),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Bildirim Ayarları',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'Anlık Takas Bildirimleri',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'Yeni bir teklif geldiğinde anında uyar.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _anlikBildirim,
                    activeThumbColor: const Color(0xFF1E3A8A),
                    onChanged: (value) =>
                        setState(() => _anlikBildirim = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.vibration,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'Sesli / Titreşimli Uyarı',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'Bildirimler geldiğinde cihaz titreşsin.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _titresimSesi,
                    activeThumbColor: const Color(0xFF1E3A8A),
                    onChanged: (value) =>
                        setState(() => _titresimSesi = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.mail_outline,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'E-posta Bilgilendirmeleri',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: _epostaAydinlatma,
                    activeThumbColor: const Color(0xFF1E3A8A),
                    onChanged: (value) =>
                        setState(() => _epostaAydinlatma = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Görünüm Ayarları',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                secondary: const Icon(
                  Icons.dark_mode_outlined,
                  color: Color(0xFF1E3A8A),
                ),
                title: const Text(
                  'Koyu Tema (Dark Mode)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                value: _geceModu,
                activeThumbColor: const Color(0xFF1E3A8A),
                onChanged: (value) {
                  setState(() => _geceModu = value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _geceModu
                            ? 'Koyu tema simüle ediliyor...'
                            : 'Aydınlık temaya geçildi.',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}