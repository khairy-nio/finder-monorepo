import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../data/datasources/post_remote_data_source.dart';
import '../../core/utils/app_messenger.dart';

class ClaimRequestModal extends StatefulWidget {
  final String postId;
  final String receiverId;
  final VoidCallback? onRequestSent;

  const ClaimRequestModal({super.key, required this.postId, required this.receiverId, this.onRequestSent});

  static Future<void> show(BuildContext context, {required String postId, required String receiverId, VoidCallback? onRequestSent}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClaimRequestModal(postId: postId, receiverId: receiverId, onRequestSent: onRequestSent),
    );
  }

  @override
  State<ClaimRequestModal> createState() => _ClaimRequestModalState();
}

class _ClaimRequestModalState extends State<ClaimRequestModal> {
  static const Color _primary = Color(0xFF0A3D91);
  List<Map<String, dynamic>> _questions = [];
  final List<TextEditingController> _answerCtrls = [];
  final TextEditingController _introCtr = TextEditingController();
  bool _loadingQ = true;
  bool _sending = false;
  String? _error;
  late PostRemoteDataSourceImpl _ds;

  @override
  void initState() {
    super.initState();
    _ds = PostRemoteDataSourceImpl(apiClient: ApiClient(tokenProvider: AuthService.instance.getIdToken));
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final qs = await _ds.getVerificationQuestions(widget.postId);
      if (mounted) setState(() { _questions = qs; _answerCtrls.addAll(qs.map((_) => TextEditingController())); _loadingQ = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingQ = false);
    }
  }

  Future<void> _submit() async {
    if (_questions.isNotEmpty) {
      for (final c in _answerCtrls) {
        if (c.text.trim().isEmpty) { AppMessenger.showError('Please answer all questions.'); return; }
      }
    }
    setState(() => _sending = true);
    try {
      final answers = List.generate(_questions.length, (i) => {'questionId': _questions[i]['id'], 'answer': _answerCtrls[i].text.trim()});
      await _ds.sendClaimRequest(receiverId: widget.receiverId, postId: widget.postId, introMessage: _introCtr.text.trim(), verificationAnswers: answers.isEmpty ? null : answers);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onRequestSent?.call();
      AppMessenger.showSuccess('Request sent! The owner will review your answers.');
    } catch (e) {
      if (mounted) setState(() { _sending = false; _error = e.toString().replaceFirst('ServerException: ', ''); });
    }
  }

  @override
  void dispose() { _introCtr.dispose(); for (final c in _answerCtrls) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.lock_open_rounded, color: _primary, size: 22)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Request Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                SizedBox(height: 2),
                Text('Answer the owner\'s questions to verify your claim.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ])),
              IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(height: 24),
          Expanded(
            child: _loadingQ ? const Center(child: CircularProgressIndicator(color: _primary)) : ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.4))),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF856404)),
                    SizedBox(width: 8),
                    Expanded(child: Text('Your answers will be reviewed by the post owner. Correct answers may grant access.', style: TextStyle(fontSize: 12, color: Color(0xFF856404), height: 1.4))),
                  ]),
                ),
                const SizedBox(height: 20),
                if (_questions.isNotEmpty) ...[
                  const Text('Verification Questions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 12),
                  ...List.generate(_questions.length, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${i + 1}. ${_questions[i]['question']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D))),
                      const SizedBox(height: 6),
                      TextField(controller: _answerCtrls[i], maxLength: 255, decoration: InputDecoration(
                        hintText: 'Your answer...', counterText: '', filled: true, fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      )),
                    ]),
                  )),
                ],
                const Text('Additional Message (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 8),
                TextField(controller: _introCtr, maxLength: 255, maxLines: 3, decoration: InputDecoration(
                  hintText: 'Add any extra context for the owner...', filled: true, fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                )),
                if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))],
                const SizedBox(height: 24),
              ],
            ),
          ),
          SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: _sending ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, disabledBackgroundColor: _primary.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: _sending ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.send_rounded, size: 18), SizedBox(width: 8), Text('Send Claim Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))]),
            )),
          )),
        ]),
      ),
    );
  }
}
