import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/partner_model.dart';
import '../order_screen.dart';
import '../recharge_screen.dart';
import '../stats_screen.dart';
import '../partner_main_screen.dart';

class HomeTab extends ConsumerWidget {
  final PartnerModel partner;
  final String userId;

  const HomeTab({
    super.key,
    required this.partner,
    required this.userId,
  });

  Color get _accentColor {
    switch (partner.partnershipType) {
      case 'PREMIUM':
        return const Color(0xFFFFD700);
      case 'VIP':
        return const Color(0xFF9B59B6);
      default:
        return AppTheme.orSignature;
    }
  }

  List<Color> get _backgroundGradient {
    switch (partner.partnershipType) {
      case 'PREMIUM':
        return [const Color(0xFF1A1200), const Color(0xFF2D1F00), const Color(0xFF1A1200)];
      case 'VIP':
        return [const Color(0xFF0D0014), const Color(0xFF1A0030), const Color(0xFF0D0014)];
      default:
        return [const Color(0xFF0A1628), const Color(0xFF0D1B2A), const Color(0xFF0A1628)];
    }
  }

  Color get _badgeColor {
    switch (partner.partnershipType) {
      case 'PREMIUM':
        return const Color(0xFFFFD700);
      case 'VIP':
        return const Color(0xFF9B59B6);
      default:
        return AppTheme.orSignature;
    }
  }

  int get _creditsAlloues {
    switch (partner.partnershipType) {
      case 'PREMIUM':
        return 300;
      case 'VIP':
        return 700;
      default:
        return 100;
    }
  }

  Color _stopColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return AppTheme.vertSucces;
      case 'FAILED':
        return AppTheme.rougeAlerte;
      case 'IN_TRANSIT':
      case 'PICKED_UP':
        return _accentColor;
      default:
        return Colors.white24;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'GAS':
        return 'Gaz';
      case 'HEAVY':
        return 'Lourd';
      default:
        return 'Colis';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(deliveriesProvider(userId));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _backgroundGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accentColor.withOpacity(0.1),
                      border: Border.all(color: _accentColor.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text('🔱', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'RL EXPRESS',
                    style: TextStyle(
                      color: AppTheme.orSignature,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _badgeColor.withOpacity(0.15),
                      border: Border.all(color: _badgeColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PARTENAIRE ${partner.partnershipType}',
                      style: TextStyle(
                        color: _badgeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white24, size: 18),
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Bonjour,',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
              Text(
                partner.businessName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Carte wallet
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accentColor.withOpacity(0.15), _backgroundGradient[1]],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accentColor.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SOLDE DISPONIBLE',
                      style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${partner.creditBalance}',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8, left: 6),
                          child: Text('cr.', style: TextStyle(color: Colors.white54, fontSize: 20)),
                        ),
                      ],
                    ),
                    Text(
                      '≈ ${partner.creditBalance * 100} FCFA  ·  $_creditsAlloues cr. alloués ce mois',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Boutons COMMANDER + RECHARGER
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderScreen(partner: partner)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt, color: _backgroundGradient[0], size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'COMMANDER',
                              style: TextStyle(
                                color: _backgroundGradient[0],
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RechargeScreen(partner: partner)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _accentColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: _accentColor, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'RECHARGER',
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Livraison active
              deliveriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (deliveries) {
                  final active = deliveries
                      .where((d) =>
                          d.status == 'ASSIGNED' ||
                          d.status == 'PICKED_UP' ||
                          d.status == 'IN_TRANSIT')
                      .toList();

                  if (active.isEmpty) return const SizedBox.shrink();

                  final delivery = active.first;
                  final delivered = delivery.stops.where((s) => s.status == 'DELIVERED').length;
                  final total = delivery.stops.length;

                  return GestureDetector(
                    onTap: () => ref.read(activeTabProvider.notifier).setTab(1),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.vertSucces.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.vertSucces.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.vertSucces,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'LIVRAISON ACTIVE',
                                style: TextStyle(
                                  color: AppTheme.vertSucces,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _accentColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$delivered/$total STOPS',
                                  style: TextStyle(
                                    color: _accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_typeLabel(delivery.deliveryType)} · ${delivery.pickupAddress}→...',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.orSignature,
                                ),
                              ),
                              ...delivery.stops.asMap().entries.map((entry) {
                                final color = _stopColor(entry.value.status);
                                return Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(child: Container(height: 2, color: color)),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                                        child: entry.value.status == 'DELIVERED'
                                            ? const Icon(Icons.check, size: 6, color: Colors.white)
                                            : null,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: delivery.stops.take(3).map((s) => Expanded(
                              child: Text(
                                s.address,
                                style: TextStyle(color: _stopColor(s.status), fontSize: 9),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Stats rapides
              deliveriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (deliveries) {
                  final now = DateTime.now();
                  final thisMois = deliveries
                      .where((d) => d.createdAt.month == now.month && d.createdAt.year == now.year)
                      .toList();
                  final delivered = thisMois.where((d) => d.status == 'DELIVERED').length;
                  final total = thisMois.length;
                  final taux = total > 0 ? (delivered / total * 100).toInt() : 0;
                  final creditsUses = thisMois.fold(0, (sum, d) => sum + d.creditsCharged);

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatsScreen(partner: partner, deliveries: deliveries),
                      ),
                    ),
                    child: Row(
                      children: [
                        _StatCard(value: '$total', label: 'Ce mois', color: _accentColor),
                        const SizedBox(width: 10),
                        _StatCard(value: '$taux%', label: 'Réussite', color: AppTheme.vertSucces),
                        const SizedBox(width: 10),
                        _StatCard(value: '$creditsUses', label: 'Cr. usés', color: Colors.white54),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}