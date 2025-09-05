import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/contact_info_widget.dart';
import './widgets/description_input_widget.dart';
import './widgets/image_upload_widget.dart';
import './widgets/incident_type_dropdown_widget.dart';
import './widgets/location_picker_widget.dart';
import './widgets/progress_indicator_widget.dart';
import './widgets/severity_slider_widget.dart';

class IncidentReportingScreen extends StatefulWidget {
  const IncidentReportingScreen({Key? key}) : super(key: key);

  @override
  State<IncidentReportingScreen> createState() =>
      _IncidentReportingScreenState();
}

class _IncidentReportingScreenState extends State<IncidentReportingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Form data
  String? _selectedIncidentType;
  double _severityLevel = 5.0;
  String _selectedLocation = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _description = '';
  List<XFile> _selectedImages = [];
  String _contactName = '';
  String _contactPhone = '';
  String _contactEmail = '';
  bool _isAnonymous = false;
  DateTime _incidentDateTime = DateTime.now();
  bool _isEmergencyPriority = false;

  // UI state
  bool _isSubmitting = false;
  bool _isDraftSaved = false;

  @override
  void initState() {
    super.initState();
    _loadDraftData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadDraftData() {
    // Simulate loading draft data
    setState(() {
      _isDraftSaved = false;
    });
  }

  double _calculateProgress() {
    int completedFields = 0;
    int totalFields = 6;

    if (_selectedIncidentType != null) completedFields++;
    if (_selectedLocation.isNotEmpty) completedFields++;
    if (_description.isNotEmpty) completedFields++;
    if (_isAnonymous || (_contactName.isNotEmpty && _contactPhone.isNotEmpty))
      completedFields++;
    if (_severityLevel > 0) completedFields++;
    if (_selectedImages.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  int _getEstimatedTime() {
    double progress = _calculateProgress();
    if (progress >= 0.8) return 1;
    if (progress >= 0.5) return 3;
    return 5;
  }

  bool _validateForm() {
    if (_selectedIncidentType == null) {
      _showValidationError('Please select an incident type');
      return false;
    }
    if (_selectedLocation.isEmpty) {
      _showValidationError('Please provide a location');
      return false;
    }
    if (_description.isEmpty) {
      _showValidationError('Please provide a description');
      return false;
    }
    if (!_isAnonymous && (_contactName.isEmpty || _contactPhone.isEmpty)) {
      _showValidationError(
          'Please provide your contact information or report anonymously');
      return false;
    }
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveDraft() {
    setState(() {
      _isDraftSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'save',
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 2.w),
            Text('Draft saved successfully'),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_validateForm()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      // Create report data
      final Map<String, dynamic> reportData = {
        "id": DateTime.now().millisecondsSinceEpoch,
        "type": _selectedIncidentType,
        "severity": _severityLevel,
        "location": _selectedLocation,
        "coordinates": {"lat": _latitude, "lng": _longitude},
        "description": _description,
        "images": _selectedImages.map((img) => img.path).toList(),
        "contact": _isAnonymous
            ? null
            : {
                "name": _contactName,
                "phone": _contactPhone,
                "email": _contactEmail,
              },
        "timestamp": _incidentDateTime.toIso8601String(),
        "priority": _isEmergencyPriority,
        "status": "submitted",
      };

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                    'Report submitted successfully! Emergency services have been notified.'),
              ),
            ],
          ),
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back or to confirmation screen
      Navigator.pushReplacementNamed(context, '/home-dashboard-screen');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to submit report. It has been saved for later submission.'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Report Incident',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        foregroundColor: AppTheme.lightTheme.appBarTheme.foregroundColor,
        elevation: AppTheme.lightTheme.appBarTheme.elevation,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.appBarTheme.foregroundColor!,
            size: 24,
          ),
        ),
        actions: [
          if (_isDraftSaved)
            Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'cloud_done',
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                    size: 20,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Saved',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            onPressed: _saveDraft,
            icon: CustomIconWidget(
              iconName: 'save',
              color: AppTheme.lightTheme.appBarTheme.foregroundColor!,
              size: 24,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress Indicator
              Padding(
                padding: EdgeInsets.all(4.w),
                child: ProgressIndicatorWidget(
                  progress: _calculateProgress(),
                  estimatedTimeMinutes: _getEstimatedTime(),
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2.h),

                      // Emergency Priority Toggle
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: _isEmergencyPriority
                              ? AppTheme.lightTheme.colorScheme.error
                                  .withValues(alpha: 0.1)
                              : AppTheme.lightTheme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isEmergencyPriority
                                ? AppTheme.lightTheme.colorScheme.error
                                : AppTheme.lightTheme.colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Switch(
                              value: _isEmergencyPriority,
                              onChanged: (value) {
                                setState(() {
                                  _isEmergencyPriority = value;
                                });
                              },
                              activeColor:
                                  AppTheme.lightTheme.colorScheme.error,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency Priority',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: _isEmergencyPriority
                                          ? AppTheme
                                              .lightTheme.colorScheme.error
                                          : AppTheme
                                              .lightTheme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    _isEmergencyPriority
                                        ? 'This report will be escalated immediately'
                                        : 'Enable for life-threatening situations',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Incident Type Dropdown
                      IncidentTypeDropdownWidget(
                        selectedType: _selectedIncidentType,
                        onChanged: (value) {
                          setState(() {
                            _selectedIncidentType = value;
                          });
                        },
                      ),

                      SizedBox(height: 3.h),

                      // Severity Slider
                      SeveritySliderWidget(
                        severity: _severityLevel,
                        onChanged: (value) {
                          setState(() {
                            _severityLevel = value;
                          });
                        },
                      ),

                      SizedBox(height: 3.h),

                      // Location Picker
                      LocationPickerWidget(
                        selectedLocation: _selectedLocation,
                        onLocationSelected: (location, lat, lng) {
                          setState(() {
                            _selectedLocation = location;
                            _latitude = lat;
                            _longitude = lng;
                          });
                        },
                      ),

                      SizedBox(height: 3.h),

                      // Description Input
                      DescriptionInputWidget(
                        description: _description,
                        onChanged: (value) {
                          setState(() {
                            _description = value;
                          });
                        },
                      ),

                      SizedBox(height: 3.h),

                      // Image Upload
                      ImageUploadWidget(
                        selectedImages: _selectedImages,
                        onImagesChanged: (images) {
                          setState(() {
                            _selectedImages = images;
                          });
                        },
                      ),

                      SizedBox(height: 3.h),

                      // Date and Time
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'schedule',
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  "Incident Time",
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _incidentDateTime,
                                        firstDate: DateTime.now()
                                            .subtract(Duration(days: 7)),
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _incidentDateTime = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            _incidentDateTime.hour,
                                            _incidentDateTime.minute,
                                          );
                                        });
                                      }
                                    },
                                    icon: CustomIconWidget(
                                      iconName: 'calendar_today',
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                      size: 16,
                                    ),
                                    label: Text(
                                      "${_incidentDateTime.day}/${_incidentDateTime.month}/${_incidentDateTime.year}",
                                      style: AppTheme
                                          .lightTheme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(
                                            _incidentDateTime),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _incidentDateTime = DateTime(
                                            _incidentDateTime.year,
                                            _incidentDateTime.month,
                                            _incidentDateTime.day,
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      }
                                    },
                                    icon: CustomIconWidget(
                                      iconName: 'access_time',
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                      size: 16,
                                    ),
                                    label: Text(
                                      "${_incidentDateTime.hour.toString().padLeft(2, '0')}:${_incidentDateTime.minute.toString().padLeft(2, '0')}",
                                      style: AppTheme
                                          .lightTheme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Contact Information
                      ContactInfoWidget(
                        name: _contactName,
                        phone: _contactPhone,
                        email: _contactEmail,
                        isAnonymous: _isAnonymous,
                        onContactInfoChanged: (name, phone, email, anonymous) {
                          setState(() {
                            _contactName = name;
                            _contactPhone = phone;
                            _contactEmail = email;
                            _isAnonymous = anonymous;
                          });
                        },
                      ),

                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),

              // Submit Button
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightTheme.colorScheme.shadow,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEmergencyPriority
                        ? AppTheme.lightTheme.colorScheme.error
                        : AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              'Submitting Report...',
                              style: AppTheme.lightTheme.textTheme.bodyLarge
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: _isEmergencyPriority
                                  ? 'priority_high'
                                  : 'send',
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              _isEmergencyPriority
                                  ? 'Submit Emergency Report'
                                  : 'Submit Report',
                              style: AppTheme.lightTheme.textTheme.bodyLarge
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
