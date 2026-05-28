import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/location_data.dart';
import '../widgets/location_autocomplete_field.dart';
import '../providers/post_provider.dart';

/// Filter Screen
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String selectedCategory = 'All';
  String selectedTimeRange = 'Last 24h';
  bool aiMatchingEnabled = false;
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  final FocusNode _countryFocus = FocusNode();
  final FocusNode _stateFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _areaFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Restore previous filter values if they exist
    final provider = context.read<PostProvider>();
    final saved = provider.activeFilters;
    if (saved != null) {
      selectedCategory = saved['category'] ?? 'All';
      selectedTimeRange = saved['timeRange'] ?? 'Last 24h';
      _countryController.text = saved['country'] ?? '';
      _stateController.text = saved['state'] ?? '';
      _cityController.text = saved['city'] ?? '';
      _areaController.text = saved['area'] ?? '';
    }
  }

  @override
  void dispose() {
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = {
      'category': selectedCategory,
      'timeRange': selectedTimeRange,
      'country': _countryController.text.trim(),
      'state': _stateController.text.trim(),
      'city': _cityController.text.trim(),
      'area': _areaController.text.trim(),
    };
    context.read<PostProvider>().applyFilters(
      filters: filters,
      category: selectedCategory == 'All' ? null : selectedCategory,
      country: _countryController.text.trim(),
      state: _stateController.text.trim(),
      city: _cityController.text.trim(),
      area: _areaController.text.trim(),
    );
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      selectedCategory = 'All';
      selectedTimeRange = 'Last 24h';
      aiMatchingEnabled = false;
      _countryController.clear();
      _stateController.clear();
      _cityController.clear();
      _areaController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search Filters',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              'Reset',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF0A3D91),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CATEGORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => selectedCategory = 'All'),
                  child: const Text(
                    'Clear',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0A3D91)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Icons Row 1
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCategoryItem('All', Icons.apps, 'All'),
                _buildCategoryItem('Wallet', Icons.account_balance_wallet_outlined, 'Wallet'),
                _buildCategoryItem('Phone', Icons.phone_android, 'Phone'),
              ],
            ),
            const SizedBox(height: 16),

            // Category Icons Row 2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCategoryItem('Keys', Icons.key, 'Keys'),
                _buildCategoryItem('Bag', Icons.work_outline, 'Bag'),
                _buildCategoryItem('Electronics', Icons.devices, 'Electronics'),
              ],
            ),
            const SizedBox(height: 16),

            // Category Icons Row 3
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCategoryItem('Documents', Icons.description_outlined, 'Documents'),
                _buildCategoryItem('Jewelry', Icons.watch_outlined, 'Jewelry'),
                _buildCategoryItem('Other', Icons.more_horiz, 'Other'),
              ],
            ),
            const SizedBox(height: 32),

            // Time Range Section
            const Text(
              'TIME RANGE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Time Range Buttons
            Row(
              children: [
                _buildTimeRangeButton('Last 24h'),
                const SizedBox(width: 8),
                _buildTimeRangeButton('Last Week'),
                const SizedBox(width: 8),
                _buildTimeRangeButton('Last Month'),
              ],
            ),

            const SizedBox(height: 32),

            // Location Section — Country → State → City order
            const Text(
              'LOCATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // 1. Country
            LocationAutocompleteField(
              controller: _countryController,
              focusNode: _countryFocus,
              hint: 'Country',
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
            ),
            const SizedBox(height: 12),

            // 2. State / Province
            LocationAutocompleteField(
              key: ValueKey('state_${_countryController.text}'),
              controller: _stateController,
              focusNode: _stateFocus,
              hint: 'State / Province (Optional)',
              optionsBuilder: (textEditingValue) {
                return LocationDataService.getStates(
                  _countryController.text,
                  textEditingValue.text,
                );
              },
              onSelected: (String selection) {
                setState(() {
                  _stateController.text = selection;
                  _cityController.clear(); // City must be re-selected after state changes
                });
                _cityFocus.requestFocus();
              },
            ),
            const SizedBox(height: 12),

            // 3. City  (depends on country + optionally state)
            LocationAutocompleteField(
              key: ValueKey('city_${_countryController.text}_${_stateController.text}'),
              controller: _cityController,
              focusNode: _cityFocus,
              hint: _stateController.text == LocationDataService.travelingState
                  ? 'Traveling Method (e.g., Train)'
                  : 'City',
              optionsBuilder: (textEditingValue) {
                return LocationDataService.getCities(
                  _countryController.text,
                  _stateController.text,
                  textEditingValue.text,
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
            ),

            if (_stateController.text != LocationDataService.travelingState) ...[
              const SizedBox(height: 12),
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
            ],

            const SizedBox(height: 16),

            // AI Matching Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A3D91).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0A3D91).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A3D91),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Matching Enabled',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Match using AI image recognition',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: aiMatchingEnabled,
                    onChanged: (value) {
                      setState(() {
                        aiMatchingEnabled = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF0A3D91),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Apply Filters Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D91),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon, String value) {
    final isSelected = selectedCategory == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = value;
        });
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0A3D91) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF0A3D91) : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String label) {
    final isSelected = selectedTimeRange == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTimeRange = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0A3D91) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
