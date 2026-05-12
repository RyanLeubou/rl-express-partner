import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/delivery_model.dart';
import '../../models/partner_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class DepotInfo {
  final String id;
  final String name;
  final String zone;
  final String address;
  final String secretaryName;
  final String secretaryPhone;

  const DepotInfo({
    required this.id,
    required this.name,
    required this.zone,
    required this.address,
    required this.secretaryName,
    required this.secretaryPhone,
  });
}

class OrderScreen extends ConsumerStatefulWidget {
  final PartnerModel partner;
  const OrderScreen({super.key, required this.partner});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'PARCEL';

  final List<DepotInfo> _depots = const [
    DepotInfo(
      id: 'depot_dla5e',
      name: 'Dépôt Douala 5e',
      zone: 'Makepe',
      address: 'Makepe, Douala 5e',
      secretaryName: 'Secrétaire Douala 5e',
      secretaryPhone: '+237 6XX XXX XXX',
    ),
    DepotInfo(
      id: 'depot_dla3e',
      name: 'Dépôt Douala 3e',
      zone: 'Yansoki',
      address: 'Yansoki, Douala 3e',
      secretaryName: 'Secrétaire Douala 3e',
      secretaryPhone: '+237 6XX XXX XXX',
    ),
  ];

  DepotInfo? _selectedDepot;

  final Map<String, int> _bottleSelection = {
    '6kg': 0,
    '6kg_eco': 0,
    '12.5kg': 0,
    '35kg': 0,
    '75kg': 0,
  };

  final List<Map<String, String>> _bottleTypes = [
    {'type': '6kg', 'label': '6 kg', 'icon': '🔵'},
    {'type': '6kg_eco', 'label': '6 kg ÉcoGaz', 'icon': '🟢'},
    {'type': '12.5kg', 'label': '12,5 kg', 'icon': '🟡'},
    {'type': '35kg', 'label': '35 kg', 'icon': '🟠'},
    {'type': '75kg', 'label': '75 kg', 'icon': '🔴'},
  ];

  final _gasDeliveryAddressController = TextEditingController();
  final _gasDeliveryContactController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _pickupContactController = TextEditingController();
  final _notesController = TextEditingController();
  final List<Map<String, TextEditingController>> _stops = [];

  bool _isLoading = false;

