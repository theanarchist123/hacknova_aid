import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/models/community_pin.dart';
import '../../../core/app_export.dart';

class PinSearchBar extends StatefulWidget {
  final List<CommunityPin> allPins;
  final Function(List<CommunityPin>) onSearchResults;
  final Function(CommunityPin) onPinSelected;
  final VoidCallback? onFilterTap;

  const PinSearchBar({
    super.key,
    required this.allPins,
    required this.onSearchResults,
    required this.onPinSelected,
    this.onFilterTap,
  });

  @override
  State<PinSearchBar> createState() => _PinSearchBarState();
}

class _PinSearchBarState extends State<PinSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<CommunityPin> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: [
          // Search input
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search community pins...',
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: _clearSearch,
                        icon: Icon(
                          Icons.clear,
                          color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    if (widget.onFilterTap != null)
                      IconButton(
                        onPressed: widget.onFilterTap,
                        icon: Icon(
                          Icons.tune,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.lightTheme.colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _performSearch(),
            ),
          ),

          // Search results dropdown
          if (_isSearching && _searchResults.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 1.h),
              constraints: BoxConstraints(maxHeight: 40.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                itemBuilder: (context, index) {
                  final pin = _searchResults[index];
                  return _buildSearchResultItem(pin);
                },
              ),
            ),

          // Quick search chips
          if (!_isSearching && _searchController.text.isEmpty)
            Container(
              margin: EdgeInsets.only(top: 1.h),
              child: _buildQuickSearchChips(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(CommunityPin pin) {
    return ListTile(
      onTap: () => _selectPin(pin),
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: _getPinTypeColor(pin.type).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomIconWidget(
          iconName: pin.type.iconName,
          color: _getPinTypeColor(pin.type),
          size: 24,
        ),
      ),
      title: Text(
        pin.title,
        style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pin.type.displayName,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (pin.description.isNotEmpty)
            Text(
              pin.description,
              style: AppTheme.lightTheme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: _getPriorityColor(pin.priority),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getPriorityText(pin.priority),
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 0.5.h),
          if (pin.verifiedBy.isNotEmpty)
            Icon(
              Icons.verified,
              color: Colors.green,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildQuickSearchChips() {
    final quickSearches = [
      {'label': 'Hazards', 'types': [PinType.hazard, PinType.fire, PinType.flood]},
      {'label': 'Medical', 'types': [PinType.medical]},
      {'label': 'Shelter', 'types': [PinType.shelter]},
      {'label': 'Water', 'types': [PinType.water_source]},
      {'label': 'Food', 'types': [PinType.food]},
      {'label': 'High Priority', 'priority': PinPriority.high},
      {'label': 'Critical', 'priority': PinPriority.critical},
      {'label': 'Verified', 'verified': true},
    ];

    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: quickSearches.map((search) {
        return ActionChip(
          label: Text(search['label'] as String),
          onPressed: () => _performQuickSearch(search),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
          labelStyle: TextStyle(
            color: AppTheme.lightTheme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    if (query.isNotEmpty && query.length >= 2) {
      _performSearch();
    } else {
      setState(() {
        _searchResults.clear();
      });
      widget.onSearchResults([]);
    }
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return;

    setState(() {
      _searchResults = widget.allPins.where((pin) {
        // Search in title
        if (pin.title.toLowerCase().contains(query)) return true;
        
        // Search in description
        if (pin.description.toLowerCase().contains(query)) return true;
        
        // Search in type name
        if (pin.type.displayName.toLowerCase().contains(query)) return true;
        
        // Search in priority
        if (_getPriorityText(pin.priority).toLowerCase().contains(query)) return true;
        
        // Search in creator name
        if (pin.createdBy.toLowerCase().contains(query)) return true;
        
        return false;
      }).take(10).toList(); // Limit to 10 results
    });

    widget.onSearchResults(_searchResults);
  }

  void _performQuickSearch(Map<String, dynamic> searchParams) {
    List<CommunityPin> results = [];

    if (searchParams.containsKey('types')) {
      final types = searchParams['types'] as List<PinType>;
      results = widget.allPins.where((pin) => types.contains(pin.type)).toList();
    } else if (searchParams.containsKey('priority')) {
      final priority = searchParams['priority'] as PinPriority;
      results = widget.allPins.where((pin) => pin.priority == priority).toList();
    } else if (searchParams.containsKey('verified')) {
      results = widget.allPins.where((pin) => pin.verifiedBy.isNotEmpty).toList();
    }

    setState(() {
      _searchResults = results.take(10).toList();
      _isSearching = true;
    });

    widget.onSearchResults(_searchResults);
  }

  void _selectPin(CommunityPin pin) {
    _focusNode.unfocus();
    setState(() {
      _isSearching = false;
      _searchResults.clear();
    });
    widget.onPinSelected(pin);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults.clear();
    });
    widget.onSearchResults([]);
  }

  Color _getPinTypeColor(PinType type) {
    if (type.isHazard) {
      return Colors.red;
    } else if (type.isResource) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  Color _getPriorityColor(PinPriority priority) {
    switch (priority) {
      case PinPriority.low:
        return Colors.green;
      case PinPriority.medium:
        return Colors.orange;
      case PinPriority.high:
        return Colors.red;
      case PinPriority.critical:
        return Colors.purple;
    }
  }

  String _getPriorityText(PinPriority priority) {
    switch (priority) {
      case PinPriority.low:
        return 'Low';
      case PinPriority.medium:
        return 'Med';
      case PinPriority.high:
        return 'High';
      case PinPriority.critical:
        return 'Crit';
    }
  }
}