import 'package:animal_sounds_flutter/pages/main_navigation_page.dart';
import 'package:animal_sounds_flutter/pages/settings.dart';
import 'package:animal_sounds_flutter/providers/category_provider.dart';
import 'package:animal_sounds_flutter/providers/favorites_provider.dart';
import 'package:animal_sounds_flutter/providers/quiz_provider.dart';
import 'package:animal_sounds_flutter/providers/search_provider.dart';
import 'package:animal_sounds_flutter/providers/settings_provider.dart';
import 'package:animal_sounds_flutter/providers/achievement_provider.dart';
import 'package:animal_sounds_flutter/providers/daily_provider.dart';
import 'package:animal_sounds_flutter/providers/discovery_provider.dart';
import 'package:animal_sounds_flutter/providers/challenge_provider.dart';
import 'package:animal_sounds_flutter/providers/game_provider.dart';
import 'package:animal_sounds_flutter/providers/usage_stats_provider.dart';
import 'package:animal_sounds_flutter/providers/coloring_provider.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:animal_sounds_flutter/services/notification_service.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:animal_sounds_flutter/widgets/achievement_unlock_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Ads and notifications start after the first frame (see
  // _AppWithDependenciesState) so a slow SDK start never delays the UI.
  runApp(EasyLocalization(
    supportedLocales: const [
      Locale('en', 'US'),
      Locale('tr', 'TR'),
      Locale('ru', 'RU'),
      Locale('pt', 'BR'),
      Locale('hi', 'IN'),
      Locale('es', 'ES'),
      Locale('ar', 'SA'),
      Locale('de', 'DE'),
    ],
    path: 'assets/translations',
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Set once the first-launch parent dialog has been requested in this
  /// process, so a navigator rebuild cannot stack a second copy.
  static bool _parentAlertRequested = false;

  @visibleForTesting
  static void resetParentAlertForTesting() => _parentAlertRequested = false;

  /// First-launch information for parents, with the daily-reminder offer.
  ///
  /// Shown once per install to anyone who has not already enabled reminders
  /// (see [shouldShowReminderOffer]).
  Future<void> showParentAlert(BuildContext context) async {
    if (_parentAlertRequested) return;
    _parentAlertRequested = true;
    final prefs = await SharedPreferences.getInstance();
    final notifications = NotificationService();
    final show = shouldShowReminderOffer(
      offerShown: prefs.getBool('reminder_offer_shown') ?? false,
      dailyReminderEnabled: await notifications.isDailyReminderEnabled(),
    );
    if (!show || !context.mounted) return;

    AnalyticsService().reminderOfferShown();
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('parent_alert_title'.tr()),
        content: SingleChildScrollView(
          child: Text('parent_alert_content'.tr()),
        ),
        actions: [
          TextButton(
            child: Text('reminder_offer_decline'.tr()),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            child: Text('reminder_offer_accept'.tr()),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    await prefs.setBool('reminder_offer_shown', true);

    if (accepted != true) {
      AnalyticsService().reminderOfferDeclined();
      return;
    }
    AnalyticsService().reminderOfferAccepted();
    final granted = await notifications.requestPermission();
    AnalyticsService().notificationPermission(granted);
    if (granted) {
      await notifications.scheduleDailyReminder(
        const TimeOfDay(hour: 18, minute: 0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => UsageStatsProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => DailyProvider()),
        ChangeNotifierProvider(create: (_) => DiscoveryProvider()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => ColoringProvider()),
      ],
      child: _AppWithDependencies(showParentAlert: showParentAlert),
    );
  }

  /// Builds the Material 3 [ThemeData] from the app color system.
  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.lightColorScheme,
      textTheme: AppTextStyles.textTheme,

      // Scaffold
      scaffoldBackgroundColor: AppColors.surface,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        titleTextStyle: AppTextStyles.headingSmall.copyWith(
          color: AppColors.onPrimary,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        elevation: 4,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.onSurfaceVariant,
        size: 24,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTextStyles.headingSmall.copyWith(
          color: AppColors.onSurface,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
      ),
    );
  }
}

/// Wrapper widget that has access to the providers via context,
/// allowing us to wire cross-provider dependencies and register listeners.
class _AppWithDependencies extends StatefulWidget {
  final Future<void> Function(BuildContext context) showParentAlert;

  const _AppWithDependencies({required this.showParentAlert});

  @override
  State<_AppWithDependencies> createState() => _AppWithDependenciesState();
}

class _AppWithDependenciesState extends State<_AppWithDependencies> {
  bool _dependenciesWired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pre-load rewarded ad so it is ready when first needed
      AdService().loadRewardedAd();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesWired) {
      _dependenciesWired = true;
      _wireDependencies();
    }
  }

  void _wireDependencies() {
    final achievementProvider =
        Provider.of<AchievementProvider>(context, listen: false);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final dailyProvider = Provider.of<DailyProvider>(context, listen: false);
    final usageStatsProvider =
        Provider.of<UsageStatsProvider>(context, listen: false);

    // Wire cross-provider dependencies
    quizProvider.setAchievementProvider(achievementProvider);
    dailyProvider.setAchievementProvider(achievementProvider);

    // Register achievement unlock listener to show celebration dialog
    achievementProvider.addUnlockListener((achievement) {
      if (mounted) {
        final navContext = _navigatorKey.currentContext;
        if (navContext != null) {
          showAchievementUnlockDialog(navContext, achievement);
        }
      }
    });

    // Track app opens
    usageStatsProvider.incrementAppOpens();
  }

  bool _remindersRefreshed = false;

  /// Re-schedules enabled reminders once per launch. Runs from the home
  /// route, where translations are guaranteed to be loaded.
  void _refreshReminders() {
    if (_remindersRefreshed) return;
    _remindersRefreshed = true;
    NotificationService().rescheduleEnabledReminders();
  }

  // Global navigator key for showing dialogs from provider callbacks
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => "app_name".tr(),
      theme: MyApp._buildTheme(),
      initialRoute: "/homePage",
      routes: {
        '/homePage': (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.showParentAlert(context);
            _refreshReminders();
          });
          return const MainNavigationPage();
        },
        '/settingsPage': (context) => const SettingsPage(),
      },
    );
  }
}
