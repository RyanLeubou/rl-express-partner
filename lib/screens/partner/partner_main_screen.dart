import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/partner_model.dart';
import 'tabs/home_tab.dart';
import 'tabs/tracking_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/contact_tab.dart';

final activeTabProvider = NotifierProvider<ActiveTabNotifier, int>(
  ActiveTabNotifier.new,
);

class ActiveTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setTab(int index) => state = index;
}

class PartnerMainScreen extends ConsumerWidget {
  const PartnerMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    final partnerAsync = ref.watch(partnerProvider(user.uid));
    final activeTab = ref.watch(activeTabProvider);

    return partnerAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.marineProfond,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.orSignature),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.marineProfond,
        body: Center(
          child: Text('Erreur: $e',
              style: const TextStyle(color: Colors.white)),
        ),
      ),
      data: (partner) {
        if (partner == null) {
          return const Scaffold(
            backgroundColor: AppTheme.marineProfond,
            body: Center(
              child: Text('Partenaire introuvable',
                  style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final tabs = [
          HomeTab(partner: partner, userId: user.uid),
          TrackingTab(partner: partner, userId: user.uid),
          HistoryTab(partner: partner, userId: user.uid),
          ContactTab(partner: partner),
        ];

        return Scaffold(
          backgroundColor: _backgroundGradient(partner)[0],
          body: tabs[activeTab],
          bottomNavigationBar: _BottomNav(
            partner: partner,
            activeTab: activeTab,
            onTabChanged: (index) {
              ref.read(activeTabProvider.notifier).setTab(index);
            },
          ),
        );
      },
    );
  }

  List<Color> _backgroundGradient(PartnerModel partner) {
    switch (partner.partnershipType) {
      case 'PREMIUM':
        return [const Color(0xFF1A1200), const Color(0xFF2D1F00)];
      case 'VIP':
        return [const Color(0xFF0D0014), const Color(0xFF1A0030)];
      default:
        return [const Color(0xFF0A1628), const Color(0xFF0D1B2A)];
    }
  }
}

class _BottomNav extends StatelessWidget {
  final PartnerModel partner;
  final int activeTab;
  final Function(int) onTabChanged;

  const _BottomNav({
    required this.partner,
    required this.activeTab,
    required this.onTabChanged,
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
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Accueil'},
      {'icon': Icons.location_on_outlined, 'activeIcon': Icons.location_on, 'label': 'Suivi'},
      {'icon': Icons.history_outlined, 'activeIcon': Icons.history, 'label': 'Historique'},
      {'icon': Icons.headset_mic_outlined, 'activeIcon': Icons.headset_mic, 'label': 'Contact'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080F1C),
        border: Border(
          top: BorderSide(color: _accentColor.withOpacity(0.15), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = activeTab == index;

              return GestureDetector(
                onTap: () => onTabChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? _accentColor.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? item['activeIcon'] as IconData : item['icon'] as IconData,
                        color: isActive ? _accentColor : Colors.white24,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: isActive ? _accentColor : Colors.white24,
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}