import 'package:flutter/material.dart';
import '../../components/primary_app_bar.dart';
import '../../components/app_button.dart';
import '../../data/services/local_notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final _notificationService = LocalNotificationService();
  bool _isEnabled = false;
  int _selectedHour = 9;
  int _selectedMinute = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final enabled = await _notificationService.isReminderEnabled();
      final time = await _notificationService.getReminderTime();

      setState(() {
        _isEnabled = enabled;
        _selectedHour = time['hour']!;
        _selectedMinute = time['minute']!;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleReminder(bool value) async {
    setState(() => _isEnabled = value);
    await _notificationService.setReminderEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Đã bật nhắc nhở ôn tập' : 'Đã tắt nhắc nhở ôn tập',
          ),
          backgroundColor: value ? AppColors.success : Colors.grey,
        ),
      );
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
      });

      await _notificationService.setReminderTime(
        _selectedHour,
        _selectedMinute,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã đặt giờ nhắc nhở: ${_formatTime(_selectedHour, _selectedMinute)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showTestNotification();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi thông báo thử nghiệm!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _checkScheduledNotifications() async {
    await _notificationService.checkScheduledNotifications();
    final pending = await _notificationService.getPendingNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Có ${pending.length} thông báo đã lên lịch. Xem console để biết chi tiết.',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'CH' : 'SA';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Nhắc nhở ôn tập', showBack: true),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Nhận thông báo hàng ngày để nhớ ôn tập flashcard',
                              style: AppTypography.body.copyWith(
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Enable/Disable switch
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: SwitchListTile(
                        value: _isEnabled,
                        onChanged: _toggleReminder,
                        title: Text(
                          'Bật nhắc nhở',
                          style: AppTypography.bodyBold,
                        ),
                        subtitle: Text(
                          _isEnabled
                              ? 'Nhận thông báo hàng ngày'
                              : 'Không nhận thông báo',
                          style: AppTypography.caption,
                        ),
                        activeColor: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Time picker
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          'Giờ nhắc nhở',
                          style: AppTypography.bodyBold,
                        ),
                        subtitle: Text(
                          _formatTime(_selectedHour, _selectedMinute),
                          style: AppTypography.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _isEnabled ? _selectTime : null,
                        enabled: _isEnabled,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Test notification button
                    // if (_isEnabled) ...[
                    //   SecondaryButton(
                    //     label: 'Thử nghiệm thông báo',
                    //     onPressed: _testNotification,
                    //     icon: Icons.notifications_active,
                    //   ),
                    //   const SizedBox(height: 12),
                    //   OutlinedButton.icon(
                    //     onPressed: _checkScheduledNotifications,
                    //     icon: const Icon(Icons.info_outline, size: 20),
                    //     label: const Text('Kiểm tra lịch thông báo'),
                    //     style: OutlinedButton.styleFrom(
                    //       minimumSize: const Size(double.infinity, 48),
                    //       side: BorderSide(color: Colors.grey.shade400),
                    //       foregroundColor: Colors.grey.shade700,
                    //     ),
                    //   ),
                    // ],
                    const SizedBox(height: 32),

                    // Additional info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mẹo học tập',
                                style: AppTypography.bodyBold.copyWith(
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ôn tập đều đặn mỗi ngày sẽ giúp bạn ghi nhớ kiến thức lâu hơn. Hãy chọn thời gian phù hợp với lịch trình của bạn!',
                            style: AppTypography.body.copyWith(
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