  final List<Map<String, dynamic>> _deliveryTypes = [
    {
      'type': 'GAS',
      'label': 'Gaz',
      'icon': Icons.local_fire_department_outlined,
      'description': 'Bouteilles 6kg à 75kg',
    },
    {
      'type': 'PARCEL',
      'label': 'Colis',
      'icon': Icons.inventory_2_outlined,
      'description': 'Tous formats',
    },
    {
      'type': 'HEAVY',
      'label': 'Lourd',
      'icon': Icons.forklift,
      'description': 'Charges volumineuses',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDepot = _depots[0];
    _addStop();
  }

  @override
  void dispose() {
    _gasDeliveryAddressController.dispose();
    _gasDeliveryContactController.dispose();
    _pickupAddressController.dispose();
    _pickupContactController.dispose();
    _notesController.dispose();
    for (final stop in _stops) {
      stop['address']!.dispose();
      stop['contact']!.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    setState(() {
      _stops.add({
        'address': TextEditingController(),
        'contact': TextEditingController(),
      });
    });
  }

  void _removeStop(int index) {
    if (_stops.length <= 1) return;
    setState(() {
      _stops[index]['address']!.dispose();
      _stops[index]['contact']!.dispose();
      _stops.removeAt(index);
    });
  }

  int get _totalBottles =>
      _bottleSelection.values.fold(0, (sum, qty) => sum + qty);

  bool get _hasBottleSelection => _totalBottles > 0;

  String get _bottlesSummary {
    final parts = <String>[];
    for (final bottle in _bottleTypes) {
      final qty = _bottleSelection[bottle['type']!] ?? 0;
      if (qty > 0) {
        parts.add('$qty × ${bottle['label']!}');
      }
    }
    return parts.join(', ');
  }

  int get _creditCostGas => widget.partner.creditPerDelivery;

  int get _creditCostMultiStop {
    final baseCredits = _selectedType == 'HEAVY'
        ? widget.partner.creditPerDelivery + 5
        : widget.partner.creditPerDelivery;
    return baseCredits * _stops.length;
  }

  int get _totalCreditCost =>
      _selectedType == 'GAS' ? _creditCostGas : _creditCostMultiStop;

  bool get _hasSufficientCredits =>
      widget.partner.creditBalance >= _totalCreditCost;

  Future<void> _callSecretary(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _submitOrder() async {
    if (_selectedType == 'GAS' && !_hasBottleSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Veuillez sélectionner au moins une bouteille'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (!_hasSufficientCredits) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final deliveryId = const Uuid().v4();

      List<DeliveryStop> stops;
      String pickupAddress;
      String notes;

      if (_selectedType == 'GAS') {
        pickupAddress = _selectedDepot!.address;
        notes =
            'Commande gaz : $_bottlesSummary. ${_notesController.text.trim()}';
        stops = [
          DeliveryStop(
            address: _gasDeliveryAddressController.text.trim(),
            contact: _gasDeliveryContactController.text.trim(),
          ),
        ];
      } else {
        pickupAddress = _pickupAddressController.text.trim();
        notes = _notesController.text.trim();
        stops = _stops
            .map((s) => DeliveryStop(
                  address: s['address']!.text.trim(),
                  contact: s['contact']!.text.trim(),
                ))
            .toList();
      }

      final delivery = DeliveryModel(
        deliveryId: deliveryId,
        partnerId: user.uid,
        depotId:
            _selectedType == 'GAS' ? _selectedDepot!.id : '',
        deliveryType: _selectedType,
        pickupAddress: pickupAddress,
        pickupContact: _selectedType == 'GAS'
            ? _selectedDepot!.secretaryPhone
            : _pickupContactController.text.trim(),
        stops: stops,
        creditsCharged: _totalCreditCost,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await ref
          .read(firestoreServiceProvider)
          .createDelivery(delivery);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('✅ Commande envoyée avec succès !'),
            backgroundColor: AppTheme.vertSucces,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
          icon:
              const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nouvelle commande',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type de livraison
              const _SectionTitle(title: 'TYPE DE LIVRAISON'),
              const SizedBox(height: 12),
              Row(
                children: _deliveryTypes.map((type) {
                  final isSelected = _selectedType == type['type'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _selectedType = type['type'] as String),
                      child: Container(
                        margin: EdgeInsets.only(
                          right: type != _deliveryTypes.last ? 8 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.orSignature.withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.orSignature
                                : Colors.white12,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              color: isSelected
                                  ? AppTheme.orSignature
                                  : Colors.white38,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              type['label'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.orSignature
                                    : Colors.white54,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              type['description'] as String,
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 9,
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
              const SizedBox(height: 28),

              // ================ FORMULAIRE GAZ ================
              if (_selectedType == 'GAS') ...[
                const _SectionTitle(title: 'DÉPÔT LE PLUS PROCHE'),
                const SizedBox(height: 12),
                Row(
                  children: _depots.map((depot) {
                    final isSelected = _selectedDepot?.id == depot.id;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedDepot = depot),
                        child: Container(
                          margin: EdgeInsets.only(
                            right: depot != _depots.last ? 12 : 0,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.orSignature.withOpacity(0.15)
                                : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.orSignature
                                  : Colors.white12,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warehouse_outlined,
                                    color: isSelected
                                        ? AppTheme.orSignature
                                        : Colors.white38,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      depot.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppTheme.orSignature
                                            : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                depot.zone,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Contact secrétaire
                if (_selectedDepot != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.navyMoyen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.support_agent,
                          color: AppTheme.orSignature,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedDepot!.secretaryName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _selectedDepot!.secretaryPhone,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _callSecretary(
                              _selectedDepot!.secretaryPhone),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.vertSucces.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppTheme.vertSucces
                                      .withOpacity(0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.phone,
                                    color: AppTheme.vertSucces,
                                    size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Appeler',
                                  style: TextStyle(
                                    color: AppTheme.vertSucces,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Sélection bouteilles
                const _SectionTitle(
                    title: 'BOUTEILLES À COMMANDER'),
                const SizedBox(height: 12),
                Column(
                  children: _bottleTypes.map((bottle) {
                    final qty =
                        _bottleSelection[bottle['type']!] ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: qty > 0
                            ? AppTheme.orSignature.withOpacity(0.08)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: qty > 0
                              ? AppTheme.orSignature.withOpacity(0.3)
                              : Colors.white10,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            bottle['icon']!,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              bottle['label']!,
                              style: TextStyle(
                                color: qty > 0
                                    ? AppTheme.orSignature
                                    : Colors.white70,
                                fontSize: 14,
                                fontWeight: qty > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          // Bouton moins
                          GestureDetector(
                            onTap: () {
                              if (qty > 0) {
                                setState(() =>
                                    _bottleSelection[bottle['type']!] =
                                        qty - 1);
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: qty > 0
                                    ? AppTheme.orSignature
                                        .withOpacity(0.15)
                                    : Colors.white10,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.remove,
                                color: qty > 0
                                    ? AppTheme.orSignature
                                    : Colors.white24,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$qty',
                              style: TextStyle(
                                color: qty > 0
                                    ? AppTheme.orSignature
                                    : Colors.white38,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Bouton plus
                          GestureDetector(
                            onTap: () {
                              setState(() =>
                                  _bottleSelection[bottle['type']!] =
                                      qty + 1);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.orSignature
                                    .withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: AppTheme.orSignature,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                // Résumé bouteilles
                if (_hasBottleSelection) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.vertSucces.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              AppTheme.vertSucces.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppTheme.vertSucces, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$_totalBottles bouteille${_totalBottles > 1 ? 's' : ''} : $_bottlesSummary',
                            style: const TextStyle(
                              color: AppTheme.vertSucces,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Adresse livraison gaz
                const _SectionTitle(title: 'ADRESSE DE LIVRAISON'),
                const SizedBox(height: 12),
                _StyledTextField(
                  controller: _gasDeliveryAddressController,
                  hint: 'Adresse de livraison',
                  icon: Icons.place_outlined,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Adresse requise'
                      : null,
                ),
                const SizedBox(height: 12),
                _StyledTextField(
                  controller: _gasDeliveryContactController,
                  hint: 'Contact destinataire (+237...)',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Contact requis'
                      : null,
                ),
                const SizedBox(height: 12),

                // Info prix fixe
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.orSignature.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            AppTheme.orSignature.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.orSignature, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Prix fixe : ${widget.partner.creditPerDelivery} crédits — quel que soit le nombre de bouteilles.',
                          style: const TextStyle(
                            color: AppTheme.orSignature,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ============= FORMULAIRE COLIS / LOURD =============
              if (_selectedType != 'GAS') ...[
                const _SectionTitle(title: "POINT D'ENLÈVEMENT"),
                const SizedBox(height: 12),
                _StyledTextField(
                  controller: _pickupAddressController,
                  hint: "Adresse d'enlèvement",
                  icon: Icons.location_on_outlined,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Adresse requise'
                      : null,
                ),
                const SizedBox(height: 12),
                _StyledTextField(
                  controller: _pickupContactController,
                  hint: 'Contact enlèvement (+237...)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Contact requis'
                      : null,
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    const Expanded(
                      child: _SectionTitle(
                          title: 'POINTS DE LIVRAISON'),
                    ),
                    GestureDetector(
                      onTap: _addStop,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.orSignature.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.orSignature
                                  .withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add,
                                color: AppTheme.orSignature,
                                size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Ajouter',
                              style: TextStyle(
                                color: AppTheme.orSignature,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ..._stops.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stop = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppTheme.orSignature,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppTheme.marineProfond,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Destinataire ${index + 1}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            if (_stops.length > 1)
                              GestureDetector(
                                onTap: () => _removeStop(index),
                                child: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _StyledTextField(
                          controller: stop['address']!,
                          hint: 'Adresse de livraison',
                          icon: Icons.place_outlined,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Adresse requise'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        _StyledTextField(
                          controller: stop['contact']!,
                          hint: 'Contact destinataire (+237...)',
                          icon: Icons.person_outline,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Contact requis'
                              : null,
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),

              // Notes
              const _SectionTitle(title: 'NOTES (OPTIONNEL)'),
              const SizedBox(height: 12),
              _StyledTextField(
                controller: _notesController,
                hint: 'Instructions spéciales pour le chauffeur...',
                icon: Icons.note_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              // Récapitulatif
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _hasSufficientCredits
                      ? AppTheme.vertSucces.withOpacity(0.1)
                      : AppTheme.rougeAlerte.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hasSufficientCredits
                        ? AppTheme.vertSucces.withOpacity(0.3)
                        : AppTheme.rougeAlerte.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    if (_selectedType == 'GAS') ...[
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dépôt',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14)),
                          Text(
                            _selectedDepot?.name ?? '',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bouteilles',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14)),
                          Text(
                            _hasBottleSelection
                                ? '$_totalBottles bouteille${_totalBottles > 1 ? 's' : ''}'
                                : 'Aucune sélection',
                            style: TextStyle(
                              color: _hasBottleSelection
                                  ? Colors.white
                                  : Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Stops',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14)),
                          Text(
                            '${_stops.length} point${_stops.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Coût total',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14)),
                        Text(
                          '$_totalCreditCost crédits',
                          style: const TextStyle(
                            color: AppTheme.orSignature,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Solde après commande',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13)),
                        Text(
                          '${widget.partner.creditBalance - _totalCreditCost} crédits',
                          style: TextStyle(
                            color: _hasSufficientCredits
                                ? AppTheme.vertSucces
                                : AppTheme.rougeAlerte,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (!_hasSufficientCredits) ...[
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_outlined,
                              color: Colors.redAccent, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Solde insuffisant — rechargez votre wallet',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bouton confirmer
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      (_isLoading || !_hasSufficientCredits)
                          ? null
                          : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orSignature,
                    foregroundColor: AppTheme.marineProfond,
                    disabledBackgroundColor: Colors.white12,
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
                          _hasSufficientCredits
                              ? 'CONFIRMER — $_totalCreditCost crédits'
                              : 'SOLDE INSUFFISANT',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: _hasSufficientCredits
                                ? AppTheme.marineProfond
                                : Colors.white24,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.white24, fontSize: 14),
        prefixIcon:
            Icon(icon, color: AppTheme.orSignature, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.orSignature,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 0,
        ),
      ),
    );
  }
}