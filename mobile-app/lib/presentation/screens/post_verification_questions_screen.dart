import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../data/datasources/post_remote_data_source.dart';
import '../../core/utils/app_messenger.dart';

/// Screen for post owners to set 3–10 verification questions.
/// Accessible from MyPostsScreen via "Set Verification Questions".
class PostVerificationQuestionsScreen extends StatefulWidget {
  final String postId;
  final String postTitle;

  const PostVerificationQuestionsScreen({super.key, required this.postId, required this.postTitle});

  @override
  State<PostVerificationQuestionsScreen> createState() => _PostVerificationQuestionsScreenState();
}

class _PostVerificationQuestionsScreenState extends State<PostVerificationQuestionsScreen> {
  static const Color _primary = Color(0xFF0A3D91);

  final List<TextEditingController> _ctrls = [];
  bool _loading = true;
  bool _saving = false;
  late PostRemoteDataSourceImpl _ds;

  final List<String> _suggestions = [
    'What color is the item?',
    'Any identifying marks or scratches?',
    'What was inside the bag/wallet?',
    'What is the brand of the item?',
    'Any hidden detail only the owner would know?',
    'Where exactly was it last seen?',
  ];

  @override
  void initState() {
    super.initState();
    _ds = PostRemoteDataSourceImpl(apiClient: ApiClient(tokenProvider: AuthService.instance.getIdToken));
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final qs = await _ds.getVerificationQuestions(widget.postId);
      if (mounted) {
        setState(() {
          _ctrls.clear();
          for (final q in qs) {
            _ctrls.add(TextEditingController(text: q['question'] as String? ?? ''));
          }
          // If no questions exist, pre-populate 3 empty controllers to guide minimum layout
          if (_ctrls.isEmpty) {
            for (int i = 0; i < 3; i++) {
              _ctrls.add(TextEditingController());
            }
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ctrls.clear();
          for (int i = 0; i < 3; i++) {
            _ctrls.add(TextEditingController());
          }
          _loading = false;
        });
      }
    }
  }

  void _addQuestion() {
    if (_ctrls.length >= 10) {
      AppMessenger.showError('Maximum 10 questions allowed.');
      return;
    }
    setState(() => _ctrls.add(TextEditingController()));
  }

  void _removeQuestion(int i) {
    setState(() {
      _ctrls[i].dispose();
      _ctrls.removeAt(i);
    });
  }

  Future<void> _save() async {
    final questions = _ctrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    
    if (questions.isEmpty) {
      // Allow disabling by clearing questions
      await _clearAll();
      return;
    }

    if (questions.length < 3) {
      AppMessenger.showError('Please add at least 3 verification questions.');
      return;
    }

    if (questions.length > 10) {
      AppMessenger.showError('Maximum 10 questions allowed.');
      return;
    }

    if (questions.any((q) => q.length < 5)) {
      AppMessenger.showError('Each question must be at least 5 characters.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _ds.updateVerificationQuestions(widget.postId, questions.map((q) => {'question': q}).toList());
      if (!mounted) return;
      AppMessenger.showSuccess('Verification questions saved!');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppMessenger.showError('Failed to save: $e');
      }
    }
  }

  Future<void> _clearAll() async {
    setState(() => _saving = true);
    try {
      await _ds.updateVerificationQuestions(widget.postId, []);
      if (!mounted) return;
      AppMessenger.showSuccess('Questions cleared.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppMessenger.showError('Failed to clear: $e');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Verification Questions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info & Guidance Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_outline_rounded, color: _primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Security & Guidance',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'These questions are shown to users who request access to your post. Only you will see their answers. Ask questions only the real owner can answer.',
                          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Examples of good questions:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        ...[
                          '• What color was the item?',
                          '• Any identifying mark or scratch?',
                          '• What was inside the bag?',
                        ].map((ex) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                ex,
                                style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'For: ${widget.postTitle}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Suggestions chips section
                  const Text(
                    'Suggestions (Tap to fill first empty question):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _suggestions
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ActionChip(
                                label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primary)),
                                backgroundColor: Colors.white,
                                elevation: 1,
                                side: BorderSide(color: _primary.withOpacity(0.2)),
                                shadowColor: Colors.black.withOpacity(0.05),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onPressed: () {
                                  // Find first empty field, or add a new one if limit not reached
                                  TextEditingController? emptyCtrl;
                                  for (final c in _ctrls) {
                                    if (c.text.trim().isEmpty) {
                                      emptyCtrl = c;
                                      break;
                                    }
                                  }
                                  if (emptyCtrl != null) {
                                    setState(() => emptyCtrl!.text = s);
                                  } else if (_ctrls.length < 10) {
                                    setState(() => _ctrls.add(TextEditingController(text: s)));
                                  } else {
                                    AppMessenger.showError('Maximum 10 questions allowed.');
                                  }
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Questions list
                  ...List.generate(
                    _ctrls.length,
                    (i) => Padding(
                      key: ObjectKey(_ctrls[i]),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _ctrls[i],
                                maxLength: 200,
                                decoration: InputDecoration(
                                  hintText: i < _suggestions.length ? _suggestions[i] : 'Enter a question...',
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade100)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade100)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  counterStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                ),
                              ),
                            ),
                            if (_ctrls.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 6.0, top: 4.0),
                                child: IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                                  onPressed: () => _removeQuestion(i),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Validation warnings & Limits
                  const SizedBox(height: 8),
                  if (_ctrls.length < 3)
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please add at least 3 verification questions.',
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_ctrls.length >= 10)
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Maximum 10 questions allowed.',
                              style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Add button
                  if (_ctrls.length < 10) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _addQuestion,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primary.withOpacity(0.3), style: BorderStyle.solid),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: _primary.withOpacity(0.7), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Add Question (${_ctrls.length}/10)',
                              style: TextStyle(color: _primary.withOpacity(0.7), fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Save Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _saving ? null : _clearAll,
                      child: Text(
                        'Clear All Questions',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
