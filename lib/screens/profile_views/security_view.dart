// lib/screens/profile_views/security_view.dart
import 'package:flutter/material.dart';

class SecurityView extends StatefulWidget {
  const SecurityView({super.key});

  @override
  State<SecurityView> createState() => _SecurityViewState();
}

class _SecurityViewState extends State<SecurityView> {
  bool _biyometrikKilit = true;
  bool _ikiAdimliDogrulama = false;

  void _yasalKosullariGoster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                      'Kullanım Koşulları ve Telif Hakları',
                      style: TextStyle(
                        fontSize: 16,
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
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  '1. Telif Hakları ve Fikri Mülkiyet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                const Text(
                  'TakasApp uygulamasının tüm kaynak kodları, arayüz tasarımları, logoları, veritabanı yapıları ve yazılım mimarisi 5846 sayılı Fikir ve Sanat Eserleri Kanunu ile koruma altındadır. Şirketimizden yazılı izin alınmaksızın kopyalanamaz, çoğaltılamaz veya tersine mühendisliğe uğratılamaz.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 14),
                const Text(
                  '2. Kullanıcı Sorumlulukları ve İlanlar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Platformumuz üzerinde kullanıcılar tarafından paylaşılan tüm ilan görselleri, açıklamalar ve materyallerin telif sorumluluğu tamamen içeriği yükleyen kullanıcıya aittir. Kullanıcılar, yükledikleri içeriklerin telif haklarına sahip olduklarını veya paylaşım yetkileri bulunduğunu kabul ederler.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 14),
                const Text(
                  '3. Hizmet Şartları',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                const Text(
                  'TakasApp, bireylerin kendi varlıklarını (araç, konut, yazlık, tekne vb.) yasal çerçeveler içerisinde doğrudan takas etmeleri amacıyla tasarlanmış bir eşleşme platformudur. Ticari amaçlı kötüye kullanım durumunda hesaplar kalıcı olarak askıya alınabilir.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    '© 2026 TakasApp. Tüm hakları saklıdır.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Güvenlik ve Hesap Ayarları',
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
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hesap Güvenliği',
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
                      Icons.lock_outline,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'Şifre Değiştir',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Şifre sıfırlama bağlantısı e-postanıza gönderildi.'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.fingerprint,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'Biyometrik Giriş (Face ID / Parmak İzi)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: _biyometrikKilit,
                    activeThumbColor: const Color(0xFF1E3A8A),
                    onChanged: (value) => setState(() => _biyometrikKilit = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.security,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'İki Adımlı Doğrulama (2FA)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: _ikiAdimliDogrulama,
                    activeThumbColor: const Color(0xFF1E3A8A),
                    onChanged: (value) => setState(() => _ikiAdimliDogrulama = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aktif Oturumlar ve Cihazlar',
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
                      Icons.devices_outlined,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'Samsung Galaxy S23 (Bu Cihaz)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'İstanbul, Türkiye • Aktif Oturum',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                    trailing: const Icon(
                      Icons.circle,
                      size: 12,
                      color: Colors.green,
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Diğer tüm cihazlardaki oturumlarınız sonlandırıldı. 🔒'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.logout_outlined,
                          color: Colors.orange,
                          size: 18,
                        ),
                        label: const Text(
                          'Tüm Diğer Cihazlardan Çıkış Yap',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Güvenlik ve Giriş Geçmişi',
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
                    leading: const Icon(Icons.history, color: Colors.indigo),
                    title: const Text(
                      'Son Giriş: Bugün, 10:50',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'IP: 192.168.1.35 • Samsung S23',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.grey),
                    title: const Text(
                      'Önceki Giriş: Dün, 14:20',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'IP: 192.168.1.10 • Web Portal',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gizlilik ve Veri Hakları',
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
                      Icons.download_outlined,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'Verilerimi İndir (KVKK Arşivi)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Tüm ilan ve işlem geçmişinizin bir kopyasını alın.',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veri arşiviniz hazırlanıyor, e-postanıza gönderilecektir. 📄'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.gavel_outlined,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'Kullanım Koşulları ve Telif Hakları',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Yasal bildirimler, lisanslar ve kullanım şartları.',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _yasalKosullariGoster(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hesap Yönetimi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Hesabımı Kalıcı Olarak Sil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600, // 🛠️ HATA BURADA GİDERİLDİ (FontWeight.w600)
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: const Text(
                  'Tüm ilanlarınız ve verileriniz kalıcı olarak yok edilir.',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hesabınızı Silmek İstediğinize Emin Misiniz?'),
                      content: const Text('Bu işlem geri alınamaz. KVKK gereği tüm verileriniz sunucularımızdan tamamen silinecektir.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Vazgeç'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Hesabınız başarıyla silindi.')),
                            );
                          },
                          child: const Text(
                            'Evet, Sil',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
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