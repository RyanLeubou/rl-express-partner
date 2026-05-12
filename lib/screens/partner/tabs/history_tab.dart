import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/partner_model.dart';
import '../../../models/delivery_model.dart';
import '../../../services/firestore_service.dart';

class HistoryTab extends ConsumerStatefulWidget {
  final PartnerModel partner;
  final String userId;

  const HistoryTab({
    super.key,
    required this.partner,
    required this.userId,
  });

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterPeriod = 'TOUT';
  String _filterType = 'TOUT';
  String _filterStatus = 'TOUT';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.partner.partnershipType) {
      case 'PREMIUM':
        return const Color(0xFFFFD700);
      case 'VIP':
        return const Color(0xFF9B59B6);
      default:
        return AppTheme.orSignature;
    }
  }

  List<DeliveryModel> _applyFilters(List<DeliveryModel> deliveries) {
    return deliveries.where((d) {
      if (_filterPeriod != 'TOUT') {
        final now = DateTime.now();
        switch (_filterPeriod) {
          case 'TODAY':
            if (d.createdAt.day != now.day ||
                d.createdAt.month != now.month ||
                d.createdAt.year != now.year) return false;
            break;
          case 'WEEK':
            if (now.difference(d.createdAt).inDays > 7) return false;
            break;
          case 'MONTH':
            if (d.createdAt.month != now.month ||
                d.createdAt.year != now.year) return false;
            break;
          case 'YEAR':
            if (d.createdAt.year != now.year) return false;
            break;
        }
      }
      if (_filterType != 'TOUT' && d.deliveryType != _filterType)
        return false;
      if (_filterStatus != 'TOUT' && d.status != _filterStatus)
        return false;
      return true;
    }).toList();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return AppTheme.vertSucces;
      case 'FAILED':
        return AppTheme.rougeAlerte;
      case 'IN_TRANSIT':
      case 'PICKED_UP':
        return _accentColor;
      default:
        return Colors.white38;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'En attente';
      case 'ASSIGNED':
        return 'Assignée';
      case 'PICKED_UP':
        return 'Prise en charge';
      case 'IN_TRANSIT':
        return 'En transit';
      case 'DELIVERED':
        return 'Livrée ✅';
      case 'FAILED':
        return 'Échouée ❌';
      default:
        return status;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'GAS':
        return '🔥 Gaz';
      case 'HEAVY':
        return '🚛 Lourd';
      default:
        return '📦 Colis';
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveriesAsync = ref.watch(deliveriesProvider(widget.userId));
    final rechargesAsync =
        ref.watch(rechargesProvider(widget.userId));

    return Container(
      color: AppTheme.marineProfond,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'HISTORIQUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs Livraisons / Recharges
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: AppTheme.marineProfond,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Livraisons'),
                    Tab(text: 'Recharges'),
                  ],
                ),
              ),
            ),

            // Contenu tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab Livraisons
                  Column(
                    children: [
                      // Filtres
                      _buildFilters(),

                      // Liste
                      Expanded(
                        child: deliveriesAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.orSignature),
                          ),
                          error: (e, _) => Center(
                            child: Text('Erreur: $e',
                                style: const TextStyle(
                                    color: Colors.white38)),
                          ),
                          data: (deliveries) {
                            final filtered = _applyFilters(deliveries);
                            if (filtered.isEmpty) {
                              return _EmptyState(
                                accentColor: _accentColor,
                                message: deliveries.isEmpty
                                    ? 'Aucune livraison'
                                    : 'Aucun résultat',
                                sub: deliveries.isEmpty
                                    ? 'Passez votre première commande !'
                                    : 'Modifiez les filtres',
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final delivery = filtered[index];
                                return Container(
                                  margin: const EdgeInsets.only(
                                      bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withOpacity(0.04),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _statusColor(
                                              delivery.status)
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _typeLabel(
                                                delivery.deliveryType),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${delivery.stops.length} stop${delivery.stops.length > 1 ? 's' : ''}',
                                            style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '-${delivery.creditsCharged} cr.',
                                            style: TextStyle(
                                              color: _accentColor,
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _statusColor(
                                                      delivery.status)
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8),
                                            ),
                                            child: Text(
                                              _statusLabel(
                                                  delivery.status),
                                              style: TextStyle(
                                                color: _statusColor(
                                                    delivery.status),
                                                fontSize: 10,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _formatDate(
                                                delivery.createdAt),
                                            style: const TextStyle(
                                              color: Colors.white24,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '📍 ${delivery.pickupAddress}',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // Tab Recharges
                  rechargesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.orSignature),
                    ),
                    error: (e, _) => Center(
                      child: Text('Erreur: $e',
                          style:
                              const TextStyle(color: Colors.white38)),
                    ),
                    data: (recharges) {
                      if (recharges.isEmpty) {
                        return _EmptyState(
                          accentColor: _accentColor,
                          message: 'Aucune recharge',
                          sub: 'Vos recharges apparaîtront ici',
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20),
                        itemCount: recharges.length,
                        itemBuilder: (context, index) {
                          final recharge = recharges[index];
                          final isOrange =
                              recharge['method'] == 'ORANGE';
                          final methodColor = isOrange
                              ? const Color(0xFFFF6600)
                              : const Color(0xFFFFCC00);
                          final status =
                              recharge['status'] ?? 'PENDING';
                          final isPending = status == 'PENDING';

                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withOpacity(0.04),
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                color: methodColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: methodColor
                                        .withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      isOrange ? 'OM' : 'MM',
                                      style: TextStyle(
                                        color: methodColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isOrange
                                            ? 'Orange Money'
                                            : 'MTN MoMo',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(
                                          (recharge['created_at']
                                                  as dynamic)
                                              .toDate(),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+${recharge['credits']} cr.',
                                      style: TextStyle(
                                        color: _accentColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${recharge['amount_fcfa']} FCFA',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(
                                          top: 4),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPending
                                            ? Colors.orange
                                                .withOpacity(0.15)
                                            : AppTheme.vertSucces
                                                .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isPending
                                            ? 'En attente'
                                            : 'Confirmé',
                                        style: TextStyle(
                                          color: isPending
                                              ? Colors.orange
                                              : AppTheme.vertSucces,
                                          fontSize: 9,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Filtres période
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                {'key': 'TOUT', 'label': 'Tout'},
                {'key': 'TODAY', 'label': "Auj."},
                {'key': 'WEEK', 'label': 'Semaine'},
                {'key': 'MONTH', 'label': 'Mois'},
                {'key': 'YEAR', 'label': 'Année'},
              ].map((f) {
                final isSelected = _filterPeriod == f['key'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _filterPeriod = f['key']!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6, bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _accentColor.withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _accentColor
                            : Colors.white12,
                      ),
                    ),
                    child: Text(
                      f['label']!,
                      style: TextStyle(
                        color:
                            isSelected ? _accentColor : Colors.white38,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Filtres type + statut
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...([
                  {'key': 'TOUT', 'label': 'Tous types'},
                  {'key': 'GAS', 'label': '🔥 Gaz'},
                  {'key': 'PARCEL', 'label': '📦 Colis'},
                  {'key': 'HEAVY', 'label': '🚛 Lourd'},
                ].map((f) {
                  final isSelected = _filterType == f['key'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _filterType = f['key']!),
                    child: Container(
                      margin:
                          const EdgeInsets.only(right: 6, bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white38
                              : Colors.white10,
                        ),
                      ),
                      child: Text(
                        f['label']!,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white24,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                })),
                ...([
                  {'key': 'TOUT', 'label': 'Tous statuts'},
                  {'key': 'PENDING', 'label': 'En attente'},
                  {'key': 'DELIVERED', 'label': '✅ Livrées'},
                  {'key': 'FAILED', 'label': '❌ Échouées'},
                ].map((f) {
                  final isSelected = _filterStatus == f['key'];
                  Color chipColor = Colors.white38;
                  if (f['key'] == 'DELIVERED')
                    chipColor = AppTheme.vertSucces;
                  if (f['key'] == 'FAILED')
                    chipColor = AppTheme.rougeAlerte;

                  return GestureDetector(
                    onTap: () =>
                        setState(() => _filterStatus = f['key']!),
                    child: Container(
                      margin:
                          const EdgeInsets.only(right: 6, bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? chipColor.withOpacity(0.15)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? chipColor
                              : Colors.white10,
                        ),
                      ),
                      child: Text(
                        f['label']!,
                        style: TextStyle(
                          color: isSelected
                              ? chipColor
                              : Colors.white24,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                })),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color accentColor;
  final String message;
  final String sub;

  const _EmptyState({
    required this.accentColor,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: accentColor.withOpacity(0.3), size: 48),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: Colors.white38, fontSize: 14)),
          Text(sub,
              style: const TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}