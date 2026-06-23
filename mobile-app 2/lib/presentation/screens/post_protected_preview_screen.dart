import 'package:flutter/material.dart';
import '../../data/models/feed_post_model.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../widgets/claim_request_modal.dart';

/// Protected post preview for non-matched, non-authorized users.
/// Shows safe data only — no images, no sensitive details.
/// Authorized users (accepted request / owner) are redirected to PostDetailScreen.
class PostProtectedPreviewScreen extends StatefulWidget {
  final FeedPost post;

  const PostProtectedPreviewScreen({super.key, required this.post});

  @override
  State<PostProtectedPreviewScreen> createState() => _PostProtectedPreviewScreenState();
}

class _PostProtectedPreviewScreenState extends State<PostProtectedPreviewScreen> {
  static const Color _primary = Color(0xFF0A3D91);
  String _requestStatus = 'none'; // 'none' | 'pending' | 'accepted' | 'rejected'
  bool _checkingAccess = true;

  @override
  void initState() {
    super.initState();
    _checkAccessStatus();
  }

  Future<void> _checkAccessStatus() async {
    try {
      final apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
      final ds = ChatRemoteDataSourceImpl(apiClient: apiClient);
      final data = await ds.checkRequestStatus(widget.post.id);
      if (!mounted) return;
      final status = data['status'] as String? ?? 'none';
      setState(() { _requestStatus = status; _checkingAccess = false; });

      // If accepted → redirect to full PostDetailScreen immediately
      if (status == 'accepted') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/post-detail', arguments: {
              'postId': widget.post.id,
              'userId': widget.post.userId,
              'title': widget.post.title,
              'category': widget.post.category,
              'timeAgo': widget.post.timeAgo,
              'posterName': 'Post Owner',
              'isVerified': widget.post.ownerVerified,
              'description': widget.post.description,
              'location': widget.post.roughLocation,
              'status': widget.post.postType,
              'matchPercentage': 0,
            });
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkingAccess = false);
    }
  }

  static IconData _categoryIcon(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'wallet': return Icons.account_balance_wallet_rounded;
      case 'phone': return Icons.smartphone_rounded;
      case 'keys': return Icons.key_rounded;
      case 'bag': return Icons.backpack_rounded;
      case 'electronics': return Icons.devices_rounded;
      case 'documents': return Icons.description_rounded;
      case 'jewelry': return Icons.diamond_rounded;
      case 'clothing': return Icons.checkroom_rounded;
      default: return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isLost = post.isLost;
    final badgeColor = isLost ? const Color(0xFFE53935) : const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Incident Report', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: _checkingAccess
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Category Icon Hero ──────────────────────────────────────
                Center(
                  child: Column(children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(color: _primary.withOpacity(0.08), borderRadius: BorderRadius.circular(24)),
                      child: Icon(_categoryIcon(post.category), color: _primary, size: 50),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(isLost ? 'LOST ITEM' : 'FOUND ITEM', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1)),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // ── Title ───────────────────────────────────────────────────
                Text(post.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 8),
                if (post.description != null && post.description!.isNotEmpty)
                  Text(post.description!, style: const TextStyle(fontSize: 15, color: Color(0xFF666666), height: 1.5)),
                const SizedBox(height: 20),

                // ── Meta row ────────────────────────────────────────────────
                Row(children: [
                  _metaChip(Icons.location_on_rounded, post.roughLocation),
                  const SizedBox(width: 10),
                  _metaChip(Icons.access_time_rounded, post.timeAgo),
                  if (post.ownerVerified) ...[const SizedBox(width: 10), _metaChip(Icons.verified_rounded, 'Verified', color: _primary)],
                ]),
                const SizedBox(height: 24),

                // ── Protected Notice ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _primary.withOpacity(0.15)),
                  ),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.shield_rounded, color: _primary, size: 20),
                      SizedBox(width: 8),
                      Text('Details Protected', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primary)),
                    ]),
                    SizedBox(height: 6),
                    Text('Item photos and sensitive details are hidden to protect the owner. Verify your identity to gain full access.', style: TextStyle(fontSize: 13, color: Color(0xFF555577), height: 1.5)),
                  ]),
                ),
                const SizedBox(height: 32),

                // ── Request Status / Action ─────────────────────────────────
                if (_requestStatus == 'pending')
                  _statusBanner(Icons.hourglass_top_rounded, 'Request Pending', 'The owner is reviewing your answers. Please wait.', const Color(0xFFFFF3CD), const Color(0xFF856404))
                else if (_requestStatus == 'rejected')
                  _statusBanner(Icons.cancel_rounded, 'Access Denied', 'Your request was not approved. You may send a new request.', const Color(0xFFFFE4E4), Colors.red)
                else
                  const SizedBox.shrink(),
              ]),
            ),
      bottomNavigationBar: _checkingAccess || _requestStatus == 'pending'
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))]),
              child: SafeArea(child: SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    ClaimRequestModal.show(context, postId: post.id, receiverId: post.userId, onRequestSent: () {
                      setState(() => _requestStatus = 'pending');
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.lock_open_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Request Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
                ),
              )),
            ),
    );
  }

  Widget _metaChip(IconData icon, String label, {Color color = const Color(0xFF666666)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500))]),
    );
  }

  Widget _statusBanner(IconData icon, String title, String body, Color bg, Color fg) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: fg, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: fg, fontSize: 14)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(color: fg.withOpacity(0.85), fontSize: 12, height: 1.4)),
        ])),
      ]),
    );
  }
}
