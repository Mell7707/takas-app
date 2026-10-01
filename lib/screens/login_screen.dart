import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:takas_app/screens/main_navigation_screen.dart';
import 'package:takas_app/services/test_helper.dart';

class LoginScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ilanlar;
  final Function(Map<String, dynamic>) onIlanEkle;
  const LoginScreen({
    super.key,
    required this.ilanlar,
    required this.onIlanEkle,
  });
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adSoyadController = TextEditingController();
  final _epostaController = TextEditingController();
  final _sifreController = TextEditingController();
  
  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _isSimulating = false;

  @override
  void dispose() {
    _adSoyadController.dispose();
    _epostaController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  void _hataMesajiGoster(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: Colors.red.shade700),
    );
  }

  // 🔥 1. GOOGLE İLE OTOMATİK GİRİŞ / ÜYELİK MOTORU
  Future<void> _googleGirisYap() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // Kullanıcı iptal ettiyse güvenli çıkış
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid);
        final docSnapshot = await userRef.get();
        if (!docSnapshot.exists) {
          await userRef.set({
            'displayName': userCredential.user!.displayName ?? 'Google Kullanıcısı',
            'email': userCredential.user!.email ?? '',
            'rating': 5.0,
            'totalReviews': 0,
            'badges': ['takas', 'guven'],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google hesabınızla hızlıca giriş yapıldı! 🚀'),
          backgroundColor: Color(0xFF1E3A8A),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(
            ilanlar: widget.ilanlar,
            onIlanEkle: widget.onIlanEkle,
          ),
        ),
      );
    } catch (e) {
      _hataMesajiGoster('Google ile giriş hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🍏 2. APPLE İLE OTOMATİK GİRİŞ / ÜYELİK MOTORU
  Future<void> _appleGirisYap() async {
    setState(() => _isLoading = true);
    try {
      final appleResult = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final OAuthProvider provider = OAuthProvider('apple.com');
      final AuthCredential credential = provider.credential(
        idToken: appleResult.identityToken,
        accessToken: appleResult.authorizationCode,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid);
        final docSnapshot = await userRef.get();
        if (!docSnapshot.exists) {
          String adSoyad = '${appleResult.givenName ?? ''} ${appleResult.familyName ?? ''}'.trim();
          if (adSoyad.isEmpty) adSoyad = 'Apple Kullanıcısı';

          await userRef.set({
            'displayName': adSoyad,
            'email': userCredential.user!.email ?? appleResult.email ?? 'gizli@appleid.com',
            'rating': 5.0,
            'totalReviews': 0,
            'badges': ['takas', 'guven'],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple ID ile güvenli giriş yapıldı! 🍏'),
          backgroundColor: Color(0xFF1E3A8A),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(
            ilanlar: widget.ilanlar,
            onIlanEkle: widget.onIlanEkle,
          ),
        ),
      );
    } catch (e) {
      _hataMesajiGoster('Apple ile giriş iptal edildi veya hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _formuGonder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        if (_isLoginMode) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _epostaController.text.trim(),
            password: _sifreController.text,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Giriş başarılı! Yönlendiriliyorsunuz... ✨'),
              backgroundColor: Color(0xFF1E3A8A),
            ),
          );
        } else {
          UserCredential creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _epostaController.text.trim(),
            password: _sifreController.text,
          );
          
          if (creds.user != null) {
            await creds.user!.updateDisplayName(_adSoyadController.text.trim());
            await FirebaseFirestore.instance.collection('users').doc(creds.user!.uid).set({
              'displayName': _adSoyadController.text.trim(),
              'email': _epostaController.text.trim(),
              'rating': 5.0,
              'totalReviews': 0,
              'badges': ['takas'],
              'createdAt': FieldValue.serverTimestamp(),
            });
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hesabınız başarıyla oluşturuldu, hoş geldiniz ${_adSoyadController.text.trim()}! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(
              ilanlar: widget.ilanlar,
              onIlanEkle: widget.onIlanEkle,
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String mesaj = 'Bir hata oluştu, lütfen tekrar deneyin.';
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          mesaj = 'E-posta adresi veya şifre hatalı!';
        } else if (e.code == 'email-already-in-use') {
          mesaj = 'Bu e-posta adresi zaten kullanımda!';
        } else if (e.code == 'invalid-email') {
          mesaj = 'Geçersiz bir e-posta adresi yazınız!';
        } else if (e.code == 'weak-password') {
          mesaj = 'Şifreniz çok zayıf!';
        }
        _hataMesajiGoster(mesaj);
      } catch (e) {
        _hataMesajiGoster('Bağlantı hatası: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double klavyeYuksekligi = MediaQuery.of(context).viewInsets.bottom;
    final bool isKlavyeAcik = klavyeYuksekligi > 0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          _isSimulating
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  tooltip: '50 Adet Simülasyon Verisi Fırlat! 🧪',
                  onPressed: () async {
                    setState(() => _isSimulating = true);
                    await TestHelper.simulasyonVerileriniYukle(
                      onIlanEkleYerel: widget.onIlanEkle,
                    );
                    if (mounted) {
                      setState(() => _isSimulating = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚡ 50 Adet Akıllı Test İlanı Başarıyla Yüklendi ve Loglandı!'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  },
                ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🧠 Çerçevesiz, Doğrudan Kusursuz Logomuz
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: isKlavyeAcik ? 60 : 95,
                  width: isKlavyeAcik ? 60 : 95,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/swap_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.swap_horiz, size: 50, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ),
                SizedBox(height: isKlavyeAcik ? 8 : 16),
                Text(
                  _isLoginMode
                      ? 'Güvenli Ticari Takas Platformu'
                      : 'Yeni Hesap Oluşturun',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: isKlavyeAcik ? 12 : 24),

                // 🌟 TEK TIKLA HIZLI GİRİŞ BÖLÜMÜ (GOOGLE & APPLE)
                if (_isLoginMode) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _googleGirisYap,
                      icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                      label: const Text(
                        'Google ile Devam Et',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _appleGirisYap,
                      icon: const Icon(Icons.apple, size: 22, color: Colors.white),
                      label: const Text(
                        'Apple ile Devam Et',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('veya e-posta ile', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                if (!_isLoginMode) ...[
                  TextFormField(
                    controller: _adSoyadController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1E3A8A)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (!_isLoginMode && (value == null || value.trim().isEmpty)) {
                        return 'Lütfen adınızı ve soyadınızı giriniz!';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _epostaController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'E-posta Adresi',
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1E3A8A)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen e-posta adresinizi giriniz!';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir e-posta adresi yazınız!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sifreController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_isLoading) _formuGonder();
                  },
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1E3A8A)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifrenizi giriniz!';
                    }
                    if (value.length < 6) {
                      return 'Şifreniz en az 6 karakter olmalıdır!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _formuGonder,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLoginMode = !_isLoginMode;
                            _adSoyadController.clear();
                            _epostaController.clear();
                            _sifreController.clear();
                            _formKey.currentState?.reset();
                          });
                        },
                  child: Text(
                    _isLoginMode
                        ? 'Hesabınız yok mu? Kayıt Ol'
                        : 'Zaten üye misiniz? Giriş Yap',
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}