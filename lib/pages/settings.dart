import 'package:animal_sounds_flutter/providers/settings_provider.dart';
import 'package:animal_sounds_flutter/services/notification_service.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '';

  // Notification state
  bool _dailyReminderEnabled = false;
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 10, minute: 0);
  bool _streakReminderEnabled = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _loadNotificationPrefs();
  }

  Future<void> _getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _loadNotificationPrefs() async {
    final dailyEnabled = await _notificationService.isDailyReminderEnabled();
    final dailyTime = await _notificationService.getDailyReminderTime();
    final streakEnabled = await _notificationService.isStreakReminderEnabled();
    setState(() {
      _dailyReminderEnabled = dailyEnabled;
      _dailyReminderTime = dailyTime;
      _streakReminderEnabled = streakEnabled;
    });
  }

  Future<void> _onDailyReminderToggled(bool value) async {
    setState(() => _dailyReminderEnabled = value);
    if (value) {
      await _notificationService.requestPermission();
      await _notificationService.scheduleDailyReminder(_dailyReminderTime);
    } else {
      await _notificationService.cancelDailyReminder();
    }
  }

  Future<void> _onStreakReminderToggled(bool value) async {
    setState(() => _streakReminderEnabled = value);
    if (value) {
      await _notificationService.requestPermission();
      await _notificationService.scheduleStreakReminder();
    } else {
      await _notificationService.cancelStreakReminder();
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dailyReminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: AppColors.lightColorScheme,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dailyReminderTime = picked);
      if (_dailyReminderEnabled) {
        await _notificationService.scheduleDailyReminder(picked);
      }
    }
  }

  void onTap() {
    AppSettings.openAppSettingsPanel(AppSettingsPanelType.volume);
  }

  IconData _volumeIcon(double level) {
    if (level <= 0.0) return Icons.volume_off_rounded;
    if (level < 0.4) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final double soundLevel = settingsProvider.getAnimalSoundLevel;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.onSurface,
        title: Text(
          'settings'.tr(),
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Sound Settings Section ---
              _SectionHeader(title: 'sound_settings'.tr()),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  // System volume tile
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.speaker_rounded,
                              color: AppColors.primaryDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'system_volume'.tr(),
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'adjust_system_volume'.tr(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.outline.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.outlineVariant.withOpacity(0.4),
                  ),

                  // App sound level slider
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'app_sound_level'.tr(),
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(soundLevel * 100).round()}%',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              _volumeIcon(soundLevel),
                              color: soundLevel <= 0.0
                                  ? AppColors.outline
                                  : AppColors.primary,
                              size: 22,
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor:
                                      AppColors.primaryContainer.withOpacity(0.5),
                                  thumbColor: AppColors.primary,
                                  overlayColor:
                                      AppColors.primary.withOpacity(0.12),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8,
                                    elevation: 2,
                                    pressedElevation: 4,
                                  ),
                                  trackHeight: 4,
                                  trackShape: const RoundedRectSliderTrackShape(),
                                ),
                                child: Slider(
                                  value: soundLevel,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: (value) {
                                    settingsProvider.setAnimalSoundLevel = value;
                                  },
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.volume_up_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // --- Notifications Section ---
              _SectionHeader(title: 'notifications'.tr()),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  // Daily reminder toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: AppColors.secondaryDark,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'daily_reminder'.tr(),
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'daily_reminder_desc'.tr(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _dailyReminderEnabled,
                          onChanged: _onDailyReminderToggled,
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.outlineVariant.withOpacity(0.4),
                  ),

                  // Reminder time picker
                  InkWell(
                    onTap: _dailyReminderEnabled ? _pickReminderTime : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.tertiaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.access_time_rounded,
                              color: AppColors.tertiaryDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'reminder_time'.tr(),
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _dailyReminderEnabled
                                        ? AppColors.onSurface
                                        : AppColors.outline,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'reminder_time_desc'.tr(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: _dailyReminderEnabled
                                        ? AppColors.onSurfaceVariant
                                        : AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _dailyReminderTime.format(context),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _dailyReminderEnabled
                                  ? AppColors.primary
                                  : AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.outlineVariant.withOpacity(0.4),
                  ),

                  // Streak reminder toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.warningContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.warning,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'streak_reminder'.tr(),
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'streak_reminder_desc'.tr(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _streakReminderEnabled,
                          onChanged: _onStreakReminderToggled,
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // --- App Info Section ---
              _SectionHeader(title: 'app_info'.tr()),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  _InfoRow(
                    title: 'version'.tr(),
                    value: _version,
                    icon: Icons.info_outline_rounded,
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.outlineVariant.withOpacity(0.4),
                  ),
                  _InfoRow(
                    title: 'developer'.tr(),
                    value: 'DevOrk',
                    icon: Icons.code_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable sub-widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.headingSmall.copyWith(
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
