import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../widgets/custom_rounded_button.dart';
import '../widgets/custom_text_field.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/app_messenger.dart';

/// KYC Verification Screen
class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _idImage;
  File? _selfieImage;

  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _idController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _captureLocationMetadata() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallbackToIpLocation();
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallbackToIpLocation();
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return _fallbackToIpLocation();
      } 

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return {
          'city': place.locality ?? 'Unknown',
          'country': place.country ?? 'Unknown',
          'source': 'gps',
        };
      }
    } catch (e) {
      debugPrint('GPS Capture failed: $e');
    }
    return _fallbackToIpLocation();
  }

  Future<Map<String, String>> _fallbackToIpLocation() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'city': data['city'] ?? 'Unknown',
          'country': data['country'] ?? 'Unknown',
          'source': 'ip',
        };
      }
    } catch (e) {
      debugPrint('IP Capture failed: $e');
    }
    return {
      'city': 'Unknown',
      'country': 'Unknown',
      'source': 'device',
    };
  }

  Future<void> _pickImage(bool isSelfie) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: isSelfie ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: isSelfie ? CameraDevice.front : CameraDevice.rear,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        if (isSelfie) {
          _selfieImage = File(pickedFile.path);
        } else {
          _idImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idImage == null) {
      AppMessenger.showError('National ID photo is required.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final locationMetadata = await _captureLocationMetadata();
      final locationString = jsonEncode(locationMetadata);

      final token = await AuthService.instance.getIdToken();
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.submitVerificationEndpoint}',
      );

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['national_id'] = _idController.text.trim()
        ..fields['phone'] = _phoneController.text.trim()
        ..fields['verification_location'] = locationString
        ..files.add(
          await http.MultipartFile.fromPath('id_image', _idImage!.path),
        );

      if (_selfieImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('selfie_image', _selfieImage!.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
          AppMessenger.showSuccess(
            'Verification submitted! We will review your documents.',
          );
        }
      } else {
        setState(() => _isLoading = false);
        AppMessenger.showError('Submission failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppMessenger.showError('Submission failed. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessView();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A3D91),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Identity Verification',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 48), // Balancing space for back button
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To keep our platform safe, please verify your identity.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Form Fields
                CustomTextField(
                  label: 'National ID Number',
                  hint: 'Enter your 14-digit ID',
                  controller: _idController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'National ID is required';
                    }
                    if (value.length != 14) {
                      return 'ID must be exactly 14 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                CustomTextField(
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.length < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Upload National ID Photo (REQUIRED)
                Row(
                  children: [
                    const Text(
                      'National ID Photo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(Required)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildImagePickerBox(
                  imageFile: _idImage,
                  label: 'Upload ID Card',
                  icon: Icons.credit_card,
                  onTap: () => _pickImage(false),
                  isRequired: true,
                ),

                const SizedBox(height: 32),

                // Upload Personal Photo (OPTIONAL)
                Row(
                  children: [
                    const Text(
                      'Personal Photo (Selfie)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(Optional)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildImagePickerBox(
                  imageFile: _selfieImage,
                  label: 'Take a Selfie',
                  icon: Icons.face_retouching_natural,
                  onTap: () => _pickImage(true),
                  isRequired: false,
                ),

                const SizedBox(height: 48),

                // Submit Button
                CustomRoundedButton(
                  text: _isLoading ? 'Submitting...' : 'Submit Verification',
                  onPressed: _isLoading ? () {} : _submitVerification,
                  backgroundColor: const Color(0xFF0A3D91),
                  prefixWidget: _isLoading 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        ) 
                      : null,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/support');
                    },
                    child: const Text(
                      'Having trouble verifying? Visit Help Center',
                      style: TextStyle(
                        color: Color(0xFF0A3D91),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerBox({
    required File? imageFile,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: imageFile != null 
                ? const Color(0xFF0A3D91) 
                : (isRequired ? Colors.red.shade200 : Colors.grey[300]!),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A3D91).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: const Color(0xFF0A3D91), size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF0A3D91),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to select image',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verification Submitted!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your documents are under review.\nYou will be notified once approved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
