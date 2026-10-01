import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SwapHistoryScreen extends StatelessWidget {
  const SwapHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Takas Geçmişi Arşivi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: currentUid == null
          ? const Center(
              child: Text(
                'Lütfen önce giriş yapın.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  );
                }
                
                final List<Map<String, dynamic>> basariliTakaslar = [
                  {
                    'kontratNo': 'TS-84219',
                    'tarih': '12/09/2026',
                    'ilanBaslik': '2022 Volvo XC90 Takası',
                    'karsiTaraf': 'Ahmet Yılmaz',
                    'durum': 'Tamamlandı',
                    'bedel': '₺1.500,00 Hizmet Komisyonu',
                    'vergiNo': 'TR9876543210',
                    'islemTuru': 'Resmi Tapu / Ruhsat Devri',
                  },
                  {
                    'kontratNo': 'TS-31405',
                    'tarih': '05/09/2026',
                    'ilanBaslik': 'Beneteau Lüks Yat Takası',
                    'karsiTaraf': 'Hüseyin Kaya',
                    'durum': 'Provizyon İptal / İade',
                    'bedel': '₺5.000,00 Teminat İade Edildi',
                    'vergiNo': 'TR1234567890',
                    'islemTuru': 'Güvence Bedeli İadesi',
                  },
                ];
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: basariliTakaslar.length,
                  itemBuilder: (context, index) {
                    final takas = basariliTakaslar[index];
                    final bool isSuccess = takas['durum'] == 'Tamamlandı';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 1,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sözleşme: #${takas['kontratNo']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSuccess
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    takas['durum']!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSuccess
                                          ? Colors.green.shade700
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              takas['ilanBaslik']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Takas Ortağı: ${takas['karsiTaraf']}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  takas['tarih']!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSuccess
                                        ? Icons.gavel_rounded
                                        : Icons.refresh_rounded,
                                    size: 14,
                                    color: isSuccess
                                        ? Colors.teal
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    takas['bedel']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF1E3A8A),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: () {
                                      _showInvoiceDetails(context, takas);
                                    },
                                    icon: const Icon(
                                      Icons.receipt_long_outlined,
                                      size: 16,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                    label: const Text(
                                      'Dekont / Fatura',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1E3A8A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A8A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Sözleşme #${takas['kontratNo']} PDF olarak indirildi. 📄',
                                          ),
                                          backgroundColor: Colors.teal,
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'PDF İndir',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showInvoiceDetails(BuildContext context, Map<String, dynamic> takas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: Colors.teal),
            const SizedBox(width: 8),
            Text(
              'Dekont #${takas['kontratNo']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İşlem: ${takas['ilanBaslik']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Taraflar: TakasApp Güvencesi & ${takas['karsiTaraf']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Vergi No / Sicil: ${takas['vergiNo']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Tür: ${takas['islemTuru']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 20),
            Text(
              'Tutar / Bedel: ${takas['bedel']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resmi fatura e-posta adresinize gönderildi. ✉️'),
                  backgroundColor: Colors.indigo,
                ),
              );
            },
            child: const Text('E-Posta Gönder'),
          ),
        ],
      ),
    );
  }
}