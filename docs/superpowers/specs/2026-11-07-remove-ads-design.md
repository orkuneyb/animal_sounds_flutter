# Remove Ads (one-time purchase) — Design

**Date:** 2026-11-07
**Target version:** 1.4.0+12
**Status:** Builder check done; owner answers applied; awaiting approval

## Why

Parents of a child-directed app are the buyers, and the most common thing
they pay for in this category is "no ads". Competing toddler apps (Animal
World for Toddlers, Kids Animal Piano, Toddler Sirens) all sell ad removal as
a single one-time in-app product, typically priced between USD 1.99 and
3.99, offered to the parent behind a gate and never pushed at the child.
Google Play's Families policy explicitly allows this but rejects "overly
aggressive commercial tactics", so the offer must be discreet.

Today the app shows a banner on four screens, an interstitial every 15th
animal sound, and five rewarded-video buttons (quiz hint, extra life, double
score, achievement hint, fun fact). None of this can be turned off.

## Goals

1. A parent can buy "Remove ads" once and never see a banner or
   interstitial again, on any device signed in with the same Google
   account.
2. Everything that used to require watching a rewarded video is granted
   for free after the purchase (user decision, 2026-11-07).
3. The purchase survives reinstalls and phone changes via Play's own
   restore, with a visible "Restore purchases" action as a fallback.
4. The offer is visible enough that a parent who wants it finds it within
   one tap from the home screen, yet never interrupts the child.

## Non-goals

- Subscriptions, consumables, bundles, discounts, promo codes.
- iOS / StoreKit (the app ships on Google Play only).
- A backend for receipt verification. Play's purchase acknowledgement is the
  verification step; the app has no server and the product is low-value.
- Removing the ad SDK from the build. It stays; it is simply never
  initialised when the entitlement is present.
- Changing what the ads are or where they appear for non-buyers.

## Anti-goals (would make this a failure even if it works)

- A child can trigger the Play purchase sheet without passing the parent
  gate. Every entry point goes through `ParentGateWidget` first.
- A paying parent sees a banner flash on startup before the entitlement
  loads. The cached flag must be read before the first frame.
- A legitimate purchase is revoked because of a transient store error.
- Any offer pops up during play. The offer lives only on the Profile tab,
  under the home banner, and in Settings.
- Any string shipped in fewer than the 8 supported languages.

## Constraints

- Flutter 3.41 / Dart 3.11, Provider, easy_localization, shared_preferences
  (existing stack; see `pubspec.yaml`).
- New dependency: `in_app_purchase` ^3.3.1 (official Flutter plugin; its
  Android implementation `in_app_purchase_android` 0.5.x uses the current
  Play Billing Library and adds the `com.android.vending.BILLING`
  permission itself). No other new runtime dependency.
- Play Console: the in-app product must exist and be active before the
  build can be tested; see "Play Console setup" below. Testing requires an
  internal-testing build and the tester account added as a licence tester.
- Kids app: no account creation, no PII in analytics, no external links in
  the offer screen other than the Play purchase sheet itself.
- Existing tests must keep passing; `flutter analyze` must stay at zero
  errors; the release AAB must build.

## The product

| Field | Value |
|---|---|
| Product ID | `remove_ads` |
| Type | Non-consumable (one-time, managed product) |
| Price | USD 1.99 tier (owner decision 2026-11-07), set in Play Console; Play localises it per country. The app always displays the store-localised price string and never hardcodes one |
| Name / description | "Remove ads" / "Removes all banner and full-screen ads forever. Hints and extra chances become free." (Play Console copy; translated in Console for the same 8 locales) |

## Behaviour

### Entitlement model

The entitlement is tri-state: **unknown** (key absent: fresh install or
reinstall), **true**, **false**. It lives in `SharedPreferences` under key
`ads_removed` and is read before `runApp` so no ad is ever requested on a
known-paid install.

*Builder's call (designer):* when the state is **unknown**, ad
initialisation waits for the first restore result, with a 3-second
timeout, after which ads start as for a free user. This happens once per
install (the first successful query writes true or false), and on first
launch the parent dialog is on screen anyway, so the delay is invisible.
A reinstalling parent therefore never sees a banner flash.

Source of truth is Play. On every cold start, after the first frame, the
app:

1. Subscribes to `InAppPurchase.purchaseStream` (before anything else, so
   purchases completed while the app was closed are not missed).
2. Checks `isAvailable()`. If the store is unavailable, keep the cached flag
   and stop; do not revoke.
3. Calls `restorePurchases()`. On Android this queries the account's owned
   purchases and emits them on the stream as `restored`.
4. Any `purchased` or `restored` event for `remove_ads` whose
   `verificationData.serverVerificationData` is non-empty sets the flag to
   true, persists it, and if `pendingCompletePurchase` is true calls
   `completePurchase` (acknowledgement; without it Play refunds after 3
   days).
