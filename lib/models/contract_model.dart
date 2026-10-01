import 'package:cloud_firestore/cloud_firestore.dart';

class ContractModel {
  final String contractId;
  final String adIdFromAntalya;
  final String adIdFromIstanbul;
  final String partyAName;
  final String partyAVehicleDetails;
  final String partyBName;
  final String partyBVehicleDetails;
  final String contractText;
  final DateTime createdAt;

  // 💰 TİCARİ FİNTEK ADAPTASYONU (MAĞAZA STANDARTLARINDA NAKİT DENGELEME SEVİYESİ)
  final double cashDifference; // Takasın üzerine eklenecek nakit farkı bedeli (Örn: 300.000 TL)
  final String cashReceiverName; // Nakit farkını tahsil edecek hak sahibi tarafın ismi

  const ContractModel({
    required this.contractId,
    required this.adIdFromAntalya,
    required this.adIdFromIstanbul,
    required this.partyAName,
    required this.partyAVehicleDetails,
    required this.partyBName,
    required this.partyBVehicleDetails,
    required this.contractText,
    required this.createdAt,
    this.cashDifference = 0.0, // Varsayılan olarak 0.0 (Kafa kafaya takas durumu)
    this.cashReceiverName = '', // Varsayılan olarak boş string
  });

  /// 🧠 GÜVENLİ TİP DÖNÜŞTÜRÜCÜ (FAIL-SAFE)
  /// Firestore'dan gelen verinin int, double, String veya null olması durumunda uygulamanın çökmesini %100 engeller.
  static double _parseDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  /// 📦 FIRESTORE FABRİKA MOTORU (Fail-Safe: Map verisini %100 güvenli nesneye dönüştürür)
  factory ContractModel.fromMap(Map<String, dynamic>? data) {
    // Veri tamamen null geldiyse, çökmek yerine boş ve güvenli bir model döndür
    if (data == null) {
      return ContractModel(
        contractId: '',
        adIdFromAntalya: '',
        adIdFromIstanbul: '',
        partyAName: '',
        partyAVehicleDetails: '',
        partyBName: '',
        partyBVehicleDetails: '',
        contractText: '',
        createdAt: DateTime.now(),
      );
    }

    // 🛡️ TARİH GÜVENLİĞİ: Timestamp, String, DateTime veya null gelme ihtimallerini engeller
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        parsedDate = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is DateTime) {
        parsedDate = data['createdAt'];
      } else if (data['createdAt'] is String) {
        parsedDate = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    }

    return ContractModel(
      contractId: data['contractId']?.toString() ?? '',
      adIdFromAntalya: data['adIdFromAntalya']?.toString() ?? '',
      adIdFromIstanbul: data['adIdFromIstanbul']?.toString() ?? '',
      partyAName: data['partyAName']?.toString() ?? '',
      partyAVehicleDetails: data['partyAVehicleDetails']?.toString() ?? '',
      partyBName: data['partyBName']?.toString() ?? '',
      partyBVehicleDetails: data['partyBVehicleDetails']?.toString() ?? '',
      contractText: data['contractText']?.toString() ?? '',
      createdAt: parsedDate,
      cashDifference: _parseDoubleSafe(data['cashDifference']),
      cashReceiverName: data['cashReceiverName']?.toString() ?? '',
    );
  }

  /// 🌐 BULUT SERİALES TİTREŞİMİ (Nesneyi Firestore dökümanına dönüştürür)
  Map<String, dynamic> toMap() {
    return {
      'contractId': contractId,
      'adIdFromAntalya': adIdFromAntalya,
      'adIdFromIstanbul': adIdFromIstanbul,
      'partyAName': partyAName,
      'partyAVehicleDetails': partyAVehicleDetails,
      'partyBName': partyBName,
      'partyBVehicleDetails': partyBVehicleDetails,
      'contractText': contractText,
      'createdAt': createdAt, // Firestore DateTime tiplerini otomatik olarak Timestamp'e çevirir
      'cashDifference': cashDifference,
      'cashReceiverName': cashReceiverName,
    };
  }
}