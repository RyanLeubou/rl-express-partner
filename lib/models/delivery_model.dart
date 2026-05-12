import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryStop {
  final String address;
  final String contact;
  final String status;

  DeliveryStop({
    required this.address,
    required this.contact,
    this.status = 'PENDING',
  });

  Map<String, dynamic> toMap() => {
        'address': address,
        'contact': contact,
        'status': status,
      };

  factory DeliveryStop.fromMap(Map<String, dynamic> data) => DeliveryStop(
        address: data['address'] ?? '',
        contact: data['contact'] ?? '',
        status: data['status'] ?? 'PENDING',
      );
}

class DeliveryModel {
  final String deliveryId;
  final String partnerId;
  final String driverId;
  final String depotId;
  final String status;
  final String deliveryType;
  final String pickupAddress;
  final String pickupContact;
  final List<DeliveryStop> stops;
  final int creditsCharged;
  final String notes;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  DeliveryModel({
    required this.deliveryId,
    required this.partnerId,
    this.driverId = '',
    this.depotId = '',
    this.status = 'PENDING',
    required this.deliveryType,
    required this.pickupAddress,
    required this.pickupContact,
    required this.stops,
    required this.creditsCharged,
    this.notes = '',
    required this.createdAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toMap() => {
        'delivery_id': deliveryId,
        'partner_id': partnerId,
        'driver_id': driverId,
        'depot_id': depotId,
        'status': status,
        'delivery_type': deliveryType,
        'pickup_address': pickupAddress,
        'pickup_contact': pickupContact,
        'stops': stops.map((s) => s.toMap()).toList(),
        'credits_charged': creditsCharged,
        'notes': notes,
        'created_at': Timestamp.fromDate(createdAt),
        'delivered_at':
            deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      };

  factory DeliveryModel.fromFirestore(Map<String, dynamic> data) {
    final stopsList = (data['stops'] as List<dynamic>? ?? [])
        .map((s) => DeliveryStop.fromMap(s as Map<String, dynamic>))
        .toList();

    return DeliveryModel(
      deliveryId: data['delivery_id'] ?? '',
      partnerId: data['partner_id'] ?? '',
      driverId: data['driver_id'] ?? '',
      depotId: data['depot_id'] ?? '',
      status: data['status'] ?? 'PENDING',
      deliveryType: data['delivery_type'] ?? 'PARCEL',
      pickupAddress: data['pickup_address'] ?? '',
      pickupContact: data['pickup_contact'] ?? '',
      stops: stopsList,
      creditsCharged: (data['credits_charged'] ?? 0).toInt(),
      notes: data['notes'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      deliveredAt: data['delivered_at'] != null
          ? (data['delivered_at'] as Timestamp).toDate()
          : null,
    );
  }
}