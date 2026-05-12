import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/partner_model.dart';
import '../../../models/delivery_model.dart';

class StatsScreen extends StatelessWidget {
  final PartnerModel partner;
  final List<DeliveryModel> deliveries;

  const StatsScreen({
    super.key,
    required this.partner,
    required this.deliveries,
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Stats globales
    final total = deliveries.length;
    final delivered =
        deliveries.where((d) => d.status == 'DELIVERED').length;
    final failed =
        deliveries.where((d) => d.status == 'FAILED').length;
    final pending = deliveries
        .where((d) =>
            d.status == 'PENDING' ||
            d.status == 'ASSIGNED' ||
            d.status == 'IN_TRANSIT' ||
            d.status == 'PICKED_UP')
        .length;
    final taux =
        total > 0 ? (delivered / total * 100).toInt() : 0;
    final totalCredits =
        deliveries.fold(0, (sum, d) => sum + d.creditsCharged);

    // Stats ce mois
    final thisMoth = deliveries
        .where((d) =>
            d.createdAt.month == now.month &&
            d.createdAt.year == now.year)
        .toList();
    final deliveredMois =
        thisMoth.where((d) => d.status == 'DELIVERED').length;
    final creditsMois =
        thisMoth.fold(0, (sum, d) => sum + d.creditsCharged);

    // Stats par type
    final gas = deliveries.where((d) => d.deliveryType == 'GAS').length;
    final parcel =
        deliveries.where((d) => d.deliveryType == 'PARCEL').length;
    final heavy =
        deliveries.where((d) => d.deliveryType == 'HEAVY').length;

    // Stops totaux
    final totalStops =
        deliveries.fold(0, (sum, d) => sum + d.stops.length);

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
          'Statistiques détaillées',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Taux de réussite global
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accentColor.withOpacity(0.15),
                    AppTheme.marineProfond,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: _accentColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '$taux%',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'TAUX DE RÉUSSITE GLOBAL',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? delivered / total : 0,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _accentColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats globales
            _SectionTitle(title: 'GLOBAL', color: _accentColor),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(value: '$total', label: 'Total', color: _accentColor),
                const SizedBox(width: 10),
                _StatCard(value: '$delivered', label: 'Livrées', color: AppTheme.vertSucces),
                const SizedBox(width: 10),
                _StatCard(value: '$failed', label: 'Échouées', color: AppTheme.rougeAlerte),
                const SizedBox(width: 10),
                _StatCard(value: '$pending', label: 'En cours', color: Colors.white38),
              ],
            ),
            const SizedBox(height: 20),

            // Stats ce mois
            _SectionTitle(title: 'CE MOIS', color: _accentColor),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(value: '${thisMoth.length}', label: 'Commandes', color: _accentColor),
                const SizedBox(width: 10),
                _StatCard(value: '$deliveredMois', label: 'Livrées', color: AppTheme.vertSucces),
                const SizedBox(width: 10),
                _StatCard(value: '$creditsMois', label: 'Cr. utilisés', color: Colors.white54),
              ],
            ),
            const SizedBox(height: 20),

            // Stats par type
            _SectionTitle(title: 'PAR TYPE DE LIVRAISON', color: _accentColor),
            const SizedBox(height: 12),
            _TypeBar(label: '🔥 Gaz', count: gas, total: total, color: const Color(0xFFFF6600)),
            const SizedBox(height: 8),
            _TypeBar(label: '📦 Colis', count: parcel, total: total, color: _accentColor),
            const SizedBox(height: 8),
            _TypeBar(label: '🚛 Lourd', count: heavy, total: total, color: Colors.white38),
            const SizedBox(height: 20),

            // Autres métriques
            _SectionTitle(title: 'MÉTRIQUES', color: _accentColor),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(value: '$totalStops', label: 'Stops total', color: _accentColor),
                const SizedBox(width: 10),
                _StatCard(
                  value: total > 0
                      ? (totalStops / total).toStringAsFixed(1)
                      : '0',
                  label: 'Moy. stops',
                  color: Colors.white54,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  value: '$totalCredits',
                  label: 'Cr. total',
                  color: Colors.white54,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Info abonnement
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accentColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ABONNEMENT ${partner.partnershipType}',
                    style: TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Crédits restants', value: '${partner.creditBalance} cr.', color: _accentColor),
                  _InfoRow(label: 'Valeur restante', value: '${partner.creditBalance * 100} FCFA', color: Colors.white54),
                  _InfoRow(label: 'Coût par livraison', value: '${partner.creditPerDelivery} cr.', color: Colors.white54),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: color.withOpacity(0.7),
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

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
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _TypeBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$count',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}