5. `pending` keeps the current flag and shows a "waiting for Play"
   message on the offer screen if it is open.
6. `error` keeps the current flag and shows a short error on the offer
   screen if it is open; logs `remove_ads_purchase_failed` with the error
   code only.
7. `canceled` does nothing.

Revocation (*builder's call, designer*): the flag goes from true back to
false only after **two consecutive cold starts** on which the store
reported available, the restore query completed, and no `remove_ads`
purchase was among the results (persisted counter
`ads_removed_miss_count`, reset to 0 by any purchased/restored event). This
is how a Play refund propagates, within two launches. A failed or
timed-out query never revokes and never increments the counter. The manual
"Restore purchases" action never revokes: if it finds nothing it only
shows `restore_nothing_found`, so a parent whose device is on a different
Google account cannot lose the entitlement by tapping Restore.

The entitlement is exposed to the widget tree as a `ChangeNotifier`
(`PurchaseProvider`) registered in the existing `MultiProvider` in
`main.dart`. The store calls are wrapped in a thin `PurchaseService` whose
interface the provider depends on, so tests can drive the state machine
with a fake instead of the platform plugin.

### What changes when ads are removed

- `BannerAdWidget` and the three pages that build their own `BannerAd`
  (`animal_info_page`, `favorites_page`, `quiz_start_page`) render nothing
  and never call `load()`.
- `AdService.initialize()` is not called at startup; `createInterstitialAd`,
  `showInterstitialAd`, `loadRewardedAd` and `showRewardedAd` become no-ops
  that return immediately. The every-15th-sound counter still ticks (no
  behaviour change for non-buyers) but never shows an ad.
- `RewardedAdButton` switches to a "premium" appearance: same place, same
  size, gift icon, label without the "Watch ad" wording (new keys
  `premium_hint`, `premium_extra_life`, `premium_double_score`,
  `premium_fun_fact`, `premium_achievement_hint`), no shimmer. Tapping it
  calls `onRewardEarned(1)` immediately and shows the existing
  `ad_reward_received` snackbar. No `rewardedAdWatched` analytics event;
  instead `reward_granted_premium` with the same `placement` parameter.
- The first-launch parent dialog text is unchanged ("may contain
  child-friendly ads" remains true for the free tier).

### Entry points (all gated)

1. **Profile tab → quick links.** A new tile above "Parent dashboard":
   icon `Icons.block_rounded` style "ads off", accent colour, title
   `remove_ads`. Tap → parent gate → Remove Ads screen. After purchase the
   tile reads `ads_removed_thanks` with a check icon and opens the same
   screen in its "thank you" state (so Restore is still reachable).
2. **Home screen banner caption.** The live home screen is
   `lib/pages/tabs/animals_tab.dart` (`home.dart` is unused). Directly
   under its banner, only
   while a banner is actually loaded and ads are not removed: a single
   discreet text button, 12 sp, `remove_ads_short` with a small icon,
   right-aligned. Tap → parent gate → Remove Ads screen. It disappears
   with the banner after purchase.
3. **Profile tab promo card.** A static card at the top of the Profile
   tab, above the quick links, while ads are not removed: small
   illustration, `promo_title` ("Ad-free version for parents"),
   `promo_body` (one line: no ads, hints and extra chances free), and a
   `remove_ads` button. Tap → parent gate → Remove Ads screen. It never
   animates, never pops up, and disappears after purchase. Logged as
   `remove_ads_offer_shown` with `source=profile_card`. (Owner decision
   2026-11-07: this replaces an earlier post-interstitial bottom sheet,
   dropped because it would interrupt the child.)
4. **Settings → new section "Purchases"** (`purchases` header) with
   `restore_purchases` tile (always) and `remove_ads` tile (only while not
   purchased). Restore runs the same restore flow and reports either
   `restore_success` or `restore_nothing_found` in a snackbar. Both tiles
   are behind the parent gate.

### Remove Ads screen

A full-screen page (`RemoveAdsPage`) in the app's existing warm visual
style, built for a parent:

- Header illustration using an existing animal asset, title
  `remove_ads_title`, three benefit bullets (`benefit_no_banners`,
  `benefit_no_interstitials`, `benefit_free_rewards`).
- Primary button showing the localised price from
  `ProductDetails.price`, e.g. "Remove ads · ₺89,99" (`buy_for_price` with
  `{price}` placeholder). Disabled with a spinner while the product is
  loading or a purchase is in flight. If product details fail to load,
  show `store_unavailable` and a retry.
- Secondary text button `restore_purchases`.
- Footnote `one_time_note` ("One-time payment. Works on every device
  signed in with the same Google account.").
- Purchased state: large check, `ads_removed_thanks`, `restore_purchases`
  still visible, no buy button.
- Pending state: `purchase_pending` text under the button.

Analytics: `remove_ads_offer_shown` {source: profile | home_banner |
profile_card | settings}, `remove_ads_purchase_started`, `remove_ads_purchased`,
`remove_ads_restored`, `remove_ads_purchase_failed` {code}. No user
identifiers (existing child-directed Analytics configuration applies).

### Localisation

Every new key is added to all 8 files under `assets/translations/` in the
same commit, and the existing translations parity test is extended to cover
them. Keys introduced: `remove_ads`, `remove_ads_short`, `remove_ads_title`,
`benefit_no_banners`, `benefit_no_interstitials`, `benefit_free_rewards`,
`buy_for_price`, `one_time_note`, `restore_purchases`, `restore_success`,
`restore_nothing_found`, `store_unavailable`, `purchase_pending`,
`purchase_failed`, `ads_removed_thanks`, `purchases`, `promo_title`,
`promo_body`, and the five `premium_*` reward labels.

## Play Console setup (developer, outside the code)

1. Monetise → Products → In-app products → Create: ID `remove_ads`, type
   managed product, name and description as above, set price tier, Activate.
2. Settings → Licence testing: add the test Google account so purchases
   are free and instantly refundable while testing.
3. Upload the 1.4.0 AAB to the internal testing track; the purchase sheet
   only works for a build installed from Play.
4. App content → Target audience and content stays as is; "contains
   in-app purchases" is declared automatically from the product list.
5. Store listing: add "Optional one-time purchase removes ads" to the
   description (recommended, not required).

## Testing

- Unit tests for `PurchaseProvider` against a fake `PurchaseService`:
  cached flag read; unknown state waits for restore then falls back after
  the timeout; purchased → flag true + completePurchase called; restored →
  flag true and miss counter reset; store unavailable → flag unchanged;
  one empty restore → flag still true, counter 1; second consecutive empty
  restore → flag false; manual restore with nothing found → flag
  unchanged; error → flag unchanged and event logged; pending → flag
  unchanged.
- Widget test: `RewardedAdButton` in premium mode grants the reward on tap
  without touching `AdService`.
- Widget test: `BannerAdWidget` renders nothing and never loads when ads are
  removed.
- Existing `ad_service_test`, `translations_test` extended; analyzer and
  full test suite green; release AAB builds.
- Manual, on the phone from the internal testing track with a licence
  tester account: buy, see banners vanish without restart, kill and
  reopen, uninstall and reinstall → Restore brings it back, refund in Play
  Console → ads return on next start.

## Bundled stability fixes (owner decision 2026-11-07)

Three small items from the 1.3.1 Crashlytics review ride along in 1.4.0,
each as its own commit:

1. **Quiz early-exit guard.** In `lib/pages/quiz_page.dart` the 2-second
   `Future.delayed` after an answer calls `_advanceToNextQuestion()` with no
   `mounted` check (the 4-second extra-life path already has one). Add the
   check so leaving the quiz during the delay no longer calls `stop()` on a
   disposed `AudioPlayer` or `setState` on an unmounted widget.
2. **Bundle the Nunito font.** Add the Nunito TTFs used by
   `lib/utils/styles.dart` under `assets/fonts/`, declare them in
   `pubspec.yaml`, and set `GoogleFonts.config.allowRuntimeFetching = false`
   so the app never downloads fonts. The offline font-fetch exception
   disappears entirely.
3. **Record non-crashing Flutter errors as non-fatal.** In `main.dart`,
   `FlutterError.onError` reports via `recordFlutterError` (non-fatal) instead
   of `recordFlutterFatalError`; `PlatformDispatcher.onError` stays fatal
   because those errors are uncaught. Crash-free metrics then reflect real
   crashes.

## Rollout

Ship as 1.4.0+12 with release notes in 8 languages (template to be handed
over as usual). Full rollout; no staged percentage.

## Left to the builder

- Exact visual design of the Remove Ads page and nudge sheet within the
  existing colour and typography system.
- Whether `PurchaseService` wraps `InAppPurchase.instance` directly or via
  a small interface; tests only require that it be fakeable.
- File layout (suggested: `lib/services/purchase_service.dart`,
  `lib/providers/purchase_provider.dart`, `lib/pages/remove_ads_page.dart`,
  `lib/widgets/remove_ads_nudge_sheet.dart`).

## Decisions log

- 2026-11-07, owner: rewarded-video perks become free after purchase.
- 2026-11-07, owner: price tier USD 1.99.
- 2026-11-07, owner: no post-interstitial nudge; static Profile card instead.
- 2026-11-07, owner: bundle the three 1.3.1 follow-up fixes into 1.4.0.
- 2026-11-07, designer: tri-state entitlement with 3 s first-launch wait.
- 2026-11-07, designer: revoke only after two consecutive empty restores;
  manual Restore never revokes.
