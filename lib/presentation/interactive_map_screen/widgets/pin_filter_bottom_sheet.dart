import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/models/community_pin.dart';
import '../../../core/app_export.dart';

class PinFilterBottomSheet extends StatefulWidget {
  final PinFilterOptions currentFilters;
  final Function(PinFilterOptions) onFiltersChanged;

  const PinFilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<PinFilterBottomSheet> createState() => _PinFilterBottomSheetState();
}

class _PinFilterBottomSheetState extends State<PinFilterBottomSheet> {
  late PinFilterOptions _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter Community Pins',
                    style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pin Types Section
                  _buildSectionHeader('Pin Types'),
                  _buildPinTypeFilters(),

                  SizedBox(height: 3.h),

                  // Priority Section
                  _buildSectionHeader('Priority Levels'),
                  _buildPriorityFilters(),

                  SizedBox(height: 3.h),

                  // Status Section
                  _buildSectionHeader('Pin Status'),
                  _buildStatusFilters(),

                  SizedBox(height: 3.h),

                  // Verification Section
                  _buildSectionHeader('Verification'),
                  _buildVerificationFilters(),

                  SizedBox(height: 3.h),

                  // Time Range Section
                  _buildSectionHeader('Time Range'),
                  _buildTimeRangeFilters(),

                  SizedBox(height: 3.h),

