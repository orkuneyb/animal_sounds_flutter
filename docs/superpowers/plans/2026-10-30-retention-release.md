# 1.3.0 Retention Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship 1.3.0+10: a daily-reminder offer in the parent dialog, a non-repeating daily animal, parent-only rate/share actions, and Firebase Analytics + Crashlytics configured for a children's app.

**Architecture:** All new behaviour sits behind three small services (`AnalyticsService`, `ReviewService`, `NotificationService` additions) and one pure utility (`DailyAnimalCycle`). `AnalyticsService` takes a pluggable backend so Tasks 1–5 build and run without Firebase; Task 6 plugs Firebase in once `google-services.json` exists. Every decision rule (when to show the offer, when to auto-prompt a review, which animal is today's) is a pure function with unit tests; plugin calls are thin and swallow errors.

**Tech Stack:** Flutter 3.41 / Dart 3, Provider, easy_localization, shared_preferences, flutter_local_notifications 18, google_mobile_ads 6, in_app_review 2.0.x, share_plus 13.x, firebase_core 5.x, firebase_analytics 13.x, firebase_crashlytics 6.x.

**Spec:** `docs/superpowers/specs/2026-10-30-retention-release-design.md`

## Global Constraints

- Version string in `pubspec.yaml` must end as `1.3.0+10` (Task 7). Do not bump earlier.
- No analytics call may identify a person: no `setUserId`, no user properties, no email/device identifiers in parameters.
- Manifest must carry `google_analytics_adid_collection_enabled=false` and `google_analytics_default_allow_ad_personalization_signals=false` (Task 6).
- `com.google.android.gms.permission.AD_ID` stays removed (`tools:node="remove"`); the existing `test/android_manifest_test.dart` guards it.
- Every translation key added must exist in all 8 files under `assets/translations/` (`en-US`, `tr-TR`, `ru-RU`, `pt-BR`, `hi-IN`, `es-ES`, `ar-SA`, `de-DE`); `test/translations_test.dart` fails otherwise.
- Analytics, review and share calls never throw to the UI; failures go to `debugPrint`.
- Rating UI (system review sheet, store listing) is reachable only from the parent dashboard, which is behind the parent gate.
- Commit messages: no `Co-Authored-By` line (project rule).
- Run `flutter test` and `flutter analyze --no-pub` before every commit; the analyzer must report no `error` lines (191 pre-existing `info`/`warning` lines are known).
- Default reminder time offered from the dialog: 18:00. `NotificationService.scheduleDailyReminder` already persists hour/minute so Settings shows it.

## Review Focus

1. Notification permission denied after the parent taps "Turn on daily reminder": nothing is scheduled, the offer is marked shown, no exception. Pinned in Task 4 (`shouldShowReminderOffer` tests + the `granted == false` branch in `showParentAlert`).
2. Day number across a daylight-saving change or a year boundary: consecutive calendar dates must map to consecutive day numbers, never the same one twice. Pinned in Task 2 (`dayNumber` tests use UTC construction and a year-boundary case).
3. Existing users who already saw the old parent alert (`has_shown_parent_alert == true`) but never enabled reminders: the offer appears exactly once more; users with reminders already on never see it. Pinned in Task 4 (`shouldShowReminderOffer` tests).
4. Review auto-prompt storm: the automatic prompt must record its timestamp *before* calling the plugin so a slow or throwing plugin cannot cause repeat prompts on the next dashboard open. Pinned in Task 5 (`shouldAutoPromptReview` tests + ordering in `maybeAutoPrompt`).
5. Analytics backend throwing (e.g. Firebase not initialised, platform channel missing in tests): the call must be swallowed, the app must continue. Pinned in Task 1 (`AnalyticsService` test with a failing backend).

---

### Task 1: AnalyticsService with pluggable backend

**Files:**
- Create: `lib/services/analytics_service.dart`
- Test: `test/analytics_service_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `typedef AnalyticsBackend = Future<void> Function(String name, Map<String, Object>? parameters);`
  - `class AnalyticsService` singleton (`AnalyticsService()` factory) with
    `void setBackend(AnalyticsBackend? backend)`,
    `void logEvent(String name, [Map<String, Object>? parameters])`,
    and named helpers used by later tasks:
    `soundPlayed(String animal)`, `dailyDiscoveryCompleted(int streak)`,
    `quizCompleted(int score)`, `soundGameOver(int score)`,
    `reminderOfferShown()`, `reminderOfferAccepted()`, `reminderOfferDeclined()`,
    `notificationPermission(bool granted)`, `rewardedAdWatched(String placement)`,
    `parentDashboardOpened()`, `reviewPrompted({required bool automatic})`,
    `shareTapped()`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/analytics_service_test.dart
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<(String, Map<String, Object>?)> captured;

  setUp(() {
    captured = [];
    AnalyticsService().setBackend((name, params) async {
      captured.add((name, params));
    });
  });

  tearDown(() => AnalyticsService().setBackend(null));

  test('forwards events to the backend', () {
    AnalyticsService().logEvent('sound_played', {'animal': 'lion'});

    expect(captured, [('sound_played', {'animal': 'lion'})]);
  });

  test('named helpers use the event names from the spec', () {
    final service = AnalyticsService();
    service.soundPlayed('cow');
    service.dailyDiscoveryCompleted(3);
    service.quizCompleted(4);
    service.soundGameOver(7);
    service.reminderOfferShown();
    service.reminderOfferAccepted();
    service.reminderOfferDeclined();
    service.notificationPermission(true);
    service.rewardedAdWatched('quiz_hint');
    service.parentDashboardOpened();
    service.reviewPrompted(automatic: false);
    service.shareTapped();

    expect(captured.map((e) => e.$1).toList(), [
      'sound_played',
      'daily_discovery_completed',
      'quiz_completed',
      'sound_game_over',
      'reminder_offer_shown',
      'reminder_offer_accepted',
      'reminder_offer_declined',
      'notification_permission',
      'rewarded_ad_watched',
      'parent_dashboard_opened',
      'review_prompted',
      'share_tapped',
    ]);
    expect(captured[1].$2, {'streak': 3});
    expect(captured[7].$2, {'granted': 1});
    expect(captured[10].$2, {'automatic': 0});
  });

  test('a throwing backend does not propagate', () async {
    AnalyticsService().setBackend((_, __) => Future.error(StateError('down')));

    expect(() => AnalyticsService().logEvent('sound_played'), returnsNormally);
    await Future<void>.delayed(Duration.zero); // let the error surface if it was going to
  });

  test('without a backend events are dropped silently', () {
    AnalyticsService().setBackend(null);

    expect(() => AnalyticsService().logEvent('sound_played'), returnsNormally);
    expect(captured, isEmpty);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/analytics_service_test.dart`
Expected: compile error — `analytics_service.dart` does not exist.

- [ ] **Step 3: Write the service**

```dart
// lib/services/analytics_service.dart
import 'package:flutter/foundation.dart';

/// Sends one event to whatever analytics backend is plugged in.
typedef AnalyticsBackend = Future<void> Function(
  String name,
  Map<String, Object>? parameters,
);

/// Single entry point for product analytics.
///
/// The backend is injected (see `main.dart`) so the app, and every test,
/// runs without Firebase. Calls are fire-and-forget and never throw.
/// Parameters are limited to strings and numbers; booleans are sent as 1/0
/// because Firebase Analytics does not accept bool parameters.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService _instance = AnalyticsService._();

  factory AnalyticsService() => _instance;

  AnalyticsBackend? _backend;

  void setBackend(AnalyticsBackend? backend) => _backend = backend;

  void logEvent(String name, [Map<String, Object>? parameters]) {
    final backend = _backend;
    if (backend == null) return;
    try {
      backend(name, parameters).catchError((Object error) {
        debugPrint('Analytics event "$name" failed: $error');
      });
    } catch (error) {
      debugPrint('Analytics event "$name" failed: $error');
    }
  }

  // --- Named events (keep in sync with the spec's event table) ---

  void soundPlayed(String animal) => logEvent('sound_played', {'animal': animal});

  void dailyDiscoveryCompleted(int streak) =>
      logEvent('daily_discovery_completed', {'streak': streak});

  void quizCompleted(int score) => logEvent('quiz_completed', {'score': score});

  void soundGameOver(int score) => logEvent('sound_game_over', {'score': score});

  void reminderOfferShown() => logEvent('reminder_offer_shown');

  void reminderOfferAccepted() => logEvent('reminder_offer_accepted');

  void reminderOfferDeclined() => logEvent('reminder_offer_declined');

  void notificationPermission(bool granted) =>
      logEvent('notification_permission', {'granted': granted ? 1 : 0});

  void rewardedAdWatched(String placement) =>
      logEvent('rewarded_ad_watched', {'placement': placement});

  void parentDashboardOpened() => logEvent('parent_dashboard_opened');

  void reviewPrompted({required bool automatic}) =>
      logEvent('review_prompted', {'automatic': automatic ? 1 : 0});

  void shareTapped() => logEvent('share_tapped');
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/analytics_service_test.dart`
Expected: 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/services/analytics_service.dart test/analytics_service_test.dart
git commit -m "feat: Add AnalyticsService with pluggable backend"
```

---

### Task 2: Non-repeating daily animal

**Files:**
- Create: `lib/utils/daily_animal_cycle.dart`
- Modify: `lib/providers/daily_provider.dart` (method `getDailyAnimal`, around line 47, and `completeDailyDiscovery`, around line 68)
- Test: `test/daily_animal_cycle_test.dart`, `test/daily_provider_test.dart`

**Interfaces:**
- Consumes: `AnalyticsService().dailyDiscoveryCompleted(int)` from Task 1.
- Produces:
  - `class DailyAnimalCycle { const DailyAnimalCycle(int length); int indexForDay(int dayNumber); static int dayNumber(DateTime date); }`
  - `DailyProvider.getDailyAnimal()` keeps its signature (`Animal getDailyAnimal()`).

- [ ] **Step 1: Write the failing cycle tests**

```dart
// test/daily_animal_cycle_test.dart
import 'package:animal_sounds_flutter/utils/daily_animal_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cycle = DailyAnimalCycle(30);

  test('30 consecutive days from a cycle start show 30 different animals', () {
    final seen = {for (var day = 60; day < 90; day++) cycle.indexForDay(day)};

    expect(seen, hasLength(30));
  });

  test('30 consecutive days starting mid-cycle never repeat within a cycle', () {
    // days 75..89 belong to cycle 2, days 90..104 to cycle 3
    final firstHalf = {for (var day = 75; day < 90; day++) cycle.indexForDay(day)};
    final secondHalf = {for (var day = 90; day < 105; day++) cycle.indexForDay(day)};

    expect(firstHalf, hasLength(15));
    expect(secondHalf, hasLength(15));
  });

  test('consecutive days never share an animal across 200 cycle boundaries', () {
    for (var boundary = 1; boundary <= 200; boundary++) {
      final day = boundary * 30;
      expect(
        cycle.indexForDay(day),
        isNot(cycle.indexForDay(day - 1)),
        reason: 'boundary at day $day repeats yesterday\'s animal',
      );
    }
  });

  test('every index stays inside the animal list', () {
    for (var day = 0; day < 3000; day++) {
      expect(cycle.indexForDay(day), inInclusiveRange(0, 29));
    }
  });

  test('the same day always gives the same animal', () {
    expect(cycle.indexForDay(12345), cycle.indexForDay(12345));
  });

  group('dayNumber', () {
    test('counts days since 1970-01-01 regardless of the time of day', () {
      expect(DailyAnimalCycle.dayNumber(DateTime(1970, 1, 1, 23, 59)), 0);
      expect(DailyAnimalCycle.dayNumber(DateTime(1970, 1, 2, 0, 1)), 1);
    });

    test('consecutive dates across a year boundary differ by exactly one', () {
      final dec31 = DailyAnimalCycle.dayNumber(DateTime(2026, 12, 31));
      final jan1 = DailyAnimalCycle.dayNumber(DateTime(2027, 1, 1));

      expect(jan1 - dec31, 1);
    });

    test('consecutive dates across the March DST change differ by exactly one', () {
      // Local midnights may be 23 or 25 hours apart; the day number must not care.
      final before = DailyAnimalCycle.dayNumber(DateTime(2026, 3, 29));
      final after = DailyAnimalCycle.dayNumber(DateTime(2026, 3, 30));

      expect(after - before, 1);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/daily_animal_cycle_test.dart`
Expected: compile error — `daily_animal_cycle.dart` does not exist.

- [ ] **Step 3: Write the cycle**

```dart
// lib/utils/daily_animal_cycle.dart
import 'dart:math';

/// Picks the animal of the day so that every animal appears exactly once per
/// cycle of [length] days and no two consecutive days share an animal.
///
/// Stateless and deterministic: the same day number always maps to the same
/// index on every device. Requires [length] >= 3.
class DailyAnimalCycle {
  const DailyAnimalCycle(this.length);

  /// Number of animals, which is also the cycle length in days.
  final int length;

  /// Days since 1970-01-01 for the calendar date of [date], using UTC
  /// construction so daylight-saving changes cannot skip or repeat a day.
  static int dayNumber(DateTime date) {
    final utcMidnight = DateTime.utc(date.year, date.month, date.day);
    return utcMidnight.difference(DateTime.utc(1970)).inDays;
  }

  int indexForDay(int dayNumber) {
    final cycle = dayNumber ~/ length;
    final position = dayNumber % length;
    return _permutation(cycle)[position];
  }

  /// The shuffled order for [cycle], adjusted so its first animal differs
  /// from the previous cycle's last animal.
  List<int> _permutation(int cycle) {
    final order = _shuffled(cycle);
    if (cycle > 0 && order.first == _shuffled(cycle - 1).last) {
      final first = order[0];
      order[0] = order[1];
      order[1] = first;
    }
    return order;
  }

  List<int> _shuffled(int cycle) =>
      List<int>.generate(length, (i) => i)..shuffle(Random(cycle));
}
```

Note: swapping positions 0 and 1 never changes `.last` while `length >= 3`, so comparing against the *unadjusted* previous permutation is exact.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/daily_animal_cycle_test.dart`
Expected: 8 tests pass.

- [ ] **Step 5: Write the failing provider test**

```dart
// test/daily_provider_test.dart
import 'package:animal_sounds_flutter/providers/daily_provider.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:animal_sounds_flutter/utils/daily_animal_cycle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService().setBackend(null);
  });

  test("today's animal comes from the non-repeating cycle", () {
    final provider = DailyProvider();
    final expectedIndex = DailyAnimalCycle(AnimalRepository.animals.length)
        .indexForDay(DailyAnimalCycle.dayNumber(DateTime.now()));

    expect(provider.getDailyAnimal().index, expectedIndex);
  });

  test('completing the daily discovery logs the new streak', () async {
    final events = <(String, Map<String, Object>?)>[];
    AnalyticsService().setBackend((name, params) async => events.add((name, params)));
    final provider = DailyProvider();
    await Future<void>.delayed(Duration.zero); // let _init() load prefs

    await provider.completeDailyDiscovery();

    expect(events, contains(('daily_discovery_completed', {'streak': 1})));
  });
}
```

- [ ] **Step 6: Run the provider test to verify it fails**

Run: `flutter test test/daily_provider_test.dart`
Expected: first test FAILS (today's animal is still chosen by the old independent random draw — it will only pass by coincidence 1 day in 30); second test FAILS because no event is logged.

- [ ] **Step 7: Update `DailyProvider`**

In `lib/providers/daily_provider.dart`, add the imports:

```dart
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:animal_sounds_flutter/utils/daily_animal_cycle.dart';
```

Replace the body of `getDailyAnimal()`:

```dart
  /// Returns today's animal from a shuffled cycle so that every animal
  /// appears once per 30 days and no animal repeats on consecutive days.
  Animal getDailyAnimal() {
    final animals = AnimalRepository.animals;
    final index = DailyAnimalCycle(animals.length)
        .indexForDay(DailyAnimalCycle.dayNumber(DateTime.now()));
    return animals[index];
  }
```

Leave `getDailyFunFact()` as it is (it calls `getDailyAnimal()` and keeps its own date seed for the fact).

In `completeDailyDiscovery()`, after `_checkStreakAchievements();` add:

```dart
    AnalyticsService().dailyDiscoveryCompleted(_streak.currentStreak);
```

- [ ] **Step 8: Run all tests**

Run: `flutter test`
Expected: all pass (previous 18 + 4 + 8 + 2).

- [ ] **Step 9: Commit**

```bash
git add lib/utils/daily_animal_cycle.dart lib/providers/daily_provider.dart test/daily_animal_cycle_test.dart test/daily_provider_test.dart
git commit -m "feat: Pick the daily animal from a non-repeating 30-day cycle"
```

---

### Task 3: Gameplay analytics hooks

**Files:**
- Modify: `lib/providers/quiz_provider.dart` (`saveScore`, around line 33)
- Modify: `lib/providers/game_provider.dart` (`checkAnswer`, around line 96)
- Modify: `lib/pages/animal_sound_page.dart` (`_playAnimalAudio`, around line 201)
- Modify: `lib/widgets/rewarded_ad_button.dart` (constructor around line 27, `_onTap` around line 71)
- Modify call sites: `lib/pages/quiz_page.dart:157`, `:209`, `:840`; `lib/pages/achievements_page.dart:398`; `lib/pages/animal_sound_page.dart:503`
- Test: `test/quiz_provider_test.dart`

**Interfaces:**
- Consumes: `AnalyticsService` helpers from Task 1.
- Produces: `RewardedAdButton` gains `final String placement;` (required, stable English identifier).

- [ ] **Step 1: Write the failing quiz provider test**

```dart
// test/quiz_provider_test.dart
import 'package:animal_sounds_flutter/models/quiz_score.dart';
import 'package:animal_sounds_flutter/providers/quiz_provider.dart';
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saving a quiz score logs quiz_completed with the correct answers', () async {
    SharedPreferences.setMockInitialValues({});
    final events = <(String, Map<String, Object>?)>[];
    AnalyticsService().setBackend((name, params) async => events.add((name, params)));
    addTearDown(() => AnalyticsService().setBackend(null));
    final provider = QuizProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.saveScore(QuizScore(
      correctAnswers: 4,
      totalQuestions: 5,
      dateTime: DateTime(2026, 10, 30),
    ));

    expect(events, contains(('quiz_completed', {'score': 4})));
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/quiz_provider_test.dart`
Expected: FAIL — `events` does not contain `quiz_completed`.

- [ ] **Step 3: Add the provider hooks**

`lib/providers/quiz_provider.dart`: add `import 'package:animal_sounds_flutter/services/analytics_service.dart';` and, as the first line inside `saveScore`:

```dart
    AnalyticsService().quizCompleted(score.correctAnswers);
```

`lib/providers/game_provider.dart`: add the same import and, inside `checkAnswer` in the `else` branch right after `saveHighScore();`:

```dart
      AnalyticsService().soundGameOver(_currentScore);
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/quiz_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Add the widget hooks**

`lib/pages/animal_sound_page.dart`: add `import 'package:animal_sounds_flutter/services/analytics_service.dart';` and in `_playAnimalAudio`, immediately after `await audioPlayer.play(AssetSource(cleanPath));`:

```dart
      AnalyticsService().soundPlayed(widget.animal.name);
```

`lib/widgets/rewarded_ad_button.dart`: add the import, add the field and constructor parameter:

```dart
  /// Stable identifier of where this button lives, for analytics
  /// (e.g. 'quiz_hint'). Never localized.
  final String placement;
```

```dart
  const RewardedAdButton({
    Key? key,
    required this.rewardDescription,
    required this.placement,
    required this.onRewardEarned,
    this.icon = Icons.play_circle_filled_rounded,
    this.gradientColors,
    this.compact = false,
  }) : super(key: key);
```

and in `_onTap`, inside `onReward: (amount) { if (mounted) { ... } }`, before `widget.onRewardEarned(amount);`:

```dart
          AnalyticsService().rewardedAdWatched(widget.placement);
```

Add `placement:` to the five call sites, next to `rewardDescription:`:

| File:line | `rewardDescription` key | `placement` |
|---|---|---|
| `lib/pages/quiz_page.dart:157` | `watch_ad_hint` | `'quiz_hint'` |
| `lib/pages/quiz_page.dart:209` | `watch_ad_extra_life` | `'quiz_extra_life'` |
| `lib/pages/quiz_page.dart:840` | `watch_ad_double_score` | `'quiz_double_score'` |
| `lib/pages/achievements_page.dart:398` | `watch_ad_achievement_hint` | `'achievement_hint'` |
| `lib/pages/animal_sound_page.dart:503` | `watch_ad_fun_fact` | `'fun_fact'` |

- [ ] **Step 6: Verify the build is clean**

Run: `flutter analyze --no-pub 2>&1 | grep -E "^\s*error"` (expect no output) and `flutter test` (expect all pass).

- [ ] **Step 7: Commit**

```bash
git add lib/providers/quiz_provider.dart lib/providers/game_provider.dart lib/pages/animal_sound_page.dart lib/widgets/rewarded_ad_button.dart lib/pages/quiz_page.dart lib/pages/achievements_page.dart test/quiz_provider_test.dart
git commit -m "feat: Log gameplay and rewarded-ad analytics events"
```

---

### Task 4: Daily reminder offer in the parent dialog

**Files:**
- Modify: `lib/services/notification_service.dart` (add a pure function next to `nextLocalInstanceOf`)
- Modify: `lib/main.dart` (`showParentAlert`, lines 55–80)
- Modify: all 8 files in `assets/translations/` (3 keys)
- Test: `test/notification_schedule_test.dart` (extend), `test/translations_test.dart` (extend)

**Interfaces:**
- Consumes: `NotificationService.requestPermission()`, `scheduleDailyReminder(TimeOfDay)`, `isDailyReminderEnabled()` (exist since 1.2.1); `AnalyticsService` helpers from Task 1.
- Produces: `bool shouldShowReminderOffer({required bool offerShown, required bool dailyReminderEnabled})` (top-level in `notification_service.dart`); SharedPreferences key `reminder_offer_shown`.

- [ ] **Step 1: Write the failing tests**

Append to `test/notification_schedule_test.dart` (inside `main`, after the existing group):

```dart
  group('shouldShowReminderOffer', () {
    test('shows for a fresh install', () {
      expect(
        shouldShowReminderOffer(offerShown: false, dailyReminderEnabled: false),
        isTrue,
      );
    });

    test('shows once more for an existing user without reminders', () {
      // has_shown_parent_alert from 1.2.x is deliberately ignored
      expect(
        shouldShowReminderOffer(offerShown: false, dailyReminderEnabled: false),
        isTrue,
      );
    });

    test('never shows again after it was shown, even if declined', () {
      expect(
        shouldShowReminderOffer(offerShown: true, dailyReminderEnabled: false),
        isFalse,
      );
    });

    test('does not show to users who already enabled reminders in Settings', () {
      expect(
        shouldShowReminderOffer(offerShown: false, dailyReminderEnabled: true),
        isFalse,
      );
    });
  });
```

Append to `test/translations_test.dart` (inside `main`):

```dart
  test('reminder offer keys exist', () {
    expect(reference, containsPair('reminder_offer_accept', isNotEmpty));
    expect(reference, containsPair('reminder_offer_decline', isNotEmpty));
    expect(reference['parent_alert_content'], contains('daily reminder'));
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/notification_schedule_test.dart test/translations_test.dart`
Expected: compile error for `shouldShowReminderOffer`; translations test fails on the missing keys.

- [ ] **Step 3: Add the rule**

In `lib/services/notification_service.dart`, directly after `nextLocalInstanceOf`:

```dart
/// Whether the first-launch parent dialog should offer the daily reminder.
///
/// Shown once per install (tracked by [offerShown]) and skipped entirely for
/// users who already turned reminders on in Settings.
bool shouldShowReminderOffer({
  required bool offerShown,
  required bool dailyReminderEnabled,
}) =>
    !offerShown && !dailyReminderEnabled;
```

- [ ] **Step 4: Add the translations**

Add the two keys right after `parent_alert_button` in each file, and append the sentence to the end of `parent_alert_content` (before the closing wish line, as a new bullet-free paragraph). Exact strings:

| Locale | `reminder_offer_accept` | `reminder_offer_decline` | Sentence appended to `parent_alert_content` (as `\n\n` + sentence, inserted before the final `\n\n` wish line) |
|---|---|---|---|
| en-US | `Turn on daily reminder` | `Not now` | `A short daily reminder helps build the habit; you can change the time in Settings.` |
| tr-TR | `Günlük hatırlatmayı aç` | `Şimdi değil` | `Kısa bir günlük hatırlatma alışkanlık kazandırır; saatini Ayarlar'dan değiştirebilirsiniz.` |
| de-DE | `Tägliche Erinnerung einschalten` | `Jetzt nicht` | `Eine kurze tägliche Erinnerung hilft beim Aufbau der Gewohnheit; die Uhrzeit können Sie in den Einstellungen ändern.` |
| es-ES | `Activar recordatorio diario` | `Ahora no` | `Un breve recordatorio diario ayuda a crear el hábito; puede cambiar la hora en Ajustes.` |
| pt-BR | `Ativar lembrete diário` | `Agora não` | `Um breve lembrete diário ajuda a criar o hábito; você pode mudar o horário em Configurações.` |
| ru-RU | `Включить ежедневное напоминание` | `Не сейчас` | `Короткое ежедневное напоминание помогает выработать привычку; время можно изменить в настройках.` |
| ar-SA | `تفعيل التذكير اليومي` | `ليس الآن` | `تذكير يومي قصير يساعد على بناء العادة؛ يمكنكم تغيير الوقت من الإعدادات.` |
| hi-IN | `रोज़ाना रिमाइंडर चालू करें` | `अभी नहीं` | `एक छोटा रोज़ाना रिमाइंडर आदत बनाने में मदद करता है; समय आप सेटिंग्स से बदल सकते हैं।` |

Example for en-US after the edit:

```json
    "parent_alert_button": "I Understand",
    "reminder_offer_accept": "Turn on daily reminder",
    "reminder_offer_decline": "Not now",
```

and `parent_alert_content` ends with `...\n- Works offline; internet is only used to load ads\n\nA short daily reminder helps build the habit; you can change the time in Settings.\n\nWe wish you safe and fun usage!`.

Do the edit with a script so the JSON stays valid (Python `json.load` after writing each file). `parent_alert_button` stays in place (unused but harmless; removing it is not part of this task).

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/notification_schedule_test.dart test/translations_test.dart`
Expected: all pass, including the 8 parity tests.

- [ ] **Step 6: Rewrite `showParentAlert` in `lib/main.dart`**

Add `import 'package:animal_sounds_flutter/services/analytics_service.dart';` and replace the whole `showParentAlert` method (lines 55–80) with:

```dart
  /// First-launch information for parents, with the daily-reminder offer.
  ///
  /// Shown once per install to anyone who has not already enabled reminders
  /// (see [shouldShowReminderOffer]).
  Future<void> showParentAlert(BuildContext context) async {
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
```

`NotificationService` is already imported in `main.dart` (used by `_refreshReminders`). The `has_shown_parent_alert` key is no longer read or written.

- [ ] **Step 7: Verify**

Run: `flutter analyze --no-pub 2>&1 | grep -E "^\s*error"` (no output) and `flutter test` (all pass).

- [ ] **Step 8: Commit**

```bash
git add lib/services/notification_service.dart lib/main.dart assets/translations test/notification_schedule_test.dart test/translations_test.dart
git commit -m "feat: Offer the daily reminder in the first-launch parent dialog"
```

---

### Task 5: Rate and share from the parent dashboard

**Files:**
- Modify: `pubspec.yaml` (dependencies)
- Create: `lib/services/review_service.dart`
- Modify: `lib/pages/parent_dashboard_page.dart` (class at line 14, `_QuickActionsCard` at line 504)
- Modify: all 8 files in `assets/translations/` (3 keys)
- Test: `test/review_service_test.dart`, `test/translations_test.dart` (extend)

**Interfaces:**
- Consumes: `AnalyticsService` helpers (Task 1); `UsageStatsProvider.appOpens` (exists).
- Produces:
  - `bool shouldAutoPromptReview({required int appOpens, DateTime? lastPrompt, required DateTime now})` (top-level in `review_service.dart`)
  - `class ReviewService { Future<void> requestReview({required bool automatic}); Future<void> maybeAutoPrompt(int appOpens); Future<void> share(); static const String storeUrl; }`

- [ ] **Step 1: Add the packages**

Run:

```bash
flutter pub add in_app_review share_plus
```

Expected: `pubspec.yaml` gains `in_app_review: ^2.0.12` and `share_plus: ^13.3.1` (or newer patch versions); `flutter pub get` succeeds.

- [ ] **Step 2: Write the failing tests**

```dart
// test/review_service_test.dart
import 'package:animal_sounds_flutter/services/review_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 30);

  group('shouldAutoPromptReview', () {
    test('waits until the app was opened 5 times', () {
      expect(shouldAutoPromptReview(appOpens: 4, lastPrompt: null, now: now), isFalse);
      expect(shouldAutoPromptReview(appOpens: 5, lastPrompt: null, now: now), isTrue);
    });

    test('does not prompt again within 90 days', () {
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      expect(
        shouldAutoPromptReview(appOpens: 50, lastPrompt: thirtyDaysAgo, now: now),
        isFalse,
      );
    });

    test('prompts again after 90 days', () {
      final ninetyOneDaysAgo = now.subtract(const Duration(days: 91));

      expect(
        shouldAutoPromptReview(appOpens: 50, lastPrompt: ninetyOneDaysAgo, now: now),
        isTrue,
      );
    });
  });

  test('store URL points at this app', () {
    expect(ReviewService.storeUrl, endsWith('id=com.devork.animalsounds'));
  });
}
```

Append to `test/translations_test.dart`:

```dart
  test('rate and share keys exist and share_text carries the url placeholder', () {
    expect(reference, containsPair('rate_app', isNotEmpty));
    expect(reference, containsPair('share_app', isNotEmpty));
    expect(reference['share_text'], contains('{url}'));
  });
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/review_service_test.dart test/translations_test.dart`
Expected: compile error (`review_service.dart` missing); translation test fails on missing keys.

- [ ] **Step 4: Write the service**

```dart
// lib/services/review_service.dart
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the parent dashboard may ask for a store review automatically.
///
/// Only after the app has been opened at least 5 times, and at most once
/// every 90 days. Google decides whether the system sheet actually appears.
bool shouldAutoPromptReview({
  required int appOpens,
  DateTime? lastPrompt,
  required DateTime now,
}) =>
    appOpens >= 5 &&
    (lastPrompt == null || now.difference(lastPrompt).inDays >= 90);

/// Store review and share actions. Parent-area only; never throws.
class ReviewService {
  static const String storeUrl =
      'https://play.google.com/store/apps/details?id=com.devork.animalsounds';

  static const String _lastPromptKey = 'review_last_prompt';

  /// Opens the in-app review sheet. For a manual request on a device where
  /// the sheet is unavailable, opens the store listing instead.
  Future<void> requestReview({required bool automatic}) async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else if (!automatic) {
        await review.openStoreListing();
      }
      AnalyticsService().reviewPrompted(automatic: automatic);
    } catch (error) {
      debugPrint('Review request failed: $error');
    }
  }

  /// Called when the parent dashboard opens. Records the timestamp before
  /// asking so a slow or failing plugin cannot cause repeated prompts.
  Future<void> maybeAutoPrompt(int appOpens) async {
    final prefs = await SharedPreferences.getInstance();
    final lastMillis = prefs.getInt(_lastPromptKey);
    final lastPrompt = lastMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastMillis);
    final now = DateTime.now();
    if (!shouldAutoPromptReview(
      appOpens: appOpens,
      lastPrompt: lastPrompt,
      now: now,
    )) {
      return;
    }
    await prefs.setInt(_lastPromptKey, now.millisecondsSinceEpoch);
    await requestReview(automatic: true);
  }

  /// Opens the system share sheet with a localized invitation.
  Future<void> share() async {
    AnalyticsService().shareTapped();
    try {
      await SharePlus.instance.share(
        ShareParams(text: 'share_text'.tr(namedArgs: {'url': storeUrl})),
      );
    } catch (error) {
      debugPrint('Share failed: $error');
    }
  }
}
```

- [ ] **Step 5: Add the translations**

Insert after `dashboard_manage_notifications` in each file:

| Locale | `rate_app` | `share_app` | `share_text` |
|---|---|---|---|
| en-US | `Rate the app` | `Share with friends` | `My child loves learning animal sounds with this app. Try it: {url}` |
| tr-TR | `Uygulamayı değerlendir` | `Arkadaşlarınla paylaş` | `Çocuğum bu uygulamayla hayvan seslerini öğrenmeye bayılıyor. Sen de dene: {url}` |
| de-DE | `App bewerten` | `Mit Freunden teilen` | `Mein Kind lernt mit dieser App begeistert Tiergeräusche. Probier sie aus: {url}` |
| es-ES | `Valorar la app` | `Compartir con amigos` | `A mi hijo le encanta aprender sonidos de animales con esta app. Pruébala: {url}` |
| pt-BR | `Avaliar o app` | `Compartilhar com amigos` | `Meu filho adora aprender sons de animais com este app. Experimente: {url}` |
| ru-RU | `Оценить приложение` | `Поделиться с друзьями` | `Мой ребёнок с удовольствием учит звуки животных в этом приложении. Попробуйте: {url}` |
| ar-SA | `قيّم التطبيق` | `شارك مع الأصدقاء` | `طفلي يحب تعلّم أصوات الحيوانات مع هذا التطبيق. جرّبه: {url}` |
| hi-IN | `ऐप को रेट करें` | `दोस्तों के साथ साझा करें` | `मेरे बच्चे को इस ऐप से जानवरों की आवाज़ें सीखना बहुत पसंद है। आप भी आज़माएँ: {url}` |

Validate every file with `json.load` after editing.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/review_service_test.dart test/translations_test.dart`
Expected: all pass.

- [ ] **Step 7: Wire the dashboard**

In `lib/pages/parent_dashboard_page.dart` add imports:

```dart
import '../services/analytics_service.dart';
import '../services/review_service.dart';
```

Convert the page to a `StatefulWidget` so it can run once-per-open logic. Replace lines 14–17:

```dart
class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AnalyticsService().parentDashboardOpened();
      ReviewService().maybeAutoPrompt(
        context.read<UsageStatsProvider>().appOpens,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
```

(The rest of the original `build` body stays unchanged; `_buildSectionTitle` moves into the State class with it.)

In `_QuickActionsCard`, replace the "manage notifications" `onTap` placeholder and add two tiles. The `children:` list becomes:

```dart
        children: [
          ListTile(
            leading: const Icon(Icons.star_outline_rounded,
                color: Color(0xFFF9A825)),
            title: Text(
              'rate_app'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
            onTap: () => ReviewService().requestReview(automatic: false),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.share_outlined,
                color: AppColors.onSurfaceVariant),
            title: Text(
              'share_app'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
            onTap: () => ReviewService().share(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications_outlined,
                color: AppColors.onSurfaceVariant),
            title: Text(
              'dashboard_manage_notifications'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
            onTap: () => Navigator.pushNamed(context, '/settingsPage'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
            title: Text(
              'dashboard_reset_stats'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
            onTap: () => _confirmReset(context),
          ),
        ],
```

(`/settingsPage` is registered in `main.dart` routes. Reset moves to the bottom so the destructive action is last.)

- [ ] **Step 8: Verify**

Run: `flutter analyze --no-pub 2>&1 | grep -E "^\s*error"` (no output) and `flutter test` (all pass). Then `flutter build apk --debug` to be sure the two new plugins compile on Android.
Expected: build succeeds.

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/services/review_service.dart lib/pages/parent_dashboard_page.dart assets/translations test/review_service_test.dart test/translations_test.dart
git commit -m "feat: Add rate and share actions to the parent dashboard"
```

---

### Task 6: Firebase Analytics + Crashlytics (needs `google-services.json`)

**Prerequisite:** `android/app/google-services.json` from the Firebase console for package `com.devork.animalsounds`, with Analytics enabled and Crashlytics turned on in the project. Do not start this task without the file; the Android build fails without it by design.

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/settings.gradle` (plugins block, lines 20–24)
- Modify: `android/app/build.gradle` (plugins block, lines 1–6)
- Modify: `android/app/src/main/AndroidManifest.xml` (inside `<application>`)
- Modify: `lib/main.dart` (`main()`)
- Add: `android/app/google-services.json` (provided)
- Test: `test/android_manifest_test.dart` (extend)

**Interfaces:**
- Consumes: `AnalyticsService.setBackend` (Task 1).
- Produces: nothing new for other tasks.

- [ ] **Step 1: Write the failing manifest test**

Append inside the `group('AndroidManifest', ...)` in `test/android_manifest_test.dart`:

```dart
    test('disables advertising-ID collection and ad personalization for Analytics', () {
      expect(
        manifest,
        contains(
          '<meta-data android:name="google_analytics_adid_collection_enabled" android:value="false" />',
        ),
      );
      expect(
        manifest,
        contains(
          '<meta-data android:name="google_analytics_default_allow_ad_personalization_signals" android:value="false" />',
        ),
      );
    });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/android_manifest_test.dart`
Expected: the new test FAILS (meta-data missing); the other 3 pass.

- [ ] **Step 3: Add the meta-data**

In `android/app/src/main/AndroidManifest.xml`, directly above the existing `<!-- Don't delete the meta-data below.` comment inside `<application>`:

```xml
        <!-- Children's app: Analytics must not use the advertising ID or
             ad-personalization signals (Google Play Families policy). -->
        <meta-data android:name="google_analytics_adid_collection_enabled" android:value="false" />
        <meta-data android:name="google_analytics_default_allow_ad_personalization_signals" android:value="false" />
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/android_manifest_test.dart`
Expected: 4 tests pass.

- [ ] **Step 5: Add the packages and Gradle plugins**

Run:

```bash
flutter pub add firebase_core firebase_analytics firebase_crashlytics
```

Copy `google-services.json` into `android/app/`.

`android/settings.gradle`, inside the `plugins { ... }` block, after the kotlin line:

```groovy
    id "com.google.gms.google-services" version "4.4.2" apply false
    id "com.google.firebase.crashlytics" version "3.0.2" apply false
```

`android/app/build.gradle`, inside the `plugins { ... }` block, after `id("dev.flutter.flutter-gradle-plugin")`:

```groovy
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
```

If Gradle reports a plugin version conflict with the FlutterFire packages just added, use the versions named in the `firebase_core` package README for that release instead of the two above.

- [ ] **Step 6: Initialise Firebase in `lib/main.dart`**

Add imports:

```dart
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:animal_sounds_flutter/services/analytics_service.dart';
```

Replace `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await _initFirebase();

  // Ads and notifications start after the first frame (see
  // _AppWithDependenciesState) so a slow SDK start never delays the UI.
  runApp(EasyLocalization(
    // ... unchanged ...
  ));
}

/// Starts Analytics and Crashlytics. Failure is logged and the app runs
/// without measurement; nothing here may block or crash startup.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    AnalyticsService().setBackend(
      (name, parameters) =>
          FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters),
    );
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);
    if (kReleaseMode) {
      FlutterError.onError = crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (error) {
    debugPrint('Firebase initialisation failed: $error');
  }
}
```

(`debugPrint` comes from `package:flutter/material.dart`, already imported.)

- [ ] **Step 7: Verify on Android**

Run: `flutter test` (all pass), `flutter analyze --no-pub 2>&1 | grep -E "^\s*error"` (no output), then `flutter build appbundle --release`.
Expected: build succeeds. Then check the merged manifest:

```bash
grep -c "google_analytics_adid_collection_enabled" build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
grep -c "gms.permission.AD_ID" build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
```

Expected: `1` and `0`.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock android/settings.gradle android/app/build.gradle android/app/google-services.json android/app/src/main/AndroidManifest.xml lib/main.dart test/android_manifest_test.dart
git commit -m "feat: Add Firebase Analytics and Crashlytics with child-directed settings"
```

---

### Task 7: Release preparation

**Files:**
- Modify: `pubspec.yaml` (version line 6)

- [ ] **Step 1: Bump the version**

Change `version: 1.2.1+9` to `version: 1.3.0+10`.

- [ ] **Step 2: Full verification**

Run, in order:

```bash
flutter test
flutter analyze --no-pub 2>&1 | grep -E "^\s*error"
flutter build appbundle --release
grep -n -E 'versionCode|versionName|targetSdkVersion' build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
```

Expected: all tests pass; no analyzer errors; AAB built; manifest shows `versionCode="10"`, `versionName="1.3.0"`, `targetSdkVersion="36"`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml
git commit -m "chore: Bump version to 1.3.0+10"
```

- [ ] **Step 4: Manual checks on an internal-test build (developer's device)**

- Fresh install: parent dialog shows "Not now" and "Turn on daily reminder"; accept → system permission → Settings shows the reminder on at 18:00. Decline → Settings shows it off.
- Update from 1.2.1 with reminders off: dialog shows once; kill and reopen: it does not show again. Update with reminders on: it never shows.
- Explore tab: today's animal differs from yesterday's (compare with a device whose date is set to yesterday if needed).
- Parent dashboard: "Rate the app" opens the Play review sheet or the store page; "Share with friends" opens the share sheet with the localized text and the store URL; "Manage Notifications" opens Settings.
- Firebase console → Analytics → DebugView (run `adb shell setprop debug.firebase.analytics.app com.devork.animalsounds` first): `reminder_offer_shown`, `sound_played`, `parent_dashboard_opened` appear.
- Play Console → Data safety: declare Analytics (app interactions, crash logs, diagnostics; not linked to identity; not for advertising) before submitting.
