import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dynamic_colors.dart';
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
  final _formKey              = GlobalKey<FormState>();
  final _titleController      = TextEditingController();
  final _descriptionController = TextEditingController();
  final _countryController    = TextEditingController();
  final _stateController      = TextEditingController();
  final _cityController       = TextEditingController();
  final _areaController       = TextEditingController();

  final FocusNode _countryFocus = FocusNode();
  final FocusNode _stateFocus   = FocusNode();
  final FocusNode _cityFocus    = FocusNode();
  final FocusNode _areaFocus    = FocusNode();

  String _selectedCategory = 'Wallet';
  String _selectedType     = 'Lost';
  File? _selectedImage;
  bool _isLoading         = false;
  int _descLength          = 0;

  late final AIMatchingRemoteDataSource _dataSource;

  static const List<String> _categories = [
    'Wallet', 'Phone', 'Keys', 'Bag', 'Electronics',
    'Documents', 'Jewelry', 'Clothing', 'Other',
  ];

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
      final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
      if (args != null && args['editPost'] != null) {
        _editPost = args['editPost'] as Post;
        _titleController.text       = _editPost!.title;
        _descriptionController.text = _editPost!.description ?? '';
        _countryController.text     = _editPost!.country;
        _stateController.text       = _editPost!.state ?? '';
        _cityController.text        = _editPost!.city ?? '';
        final cat = _editPost!.category ?? 'Other';
        _selectedCategory = _categories.firstWhere(
          (c) => c.toLowerCase() == cat.toLowerCase(),
          orElse: () => 'Other',
        );
        _selectedType = _editPost!.postType.toLowerCase() == 'lost'
            ? 'Lost'
            : 'Found';
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
    final XFile? img = await ImagePicker().pickImage(
      source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85,
    );
    if (img != null) setState(() => _selectedImage = File(img.path));
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl2)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl2, AppSpacing.lg, AppSpacing.xl2, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SheetOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take a photo',
                subtitle: 'Use your camera',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _SheetOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from gallery',
                subtitle: 'Pick an existing photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null && _editPost == null) {
      AppMessenger.showError('Please add a photo of the item');
      return;
    }
    setState(() => _isLoading = true);

    try {
      if (_editPost != null) {
        final apiClient = ApiClient(
            tokenProvider: AuthService.instance.getIdToken);
        final postDs = PostRemoteDataSourceImpl(apiClient: apiClient);
        String newImageUrl = _editPost!.imageUrl;

        if (_selectedImage != null) {
          final token = await AuthService.instance.getIdToken();
          final req = http.MultipartRequest(
            'POST',
            Uri.parse('${ApiConstants.baseUrl}/chat/upload-image'),
          );
          req.headers['Authorization'] = 'Bearer $token';
          req.files.add(await http.MultipartFile.fromPath(
              'image', _selectedImage!.path));
          final streamed = await req.send();
          final resp = await http.Response.fromStream(streamed);
          if (resp.statusCode == 200 || resp.statusCode == 201) {
            final m = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(resp.body);
            if (m != null) newImageUrl = m.group(1)!;
          } else {
            throw Exception('Failed to upload image.');
          }
        }

        final updated = _editPost!.copyWith(
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
        await postDs.updatePost(PostModel.fromEntity(updated));
        setState(() => _isLoading = false);
        if (mounted) {
          AppMessenger.showSuccess('Post updated successfully!');
          Navigator.pop(context);
        }
      } else {
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
        setState(() => _isLoading = false);

        final matches = (result['matches'] as List<dynamic>?) ??
            ((result['data'] as Map?)?['matches'] as List<dynamic>?) ??
            const [];
        final uploadedUrl = (result['uploaded_image_url'] as String?) ??
            ((result['data'] as Map?)?['uploaded_image_url'] as String?);

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/ai-matching-results',
            arguments: {
              'matchesCount': matches.length,
              'matches': matches,
              'success': result['success'] ?? true,
              'uploadedImageUrl': uploadedUrl,
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
      setState(() => _isLoading = false);
      if (mounted) {
        AppMessenger.showSnackBar(
          SnackBar(
            content: const Text('Failed to submit. Please try again.'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: AppColors.white,
              onPressed: _submitPost,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified =
        context.watch<UserProvider>().backendUser?.verified ?? false;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_editPost != null ? 'Edit Post' : 'Report Item'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline_rounded,
                size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: !isVerified
          ? const _UnverifiedGate()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl2),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Image Upload ───────────────────────────────────────
                    _ImageUploadArea(
                      image: _selectedImage,
                      onTap: _showImagePicker,
                      onRemove: () =>
                          setState(() => _selectedImage = null),
                    ),

                    const SizedBox(height: AppSpacing.xl2),

                    // ── Post Type ──────────────────────────────────────────
                    _FieldLabel('Post type'),
                    const SizedBox(height: AppSpacing.sm),
                    _TypeSelector(
                      selected: _selectedType,
                      onChanged: (v) => setState(() => _selectedType = v),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Category ───────────────────────────────────────────
                    _FieldLabel('Category'),
                    const SizedBox(height: AppSpacing.sm),
                    _CategoryPicker(
                      selected: _selectedCategory,
                      categories: _categories,
                      onChanged: (v) =>
                          setState(() => _selectedCategory = v),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Title ──────────────────────────────────────────────
                    _FieldLabel('Title'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'e.g., Black leather wallet',
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Please enter a title';
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Description ────────────────────────────────────────
                    _FieldLabel('Description'),
                    const SizedBox(height: AppSpacing.xs),
                    _PrivacyTip(),
                    const SizedBox(height: AppSpacing.sm),
                    Stack(
                      children: [
                        _buildTextField(
                          controller: _descriptionController,
                          hint: 'Brief, general description…',
                          maxLines: 4,
                          maxLength: 140,
                          onChanged: (v) =>
                              setState(() => _descLength = v.length),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Please enter a description';
                            if (v.length > 140)
                              return 'Max 140 characters';
                            return null;
                          },
                        ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Text(
                            '$_descLength / 140',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _descLength > 130
                                  ? AppColors.error
                                  : _descLength > 100
                                      ? AppColors.warning
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Location ───────────────────────────────────────────
                    _FieldLabel('Location'),
                    const SizedBox(height: AppSpacing.sm),
                    LocationAutocompleteField(
                      controller: _countryController,
                      focusNode: _countryFocus,
                      hint: 'Country',
                      optionsBuilder: (tv) =>
                          LocationDataService.getCountries(tv.text),
                      onSelected: (s) {
                        setState(() {
                          _countryController.text = s;
                          _stateController.clear();
                          _cityController.clear();
                        });
                        _stateFocus.requestFocus();
                      },
                      itemPrefixBuilder:
                          LocationDataService.getCountryFlag,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Min 2 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LocationAutocompleteField(
                      key: ValueKey('state_${_countryController.text}'),
                      controller: _stateController,
                      focusNode: _stateFocus,
                      hint: 'State / Province (optional)',
                      optionsBuilder: (tv) =>
                          LocationDataService.getStates(
                              _countryController.text, tv.text),
                      onSelected: (s) {
                        setState(() {
                          _stateController.text = s;
                          _cityController.clear();
                        });
                        _cityFocus.requestFocus();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LocationAutocompleteField(
                      key: ValueKey(
                          'city_${_countryController.text}_${_stateController.text}'),
                      controller: _cityController,
                      focusNode: _cityFocus,
                      hint: _stateController.text ==
                              LocationDataService.travelingState
                          ? 'Transport method'
                          : 'City',
                      optionsBuilder: (tv) =>
                          LocationDataService.getCities(
                              _countryController.text,
                              _stateController.text,
                              tv.text),
                      onSelected: (s) {
                        setState(() {
                          _cityController.text = s;
                          _areaController.clear();
                        });
                        if (_stateController.text !=
                            LocationDataService.travelingState) {
                          _areaFocus.requestFocus();
                        } else {
                          _cityFocus.unfocus();
                        }
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Min 2 characters';
                        return null;
                      },
                    ),
                    if (_stateController.text !=
                        LocationDataService.travelingState) ...[
                      const SizedBox(height: AppSpacing.md),
                      LocationAutocompleteField(
                        key: ValueKey(
                            'area_${_countryController.text}_${_stateController.text}_${_cityController.text}'),
                        controller: _areaController,
                        focusNode: _areaFocus,
                        hint: 'Area / District (optional)',
                        optionsBuilder: (tv) =>
                            LocationDataService.getAreas(
                                _countryController.text,
                                _stateController.text,
                                _cityController.text,
                                tv.text),
                        onSelected: (s) {
                          setState(() => _areaController.text = s);
                          _areaFocus.unfocus();
                        },
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl3),

                    // ── Submit ─────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitPost,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(
                          _isLoading
                              ? 'Processing…'
                              : (_editPost != null
                                  ? 'Update Post'
                                  : (_selectedType == 'Lost'
                                      ? 'Find Matches with AI'
                                      : 'Post & Find Owner')),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 15,
        ),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide:
              const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _ImageUploadArea extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImageUploadArea({
    required this.image,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: image != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
            width: image != null ? 2 : 1.5,
            style: image != null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: image != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg - 1),
                    child: Image.file(
                      image!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.neutral900.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 26,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Tap to add photo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Required for AI matching',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TypeSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['Lost', 'Found'].map((type) {
        final isLost    = type == 'Lost';
        final isSelected = selected == type;
        final activeColor =
            isLost ? AppColors.lostBadge : AppColors.foundBadge;
        final activeBg =
            isLost ? AppColors.lostBadgeBg : AppColors.foundBadgeBg;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                right: isLost ? AppSpacing.sm : 0,
                left: isLost ? 0 : AppSpacing.sm,
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: isSelected ? activeBg : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected ? activeColor : Theme.of(context).colorScheme.outline,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLost
                        ? Icons.search_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: isSelected
                        ? activeColor
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? activeColor
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final String selected;
  final List<String> categories;
  final ValueChanged<String> onChanged;

  const _CategoryPicker({
    required this.selected,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items: categories.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(c,
                  style: TextStyle(
                      fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
            );
          }).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

class _PrivacyTip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined,
              size: 14, color: AppColors.warning),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep it general — protect sensitive details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '✓ "Lost black wallet near Nasr City"\n✗ "Wallet has Banque Misr card inside"',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnverifiedGate extends StatelessWidget {
  const _UnverifiedGate();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warningMuted,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusXl2),
              ),
              child: const Icon(
                Icons.gpp_maybe_rounded,
                size: 40,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Verification required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'To maintain a safe community, you must verify your identity before reporting items.',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl3),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(
                  context, '/kyc-verification'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text(
                'Verify My Account',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
