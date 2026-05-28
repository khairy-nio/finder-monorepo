import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../../core/utils/app_messenger.dart';

class RewardsCatalogScreen extends StatefulWidget {
  const RewardsCatalogScreen({super.key});

  @override
  State<RewardsCatalogScreen> createState() => _RewardsCatalogScreenState();
}

class _RewardsCatalogScreenState extends State<RewardsCatalogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRedeeming = false;
  List<Map<String, dynamic>> _pointsHistory = [];
  List<Map<String, dynamic>> _redemptionsHistory = [];
  bool _isLoadingHistory = false;

  final List<Map<String, dynamic>> _rewards = [
    {
      'id': 'amazon_10',
      'title': 'Amazon Gift Card \$10',
      'description': 'Digital gift card code sent to your email instantly.',
      'cost': 100,
      'icon': Icons.card_giftcard,
      'gradient': [Color(0xFFFF9900), Color(0xFFFF5500)],
    },
    {
      'id': 'amazon_25',
      'title': 'Amazon Gift Card \$25',
      'description': 'High value digital gift card code for any purchases.',
      'cost': 220,
      'icon': Icons.card_giftcard,
      'gradient': [Color(0xFF232F3E), Color(0xFF146B93)],
    },
    {
      'id': 'carrefour_50',
      'title': 'Carrefour Coupon',
      'description': 'Shopping coupon valid at any Carrefour physical store.',
      'cost': 80,
      'icon': Icons.shopping_cart_outlined,
      'gradient': [Color(0xFF003087), Color(0xFF0079C1)],
    },
    {
      'id': 'gold_badge',
      'title': 'Gold Contributor Badge',
      'description': 'Permanent glowing gold badge shown on your public profile.',
      'cost': 40,
      'icon': Icons.stars_sharp,
      'gradient': [Color(0xFFFFD700), Color(0xFFFFA500)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);
    final userProvider = context.read<UserProvider>();
    final history = await userProvider.getPointsHistory();
    final redemptions = await userProvider.getRedemptions();
    if (mounted) {
      setState(() {
        _pointsHistory = history;
        _redemptionsHistory = redemptions;
        _isLoadingHistory = false;
      });
    }
  }

  void _triggerRedeem(Map<String, dynamic> reward) {
    final userProvider = context.read<UserProvider>();
    final userPoints = userProvider.backendUser?.recoveryPoints ?? 0;

    if (userPoints < reward['cost']) {
      AppMessenger.showError(
        'Insufficient points. You need ${reward['cost']} Pts but only have $userPoints Pts.'
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Redeem ${reward['title']}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will deduct ${reward['cost']} points from your account balance.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                reward['description'],
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _processRedemption(reward['id'], reward['title']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processRedemption(String rewardId, String rewardTitle) async {
    setState(() => _isRedeeming = true);
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.redeemReward(rewardId);

    if (mounted) {
      setState(() => _isRedeeming = false);
      if (success) {
        // Show points spend success dialog with nice visual design
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Redemption Successful!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have successfully claimed $rewardTitle.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A3D91),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Awesome'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        _loadHistory(); // Refresh history tab data
      } else {
        AppMessenger.showError('Redemption failed. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final points = userProvider.backendUser?.recoveryPoints ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Rewards & Leaderboard'),
        backgroundColor: const Color(0xFF0A3D91),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Point Balance Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A3D91),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recovery Points Balance',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 4),
                            Text(
                              '$points Pts',
                              style: const TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // TabBar
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF0A3D91),
                labelColor: const Color(0xFF0A3D91),
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Catalog'),
                  Tab(text: 'My Claims'),
                  Tab(text: 'Points Log'),
                ],
              ),

              // TabView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCatalogTab(points),
                    _buildClaimsTab(),
                    _buildPointsLogTab(),
                  ],
                ),
              ),
            ],
          ),
          if (_isRedeeming)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFA500)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCatalogTab(int currentPoints) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rewards.length,
      itemBuilder: (context, index) {
        final reward = _rewards[index];
        final canAfford = currentPoints >= reward['cost'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon block with gradient
                Container(
                  width: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: reward['gradient'],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Icon(reward['icon'], color: Colors.white, size: 36),
                ),
                // Text details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          reward['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reward['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${reward['cost']} Pts',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _triggerRedeem(reward),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canAfford ? const Color(0xFF0A3D91) : Colors.grey.shade300,
                                foregroundColor: canAfford ? Colors.white : Colors.grey.shade600,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Redeem'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClaimsTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_redemptionsHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No rewards claimed yet',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _redemptionsHistory.length,
      itemBuilder: (context, index) {
        final item = _redemptionsHistory[index];
        final title = item['reward_title'] ?? 'Digital Reward';
        final cost = item['points_spent'] ?? 0;
        final date = item['created_at'] != null 
            ? DateTime.tryParse(item['created_at'].toString()) 
            : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date != null ? '${date.day}/${date.month}/${date.year}' : 'Recent',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Text(
                '-$cost Pts',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPointsLogTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pointsHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No points logs yet',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pointsHistory.length,
      itemBuilder: (context, index) {
        final item = _pointsHistory[index];
        final points = item['points'] ?? 0;
        final reason = item['reason'] ?? 'Community assistance';
        final isAddition = points > 0;
        final post = item['associatedPost'];
        final postTitle = post != null ? post['title'] : null;

        String displayTitle = '';
        if (reason == 'successful_recovery') {
          displayTitle = postTitle != null ? 'Successful recovery: "$postTitle"' : 'Successful resolution reward';
        } else if (reason.startsWith('redeem_')) {
          displayTitle = 'Redeemed reward';
        } else {
          displayTitle = reason.replaceAll('_', ' ').toUpperCase();
        }

        final date = item['created_at'] != null 
            ? DateTime.tryParse(item['created_at'].toString()) 
            : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isAddition ? Colors.amber.shade50 : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAddition ? Icons.star : Icons.shopping_bag,
                  color: isAddition ? Colors.orange : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date != null ? '${date.day}/${date.month}/${date.year}' : 'Recent',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Text(
                '${isAddition ? "+" : ""}$points Pts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAddition ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}



