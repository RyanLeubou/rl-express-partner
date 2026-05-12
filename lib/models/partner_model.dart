class PartnerModel {
  final String partnerId;
  final String businessName;
  final int creditBalance;
  final int creditPerDelivery;
  final String partnershipType;
  final int totalDeliveries;
  final bool isActive;

  PartnerModel({
    required this.partnerId,
    required this.businessName,
    required this.creditBalance,
    required this.creditPerDelivery,
    required this.partnershipType,
    required this.totalDeliveries,
    required this.isActive,
  });

  factory PartnerModel.fromFirestore(Map<String, dynamic> data) {
    return PartnerModel(
      partnerId: data['partner_id'] ?? '',
      businessName: data['business_name'] ?? '',
      creditBalance: (data['credit_balance'] ?? 0).toInt(),
      creditPerDelivery: (data['credit_per_delivery'] ?? 10).toInt(),
      partnershipType: data['partnership_type'] ?? 'STANDARD',
      totalDeliveries: (data['total_deliveries'] ?? 0).toInt(),
      isActive: data['is_active'] ?? true,
    );
  }
}
