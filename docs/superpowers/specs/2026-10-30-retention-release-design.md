# 1.3.0 Retention Release — Design

**Date:** 2026-10-30
**Version:** 1.3.0+10
**Status:** Approved in conversation; pending written-spec review

## Why

Play Console data (Sep–Oct 2026) shows the app acquires ~430 devices per
28 days and loses roughly the same number: 7-day retention is ~5% of first
opens, DAU/MAU is 7.3%, and the install base is flat at ~1,130. 1.2.1 made
reminders work for the first time; 1.3.0 makes the app ask for them, keeps
the daily content fresh, lets parents rate and share, and adds measurement so
the next decisions are data-driven.

## Scope

In scope:

1. Firebase Analytics + Crashlytics with child-directed configuration.
2. Daily reminder offer inside the first-launch parent dialog.
3. Non-repeating daily animal cycle.
4. Rate and share actions in the parent dashboard, plus a gated automatic
   in-app review request.

Out of scope: new animals, iOS, store listing text, the every-15th-open
interstitial on the animal page, any analytics user identification.

## 1. Measurement

### Dependencies

- `firebase_core`, `firebase_analytics`, `firebase_crashlytics`
- Android: `com.google.gms.google-services` and
  `com.google.firebase.crashlytics` Gradle plugins; `google-services.json`
  in `android/app/` (provided by the developer from the Firebase console
  for package `com.devork.animalsounds`; the file is committed, it holds no
  secrets).

### Families-policy configuration

In `AndroidManifest.xml`:

```xml
<meta-data android:name="google_analytics_adid_collection_enabled" android:value="false" />
<meta-data android:name="google_analytics_default_allow_ad_personalization_signals" android:value="false" />
```

No `setUserId`, no user properties that identify a person, no email or
device identifiers in events.

### `AnalyticsService` (`lib/services/analytics_service.dart`)

Singleton wrapper around `FirebaseAnalytics`. Every method is fire-and-forget
and swallows errors; if `Firebase.initializeApp()` failed, every call is a
no-op. Events and parameters:

| Event | Parameters | Where |
|---|---|---|
| `sound_played` | `animal` | `AnimalSoundPage` |
| `daily_discovery_completed` | `streak` | `DailyProvider.completeDailyDiscovery` |
| `quiz_completed` | `score` | quiz completion |
| `sound_game_over` | `score` | sound guess game |
| `reminder_offer_shown` | — | parent dialog |
| `reminder_offer_accepted` / `reminder_offer_declined` | — | parent dialog |
| `notification_permission` | `granted` (bool) | after the system prompt |
| `rewarded_ad_watched` | `placement` | `RewardedAdButton` reward callback |
| `parent_dashboard_opened` | — | after the parent gate passes |
| `review_prompted` | `automatic` (bool) | `ReviewService` |
| `share_tapped` | — | parent dashboard |

Firebase's automatic `first_open`, `app_remove` and `session_start` events
give the funnel without extra code.

### Crashlytics

- `FlutterError.onError` and `PlatformDispatcher.instance.onError` forward
  to Crashlytics (`recordFlutterFatalError` / `recordError`).
- ANRs are captured by the native SDK; nothing extra needed.
- Collection is enabled in release builds only (`kReleaseMode`).

### Startup

`Firebase.initializeApp()` runs in `main()` before `runApp` because it is
fast (reads bundled config) and the error handlers need it. Ads and
notifications stay post-first-frame as in 1.2.1. Initialization failure is
caught and logged; the app continues without analytics.

## 2. Reminder offer in the parent dialog

### Behaviour

The existing first-launch parent dialog (`MyApp.showParentAlert`) gains two
actions in place of the single "I understand" button:

- **Primary: "Turn on daily reminder"** — calls
  `NotificationService.requestPermission()`, then, if granted,
  `scheduleDailyReminder(TimeOfDay(hour: 18, minute: 0))`. The time is
  stored through the service so Settings shows 18:00. Logs
  `reminder_offer_accepted` and `notification_permission{granted}`.
- **Secondary: "Not now"** — logs `reminder_offer_declined`; nothing is
  scheduled. Settings still allows enabling later.

The dialog stays non-dismissible by tapping outside, as today.

### When it shows

A new preference `reminder_offer_shown` (bool) replaces
`has_shown_parent_alert` as the gate. The dialog shows when
`reminder_offer_shown` is false **and** the daily reminder is not already
enabled. The old key is left in place (ignored). Consequences:

