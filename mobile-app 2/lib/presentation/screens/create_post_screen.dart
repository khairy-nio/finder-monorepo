import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/constants/finder_colors.dart';
import '../widgets/map_location_picker.dart';
import '../../data/datasources/ai_matching_remote_data_source.dart';
import '../../core/utils/location_data.dart';
import '../widgets/location_autocomplete_field.dart';
import '../../core/services/auth_service.dart';
import '../../domain/entities/post.dart';
import '../../data/models/post_model.dart';
import '../../data/datasources/post_remote_data_source.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_messenger.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();

  final FocusNode _countryFocus = FocusNode();
  final FocusNode _stateFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _areaFocus = FocusNode();

  String _selectedCategory = 'Wallet';
  String _selectedType = 'Lost';
  File? _selectedImage;
  bool _isLoading = false;
  int _descriptionLength = 0; // Live character counter for 140-char limit

  // Backend data source
  late final AIMatchingRemoteDataSource _dataSource;

  final List<String> _categories = [
    'Wallet',
    'Phone',
    'Keys',
    'Bag',
    'Electronics',
    'Documents',
    'Jewelry',
    'Clothing',
    'Other',
  ];

  final List<String> _types = ['Lost', 'Found'];

  Post? _editPost;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _dataSource = AIMatchingRemoteDataSource(
      client: http.Client(),
      tokenProvider: AuthService.instance.getIdToken,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['editPost'] != null) {
        _editPost = args['editPost'] as Post;
        _titleController.text = _editPost!.title;
        _descriptionController.text = _editPost!.description ?? '';
        _countryController.text = _editPost!.country;
        _stateController.text = _editPost!.state ?? '';
        _cityController.text = _editPost!.city ?? '';
        
        final cat = _editPost!.category ?? 'Other';
        final matchedCat = _categories.firstWhere(
          (c) => c.toLowerCase() == cat.toLowerCase(), 
          orElse: () => 'Other'
        );
        _selectedCategory = matchedCat;
        
        final pType = _editPost!.postType.toLowerCase() == 'lost' ? 'Lost' : 'Found';
        _selectedType = pType;
      }
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _countryFocus.dispose();
    _stateFocus.dispose();
    _cityFocus.dispose();
    _areaFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FinderColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Image Source',
              style: TextStyle(
                color: FinderColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A3D91).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF0A3D91)),
              ),
              title: const Text(
                'Camera',
                style: TextStyle(color: FinderColors.textPrimary),
              ),
              subtitle: const Text(
                'Take a new photo',
                style: TextStyle(color: FinderColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A3D91).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF0A3D91),
                ),
              ),
              title: const Text(
                'Gallery',
                style: TextStyle(color: FinderColors.textPrimary),
              ),
              subtitle: const Text(
                'Choose from gallery',
                style: TextStyle(color: FinderColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null && _editPost == null) {
        AppMessenger.showError('Please add an image of the item');
        return;
      }

      setState(() => _isLoading = true);

      try {
        if (_editPost != null) {
          print('📤 Updating post...');

          final apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
          final postDs = PostRemoteDataSourceImpl(apiClient: apiClient);

          String newImageUrl = _editPost!.imageUrl;

          if (_selectedImage != null) {
            print('Uploading new image...');
            final token = await AuthService.instance.getIdToken();
            final request = http.MultipartRequest(
              'POST',
              Uri.parse('${ApiConstants.baseUrl}/chat/upload-image'),
            );
            request.headers['Authorization'] = 'Bearer $token';
            request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
            final streamed = await request.send();
            final resp = await http.Response.fromStream(streamed);

            if (resp.statusCode == 200 || resp.statusCode == 201) {
              final urlMatch = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(resp.body);
              if (urlMatch != null) {
                newImageUrl = urlMatch.group(1)!;
              }
            } else {
              throw Exception('Failed to upload new image.');
            }
          }

          final updatedEntity = _editPost!.copyWith(
            title: _titleController.text,
            description: _descriptionController.text,
            category: _selectedCategory,
            country: _countryController.text,
            state: _stateController.text.isEmpty ? null : _stateController.text,
            city: _cityController.text,
            area: _areaController.text.isEmpty ? null : _areaController.text,
            postType: _selectedType.toLowerCase(),
            imageUrl: newImageUrl,
          );

          final updatedPostModel = PostModel.fromEntity(updatedEntity);
          await postDs.updatePost(updatedPostModel);

          setState(() => _isLoading = false);          
          if (mounted) {
            AppMessenger.showSuccess('Post updated successfully!');
            Navigator.pop(context);
          }
        } else {
          print('📤 Submitting post to backend...');
          print('   Title: ${_titleController.text}');
          print('   Type: ${_selectedType.toLowerCase()}');
          print('   Category: $_selectedCategory');

          // Call backend API to find matches FIRST
          final result = await _dataSource.findMatches(
            image: _selectedImage!,
            title: _titleController.text,
            description: _descriptionController.text,
            category: _selectedCategory,
            country: _countryController.text,
            state: _stateController.text,
            city: _cityController.text,
            area: _areaController.text,
            postType: _selectedType.toLowerCase(),
          );

          print('✅ Backend response received: $result');
          setState(() => _isLoading = false);

          final matches = (result['matches'] as List<dynamic>?) ??
              ((result['data'] as Map<String, dynamic>?)?['matches'] as List<dynamic>?) ??
              const [];
          final uploadedImageUrl = (result['uploaded_image_url'] as String?) ??
              ((result['data'] as Map<String, dynamic>?)?['uploaded_image_url'] as String?);

          // Navigate to AI matching results with real data from backend
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/ai-matching-results',
              arguments: {
                'matchesCount': matches.length,
                'matches': matches,
                'success': result['success'] ?? true,
                'uploadedImageUrl': uploadedImageUrl,
                // Include user's post data for preview and final creation
                'title': _titleController.text,
                'description': _descriptionController.text,
                'category': _selectedCategory,
                'country': _countryController.text,
                'state': _stateController.text,
                'city': _cityController.text,
                'area': _areaController.text,
                'postType': _selectedType.toLowerCase(),
                'imageUrl': _selectedImage?.path ?? '',
              },
            );
          }
        }
      } catch (e) {
        print('❌ Error submitting post: $e');
        setState(() => _isLoading = false);

        // Show error message
        if (mounted) {
          AppMessenger.showSnackBar(
            SnackBar(
              content: const Text('Failed to submit post. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _submitPost,
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isVerified = userProvider.backendUser?.verified ?? false;

    return Scaffold(
      backgroundColor: FinderColors.background,
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
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Report Item',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white70),
                onPressed: () {
                  // Show help dialog
                },
              ),
            ],
          ),
        ),
      ),
      body: !isVerified
          ? _buildUnverifiedLock(context)
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Upload Section
                      GestureDetector(
                        onTap: _showImagePickerModal,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0A3D91),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                    child: _selectedImage != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  _selectedImage!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0A3D91,
                                  ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Color(0xFF0A3D91),
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Add Photo',
                                style: TextStyle(
                                  color: FinderColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap to upload an image of the item',
                                style: TextStyle(
                                  color: FinderColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Type Selection (Lost/Found)
                const Text(
                  'Type',
                  style: TextStyle(
                    color: FinderColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _types.map((type) {
                    final isSelected = _selectedType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: Container(
                          margin: EdgeInsets.only(
                            right: type == 'Lost' ? 8 : 0,
                            left: type == 'Found' ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0A3D91)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0A3D91)
                                  : FinderColors.lightBrown,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type == 'Lost'
                                    ? Icons.search
                                    : Icons.check_circle_outline,
                                color: isSelected
                                    ? Colors.white
                                    : FinderColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                type,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : FinderColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Title Field
                _buildLabel('Title'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _titleController,
                  hint: 'e.g., Black Leather Wallet',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category Dropdown
                _buildLabel('Category'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0A3D91)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: FinderColors.textSecondary,
                      ),
                      style: const TextStyle(
                        color: FinderColors.textPrimary,
                        fontSize: 16,
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Description Field ─────────────────────────────────────
                _buildLabel('Description'),
                const SizedBox(height: 4),
                // Safety guidance
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.4)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.shield_outlined, size: 13, color: Color(0xFF856404)),
                        SizedBox(width: 4),
                        Text('Privacy tip: Keep it general', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF856404))),
                      ]),
                      SizedBox(height: 4),
                      Text('✅  "Lost black wallet near Nasr City"', style: TextStyle(fontSize: 11, color: Color(0xFF856404))),
                      Text('❌  "Wallet has Banque Misr card inside"', style: TextStyle(fontSize: 11, color: Color(0xFF856404))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    _buildTextField(
                      controller: _descriptionController,
                      hint: 'Brief, general description...',
                      maxLines: 4,
                      maxLength: 140,
                      onChanged: (v) => setState(() => _descriptionLength = v.length),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a description';
                        if (value.length > 140) return 'Max 140 characters';
                        return null;
                      },
                    ),
                    Positioned(
                      right: 10, bottom: 10,
                      child: Text(
                        '$_descriptionLength / 140',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _descriptionLength > 130
                              ? Colors.red
                              : _descriptionLength > 100
                                  ? Colors.orange
                                  : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Location Fields (Autocomplete Input)
                _buildLabel('Location'),
                const SizedBox(height: 8),
                // 1. Country
                LocationAutocompleteField(
                  controller: _countryController,
                  focusNode: _countryFocus,
                  hint: 'Country (e.g., USA)',
                  optionsBuilder: (textEditingValue) {
                    return LocationDataService.getCountries(textEditingValue.text);
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _countryController.text = selection;
                      _stateController.clear();
                      _cityController.clear();
                    });
                    _stateFocus.requestFocus();
                  },
                  itemPrefixBuilder: LocationDataService.getCountryFlag,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    if (value.trim().length < 2) return 'Min 2 chars';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // 2. State / Province
                LocationAutocompleteField(
                  key: ValueKey('state_${_countryController.text}'),
                  controller: _stateController,
                  focusNode: _stateFocus,
                  hint: 'State/Province (Optional)',
                  optionsBuilder: (textEditingValue) {
                    return LocationDataService.getStates(
                      _countryController.text, 
                      textEditingValue.text
                    );
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _stateController.text = selection;
                      _cityController.clear();
                    });
                    _cityFocus.requestFocus();
                  },
                ),
                const SizedBox(height: 12),

                // 3. City
                LocationAutocompleteField(
                  key: ValueKey('city_${_countryController.text}_${_stateController.text}'),
                  controller: _cityController,
                  focusNode: _cityFocus,
                  hint: _stateController.text == LocationDataService.travelingState
                      ? 'Traveling Method (e.g., Train)'
                      : 'City (e.g., NY)',
                  optionsBuilder: (textEditingValue) {
                    return LocationDataService.getCities(
                      _countryController.text, 
                      _stateController.text, 
                      textEditingValue.text
                    );
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _cityController.text = selection;
                      _areaController.clear();
                    });
                    if (_stateController.text != LocationDataService.travelingState) {
                      _areaFocus.requestFocus();
                    } else {
                      _cityFocus.unfocus();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    if (value.trim().length < 2) return 'Min 2 chars';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                if (_stateController.text != LocationDataService.travelingState) ...[
                  // 4. Area
                  LocationAutocompleteField(
                    key: ValueKey('area_${_countryController.text}_${_stateController.text}_${_cityController.text}'),
                    controller: _areaController,
                    focusNode: _areaFocus,
                    hint: 'Area / District (Optional)',
                    optionsBuilder: (textEditingValue) {
                      return LocationDataService.getAreas(
                        _countryController.text,
                        _stateController.text,
                        _cityController.text,
                        textEditingValue.text,
                      );
                    },
                    onSelected: (String selection) {
                      setState(() {
                        _areaController.text = selection;
                      });
                      _areaFocus.unfocus();
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A3D91),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _editPost != null
                                    ? 'Update Post'
                                    : (_selectedType == 'Lost'
                                        ? 'Find Matches with AI'
                                        : 'Post & Find Owner'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: FinderColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    IconData? prefixIcon,
    IconData? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      style: const TextStyle(color: FinderColors.textPrimary, fontSize: 16),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: FinderColors.textSecondary),
        counterText: '', // Hide default counter — we render our own
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: FinderColors.textSecondary)
            : null,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: const Color(0xFF0A3D91))
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A3D91)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A3D91)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A3D91), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.all(16),
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
                color: FinderColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'To maintain a safe and trustworthy community, you must verify your identity before reporting items or creating posts.',
              style: TextStyle(
                fontSize: 16,
                color: FinderColors.textSecondary,
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
