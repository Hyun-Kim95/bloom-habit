import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/notifications/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  final NotificationService _notif = NotificationService();
  bool _enabled = false;
  int _hour = 9;
  int _minute = 0;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final enabled = await _notif.isEnabled();
    final time = await _notif.getScheduledTime();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _hour = time.hour;
        _minute = time.minute;
        _loading = false;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked != null && mounted) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
      await _save();
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _notif.saveAndReschedule(enabled: _enabled, hour: _hour, minute: _minute);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _toggleEnabled(bool value) async {
    if (value) {
      final granted = await _notif.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림 권한이 필요합니다. 설정에서 허용해 주세요.')),
        );
        return;
      }
    }
    setState(() => _enabled = value);
    await _notif.saveAndReschedule(enabled: value, hour: _hour, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          '알림',
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: SwitchListTile(
                    value: _enabled,
                    onChanged: (v) => _toggleEnabled(v),
                    title: Text(
                      '일일 리마인더',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                      ),
                    ),
                    subtitle: Text(
                      '매일 설정한 시간에 습관 확인 알림',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                    activeColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule, color: AppColors.primary),
                    title: Text(
                      '알림 시간',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                      ),
                    ),
                    trailing: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                    onTap: _enabled ? _pickTime : null,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '알림을 켜면 매일 정해진 시간에 "오늘의 습관" 리마인더가 울립니다. '
                    '알림 권한이 필요합니다.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