- New users: dialog once on first launch.
- Existing users without reminders: dialog once more after updating.
- Existing users who already enabled reminders in Settings: never again.

After either button, `reminder_offer_shown` is set to true. The shown event
is logged when the dialog appears.

### Text

New translation keys in all 8 locales: `reminder_offer_accept`,
`reminder_offer_decline`, and an added sentence in `parent_alert_content`
explaining the reminder ("A short daily reminder helps build the habit; you
can change the time in Settings."). The translation-parity test guards the
key set.

## 3. Non-repeating daily animal

### `DailyAnimalCycle` (`lib/utils/daily_animal_cycle.dart`)

Pure, stateless:

```dart
class DailyAnimalCycle {
  const DailyAnimalCycle(this.length); // number of animals
  int indexForDay(int dayNumber);      // dayNumber = days since 1970-01-01 (local date)
}
```

- `cycle = dayNumber ~/ length`, `position = dayNumber % length`.
- Permutation for a cycle: `List.generate(length, (i) => i)..shuffle(Random(cycle))`.
- Boundary rule: if `permutation[0]` equals the last element of the previous
  cycle's permutation, swap `permutation[0]` with `permutation[1]`. This
  guarantees no two consecutive days share an animal, including across the
  boundary, and keeps the result deterministic.

`DailyProvider.getDailyAnimal()` becomes
`animals[DailyAnimalCycle(animals.length).indexForDay(dayNumber(DateTime.now()))]`.
`getDailyFunFact()` keeps its date-seeded choice among the animal's facts.
`home.dart` (dead code) is not touched.

### Tests

- 30 consecutive days produce 30 distinct indices.
- Day N and day N+1 never return the same index across 10 cycle boundaries.
- Same day always returns the same index.

## 4. Rate and share

### Dependencies

`in_app_review`, `share_plus`.

### `ReviewService` (`lib/services/review_service.dart`)

- `Future<void> requestReview({required bool automatic})`: if
  `InAppReview.instance.isAvailable()`, call `requestReview()`; otherwise,
  for manual requests only, `openStoreListing()`. Logs `review_prompted`.
  Errors are swallowed.
- Automatic policy is a pure function, unit-tested:

```dart
bool shouldAutoPrompt({required int appOpens, DateTime? lastPrompt, required DateTime now}) =>
    appOpens >= 5 && (lastPrompt == null || now.difference(lastPrompt).inDays >= 90);
```

- `lastPrompt` is stored in SharedPreferences (`review_last_prompt`).

### Parent dashboard

Two new `ListTile`s in the "Quick actions" section:

- **Rate the app** → `ReviewService.requestReview(automatic: false)`.
- **Share with friends** → share sheet with `share_text` (localized, includes
  the store URL); logs `share_tapped`.

On dashboard open (after the parent gate), log `parent_dashboard_opened`
and, if `shouldAutoPrompt(...)`, call `requestReview(automatic: true)` and
store the timestamp. Google decides whether the system dialog actually
appears; the app never shows its own rating UI to children.

New translation keys: `rate_app`, `share_app`, `share_text` (with a `{url}`
placeholder).

## Error handling

- Analytics, Crashlytics, review and share calls never surface exceptions to
  the UI; failures are logged with `debugPrint`.
- Notification permission denied: the offer is marked shown, nothing is
  scheduled, no retry prompt.
- Missing `google-services.json` fails the Android build at compile time,
  which is intentional: a release without measurement is not what this
  version is for.

## Testing

Automated (added to the existing suite):

- `DailyAnimalCycle` tests (section 3).
- `shouldAutoPrompt` tests: below threshold, above threshold with no prior
  prompt, prompted 30 days ago, prompted 91 days ago.
- Translation parity test keeps guarding the new keys.
- Manifest test extended: the two Analytics meta-data flags are present.

Manual, on an internal-test build:

- First launch: dialog shows both buttons; accept → system permission →
  Settings shows reminder on at 18:00; decline → nothing scheduled.
- Update from 1.2.1 with reminders off: dialog shows once; with reminders on:
  it does not show.
- Daily animal differs from yesterday's.
- Parent dashboard: rate opens the system sheet or store; share opens the
  system share sheet with the localized text.
- Firebase DebugView shows the events listed above.

## Release

Version `1.3.0+10`. Play Console: the Data safety form must declare
Analytics (app interactions, crash logs, diagnostics — not linked to
identity, not used for ads). Release notes in 8 languages as for 1.2.1.
