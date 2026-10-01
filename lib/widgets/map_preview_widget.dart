import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPreviewWidget extends StatelessWidget {
  final Map<String, dynamic> ilanVerisi;

  const MapPreviewWidget({super.key, required this.ilanVerisi});

  // 🎨 KURUMSAL RENK MÜHRÜ
  static const Color _primaryBlue = Color(0xFF1E3A8A);

  // 🧠 FAIL-SAFE KOORDİNAT ÇÖZÜCÜ (Uygulamanın çökmesini %100 engeller)
  double _parseKoordinat(dynamic val, double varsayilan) {
    try {
      if (val == null) return varsayilan;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) {
        final safDeger = val.replaceAll(',', '.').trim();
        return double.tryParse(safDeger) ?? varsayilan;
      }
    } catch (_) {
      return varsayilan;
    }
    return varsayilan;
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ Güvenli koordinat dönüşümü uygulanıyor
    final double enlem = _parseKoordinat(ilanVerisi['enlem'], 41.0082);
    final double boylam = _parseKoordinat(ilanVerisi['boylam'], 28.9784);
    
    final LatLng ilanKonumu = LatLng(enlem, boylam);
    final String isaretciBaslik = ilanVerisi['baslik']?.toString() ?? 'İlan Konumu';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on, color: _primaryBlue, size: 18),
            SizedBox(width: 6),
            Text(
              'Mülk / Araç Konumu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 🔹 VERSİYON HATALARINI AŞAN AKILLI DÜZEN
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: ilanKonumu,
                  zoom: 13,
                ),
                markers: <Marker>{
                  Marker(
                    markerId: const MarkerId('ilan_konum_marker'),
                    position: ilanKonumu,
                    infoWindow: InfoWindow(
                      title: isaretciBaslik,
                    ),
                  ),
                },
                // 🛑 SCROLL ÇAKIŞMASINI ÖNLEYEN KORUMALAR (UX İyileştirmesi)
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                
                // Standart UI Kapatmaları
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}