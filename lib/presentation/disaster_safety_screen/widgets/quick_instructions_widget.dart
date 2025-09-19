import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class QuickInstructionsWidget extends StatelessWidget {
  const QuickInstructionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildQuickGuide(
          'Cyclone',
          Icons.cyclone,
          AppTheme.primaryLight,
          [
            'Monitor weather warnings',
            'Secure loose objects',
            'Stay indoors during storm',
            'Keep emergency kit ready',
            'Avoid flood waters'
          ],
          [
            'Don\'t ignore evacuation orders',
            'Don\'t use electrical appliances',
            'Don\'t go outside during eye',
            'Don\'t drive in strong winds',
            'Don\'t touch power lines'
          ],
        ),
        SizedBox(height: 2.h),
        _buildQuickGuide(
          'Floods',
          Icons.water,
          Colors.blue.shade600,
          [
            'Move to higher ground',
            'Turn off utilities',
            'Monitor flood warnings',
            'Keep emergency supplies',
            'Follow evacuation routes'
          ],
          [
            'Don\'t walk in moving water',
            'Don\'t drive through floods',
            'Don\'t drink flood water',
            'Don\'t return until safe',
            'Don\'t ignore warnings'
          ],
        ),
        SizedBox(height: 2.h),
        _buildQuickGuide(
          'Forest Fire',
          Icons.local_fire_department,
          Colors.orange.shade700,
          [
            'Evacuate when told',
            'Create defensible space',
            'Have evacuation plan',
            'Keep tools ready',
            'Monitor fire alerts'
          ],
          [
            'Don\'t delay evacuation',
            'Don\'t use water on grease fires',
            'Don\'t park on dry grass',
            'Don\'t throw cigarettes',
            'Don\'t return too early'
          ],
        ),
        SizedBox(height: 2.h),
        _buildQuickGuide(
          'Earthquake',
          Icons.landscape,
          Colors.brown.shade600,
          [
            'Drop, Cover, Hold On',
            'Stay where you are',
            'Protect head and neck',
            'Check for injuries after',
            'Be ready for aftershocks'
          ],
          [
            'Don\'t run outside',
            'Don\'t stand in doorways',
            'Don\'t use elevators',
            'Don\'t light matches',
            'Don\'t panic'
          ],
        ),
      ],
    );
  }

  Widget _buildQuickGuide(
    String disaster,
    IconData icon,
    Color color,
    List<String> dos,
    List<String> donts,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  disaster,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Quick Guide',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Container(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                // Do's Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 4.w,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'DO\'S',
                            style: AppTheme.lightTheme.textTheme.titleSmall
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      ...dos.map((item) => _buildQuickItem(
                        item,
                        Colors.green.shade600,
                        Icons.check,
                      )),
                    ],
                  ),
                ),
                
                // Divider
                Container(
                  width: 1,
                  height: 20.h,
                  color: Colors.grey.shade300,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                ),
                
                // Don'ts Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.cancel,
                            color: Colors.red.shade600,
                            size: 4.w,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'DON\'TS',
                            style: AppTheme.lightTheme.textTheme.titleSmall
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      ...donts.map((item) => _buildQuickItem(
                        item,
                        Colors.red.shade600,
                        Icons.close,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickItem(String text, Color color, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 0.2.h),
            child: Icon(
              icon,
              color: color,
              size: 3.w,
            ),
          ),
          SizedBox(width: 1.5.w),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textHighEmphasisLight,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}