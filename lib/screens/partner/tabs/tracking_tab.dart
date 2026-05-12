import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/partner_model.dart';
import '../../../models/delivery_model.dart';
import '../../../services/firestore_service.dart';

class TrackingTab extends ConsumerWidget {
  final PartnerModel partner;
  final String userId;

  const TrackingTab({
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

  String _statusLabel(String status) {
    switch (status) {
      case 'ASSIGNED':
        return 'Chauffeur assigné';
      case 'PICKED_UP':
        return 'Colis pris en charge';
      case 'IN_TRANSIT':
        return 'En transit';
      default:
        return status;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(deliveriesProvider(userId));

    return Container(
      color: AppTheme.marineProfond,
      child: SafeArea(
        child: deliveriesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.orSignature),
          ),
          error: (e, _) => Center(
            child: Text('Erreur: $e',
                style: const TextStyle(color: Colors.white)),
          ),
          data: (deliveries) {
            final active = deliveries
                .where((d) =>
                    d.status == 'ASSIGNED' ||
                    d.status == 'PICKED_UP' ||
                    d.status == 'IN_TRANSIT')
                .toList();

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      const Text(
                        'SUIVI EN TEMPS RÉEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (active.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.vertSucces.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    AppTheme.vertSucces.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.vertSucces,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _statusLabel(active.first.status),
                                style: const TextStyle(
                                  color: AppTheme.vertSucces,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Zone carte — Mapbox sur mobile, placeholder sur web
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _accentColor.withOpacity(
                              active.isNotEmpty ? 0.3 : 0.1)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: kIsWeb
                        ? _WebMapPlaceholder(
                            active: active,
                            accentColor: _accentColor,
                          )
                        : _MobileMap(
                            active: active,
                            accentColor: _accentColor,
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Panneau infos
                if (active.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _accentColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.gps_fixed,
                              color: _accentColor, size: 18),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Le suivi GPS en temps réel s\'activera automatiquement dès votre prochaine commande assignée.',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chips infos
                            Row(
                              children: [
                                _InfoChip(
                                  icon: Icons.category_outlined,
                                  label: _typeLabel(
                                      active.first.deliveryType),
                                  color: _accentColor,
                                ),
                                const SizedBox(width: 8),
                                _InfoChip(
                                  icon: Icons.place_outlined,
                                  label:
                                      '${active.first.stops.length} stop${active.first.stops.length > 1 ? 's' : ''}',
                                  color: _accentColor,
                                ),
                                const SizedBox(width: 8),
                                _InfoChip(
                                  icon: Icons.toll_outlined,
                                  label:
                                      '${active.first.creditsCharged} cr.',
                                  color: _accentColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Progression stops
                            const Text(
                              'PROGRESSION',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                                ...active.first.stops
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final color =
                                      _stopColor(entry.value.status);
                                  return Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Container(
                                                height: 2, color: color)),
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: color,
                                          ),
                                          child: entry.value.status ==
                                                  'DELIVERED'
                                              ? const Icon(Icons.check,
                                                  size: 6,
                                                  color: Colors.white)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Adresses
                            _AddressRow(
                              icon: Icons.location_on_outlined,
                              label: 'Enlèvement',
                              address: active.first.pickupAddress,
                              color: _accentColor,
                            ),
                            ...active.first.stops.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _AddressRow(
                                  icon: Icons.place_outlined,
                                  label: 'Stop ${entry.key + 1}',
                                  address: entry.value.address,
                                  color: _stopColor(entry.value.status),
                                ),
                              ),
                            ),

                            if (active.first.notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _AddressRow(
                                icon: Icons.note_outlined,
                                label: 'Notes',
                                address: active.first.notes,
                                color: Colors.white38,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// Placeholder Web — grille simulée
// ============================================================
class _WebMapPlaceholder extends StatelessWidget {
  final List<DeliveryModel> active;
  final Color accentColor;

  const _WebMapPlaceholder({
    required this.active,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grille simulant une carte
        CustomPaint(
          painter: _MapGridPainter(),
          size: Size.infinite,
        ),

        // Contenu central
        if (active.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off_outlined,
                  color: accentColor.withOpacity(0.4),
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aucune livraison active',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'La carte GPS s\'activera\ndès qu\'un chauffeur sera assigné',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: accentColor.withOpacity(0.4)),
                  ),
                  child: const Text('🏍️',
                      style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Chauffeur en route',
                    style: TextStyle(
                      color: Color(0xFF0A1628),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Badge GPS actif
        if (active.isNotEmpty)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.vertSucces.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_fixed, color: Colors.white, size: 10),
                  SizedBox(width: 4),
                  Text(
                    'GPS ACTIF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Badge web
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Carte GPS disponible sur mobile',
              style: TextStyle(color: Colors.white38, fontSize: 9),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Carte Mobile — Mapbox (Android + iOS uniquement)
// ============================================================
class _MobileMap extends StatefulWidget {
  final List<DeliveryModel> active;
  final Color accentColor;

  const _MobileMap({
    required this.active,
    required this.accentColor,
  });

  @override
  State<_MobileMap> createState() => _MobileMapState();
}

class _MobileMapState extends State<_MobileMap> {
  // Mapbox sera initialisé ici quand on sera sur mobile
  // Pour l'instant placeholder identique au web

  @override
  Widget build(BuildContext context) {
    // TODO: intégrer MapWidget de mapbox_maps_flutter ici
    // quand le build mobile sera configuré
    return Stack(
      children: [
        CustomPaint(
          painter: _MapGridPainter(),
          size: Size.infinite,
        ),
        if (widget.active.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off_outlined,
                  color: widget.accentColor.withOpacity(0.4),
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aucune livraison active',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'La carte GPS s\'activera\ndès qu\'un chauffeur sera assigné',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: widget.accentColor.withOpacity(0.4)),
                  ),
                  child:
                      const Text('🏍️', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Chauffeur en route',
                    style: TextStyle(
                      color: Color(0xFF0A1628),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.active.isNotEmpty)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.vertSucces.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_fixed, color: Colors.white, size: 10),
                  SizedBox(width: 4),
                  Text(
                    'GPS ACTIF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// Widgets communs
// ============================================================
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String address;
  final Color color;

  const _AddressRow({
    required this.icon,
    required this.label,
    required this.address,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white24, fontSize: 10)),
              Text(address,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1B3A6B).withOpacity(0.3)
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final roadPaint = Paint()
      ..color = const Color(0xFF1B3A6B).withOpacity(0.6)
      ..strokeWidth = 2.5;

    canvas.drawLine(Offset(0, size.height * 0.35),
        Offset(size.width, size.height * 0.35), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.65),
        Offset(size.width, size.height * 0.65), roadPaint);
    canvas.drawLine(Offset(size.width * 0.25, 0),
        Offset(size.width * 0.25, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.6, 0),
        Offset(size.width * 0.6, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}