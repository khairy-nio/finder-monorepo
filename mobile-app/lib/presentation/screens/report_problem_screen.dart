import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/app_messenger.dart';


/// Report a Problem Screen
class ReportProblemScreen extends StatefulWidget {
  final String reportType;
  final String? targetId;
  final String? targetName;

  const ReportProblemScreen({
    super.key,
    this.reportType = 'general_support',
    this.targetId,
    this.targetName,
  });

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedOption;
  bool _isLoading = false;

  List<String> get _options {
    switch (widget.reportType) {
      case 'user':
        return [
          'Scam or fraudulent behavior',
          'Fake ownership claim',
          'Suspicious activity',
          'Harassment or abusive behavior',
          'Spam requests/messages',
          'Attempted theft',
          'Inappropriate communication',
          'Impersonation',
          'Asking for payment suspiciously',
          'Refusing verification process',
          'Other',
        ];
      case 'post':
        return [
          'Fake lost/found item',
          'Duplicate listing',
          'Incorrect category',
          'Misleading information',
          'Suspicious ownership claim',
          'Inappropriate images',
          'Spam post',
          'Item already returned',
          'Fraudulent reward claim',
          'Other',
        ];
      case 'message':
      case 'chat':
        return [
          'Harassment',
          'Spam',
          'Scam attempt',
          'Threatening behavior',
          'Inappropriate content',
          'Fake ownership negotiation',
          'Payment scam attempt',
          'Other',
        ];
      case 'general_support':
      default:
        return [
          'App bug',
          'Notification issue',
          'Chat issue',
          'Verification issue',
          'Report system issue',
          'Performance issue',
          'Account issue',
          'UI problem',
          'Other',
        ];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate() && _selectedOption != null) {
      if (widget.reportType != 'general_support' && widget.targetId == null) {
        AppMessenger.showError('Reporting requires a specific target.');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final apiClient = ApiClient(
          tokenProvider: AuthService.instance.getIdToken,
        );

        final note = '${_titleController.text.trim()} - ${_descriptionController.text.trim()}';

        final body = <String, dynamic>{
          'reportType': widget.reportType,
          'reason': _selectedOption,
          'note': note,
        };

        if (widget.reportType == 'user') {
          body['reported_user_id'] = widget.targetId;
        } else if (widget.reportType == 'post') {
          body['reported_post_id'] = widget.targetId;
        } else if (widget.reportType == 'message') {
          body['reported_message_id'] = widget.targetId;
        } else if (widget.reportType == 'chat') {
          body['reported_chat_id'] = widget.targetId;
        }

        await apiClient.post(
          ApiConstants.createReportEndpoint,
          body: body,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          AppMessenger.showSuccess('Report submitted successfully!');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppMessenger.showError(e.toString());
        }
      }
    } else if (_selectedOption == null) {
      AppMessenger.showError('Please select a reason');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isVerified = userProvider.backendUser?.verified ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A3D91),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Report a Problem',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: !isVerified
          ? _buildUnverifiedLock(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    if (widget.targetName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.report_gmailerrorred, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Reporting: ${widget.targetName}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // I would like to dropdown
                    const Text(
                      'I would like to',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedOption,
                          isExpanded: true,
                          hint: const Text(
                            'Select an option',
                            style: TextStyle(color: Colors.grey),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                          items: _options.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedOption = value;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title field
                    const Text(
                      'Title',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A3D91),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter a title',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0A3D91),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Description field
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A3D91),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: 'Please describe the problem',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0A3D91),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe the problem';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 40),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A3D91),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: const Color(0xFF0A3D91).withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUnverifiedLock(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0A3D91).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gpp_maybe,
                size: 80,
                color: Color(0xFF0A3D91),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Account Verification Required',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'To maintain a safe and trustworthy community, you must verify your identity before submitting a report.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/kyc-verification');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D91),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Verify My Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
