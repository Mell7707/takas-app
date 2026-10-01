import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
// 📌 Tüm Ekran Importları
import 'package:takas_app/screens/login_screen.dart';
import 'package:takas_app/screens/calendar_match_screen.dart';
import 'package:takas_app/screens/ad_detail_screen.dart';
import 'package:takas_app/screens/ad_list_screen.dart';
import 'package:takas_app/screens/chat_screen.dart';
import 'package:takas_app/screens/profile_screen.dart';
import 'package:takas_app/screens/favorites_screen.dart';
import 'package:takas_app/screens/create_ad_screen.dart';
import 'package:takas_app/screens/splash_screen.dart';
import 'package:takas_app/screens/swap_history_screen.dart';
void main() async {
  // 🛠️ Flutter ve Firebase bağlayıcılarını hazırlar
  WidgetsFlutterBinding.ensureInitialized();
  // 🔥 Firebase projenizi (TakasApp) uygulamanın açılışında başlatır
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TakasApp());
}
class TakasApp extends StatefulWidget {
  const TakasApp({super.key});
  @override
  State<TakasApp> createState() => _TakasAppState();
}
class _TakasAppState extends State<TakasApp> {
  // 🌟 GLOBAL İLAN LİSTESİ (Uygulamanın kalbi burası)
  final List<Map<String, dynamic>> globalIlanlar = [];
  // 🌟 Yeni ilanı hem Firestore veri tabanına hem de yerel listeye ekleyen fonksiyon
  void yeniIlanEkle(Map<String, dynamic> yeniIlan) async {
    try {
      // 🔐 O an giriş yapmış olan kullanıcının benzersiz kimliğini (UID) çekiyoruz
      final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      // İlan verisinin içine 'userId' alanını ekliyoruz
      yeniIlan['userId'] = currentUserUid ?? 'anonim';
      yeniIlan['createdAt'] =
          FieldValue.serverTimestamp(); // Akış sıralaması için zaman damgası
      // 🔥 İlanı Firestore'daki 'ilanlar' koleksiyonuna gönderiyoruz
      await FirebaseFirestore.instance.collection('ilanlar').add(yeniIlan);
      // Buluta başarıyla yazıldıktan sonra ekranı ve yerel listeyi güncelliyoruz
      if (!mounted) return;
      setState(() {
        globalIlanlar.insert(
          0,
          yeniIlan,
        ); // Yeni ilanı listenin en başına ekler
      });
      debugPrint(
        "🚀 İlan kullanıcı ID'si ($currentUserUid) ile birlikte başarıyla kaydedildi!",
      );
    } catch (e) {
      debugPrint("❌ Firestore'a veri kaydedilirken hata oluştu: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TakasApp',
      debugShowCheckedModeBanner: false,
      // 🎨 GLOBAL KURUMSAL GREEN-TECH TEMALANDIRMA MÜHRÜ
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1E3A8A), // Kurumsal Derin Lacivert
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: Colors.teal, // Lojistik ve Güvenli Kart Yeşili
          tertiary: Colors.orange, // Takas Kriterleri Turuncusu
        ),
        scaffoldBackgroundColor: Colors.white,
        // Dropdown ve Textfield'lar için global uyumluluk tasarımı
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
          ),
        ),
        // Buton Temalarının Standardizasyonu
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 1,
          ),
        ),
        // Üst Şerit (AppBar) Standardizasyonu
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E3A8A),
          elevation: 0.5,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ),
      // ⚡ KÜRESEL STANDART: Uygulama artık jet hızındaki Açılış Ekranı ile başlar!
      home: const SplashScreen(),
      // 🗺️ MERKEZİ ROTA VE REAKTİF ARGÜMAN ENTEGRASYON MOTORU
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (context) =>
                  LoginScreen(ilanlar: globalIlanlar, onIlanEkle: yeniIlanEkle),
            );
          case '/calendar-match':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (context) => CalendarMatchScreen(
                activeAdId: args['activeAdId'] ?? '',
                category: args['category'] ?? 'Araç',
                baslangicTarihi: args['baslangicTarihi'],
                bitisTarihi: args['bitisTarihi'],
              ),
            );
          case '/ad-detail':
            final ilanVerisi =
                settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (context) => AdDetailScreen(ilanVerisi: ilanVerisi),
            );
          case '/create-ad':
            return MaterialPageRoute(
              builder: (context) => CreateAdScreen(
                varsayilanKategori: settings.arguments as String? ?? 'Araç',
                onAdCreated: yeniIlanEkle,
              ),
            );
          case '/ad-list':
            return MaterialPageRoute(
              builder: (context) => AdListScreen(
                canliIlanlar: globalIlanlar,
                onCategoryPressed: (kat) {},
              ),
            );
          case '/chat':
            final dynamic args = settings.arguments;
            final Map<String, dynamic> chatIlanVerisi =
                (args is Map<String, dynamic>) ? args : {};
            return MaterialPageRoute(
              builder: (context) => ChatScreen(ilanVerisi: chatIlanVerisi),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (context) => ProfileScreen(canliIlanlar: globalIlanlar),
            );
          case '/favorites':
            return MaterialPageRoute(
              builder: (context) =>
                  FavoritesScreen(canliIlanlar: globalIlanlar),
            );
          case '/swap-history':
            return MaterialPageRoute(
              builder: (context) => const SwapHistoryScreen(),
            );
          default:
            return null;
        }
      },
    );
  }
}
