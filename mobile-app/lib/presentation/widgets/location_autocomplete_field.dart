import 'package:flutter/material.dart';
import '../../core/constants/finder_colors.dart';

class LocationAutocompleteField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Iterable<String> Function(TextEditingValue) optionsBuilder;
  final void Function(String) onSelected;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final String Function(String)? itemPrefixBuilder;

  const LocationAutocompleteField({
    super.key,
    required this.hint,
    required this.controller,
    this.focusNode,
    required this.optionsBuilder,
    required this.onSelected,
    this.validator,
    this.prefixIcon,
    this.itemPrefixBuilder,
  });

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  late FocusNode _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);

    // If it starts with focus (auto-focus from previous field selection),
    // we nudge it to show suggestions immediately.
    if (_internalFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.controller.text.isEmpty) {
          widget.controller.text = ''; 
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    } else {
      _internalFocusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (_internalFocusNode.hasFocus && widget.controller.text.isEmpty) {
      // Trigger optionsBuilder by "nudging" the controller
      widget.controller.text = ''; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _internalFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            // If the field is focused but empty, show all options
            return widget.optionsBuilder(textEditingValue);
          },
          onSelected: widget.onSelected,
          fieldViewBuilder: (context, textEditingController, node, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: node,
              onFieldSubmitted: (String value) {
                onFieldSubmitted();
              },
              validator: widget.validator,
              style: const TextStyle(color: FinderColors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(color: FinderColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: widget.prefixIcon,
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
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  width: constraints.maxWidth,
                  margin: EdgeInsets.zero,
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        final prefix = widget.itemPrefixBuilder?.call(option) ?? '';
                        
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            onSelected(option);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: index != options.length - 1
                                  ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                if (prefix.isNotEmpty) ...[
                                  Text(prefix, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: _HighlightText(
                                    text: option,
                                    query: widget.controller.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }
}

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: const TextStyle(color: FinderColors.textPrimary, fontSize: 16),
      );
    }

    final String lowercaseText = text.toLowerCase();
    final String lowercaseQuery = query.toLowerCase();
    
    if (!lowercaseText.contains(lowercaseQuery)) {
      return Text(
        text,
        style: const TextStyle(color: FinderColors.textPrimary, fontSize: 16),
      );
    }

    final int startIndex = lowercaseText.indexOf(lowercaseQuery);
    final int endIndex = startIndex + lowercaseQuery.length;

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: FinderColors.textPrimary, fontSize: 16),
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A3D91), // Highlight color
            ),
          ),
          TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }
}
