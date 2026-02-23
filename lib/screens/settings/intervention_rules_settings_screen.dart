import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/todo_model.dart';
import '../../services/app_blocker_service.dart';
import '../../services/app_logger.dart';

class InterventionRulesSettingsScreen extends StatefulWidget {
  const InterventionRulesSettingsScreen({super.key});

  @override
  State<InterventionRulesSettingsScreen> createState() =>
      _InterventionRulesSettingsScreenState();
}

class _InterventionRulesSettingsScreenState
    extends State<InterventionRulesSettingsScreen> {
  static const String _tag = 'InterventionRulesSettingsScreen';

  bool _isLoading = true;
  int _lowHours = AppBlockerService.defaultLowWindowHours;
  int _mediumHours = AppBlockerService.defaultMediumWindowHours;
  int _highHours = AppBlockerService.defaultHighWindowHours;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      final windows = await AppBlockerService.getInterventionWindows();

      if (!mounted) return;
      setState(() {
        _lowHours =
            windows[TodoPriority.low] ??
            AppBlockerService.defaultLowWindowHours;
        _mediumHours =
            windows[TodoPriority.medium] ??
            AppBlockerService.defaultMediumWindowHours;
        _highHours =
            windows[TodoPriority.high] ??
            AppBlockerService.defaultHighWindowHours;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to load intervention rules.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateWindow(TodoPriority priority, int nextValue) async {
    final clamped = nextValue.clamp(0, 48);

    final current = switch (priority) {
      TodoPriority.low => _lowHours,
      TodoPriority.medium => _mediumHours,
      TodoPriority.high => _highHours,
    };

    if (current == clamped) {
      return;
    }

    await AppBlockerService.saveInterventionWindow(priority, clamped);

    if (!mounted) return;
    setState(() {
      switch (priority) {
        case TodoPriority.low:
          _lowHours = clamped;
          break;
        case TodoPriority.medium:
          _mediumHours = clamped;
          break;
        case TodoPriority.high:
          _highHours = clamped;
          break;
      }
    });

    HapticFeedback.selectionClick();
  }

  Future<void> _resetDefaults() async {
    await AppBlockerService.saveInterventionWindow(
      TodoPriority.low,
      AppBlockerService.defaultLowWindowHours,
    );
    await AppBlockerService.saveInterventionWindow(
      TodoPriority.medium,
      AppBlockerService.defaultMediumWindowHours,
    );
    await AppBlockerService.saveInterventionWindow(
      TodoPriority.high,
      AppBlockerService.defaultHighWindowHours,
    );

    if (!mounted) return;
    setState(() {
      _lowHours = AppBlockerService.defaultLowWindowHours;
      _mediumHours = AppBlockerService.defaultMediumWindowHours;
      _highHours = AppBlockerService.defaultHighWindowHours;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan urgensi dikembalikan ke default'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.black87),
        ),
        actions: [
          IconButton(
            onPressed: _resetDefaults,
            icon: Icon(Icons.restart_alt, color: Colors.grey[700]),
            tooltip: 'Reset default',
          ),
        ],
        title: Text(
          'Aturan Intervensi',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A6FA5)),
            )
          : ListView(
              padding: EdgeInsets.all(20.r),
              children: [
                _buildInfoCard(),
                SizedBox(height: 12.h),
                _buildCompactRuleTile(
                  label: 'Low',
                  color: Colors.grey[500]!,
                  value: _lowHours,
                  onDecrease: () =>
                      _updateWindow(TodoPriority.low, _lowHours - 1),
                  onIncrease: () =>
                      _updateWindow(TodoPriority.low, _lowHours + 1),
                ),
                SizedBox(height: 8.h),
                _buildCompactRuleTile(
                  label: 'Medium',
                  color: Colors.grey[700]!,
                  value: _mediumHours,
                  onDecrease: () =>
                      _updateWindow(TodoPriority.medium, _mediumHours - 1),
                  onIncrease: () =>
                      _updateWindow(TodoPriority.medium, _mediumHours + 1),
                ),
                SizedBox(height: 8.h),
                _buildCompactRuleTile(
                  label: 'High',
                  color: const Color(0xFF4A6FA5),
                  value: _highHours,
                  onDecrease: () =>
                      _updateWindow(TodoPriority.high, _highHours - 1),
                  onIncrease: () =>
                      _updateWindow(TodoPriority.high, _highHours + 1),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'Atur berapa jam sebelum deadline agar intervensi aktif. Nilai 0 jam berarti prioritas tersebut tidak memicu intervensi.',
        style: TextStyle(
          fontSize: 13.sp,
          color: Colors.grey[700],
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildCompactRuleTile({
    required String label,
    required Color color,
    required int value,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          _buildStepButton(
            icon: Icons.remove,
            enabled: value > 0,
            onTap: onDecrease,
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              '$value jam',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          _buildStepButton(
            icon: Icons.add,
            enabled: value < 48,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 32.w,
      height: 32.w,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.grey[100] : Colors.grey[50],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 18.sp,
            color: enabled ? Colors.black87 : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
