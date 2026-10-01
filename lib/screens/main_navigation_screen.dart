import 'package:flutter/material.dart';
import 'package:takas_app/screens/create_ad_screen.dart';
import 'package:takas_app/screens/ad_list_screen.dart';
import 'package:takas_app/screens/profile_screen.dart';
import 'package:takas_app/screens/favorites_screen.dart';
import 'package:takas_app/screens/incoming_offers_screen.dart'; // 👈 Teklifler ekranı eklendi

class MainNavigationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ilanlar;
  final Function(Map<String, dynamic>) onIlanEkle;
  
  const MainNavigationScreen({
    super.key,
    required this.ilanlar,
    required this.onIlanEkle,
  });
  
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String _secilenKategori = 'Araç';
  
  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return AdListScreen(
          canliIlanlar: widget.ilanlar,
          onCategoryPressed: (kategoriIsmi) {
            // 🛡️ DEAD-CONTEXT KORUMASI
            if (!mounted) return;
            setState(() {
              _secilenKategori = kategoriIsmi;
              _currentIndex = 1;
            });
          },
        );
      case 1:
        return CreateAdScreen(
          varsayilanKategori: _secilenKategori,
          onAdCreated: (yeniIlanVerisi) {
            widget.onIlanEkle(yeniIlanVerisi);
            // 🛡️ DEAD-CONTEXT KORUMASI
            if (!mounted) return;
            setState(() {
              _currentIndex = 0;
            });
          },
        );
      case 2:
        return const IncomingOffersScreen(); // 👈 3. Sekme (Tam Orta): Teklifler Ekranı
      case 3:
        return FavoritesScreen(canliIlanlar: widget.ilanlar);
      case 4:
        return ProfileScreen(canliIlanlar: widget.ilanlar);
      default:
        return ProfileScreen(canliIlanlar: widget.ilanlar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (!mounted) return;
          setState(() => _currentIndex = index);
        },
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Keşfet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box), 
            label: 'İlan Ver'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake), // 👈 Uygulamanın kalbi tam merkeze yerleşti
            label: 'Teklifler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: 'Profil'
          ),
        ],
      ),
    );
  }
}