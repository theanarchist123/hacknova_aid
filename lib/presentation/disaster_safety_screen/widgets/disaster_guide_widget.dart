import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class DisasterGuideWidget extends StatefulWidget {
  final String disasterType;
  final IconData iconData;
  final Color color;
  final String overview;
  final List<String> beforeSteps;
  final List<String> duringSteps;
  final List<String> afterSteps;

  const DisasterGuideWidget({
    super.key,
    required this.disasterType,
    required this.iconData,
    required this.color,
    required this.overview,
    required this.beforeSteps,
    required this.duringSteps,
    required this.afterSteps,
  });

  @override
  State<DisasterGuideWidget> createState() => _DisasterGuideWidgetState();
}

class _DisasterGuideWidgetState extends State<DisasterGuideWidget>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.iconData,
                      color: widget.color,
                      size: 6.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.disasterType,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Tap to view safety guidelines',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                            color: AppTheme.textMediumEmphasisLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: widget.color,
                      size: 6.w,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          SizeTransition(
            sizeFactor: _animation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview
                  _buildSectionTitle('Overview', Icons.info_outline),
                  SizedBox(height: 1.h),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.overview,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textHighEmphasisLight,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Before Section
                  _buildSectionTitle('Before ${widget.disasterType}', Icons.schedule),
                  SizedBox(height: 1.h),
                  _buildStepsList(widget.beforeSteps, Colors.blue.shade600),
                  SizedBox(height: 3.h),

                  // During Section
                  _buildSectionTitle('During ${widget.disasterType}', Icons.warning),
                  SizedBox(height: 1.h),
                  _buildStepsList(widget.duringSteps, Colors.orange.shade600),
                  SizedBox(height: 3.h),

                  // After Section
                  _buildSectionTitle('After ${widget.disasterType}', Icons.check_circle_outline),
                  SizedBox(height: 1.h),
                  _buildStepsList(widget.afterSteps, Colors.green.shade600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: widget.color,
          size: 5.w,
        ),
        SizedBox(width: 2.w),
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.color,
          ),
        ),
      ],
    );
  }

  Widget _buildStepsList(List<String> steps, Color stepColor) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        int index = entry.key;
        String step = entry.value;
        return Container(
          margin: EdgeInsets.only(bottom: 1.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 0.5.h, right: 3.w),
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: stepColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stepColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: stepColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  step,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textHighEmphasisLight,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}