import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/partner_model.dart';

class ContactTab extends StatelessWidget {
  final PartnerModel partner;

  const ContactTab({super.key, required this.partner});

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

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _email(String mail) async {
    final uri = Uri.parse('mailto:$mail');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final depots = [
      {
        'name': 'Dépôt Douala 5e',
        'zone': 'Makepe, Douala 5e',
        'address': 'Quartier Makepe, Douala 5e arrondissement, Cameroun',
        'secretary': 'Secrétaire Douala 5e',
        'phone': '+237 6XX XXX XXX',
        'email': 'depot5e@rl-express.cm',
        'hours': 'Lun–Dim : 7h00 – 18h00',
        'icon': '🏭',
      },
      {
        'name': 'Dépôt Douala 3e',
        'zone': 'Yassa, Douala 3e',
        'address': 'Quartier Yassa, Douala 3e arrondissement, Cameroun',
        'secretary': 'Secrétaire Douala 3e',
        'phone': '+237 6XX XXX XXX',
        'email': 'depot3e@rl-express.cm',
        'hours': 'Lun–Dim : 7h00 – 18h00',
        'icon': '🏭',
      },
    ];

    return Container(
      color: AppTheme.marineProfond,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'CONTACT & SUPPORT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Contactez directement votre dépôt',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // Dépôts
              ...depots.map((depot) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _accentColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        // En-tête dépôt
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.08),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              Text(depot['icon']!,
                                  style:
                                      const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      depot['name']!,
                                      style: TextStyle(
                                        color: _accentColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      depot['zone']!,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Infos
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Adresse
                              _ContactRow(
                                icon: Icons.location_on_outlined,
                                label: 'Adresse',
                                value: depot['address']!,
                                color: _accentColor,
                                onTap: () =>
                                    _openMaps(depot['address']!),
                                actionLabel: 'Voir sur Maps',
                                actionIcon: Icons.map_outlined,
                              ),
                              const Divider(
                                  color: Colors.white10, height: 20),

                              // Secrétaire + téléphone
                              _ContactRow(
                                icon: Icons.support_agent,
                                label: depot['secretary']!,
                                value: depot['phone']!,
                                color: AppTheme.vertSucces,
                                onTap: () => _call(depot['phone']!),
                                actionLabel: 'Appeler',
                                actionIcon: Icons.phone,
                              ),
                              const Divider(
                                  color: Colors.white10, height: 20),

                              // Email
                              _ContactRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: depot['email']!,
                                color: Colors.white54,
                                onTap: () => _email(depot['email']!),
                                actionLabel: 'Écrire',
                                actionIcon: Icons.send_outlined,
                              ),
                              const Divider(
                                  color: Colors.white10, height: 20),

                              // Horaires
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: Colors.white38, size: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Horaires',
                                          style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11),
                                        ),
                                        Text(
                                          depot['hours']!,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 8),

              // Contact général RL EXPRESS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _accentColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RL EXPRESS 🔱 — Direction',
                      style: TextStyle(
                        color: _accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ContactRow(
                      icon: Icons.phone_outlined,
                      label: 'Direction',
                      value: '+237 691 486 546',
                      color: _accentColor,
                      onTap: () => _call('+237691486546'),
                      actionLabel: 'Appeler',
                      actionIcon: Icons.phone,
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    _ContactRow(
                      icon: Icons.email_outlined,
                      label: 'Email général',
                      value: 'rl_express.douala@gmail.com',
                      color: Colors.white54,
                      onTap: () =>
                          _email('rl_express.douala@gmail.com'),
                      actionLabel: 'Écrire',
                      actionIcon: Icons.send_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  final String actionLabel;
  final IconData actionIcon;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    required this.actionLabel,
    required this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 10)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(actionIcon, color: color, size: 12),
                const SizedBox(width: 4),
                Text(
                  actionLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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