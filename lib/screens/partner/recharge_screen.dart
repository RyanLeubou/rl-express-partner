import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/partner_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class RechargeScreen extends ConsumerStatefulWidget {
  final PartnerModel partner;
  const RechargeScreen({super.key, required this.partner});

  @override
  ConsumerState<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends ConsumerState<RechargeScreen> {
  String _selectedMethod = 'ORANGE';
  int _selectedAmount = 1000;
  bool _isLoading = false;

  final List<int> _amounts = [1000, 2000, 5000, 10000, 20000, 50000];

  final List<Map<String, dynamic>> _methods = [
    {
      'id': 'ORANGE',
      'label': 'Orange Money',
      'color': const Color(0xFFFF6600),
      'icon': Icons.circle,
    },
    {
      'id': 'MTN',
      'label': 'MTN MoMo',
      'color': const Color(0xFFFFCC00),
      'icon': Icons.circle,
    },
  ];

  int get _creditsToReceive => _selectedAmount ~/ 100;

  Future<void> _initiateRecharge() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authServiceProvider).currentUser!;

      await ref.read(firestoreServiceProvider).createRechargeRequest(
            partnerId: user.uid,
            amount: _selectedAmount,
            method: _selectedMethod,
            credits: _creditsToReceive,
          );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF0D1B2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.orSignature.withOpacity(0.3)),
            ),
            title: const Text(
              'Recharge initiée ✅',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vous allez recevoir une notification USSD sur votre téléphone pour valider le paiement de $_selectedAmount FCFA via $_selectedMethod.',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.orSignature.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.orSignature.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.orSignature, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Votre solde sera crédité de $_creditsToReceive crédits après confirmation.',
                          style: const TextStyle(
                              color: AppTheme.orSignature, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  'OK, J\'attends la notification',
                  style: TextStyle(color: AppTheme.orSignature),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppTheme.rougeAlerte,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.marineProfond,
      appBar: AppBar(
        backgroundColor: AppTheme.marineProfond,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recharger le wallet',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Solde actuel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.navyMoyen.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.orSignature.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppTheme.orSignature,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Solde actuel',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      Text(
                        '${widget.partner.creditBalance} crédits',
                        style: const TextStyle(
                          color: AppTheme.orSignature,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '≈ ${widget.partner.creditBalance * 100} FCFA',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Moyen de paiement
            const Text(
              'MOYEN DE PAIEMENT',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _methods.map((method) {
                final isSelected = _selectedMethod == method['id'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedMethod = method['id']),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: method != _methods.last ? 12 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (method['color'] as Color).withOpacity(0.15)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? method['color'] as Color
                              : Colors.white12,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  (method['color'] as Color).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                method['id'] == 'ORANGE' ? 'OM' : 'MM',
                                style: TextStyle(
                                  color: method['color'] as Color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            method['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? method['color'] as Color
                                  : Colors.white54,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Montant
            const Text(
              'MONTANT (FCFA)',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2,
              children: _amounts.map((amount) {
                final isSelected = _selectedAmount == amount;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAmount = amount),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.orSignature.withOpacity(0.15)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.orSignature
                            : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${amount ~/ 1000}k',
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.orSignature
                              : Colors.white54,
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Récapitulatif
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.vertSucces.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.vertSucces.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Montant à payer',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      Text(
                        '$_selectedAmount FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Crédits reçus',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      Text(
                        '+ $_creditsToReceive crédits',
                        style: const TextStyle(
                          color: AppTheme.vertSucces,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nouveau solde',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      Text(
                        '${widget.partner.creditBalance + _creditsToReceive} crédits',
                        style: const TextStyle(
                          color: AppTheme.orSignature,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Via',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      Text(
                        _selectedMethod == 'ORANGE'
                            ? 'Orange Money'
                            : 'MTN MoMo',
                        style: TextStyle(
                          color: _selectedMethod == 'ORANGE'
                              ? const Color(0xFFFF6600)
                              : const Color(0xFFFFCC00),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Bouton recharger
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _initiateRecharge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orSignature,
                  foregroundColor: AppTheme.marineProfond,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.marineProfond,
                        ),
                      )
                    : Text(
                        'RECHARGER — $_selectedAmount FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '1 crédit = 100 FCFA  ·  Paiement sécurisé',
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}