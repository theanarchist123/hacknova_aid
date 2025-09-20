import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/community_pin.dart';
import '../../../core/app_export.dart';

class PinCreationBottomSheet extends StatefulWidget {
  final LatLng location;
  final Function(CommunityPin) onPinCreated;

  const PinCreationBottomSheet({
    super.key,
    required this.location,
    required this.onPinCreated,
  });

  @override
  State<PinCreationBottomSheet> createState() => _PinCreationBottomSheetState();
}

class _PinCreationBottomSheetState extends State<PinCreationBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final PageController _pageController = PageController();

  PinType _selectedType = PinType.hazard;
  PinPriority _selectedPriority = PinPriority.medium;
  int _currentPage = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
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
                if (_currentPage > 0)
                  IconButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: CustomIconWidget(
                      iconName: 'arrow_back',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                Expanded(
                  child: Text(
                    _getPageTitle(),
                    style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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

          // Progress indicator
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildTypeSelectionPage(),
                _buildDetailsPage(),
                _buildConfirmationPage(),
              ],
            ),
          ),

          // Bottom action button
          Padding(
            padding: EdgeInsets.all(4.w),
            child: SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: _getButtonAction(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _getButtonText(),
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelectionPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of pin do you want to create?',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          SizedBox(height: 2.h),

          // Hazards section
          Text(
            'Hazards & Dangers',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          _buildPinTypeGrid([
            PinType.hazard,
            PinType.fire,
            PinType.flood,
            PinType.landslide,
            PinType.blocked_road,
          ]),

          SizedBox(height: 3.h),

          // Resources section
          Text(
            'Resources & Safety',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          _buildPinTypeGrid([
            PinType.water_source,
            PinType.shelter,
            PinType.medical,
            PinType.food,
            PinType.safe_zone,
            PinType.evacuation_route,
            PinType.emergency_contact,
          ]),

          SizedBox(height: 3.h),

          // Other section
          Text(
            'Other',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          _buildPinTypeGrid([
            PinType.resource,
            PinType.other,
          ]),
          
          // Bottom padding to prevent overlap with button
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildPinTypeGrid(List<PinType> types) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 1.h,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        final isSelected = _selectedType == type;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = type;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: type.iconName,
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primary
                      : type.isHazard
                          ? Colors.red
                          : type.isResource
                              ? Colors.green
                              : AppTheme.lightTheme.colorScheme.onSurface,
                  size: 32,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  type.displayName,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected type display
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: _selectedType.iconName,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 32,
                ),
                SizedBox(width: 3.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedType.displayName,
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.location.latitude.toStringAsFixed(4)}, ${widget.location.longitude.toStringAsFixed(4)}',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Title field
          Text(
            'Title *',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Enter a descriptive title...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(
                Icons.title,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            maxLength: 50,
          ),

          SizedBox(height: 2.h),

          // Description field
          Text(
            'Description *',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'Provide more details...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(
                Icons.description,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            maxLines: 3,
            maxLength: 200,
          ),

          SizedBox(height: 2.h),

          // Priority selector
          Text(
            'Priority Level',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: PinPriority.values.map((priority) {
              final isSelected = _selectedPriority == priority;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPriority = priority;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 1.w),
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getPriorityColor(priority).withValues(alpha: 0.2)
                          : AppTheme.lightTheme.colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? _getPriorityColor(priority)
                            : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getPriorityDisplayName(priority),
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? _getPriorityColor(priority)
                            : AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          // Bottom padding to prevent overlap with button
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildConfirmationPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Confirm',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.h),

          // Pin preview
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(_selectedPriority).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: _selectedType.iconName,
                        color: _getPriorityColor(_selectedPriority),
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleController.text.isNotEmpty 
                                ? _titleController.text 
                                : 'Untitled ${_selectedType.displayName}',
                            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _selectedType.displayName,
                            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(_selectedPriority),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPriorityDisplayName(_selectedPriority).toUpperCase(),
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                if (_descriptionController.text.isNotEmpty) ...[
                  Text(
                    _descriptionController.text,
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: 2.h),
                ],

                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${widget.location.latitude.toStringAsFixed(6)}, ${widget.location.longitude.toStringAsFixed(6)}',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Info about sharing
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Sharing',
                        style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'This pin will be shared with nearby devices via Bluetooth mesh networking to help build a community hazard map.',
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom padding to prevent overlap with button
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_currentPage) {
      case 0:
        return 'Select Pin Type';
      case 1:
        return 'Add Details';
      case 2:
        return 'Review & Confirm';
      default:
        return 'Create Pin';
    }
  }

  String _getButtonText() {
    switch (_currentPage) {
      case 0:
        return 'Continue';
      case 1:
        return 'Continue';
      case 2:
        return 'Create Pin';
      default:
        return 'Continue';
    }
  }

  VoidCallback? _getButtonAction() {
    switch (_currentPage) {
      case 0:
        return () {
          print('🔧 Moving from type selection to details page');
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        };
      case 1:
        return _titleController.text.trim().isNotEmpty
            ? () {
                print('🔧 Moving from details to confirmation page');
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            : null;
      case 2:
        return () {
          print('🔧 Create pin button pressed');
          _createPin();
        };
      default:
        return null;
    }
  }

  void _createPin() {
    print('🔧 Creating pin with title: "${_titleController.text.trim()}"');
    print('🔧 Selected type: $_selectedType');
    print('🔧 Location: ${widget.location}');
    
    final pin = CommunityPin(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      location: widget.location,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'user_${DateTime.now().millisecondsSinceEpoch}', // TODO: Use actual device/user ID
    );

    print('🔧 Pin created, calling onPinCreated callback');
    widget.onPinCreated(pin);
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
}