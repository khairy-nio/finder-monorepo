import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/app_messenger.dart';
import '../../core/utils/location_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/location_autocomplete_field.dart';
import '../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final _countryController = TextEditingController();
  final _stateController   = TextEditingController();
  final _cityController    = TextEditingController();
  final _areaController    = TextEditingController();

  final FocusNode _nameFocus    = FocusNode();
  final FocusNode _phoneFocus   = FocusNode();
  final FocusNode _countryFocus = FocusNode();
  final FocusNode _stateFocus   = FocusNode();
  final FocusNode _cityFocus    = FocusNode();
  final FocusNode _areaFocus    = FocusNode();

  String _selectedGender = 'Male';
  bool _isLoading = false;
  File? _pickedSelfie;
  String? _currentSelfieUrl;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final firebaseUser = AuthService.instance.currentUser;
    _nameController  = TextEditingController(text: firebaseUser?.displayName ?? '');
    _emailController = TextEditingController(text: firebaseUser?.email ?? '');
    _phoneController = TextEditingController();

    final cachedUser = context.read<UserProvider>().backendUser;
    if (cachedUser != null) _populateFrom(cachedUser);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<UserProvider>();
      await provider.loadUser();
      final freshUser = provider.backendUser;
      if (freshUser != null && mounted) setState(() => _populateFrom(freshUser));
    });
  }

  void _populateFrom(dynamic user) {
    _nameController.text  = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber ?? '';
    _countryController.text = user.country ?? '';
    _stateController.text   = user.state ?? '';
    _cityController.text    = user.city ?? '';
    _areaController.text    = user.area ?? '';
    _currentSelfieUrl       = user.selfieImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _countryFocus.dispose();
    _stateFocus.dispose();
    _cityFocus.dispose();
    _areaFocus.dispose();
    super.dispose();
  }

  Future<void> _pickSelfie() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (picked != null) setState(() => _pickedSelfie = File(picked.path));
    } catch (e) {
      AppMessenger.showError('Failed to pick image: $e');
    }
  }

  Future<void> _save() async {
    // Always dismiss keyboard before saving
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
      String? selfieUrl = _currentSelfieUrl;
      if (_pickedSelfie != null) {
        final uploadResult = await apiClient.postMultipart(
          '/user/upload-image',
          filePath: _pickedSelfie!.path,
        );
        selfieUrl = uploadResult['data']['url'];
      }
      await apiClient.put(ApiConstants.userProfileEndpoint, body: {
        'name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'country': _countryController.text.trim(),
        'state': _stateController.text.trim(),
        'city': _cityController.text.trim(),
        'area': _areaController.text.trim(),
        'selfie_image_url': selfieUrl,
      });
      await AuthService.instance.currentUser?.updateDisplayName(_nameController.text.trim());
      if (mounted) await context.read<UserProvider>().loadUser();
      if (mounted) {
        setState(() => _isLoading = false);
        AppMessenger.showSuccess('Profile updated successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppMessenger.showError('Failed to save changes: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: GestureDetector(
        // ── KEYBOARD FIX: tap anywhere to dismiss keyboard ────────────────
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: AppSpacing.brSm,
                ),
                child: Icon(Icons.arrow_back_rounded,
                    size: 18, color: Theme.of(context).colorScheme.onSurface),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Edit Profile',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Theme.of(context).colorScheme.primary))
                    : Text(
                        'Save',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          body: SingleChildScrollView(
            // ── KEYBOARD FIX: drag scroll also dismisses keyboard ─────────
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar + Selfie ──────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        _SelfieUpload(
                          pickedSelfie: _pickedSelfie,
                          currentSelfieUrl: _currentSelfieUrl,
                          onTap: _pickSelfie,
                          onClear: () => setState(() {
                            _pickedSelfie = null;
                            _currentSelfieUrl = null;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Verification selfie',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl3),

                  // ── Personal Info ────────────────────────────────────────
                  const _SectionLabel('Personal info'),
                  const SizedBox(height: AppSpacing.md),

                  _FieldLabel('Full name'),
                  const SizedBox(height: AppSpacing.xs),
                  _FormField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    hint: 'Your full name',
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _FieldLabel('Email'),
                  const SizedBox(height: AppSpacing.xs),
                  _FormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: false,
                    hint: '',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _FieldLabel('Phone number'),
                  const SizedBox(height: AppSpacing.xs),
                  _FormField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    hint: '+1 234 567 8900',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    prefixIcon: const Icon(Icons.phone_outlined,
                        size: 18, color: AppColors.textTertiary),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.length < 8) {
                        return 'Invalid phone number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl3),

                  // ── Location ─────────────────────────────────────────────
                  const _SectionLabel('Location'),
                  const SizedBox(height: AppSpacing.md),

                  _FieldLabel('Country'),
                  const SizedBox(height: AppSpacing.xs),
                  LocationAutocompleteField(
                    controller: _countryController,
                    focusNode: _countryFocus,
                    hint: 'Select country',
                    optionsBuilder: (v) => LocationDataService.getCountries(v.text),
                    onSelected: (s) {
                      setState(() {
                        _countryController.text = s;
                        _stateController.clear();
                        _cityController.clear();
                      });
                      _stateFocus.requestFocus();
                    },
                    itemPrefixBuilder: LocationDataService.getCountryFlag,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('State'),
                            const SizedBox(height: AppSpacing.xs),
                            LocationAutocompleteField(
                              key: ValueKey('state_${_countryController.text}'),
                              controller: _stateController,
                              focusNode: _stateFocus,
                              hint: 'Select state',
                              optionsBuilder: (v) => LocationDataService.getStates(
                                  _countryController.text, v.text),
                              onSelected: (s) {
                                setState(() {
                                  _stateController.text = s;
                                  _cityController.clear();
                                });
                                _cityFocus.requestFocus();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('City'),
                            const SizedBox(height: AppSpacing.xs),
                            LocationAutocompleteField(
                              key: ValueKey(
                                  'city_${_countryController.text}_${_stateController.text}'),
                              controller: _cityController,
                              focusNode: _cityFocus,
                              hint: 'Select city',
                              optionsBuilder: (v) => LocationDataService.getCities(
                                  _countryController.text,
                                  _stateController.text,
                                  v.text),
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (_stateController.text != LocationDataService.travelingState) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _FieldLabel('Area / District'),
                    const SizedBox(height: AppSpacing.xs),
                    LocationAutocompleteField(
                      key: ValueKey(
                          'area_${_countryController.text}_${_stateController.text}_${_cityController.text}'),
                      controller: _areaController,
                      focusNode: _areaFocus,
                      hint: 'Select area',
                      optionsBuilder: (v) => LocationDataService.getAreas(
                          _countryController.text,
                          _stateController.text,
                          _cityController.text,
                          v.text),
                      onSelected: (s) {
                        setState(() => _areaController.text = s);
                        _areaFocus.unfocus();
                      },
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl3),

                  // ── Preferences ──────────────────────────────────────────
                  const _SectionLabel('Preferences'),
                  const SizedBox(height: AppSpacing.md),

                  _FieldLabel('Gender'),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: AppSpacing.brMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 20, color: AppColors.textTertiary),
                        style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500),
                        items: ['Male', 'Female']
                            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedGender = v!),
                      ),
                    ),
                  ),

                  // ── Bottom padding so Save button stays above keyboard ────
                  const SizedBox(height: AppSpacing.xl3),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.brMd),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: AppColors.white, strokeWidth: 2))
                          : const Text(
                              'Save changes',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 1.1),
    );
  }
}

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
          color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _FormField({
    required this.controller,
    this.focusNode,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.prefixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: enabled ? Theme.of(context).colorScheme.onSurface : AppColors.textTertiary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 15, color: AppColors.textTertiary),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: enabled ? Theme.of(context).scaffoldBackgroundColor : AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.brMd,
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: AppSpacing.brMd),
      ),
    );
  }
}

