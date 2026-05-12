import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/partner_model.dart';
import '../models/delivery_model.dart';
import '../services/notification_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final partnerProvider = StreamProvider.family<PartnerModel?, String>(
  (ref, uid) => ref.read(firestoreServiceProvider).watchPartner(uid),
);

final deliveriesProvider =
    StreamProvider.family<List<DeliveryModel>, String>(
  (ref, partnerId) =>
      ref.read(firestoreServiceProvider).watchDeliveries(partnerId),
);

final rechargesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
  (ref, partnerId) =>
      ref.read(firestoreServiceProvider).watchRecharges(partnerId),
);

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<PartnerModel?> watchPartner(String uid) {
    return _db
        .collection('partners')
        .doc(uid)
        .snapshots()
        .map((snap) =>
            snap.exists ? PartnerModel.fromFirestore(snap.data()!) : null);
  }

  Stream<List<DeliveryModel>> watchDeliveries(String partnerId) {
    return _db
        .collection('deliveries')
        .where('partner_id', isEqualTo: partnerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => DeliveryModel.fromFirestore(doc.data()))
            .toList());
  }

  Stream<List<Map<String, dynamic>>> watchRecharges(String partnerId) {
    return _db
        .collection('recharge_requests')
        .where('partner_id', isEqualTo: partnerId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  Future<void> createDelivery(DeliveryModel delivery) async {
    final batch = _db.batch();

    final deliveryRef =
        _db.collection('deliveries').doc(delivery.deliveryId);
    batch.set(deliveryRef, delivery.toMap());

    final partnerRef =
        _db.collection('partners').doc(delivery.partnerId);
    batch.update(partnerRef, {
      'credit_balance': FieldValue.increment(-delivery.creditsCharged),
    });

    final ledgerRef = _db.collection('ledger').doc();
    batch.set(ledgerRef, {
      'entry_id': ledgerRef.id,
      'partner_id': delivery.partnerId,
      'type': 'DEBIT',
      'amount': -delivery.creditsCharged,
      'delivery_id': delivery.deliveryId,
      'created_at': Timestamp.now(),
    });

    await batch.commit();

    await NotificationService().showLocalNotification(
      title: '✅ Commande confirmée',
      body: 'Votre commande a été envoyée. Un chauffeur va être assigné.',
      payload: delivery.deliveryId,
    );
  }

  Future<void> createRechargeRequest({
    required String partnerId,
    required int amount,
    required String method,
    required int credits,
  }) async {
    final rechargeRef = _db.collection('recharge_requests').doc();
    await rechargeRef.set({
      'request_id': rechargeRef.id,
      'partner_id': partnerId,
      'amount_fcfa': amount,
      'credits': credits,
      'method': method,
      'status': 'PENDING',
      'created_at': Timestamp.now(),
    });

    await NotificationService().showLocalNotification(
      title: '💳 Recharge initiée',
      body: 'Votre recharge de $amount FCFA est en attente de validation.',
      payload: partnerId,
    );
  }

  Future<void> savePartnerFcmToken({
    required String partnerId,
    required String token,
  }) async {
    await _db.collection('partners').doc(partnerId).update({
      'fcm_token': token,
      'token_updated_at': Timestamp.now(),
    });
  }
}