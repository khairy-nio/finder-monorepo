import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../core/utils/app_messenger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Points Wallet & Cash Redemption Screen
// Replaces the old RewardsCatalogScreen.
//
// Three tabs:
//   1. Wallet    — balance, conversion rate, tier cards
//   2. Cash Out  — select tier → wallet provider → enter number → submit
//   3. History   — redemption history + points transaction log (sub-tabs)
// ─────────────────────────────────────────────────────────────────────────────

class RewardsCatalogScreen extends StatefulWidget {
  const RewardsCatalogScreen({super.key});

  @override
  State<RewardsCatalogScreen> createState() => _RewardsCatalogScreenState();
}

class _RewardsCatalogScreenState extends State<RewardsCatalogScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────
  late TabController _tabController;
  final _walletNumberController = TextEditingController();

  // ── UI State ─────────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isSubmitting = false;

  // ── Wallet Data ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _tiers = [];
  List<String> _walletProviders = [];
  int _pointsPerEgp = 10;

  // ── History Data ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _pointsHistory = [];
  List<Map<String, dynamic>> _redemptionsHistory = [];
  bool _isLoadingHistory = false;

  // ── Cash-Out Form State ──────────────────────────────────────────────────
  Map<String, dynamic>? _selectedTier;
  String? _selectedProvider;

  // ── Fallback static tiers (if API is unavailable) ────────────────────────
  static const _fallbackTiers = [
    {'points': 500,  'cash_amount_egp': 50.0,  'label': '50 EGP'},
    {'points': 1000, 'cash_amount_egp': 100.0, 'label': '100 EGP'},
    {'points': 1500, 'cash_amount_egp': 150.0, 'label': '150 EGP'},
    {'points': 2000, 'cash_amount_egp': 200.0, 'label': '200 EGP'},
  ];

  static const _fallbackProviders = [
    'vodafone_cash', 'orange_cash', 'etisalat_cash', 'instapay', 'other_wallet',
  ];

  // ── Provider label helpers ────────────────────────────────────────────────
  static const _providerLabels = {
    'vodafone_cash' : 'Vodafone Cash',
    'orange_cash'   : 'Orange Cash',
    'etisalat_cash' : 'Etisalat Cash',
    'instapay'      : 'InstaPay',
    'other_wallet'  : 'Other Wallet',
  };

  static const _providerIcons = {
    'vodafone_cash' : Icons.phone_android,
    'orange_cash'   : Icons.phone_android,
    'etisalat_cash' : Icons.phone_android,
    'instapay'      : Icons.account_balance,
    'other_wallet'  : Icons.wallet,
  };

  static const _providerColors = {
    'vodafone_cash' : Color(0xFFE60000),
    'orange_cash'   : Color(0xFFFF7900),
    'etisalat_cash' : Color(0xFF009900),
    'instapay'      : Color(0xFF0A3D91),
    'other_wallet'  : Color(0xFF607D8B),
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 2) {
        _loadHistory();
      }
    });
    _initialLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _walletNumberController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Data Loading
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _initialLoad() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();

    // Load points summary + tiers in parallel
    final results = await Future.wait([
      userProvider.loadPointsSummary(),
      userProvider.getCashTiers(),
    ]);

    final tiersData = results[1] as Map<String, dynamic>?;

    if (mounted) {
      setState(() {
        if (tiersData != null && tiersData.isNotEmpty) {
          final rawTiers = tiersData['tiers'] as List?;
          _tiers = rawTiers?.map((e) => e as Map<String, dynamic>).toList()
              ?? _fallbackTiers;

          final rawProviders = tiersData['wallet_providers'] as List?;
          _walletProviders = rawProviders?.map((e) => e as String).toList()
              ?? _fallbackProviders;

          _pointsPerEgp = (tiersData['points_per_egp'] as num?)?.toInt() ?? 10;
        } else {
          _tiers = _fallbackTiers;
          _walletProviders = _fallbackProviders;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    if (!mounted || _isLoadingHistory) return;
    setState(() => _isLoadingHistory = true);

    final userProvider = context.read<UserProvider>();
    final results = await Future.wait([
      userProvider.getPointsHistory(),
      userProvider.getRedemptions(),
    ]);

    if (mounted) {
      setState(() {
        _pointsHistory = results[0] as List<Map<String, dynamic>>;
        _redemptionsHistory = results[1] as List<Map<String, dynamic>>;
        _isLoadingHistory = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cash-Out Actions
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _submitRedemption() async {
    if (_selectedTier == null) {
      AppMessenger.showError('Please select a payout amount.');
      return;
    }
    if (_selectedProvider == null) {
      AppMessenger.showError('Please select a wallet provider.');
      return;
    }
    final walletNumber = _walletNumberController.text.trim();
    if (walletNumber.isEmpty) {
      AppMessenger.showError('Please enter your wallet number.');
      return;
    }

    final userProvider = context.read<UserProvider>();
    final currentPoints = userProvider.backendUser?.recoveryPoints ?? 0;
    final tierPoints = (_selectedTier!['points'] as num).toInt();
    final tierEgp = (_selectedTier!['cash_amount_egp'] as num).toDouble();

    if (currentPoints < tierPoints) {
      AppMessenger.showError(
          'Insufficient points. You need $tierPoints pts but only have $currentPoints pts.');
      return;
    }

    // Confirm dialog
    final confirmed = await _showConfirmDialog(tierPoints, tierEgp, _selectedProvider!, walletNumber);
    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    final result = await userProvider.redeemCash(
      tierPoints:     tierPoints,
      walletProvider: _selectedProvider!,
      walletNumber:   walletNumber,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result != null) {
        _walletNumberController.clear();
        setState(() {
          _selectedTier     = null;
          _selectedProvider = null;
        });
        _showSuccessDialog(tierEgp, _selectedProvider ?? '');
        _tabController.animateTo(2); // go to history tab
        _loadHistory();
      } else {
        AppMessenger.showError('Redemption failed. Please try again.');
      }
    }
  }

  Future<bool> _showConfirmDialog(
      int points, double egp, String provider, String number) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Confirm Redemption'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _confirmRow('Amount', '$points points → $egp EGP'),
                _confirmRow('Wallet', _providerLabels[provider] ?? provider),
                _confirmRow('Number', number),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Text(
                    'Points will be deducted immediately. '
                    'Payout will be processed by our team within 1–3 business days.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D91),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _showSuccessDialog(double egp, String provider) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 44),
              ),
              const SizedBox(height: 20),
              const Text('Request Submitted!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                '$egp EGP will be sent to your ${_providerLabels[provider] ?? provider} wallet '
                'within 1–3 business days.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A3D91),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Great!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final points = userProvider.backendUser?.recoveryPoints ?? 0;
    final summary = userProvider.pointsSummary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Points Wallet'),
        backgroundColor: const Color(0xFF0A3D91),
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                // ── Header Card ────────────────────────────────────────────
                _buildHeader(points, summary),

                // ── Tab Bar ────────────────────────────────────────────────
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF0A3D91),
                    labelColor: const Color(0xFF0A3D91),
                    unselectedLabelColor: Colors.grey,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Wallet'),
                      Tab(text: 'Cash Out'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),

                // ── Tab Views ──────────────────────────────────────────────
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A3D91)))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildWalletTab(points),
                            _buildCashOutTab(points),
                            _buildHistoryTab(),
                          ],
                        ),
                ),
              ],
            ),
          ),

          // ── Submission overlay ────────────────────────────────────────
          if (_isSubmitting)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFA500)),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(int points, PointsSummary? summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0A3D91),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stars_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recovery Points',
                          style: TextStyle(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('$points pts',
                          style: const TextStyle(
                              fontSize: 30,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5)),
                      Text(
                        '≈ ${(points / _pointsPerEgp).toStringAsFixed(1)} EGP cash value',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Summary stats row
          if (summary != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip('Earned', '+${summary.totalEarned} pts', Colors.green.shade300),
                _statChip('Redeemed', '-${summary.totalRedeemed} pts', Colors.red.shade300),
                _statChip('Pending', '${summary.pendingRedemptions} req', Colors.orange.shade300),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab 1 — Wallet (info + tier cards)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildWalletTab(int currentPoints) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // How points work
        _sectionCard(
          icon: Icons.info_outline,
          title: 'How Points Work',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _BulletItem('Every successful recovery distributes 100 points'),
              _BulletItem('Finder (person who returned the item) gets 70 pts'),
              _BulletItem('Owner (person who lost the item) gets 30 pts'),
              _BulletItem('Points never expire'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Conversion rate
        _sectionCard(
          icon: Icons.currency_exchange,
          title: 'Cash Conversion Rate',
          content: Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 6),
              Text('$_pointsPerEgp points',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text(' = ', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const Text('1 EGP',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Cash Redemption Tiers',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF0A3D91))),
        const SizedBox(height: 10),

        ..._tiers.map((tier) {
          final pts = (tier['points'] as num).toInt();
          final egp = (tier['cash_amount_egp'] as num).toDouble();
          final canAfford = currentPoints >= pts;
          return _TierCard(
            points: pts,
            egp: egp,
            canAfford: canAfford,
            onCashOut: canAfford
                ? () {
                    setState(() => _selectedTier = tier);
                    _tabController.animateTo(1);
                  }
                : null,
          );
        }).toList(),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0A3D91)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0A3D91))),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab 2 — Cash Out form
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCashOutTab(int currentPoints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Step 1: Select tier ────────────────────────────────────────
          _stepLabel('Step 1', 'Choose Payout Amount'),
          const SizedBox(height: 10),
          ..._tiers.map((tier) {
            final pts = (tier['points'] as num).toInt();
            final egp = (tier['cash_amount_egp'] as num).toDouble();
            final canAfford = currentPoints >= pts;
            final isSelected = _selectedTier?['points'] == tier['points'];

            return GestureDetector(
              onTap: canAfford ? () => setState(() => _selectedTier = tier) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0A3D91)
                      : canAfford
                          ? Colors.white
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0A3D91)
                        : canAfford
                            ? Colors.grey.shade200
                            : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF0A3D91).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: isSelected
                          ? Colors.white
                          : canAfford
                              ? const Color(0xFF0A3D91)
                              : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$pts pts → $egp EGP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected
                              ? Colors.white
                              : canAfford
                                  ? Colors.black87
                                  : Colors.grey,
                        ),
                      ),
                    ),
                    if (!canAfford)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Need ${pts - currentPoints} more',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.white, size: 22),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          // ── Step 2: Select wallet provider ─────────────────────────────
          _stepLabel('Step 2', 'Select Wallet Provider'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: _walletProviders.map((provider) {
              final isSelected = _selectedProvider == provider;
              final color = _providerColors[provider] ?? Colors.grey;
              final icon = _providerIcons[provider] ?? Icons.wallet;
              final label = _providerLabels[provider] ?? provider;

              return GestureDetector(
                onTap: () => setState(() => _selectedProvider = provider),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? color : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── Step 3: Wallet number ──────────────────────────────────────
          _stepLabel('Step 3', 'Enter Wallet Number'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _walletNumberController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
              decoration: const InputDecoration(
                hintText: 'e.g. 01012345678',
                prefixIcon: Icon(Icons.phone, color: Color(0xFF0A3D91)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Submit button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitRedemption,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Submit Redemption Request',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A3D91),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),

          const SizedBox(height: 12),
          Center(
            child: Text(
              'Payouts are processed manually within 1–3 business days.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _stepLabel(String step, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0A3D91),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(step,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab 3 — History (redemptions + points log)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Color(0xFF0A3D91),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF0A3D91),
              indicatorWeight: 2,
              labelStyle: TextStyle(fontSize: 13),
              tabs: [
                Tab(text: 'Redemptions'),
                Tab(text: 'Points Log'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRedemptionsTab(),
                _buildPointsLogTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionsTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_redemptionsHistory.isEmpty) {
      return _emptyState(Icons.account_balance_wallet_outlined, 'No redemption requests yet');
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _redemptionsHistory.length,
        itemBuilder: (context, index) {
          final item = _redemptionsHistory[index];
          final pts  = (item['points_spent'] as num?)?.toInt() ?? 0;
          final egp  = (item['cash_amount_egp'] as num?)?.toDouble() ?? 0.0;
          final provider = item['wallet_provider'] as String? ?? '';
          final maskedNum = item['wallet_number_masked'] as String? ?? '***';
          final status  = item['status'] as String? ?? 'pending';
          final reason  = item['failure_reason'] as String?;
          final paidAt  = item['paid_at'] != null
              ? DateTime.tryParse(item['paid_at'].toString())
              : null;
          final createdAt = item['created_at'] != null
              ? DateTime.tryParse(item['created_at'].toString())
              : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_statusIcon(status), color: _statusColor(status), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$egp EGP via ${_providerLabels[provider] ?? provider}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('$pts pts deducted • $maskedNum',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    _StatusBadge(status: status),
                  ],
                ),
                if (reason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(reason,
                              style: const TextStyle(fontSize: 12, color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      createdAt != null
                          ? 'Requested: ${createdAt.day}/${createdAt.month}/${createdAt.year}'
                          : 'Recent request',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    if (paidAt != null)
                      Text(
                        'Paid: ${paidAt.day}/${paidAt.month}/${paidAt.year}',
                        style: const TextStyle(fontSize: 11, color: Colors.green),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPointsLogTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pointsHistory.isEmpty) {
      return _emptyState(Icons.history_toggle_off, 'No points transactions yet');
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pointsHistory.length,
        itemBuilder: (context, index) {
          final item   = _pointsHistory[index];
          final pts    = (item['points'] as num?)?.toInt() ?? 0;
          final label  = item['reason_label'] as String? ?? item['reason'] ?? '';
          final post   = item['post'] as Map<String, dynamic>?;
          final date   = item['created_at'] != null
              ? DateTime.tryParse(item['created_at'].toString())
              : null;
          final isGain = pts > 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isGain ? Colors.amber.shade50 : Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isGain ? Icons.add_circle_outline : Icons.remove_circle_outline,
                    color: isGain ? Colors.orange : Colors.red,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      if (post != null)
                        Text('"${post['title']}"',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      Text(
                        date != null
                            ? '${date.day}/${date.month}/${date.year}'
                            : 'Recent',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isGain ? "+" : ""}$pts pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isGain ? const Color(0xFF2E7D32) : Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':   return Colors.orange;
      case 'approved':  return Colors.blue;
      case 'paid':      return Colors.green;
      case 'rejected':  return Colors.red;
      case 'cancelled': return Colors.grey;
      default:          return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':   return Icons.hourglass_empty;
      case 'approved':  return Icons.thumb_up_outlined;
      case 'paid':      return Icons.check_circle_outline;
      case 'rejected':  return Icons.cancel_outlined;
      case 'cancelled': return Icons.block;
      default:          return Icons.help_outline;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF0A3D91))),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final int points;
  final double egp;
  final bool canAfford;
  final VoidCallback? onCashOut;

  const _TierCard({
    required this.points,
    required this.egp,
    required this.canAfford,
    this.onCashOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canAfford ? Colors.grey.shade200 : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canAfford
                    ? [const Color(0xFF0A3D91), const Color(0xFF1565C0)]
                    : [Colors.grey.shade300, Colors.grey.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${egp.toStringAsFixed(0)} EGP Cash',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: canAfford ? Colors.black87 : Colors.grey,
                  ),
                ),
                Text(
                  '$points points required',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onCashOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? const Color(0xFF0A3D91) : Colors.grey.shade300,
              foregroundColor: canAfford ? Colors.white : Colors.grey.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
            child: const Text('Redeem', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> colors = {
      'pending'   : Colors.orange,
      'approved'  : Colors.blue,
      'paid'      : Colors.green,
      'rejected'  : Colors.red,
      'cancelled' : Colors.grey,
    };
    final color = colors[status] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