class _SelfieUpload extends StatelessWidget {
  final File? pickedSelfie;
  final String? currentSelfieUrl;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _SelfieUpload({
    required this.pickedSelfie,
    required this.currentSelfieUrl,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = pickedSelfie != null ||
        (currentSelfieUrl != null && currentSelfieUrl!.isNotEmpty);

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 110,
            height: 148,
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: AppSpacing.brLg,
              border: Border.all(
                color: hasImage ? Theme.of(context).colorScheme.primary : AppColors.border,
                width: hasImage ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: AppSpacing.brLg,
              child: pickedSelfie != null
                  ? Image.file(pickedSelfie!, fit: BoxFit.cover)
                  : (currentSelfieUrl != null && currentSelfieUrl!.isNotEmpty)
                      ? Image.network(
                          currentSelfieUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _SelfieEmpty(),
                        )
                      : const _SelfieEmpty(),
            ),
          ),
        ),

        // Edit button
        Positioned(
          bottom: 8,
          right: 8,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2)),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 14, color: AppColors.white),
            ),
          ),
        ),

        // Clear button
        if (hasImage)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    size: 12, color: AppColors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _SelfieEmpty extends StatelessWidget {
  const _SelfieEmpty();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.face_rounded, size: 36, color: AppColors.neutral400),
        SizedBox(height: 6),
        Text(
          'Take selfie',
          style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
