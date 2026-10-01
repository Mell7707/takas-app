import 'dart:async';
import 'package:flutter/material.dart';

class NotificationService {
  // Sınıfın dışarıdan nesne olarak türetilmesini engellemek için private constructor
  NotificationService._();

  // 🧠 BELLEK KORUMA KALKANI: Üst üste binen eski bildirim kalıntılarını temizleyen statik havuz
  static OverlayEntry? _aktifBildirimEntry;
  static Timer? _bildirimZamanlayici;

  /// 🌟 Kurumsal Bildirim Tetikleyicisi
  static void canliBildirimGoster({
    required BuildContext context,
    required String baslik,
    required String mesaj,
    IconData ikon = Icons.notifications_active,
    Color ikonRengi = const Color(0xFF1E3A8A),
  }) {
    // 🔐 GÜVENLİK ADIMI 1: Context hayatta değilse işlemi iptal et (Dead-Context Koruması)
    if (!context.mounted) return;

    // 🔐 GÜVENLİK ADIMI 2: Overlay referansının güvenli kontrolü (Bypass Crash)
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return; 

    // 🔐 GÜVENLİK ADIMI 3: Eğer ekranda halihazırda açık bir bildirim varsa çakışmayı önlemek için önce onu yok et
    gizle();

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: SafeArea( // 🛡️ Çentik çakışmasını engeller
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ikonRengi.withValues(alpha: 0.1),
                    child: Icon(ikon, color: ikonRengi),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          baslik,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mesaj,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _aktifBildirimEntry = overlayEntry;
    
    // 🛡️ KORUMA: Ağaca ekleme yaparken oluşan asenkron problemleri yakalar
    try {
      overlay.insert(overlayEntry);
    } catch (_) {
      return; 
    }

    // ⏳ 3 saniye sonra bildirimi güvenli bir şekilde ekrandan kaldıran kurumsal zamanlayıcı
    _bildirimZamanlayici = Timer(const Duration(seconds: 3), () {
      gizle();
    });
  }

  /// 🧹 GÜVENLİ TEMİZLEYİCİ: Bildirimi manuel veya zamanlayıcı ile yok etmek için
  static void gizle() {
    if (_aktifBildirimEntry != null) {
      if (_aktifBildirimEntry!.mounted) {
        try {
          _aktifBildirimEntry!.remove();
        } catch (_) {
          // Zaten silinmiş/kopmuş bir widget'ı silmeye çalışırken oluşan hatayı yutar
        }
      }
      _aktifBildirimEntry = null;
    }
    _bildirimZamanlayici?.cancel();
    _bildirimZamanlayici = null;
  }
}