                  // Distance Section
                  _buildSectionHeader('Distance from Location'),
                  _buildDistanceFilters(),

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset All'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                      foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  Widget _buildPinTypeFilters() {
    return Column(
      children: [
        // Hazards
        _buildTypeGroup(
          'Hazards',
          [PinType.hazard, PinType.fire, PinType.flood, PinType.landslide, PinType.blocked_road],
          Colors.red,
        ),
        SizedBox(height: 2.h),
        
        // Resources
        _buildTypeGroup(
          'Resources',
          [PinType.water_source, PinType.shelter, PinType.medical, PinType.food, PinType.safe_zone],
          Colors.green,
        ),
        SizedBox(height: 2.h),
        
        // Other
        _buildTypeGroup(
          'Other',
          [PinType.evacuation_route, PinType.emergency_contact, PinType.resource, PinType.other],
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildTypeGroup(String groupName, List<PinType> types, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, color: color, size: 12),
              SizedBox(width: 2.w),
              Text(
                groupName,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _toggleAllInGroup(types, true),
                child: const Text('All'),
              ),
              TextButton(
                onPressed: () => _toggleAllInGroup(types, false),
                child: const Text('None'),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: types.map((type) => _buildTypeChip(type)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(PinType type) {
    final isSelected = _filters.enabledTypes.contains(type);
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: type.iconName,
            size: 16,
            color: isSelected 
                ? AppTheme.lightTheme.colorScheme.onPrimary
                : AppTheme.lightTheme.colorScheme.onSurface,
          ),
          SizedBox(width: 1.w),
          Text(type.displayName),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _filters.enabledTypes.add(type);
          } else {
            _filters.enabledTypes.remove(type);
          }
        });
      },
      selectedColor: AppTheme.lightTheme.colorScheme.primary,
      checkmarkColor: AppTheme.lightTheme.colorScheme.onPrimary,
    );
  }

  Widget _buildPriorityFilters() {
    return Wrap(
      spacing: 2.w,
      children: PinPriority.values.map((priority) {
        final isSelected = _filters.enabledPriorities.contains(priority);
        return FilterChip(
          label: Text(_getPriorityDisplayName(priority)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _filters.enabledPriorities.add(priority);
              } else {
                _filters.enabledPriorities.remove(priority);
              }
            });
          },
          selectedColor: _getPriorityColor(priority),
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _buildStatusFilters() {
    return Wrap(
      spacing: 2.w,
      children: PinStatus.values.map((status) {
        final isSelected = _filters.enabledStatuses.contains(status);
        return FilterChip(
          label: Text(_getStatusDisplayName(status)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _filters.enabledStatuses.add(status);
              } else {
                _filters.enabledStatuses.remove(status);
              }
            });
          },
          selectedColor: _getStatusColor(status),
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _buildVerificationFilters() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Show verified pins'),
          value: _filters.showVerified,
          onChanged: (value) {
            setState(() {
              _filters.showVerified = value ?? true;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Show unverified pins'),
          value: _filters.showUnverified,
          onChanged: (value) {
            setState(() {
              _filters.showUnverified = value ?? true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTimeRangeFilters() {
    return Column(
      children: [
        ListTile(
          title: const Text('Created within'),
          subtitle: Text(_getTimeRangeDisplayName(_filters.timeRange)),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: _showTimeRangeDialog,
        ),
      ],
    );
  }

  Widget _buildDistanceFilters() {
    return Column(
      children: [
        ListTile(
          title: const Text('Distance'),
          subtitle: Text(_filters.maxDistanceKm == null 
              ? 'Show all distances' 
              : 'Within ${_filters.maxDistanceKm!.toStringAsFixed(1)} km'),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: _showDistanceDialog,
        ),
        if (_filters.maxDistanceKm != null)
          Slider(
            value: _filters.maxDistanceKm!,
            min: 0.5,
            max: 50.0,
            divisions: 20,
            label: '${_filters.maxDistanceKm!.toStringAsFixed(1)} km',
            onChanged: (value) {
              setState(() {
                _filters.maxDistanceKm = value;
              });
            },
          ),
      ],
    );
  }

  void _toggleAllInGroup(List<PinType> types, bool enable) {
    setState(() {
      if (enable) {
        _filters.enabledTypes.addAll(types);
      } else {
        for (final type in types) {
          _filters.enabledTypes.remove(type);
        }
      }
    });
  }

  void _showTimeRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Time Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TimeRange.values.map((range) {
            return RadioListTile<TimeRange>(
              title: Text(_getTimeRangeDisplayName(range)),
              value: range,
              groupValue: _filters.timeRange,
              onChanged: (value) {
                setState(() {
                  _filters.timeRange = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDistanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Distance Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<double?>(
              title: const Text('Show all distances'),
              value: null,
              groupValue: _filters.maxDistanceKm,
              onChanged: (value) {
                setState(() {
                  _filters.maxDistanceKm = value;
                });
                Navigator.pop(context);
              },
            ),
            ...([1.0, 2.0, 5.0, 10.0, 25.0, 50.0].map((distance) {
              return RadioListTile<double?>(
                title: Text('Within ${distance.toStringAsFixed(0)} km'),
                value: distance,
                groupValue: _filters.maxDistanceKm,
                onChanged: (value) {
                  setState(() {
                    _filters.maxDistanceKm = value;
                  });
                  Navigator.pop(context);
                },
              );
            })),
          ],
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = PinFilterOptions.defaultFilters();
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.pop(context);
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

  String _getPriorityDisplayName(PinPriority priority) {
    switch (priority) {
      case PinPriority.low:
        return 'Low';
      case PinPriority.medium:
        return 'Medium';
      case PinPriority.high:
        return 'High';
      case PinPriority.critical:
        return 'Critical';
    }
  }

  Color _getStatusColor(PinStatus status) {
    switch (status) {
      case PinStatus.active:
        return Colors.green;
      case PinStatus.resolved:
        return Colors.blue;
      case PinStatus.verified:
        return Colors.teal;
      case PinStatus.needs_verification:
        return Colors.orange;
    }
  }

  String _getStatusDisplayName(PinStatus status) {
    switch (status) {
      case PinStatus.active:
        return 'Active';
      case PinStatus.resolved:
        return 'Resolved';
      case PinStatus.verified:
        return 'Verified';
      case PinStatus.needs_verification:
        return 'Needs Verification';
    }
  }

  String _getTimeRangeDisplayName(TimeRange range) {
    switch (range) {
      case TimeRange.all:
        return 'All time';
      case TimeRange.lastHour:
        return 'Last hour';
      case TimeRange.last6Hours:
        return 'Last 6 hours';
      case TimeRange.last24Hours:
        return 'Last 24 hours';
      case TimeRange.lastWeek:
        return 'Last week';
      case TimeRange.lastMonth:
        return 'Last month';
    }
  }
}

// Filter options data class
class PinFilterOptions {
  Set<PinType> enabledTypes;
  Set<PinPriority> enabledPriorities;
  Set<PinStatus> enabledStatuses;
  bool showVerified;
  bool showUnverified;
  TimeRange timeRange;
  double? maxDistanceKm;

  PinFilterOptions({
    required this.enabledTypes,
    required this.enabledPriorities,
    required this.enabledStatuses,
    required this.showVerified,
    required this.showUnverified,
    required this.timeRange,
    this.maxDistanceKm,
  });

  factory PinFilterOptions.defaultFilters() {
    return PinFilterOptions(
      enabledTypes: Set.from(PinType.values),
      enabledPriorities: Set.from(PinPriority.values),
      enabledStatuses: Set.from(PinStatus.values),
      showVerified: true,
      showUnverified: true,
      timeRange: TimeRange.all,
      maxDistanceKm: null,
    );
  }

  PinFilterOptions copyWith({
    Set<PinType>? enabledTypes,
    Set<PinPriority>? enabledPriorities,
    Set<PinStatus>? enabledStatuses,
    bool? showVerified,
    bool? showUnverified,
    TimeRange? timeRange,
    double? maxDistanceKm,
  }) {
    return PinFilterOptions(
      enabledTypes: enabledTypes ?? Set.from(this.enabledTypes),
      enabledPriorities: enabledPriorities ?? Set.from(this.enabledPriorities),
      enabledStatuses: enabledStatuses ?? Set.from(this.enabledStatuses),
      showVerified: showVerified ?? this.showVerified,
      showUnverified: showUnverified ?? this.showUnverified,
      timeRange: timeRange ?? this.timeRange,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    );
  }

  bool shouldShowPin(CommunityPin pin, {double? distanceFromUserKm}) {
    // Check type
    if (!enabledTypes.contains(pin.type)) return false;

    // Check priority
    if (!enabledPriorities.contains(pin.priority)) return false;

    // Check status
    if (!enabledStatuses.contains(pin.status)) return false;

    // Check verification
    final isVerified = pin.verifiedBy.isNotEmpty;
    if (isVerified && !showVerified) return false;
    if (!isVerified && !showUnverified) return false;

    // Check time range
    if (!_isWithinTimeRange(pin.createdAt)) return false;

    // Check distance
    if (maxDistanceKm != null && distanceFromUserKm != null) {
      if (distanceFromUserKm > maxDistanceKm!) return false;
    }

    return true;
  }

  bool _isWithinTimeRange(DateTime pinTime) {
    final now = DateTime.now();
    final difference = now.difference(pinTime);

    switch (timeRange) {
      case TimeRange.all:
        return true;
      case TimeRange.lastHour:
        return difference.inHours < 1;
      case TimeRange.last6Hours:
        return difference.inHours < 6;
      case TimeRange.last24Hours:
        return difference.inDays < 1;
      case TimeRange.lastWeek:
        return difference.inDays < 7;
      case TimeRange.lastMonth:
        return difference.inDays < 30;
    }
  }
}

enum TimeRange {
  all,
  lastHour,
  last6Hours,
  last24Hours,
  lastWeek,
  lastMonth,
}