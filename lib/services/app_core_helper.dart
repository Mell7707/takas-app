import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppCoreHelper {
  // Sınıfın dışarıdan nesne olarak türetilmesini engellemek için private constructor
  AppCoreHelper._();

  // 🗺️ MÜHÜRLÜ KURUMSAL LOKASYON MATRİSİ
  static const Map<String, List<String>> lokasyonHaritasi = {
    'İstanbul': [
      'Kadıköy',
      'Beşiktaş',
      'Şişli',
      'Üsküdar',
      'Bakırköy',
      'Sarıyer',
    ],
    'Ankara': ['Çankaya', 'Yenimahalle', 'Ümitköy', 'Gölbaşı', 'Etimesgut'],
    'İzmir': ['Çeşme', 'Alsancak', 'Karşıyaka', 'Urla', 'Bornova', 'Alaçatı'],
    'Bursa': ['Nilüfer', 'Osmangazi', 'Yıldırım', 'Mudanya'],
    'Antalya': ['Muratpaşa', 'Konyaaltı', 'Alanya', 'Kemer', 'Kaş'],
  };

  // 🚗 MÜHÜRLÜ ARAÇ MARKA / MODEL MATRİSİ
  static const Map<String, List<String>> markaModelHaritasi = {
    'Volvo': ['XC90', 'XC60', 'S90', 'S60', 'V60'],
    'Mercedes': ['C200', 'E200', 'CLA 200', 'A180'],
    'BMW': ['320i', '520d', 'i4', 'X5'],
    'Audi': ['A4', 'A6', 'Q3', 'Q7'],
    'Toyota': ['Corolla', 'Yaris', 'RAV4', 'Hilux'],
  };

  /// 🧠 MAĞAZA STANDARTLARINDA GÜVENLİ TARİH ÇÖZÜCÜ (FAIL-SAFE DATE PARSER)
  /// Girdi ne olursa olsun (Timestamp, String, Null, DateTime) uygulamayı asla çökertmez.
  static DateTime? parseStringToDate(dynamic dateInput) {
    if (dateInput == null) return null;
    
    try {
      if (dateInput is Timestamp) return dateInput.toDate();
      if (dateInput is DateTime) return dateInput;

      final String cleanStr = dateInput.toString().trim();
      if (cleanStr.isEmpty || cleanStr.toLowerCase() == 'seçiniz' || cleanStr.toLowerCase() == 'belirtilmedi' || cleanStr.toLowerCase() == 'null') {
        return null;
      }

      // Doğrudan ISO formatı veya standart tarih denemesi (Hızlı Parsing)
      final DateTime? directParse = DateTime.tryParse(cleanStr);
      if (directParse != null) return directParse;

      // Özel tarih formatları için deneme listesi
      final String normalizedStr = cleanStr.replaceAll('.', '/').replaceAll('-', '/');
      final List<String> formats = [
        'd/M/yyyy',
        'dd/MM/yyyy',
        'yyyy-MM-dd',
        'yyyy/MM/dd',
        'yyyy-MM-dd HH:mm:ss.SSS',
      ];

      for (final format in formats) {
        try {
          return DateFormat(format).parseStrict(normalizedStr);
        } catch (_) {
          continue; // Diğer formatı dene, uygulamayı çökertme (Bypass Crash)
        }
      }
    } catch (_) {
      // Beklenmeyen hafıza hatasını yutar, uygulamanın kırmızı ekran vermesini önler.
      return null;
    }

    return null; // Hiçbiri uymazsa güvenli şekilde null dön
  }

  /// 🗓️ TARİH FORMATLAYICI MÜHRÜ (dd/MM/yyyy formatında güvenli çıktı sunar)
  static String tarihFormatla(DateTime? tarih) {
    if (tarih == null) return 'Seçiniz';
    try {
      return DateFormat('dd/MM/yyyy').format(tarih);
    } catch (_) {
      return 'Seçiniz';
    }
  }
}