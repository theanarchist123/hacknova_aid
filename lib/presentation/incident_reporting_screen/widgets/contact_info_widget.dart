import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ContactInfoWidget extends StatefulWidget {
  final String name;
  final String phone;
  final String email;
  final bool isAnonymous;
  final Function(String, String, String, bool) onContactInfoChanged;

  const ContactInfoWidget({
    Key? key,
    required this.name,
    required this.phone,
    required this.email,
    required this.isAnonymous,
    required this.onContactInfoChanged,
  }) : super(key: key);

  @override
  State<ContactInfoWidget> createState() => _ContactInfoWidgetState();
}

class _ContactInfoWidgetState extends State<ContactInfoWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _phoneController.text = widget.phone;
    _emailController.text = widget.email;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updateContactInfo() {
    widget.onContactInfoChanged(
      _nameController.text,
      _phoneController.text,
      _emailController.text,
      widget.isAnonymous,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'person',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  "Contact Information",
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Checkbox(
                  value: widget.isAnonymous,
                  onChanged: (value) {
                    widget.onContactInfoChanged(
                      _nameController.text,
                      _phoneController.text,
                      _emailController.text,
                      value ?? false,
                    );
                  },
                  activeColor: AppTheme.lightTheme.colorScheme.primary,
                ),
                Expanded(
                  child: Text(
                    "Report anonymously",
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          if (!widget.isAnonymous) ...[
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 4.w).copyWith(bottom: 2.h),
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Full Name *",
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'person_outline',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => _updateContactInfo(),
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 4.w).copyWith(bottom: 2.h),
              child: TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number *",
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'phone',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) => _updateContactInfo(),
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 4.w).copyWith(bottom: 2.h),
              child: TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'email',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => _updateContactInfo(),
              ),
            ),
          ],
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 4.w).copyWith(bottom: 2.h),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'privacy_tip',
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 14,
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    widget.isAnonymous
                        ? "Your identity will remain completely anonymous"
                        : "Your information will be kept confidential and used only for emergency response",
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
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
