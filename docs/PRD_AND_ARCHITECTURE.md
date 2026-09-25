# Apna Ledger — PRD & Code Architecture

> Product: **Apna Ledger** ("Rakhe Pai Pai Ka Hisaab") · Parent company: **Appex Business**
> Stack: **Flutter** (Android · iOS · Web) · **Riverpod** state · **go_router** · **Firebase**
> Package ids: QA `com.appexbusiness.apnaledgerqa` · Prod `com.appexbusiness.apnaledger`

This document is written so a new developer **or an AI assistant** can understand what the
app does and how the code is organised, then continue the work confidently.

---

## 1. Product overview (PRD)

**Vision.** A simple, private, multilingual money tracker for Indian individuals & small
businesses. No bank linking, no documents — the user types their own entries. Tagline:
"every paisa recorded".

**Target users.** Shopkeepers, families, freelancers who want a fast day-to-day ledger in
their own language.

**Core principles.**
- Privacy first — no bank logins / OTP scraping / document upload.
- Works offline (local storage) and syncs to Firebase when available.
- Fully localized (English, Hindi, Gujarati; core Bengali/Telugu/Tamil).
- Light + dark themes; responsive for phone / tablet / web.

### 1.1 Feature list
| Area | What it does |
|---|---|
| Auth | Phone + password (+ master OTP `123456`), Google Sign-In, "stay logged in", forgot-password (OTP → reset), delete account (password), profile edit. |
| Transactions | 4 types — **Income** (green), **Spending** (red), **Money Given** (amber), **Money Taken** (purple). Amount capped at ₹1,00,00,000. Loan fields (interest %, dates), recurrence (once/daily/weekly/monthly/yearly + start date). |
| Home | Animated **Total Net Balance** (+ⓘ formula), 4 clickable type tiles, quick-add cards (blink dot), quick categories, streak, **Insights** (animated bars + spending donut with Day/Week/Month/Year filter), Ledger history (search + type filter + download), tool icons (Download, Calculator, Notes, Savings Goals), offline banner. |
| Categories | Category + sub-category CRUD, per-category income/expense, tap → filtered ledger, CSV/PDF export, N inline sub-categories, duplicate-name guard. |
| Ledger | Search, type/date filters, day-grouped history, tap → **detail view** → edit/delete (confirmation). |
| Calculator | Basic pad (expression + history), split-a-bill, apply-discount; "add result as transaction". |
| Savings Goals | Own screen: goal (name, target, target date), add money, animated progress. |
| Notes | Card notepad (optional title + body, date/time stamps). |
| Export | CSV + branded **PDF** (AppexBusiness) with date-range + type filter; direct download (web download / desktop Downloads / mobile docs). |
| Settings | Profile CRUD, language, theme, **App Lock** (PIN + biometric), Share, Privacy, Terms, How-to-use, About, environment badge (QA/UAT), delete account. |
| Security | Strong password (≥8, upper, number, special), PIN + biometric app lock. |

### 1.2 Deferred / roadmap (not yet built)
Calendar day-wise view + graphs · Contacts (import/create, categories) · Challenges inside
Savings Goals · Notification centre + download-history sheet · Light-theme colour chooser ·
Rich-text notepad · Auto-recurring approval queue · full pro translations for bn/te/ta ·
migrate auth to Firebase Auth phone/email providers (hardening).

---

## 2. Architecture

**Clean, feature-first architecture** with Riverpod DI.

```
lib/
  main.dart / main_qa.dart / main_uat.dart / main_prod.dart   # flavor entrypoints
  bootstrap.dart              # init: prefs, Firebase, anon-auth, Crashlytics, FCM, runApp
  firebase_options_{qa,prod}.dart
  app/
    app.dart                  # MaterialApp.router (theme, l10n, routerProvider)
    router/app_router.dart    # go_router: splash, auth, shell (Home/Txns/Categories/Settings), pushed screens
  core/
    config/      flavor.dart, env_config.dart          # Flavor enum, per-env config (masterOtp, toggles)
    constants/   app_constants.dart, india_states.dart
    di/injector.dart          # ALL providers; picks repo impl by kBackend + firestore availability
    error/failure.dart        # AppFailure(messageKey)
    services/    local_storage (SharedPreferences), analytics, logger, export (CSV/PDF),
                 file_saver(+_io/_web conditional), biometric, messaging (FCM), connectivity
    theme/       app_colors, app_typography (Manrope via google_fonts), app_theme (+ AppSemanticColors extension: income/expense/loanGiven/loanTaken/muted/border, byTypeKey)
    utils/       formatters (money/date; moneySmart = compact >1cr), validators, icon_utils (const kCategoryIcons), app_links
    widgets/     app_button (debounced), app_text_field, app_bottom_sheet (showAppSheet),
                 app_dialog (showAppConfirm — bottom sheet), animated_money (overflow-safe),
                 powered_by, internet_banner, blinking_dot, fade_in, section_header, india_phone_prefix
  features/<feature>/
    domain/       entities + repository interfaces
    data/         local_* and firestore_* repository implementations
    presentation/ providers (Riverpod), screens, widgets
  l10n/          app_en/hi/gu/bn/te/ta.arb  (gen-l10n -> AppLocalizations)
```

### 2.1 State & DI (Riverpod)
- `injector.dart` holds every provider. Repositories are chosen at runtime:
  `firestoreProvider` is `null` by default and **overridden in bootstrap** with the live
  `FirebaseFirestore` instance only after anonymous sign-in succeeds.
- If `firestore != null` → **Firestore** repos (auth/transactions/categories); else **local**
  (SharedPreferences). This is the offline-safe fallback.
- `kBackend` in injector expresses the intended backend (currently `Backend.firebase`).

### 2.2 Data models
- `TxnEntry` (transactions/domain/transaction.dart): id, userId, `TransactionType`, amount,
  categoryId, subCategoryId, date, note, interestPercent?, dueDate?, `Recurrence`,
  recurrenceStart?, counterparty?. `signed = amount * type.sign` (income/moneyTaken = +1).
- `Category` / `SubCategory` (categories/domain/category.dart): id, name, iconCode (int →
  const icon via `iconFromCode`), colorIndex, isDefault, subCategories[].
- `AppUser` (auth/domain/app_user.dart): id, phone, fullName?, email?, dob?, state?.
- `SavingsGoal`, `QuickNote` (tools/domain).

### 2.3 Backends
- **Local** repos store JSON in SharedPreferences; transaction/category repos use a broadcast
  `StreamController` so `watch()` emits on every change (real-time in-app).
- **Firestore** repos:
  - Auth: `app_users` keyed by **phone number** (doc id) → cross-device login + uniqueness.
    Session (stay-logged-in) stays local. Also writes `users/{id}` profile for tracking.
  - Transactions: `users/{userId}/transactions` via `.snapshots()` (real-time).
  - Categories: `users/{userId}/categories`, `ensureSeeded` seeds defaults on first login.

### 2.4 Auth flow
1. `SplashScreen` (branded, 3D) → decides route: logged-in + lock → `/lock`, else `/dashboard`
   (router redirect sends to `/login` / `/onboarding` if needed).
2. Register: phone + strong password + OTP (`123456`) → account. Google: pick account →
   if email already maps to exactly one account → login; else phone + OTP, then reconcile
   (link email to existing phone OR create). Phone stays compulsory the first time.
3. App Lock: PIN (4-digit, hashed) and/or biometric on launch via `LockScreen`.

### 2.5 Theming, l10n, responsiveness
- `AppTheme` builds light/dark from `AppColors` + `AppSemanticColors` (per-type colours).
  Access via `context.semantic.byTypeKey(type.key)`.
- Localization via ARB + `flutter gen-l10n` (`generate: true`), `AppLocalizations.of(context)`.
- Money never overflows: `AnimatedMoney` + `Formatters.moneySmart` (compact >₹1cr) +
  `FittedBox`/`Flexible`. Screens use `ConstrainedBox(maxWidth: …)` + `SafeArea`.

---

## 3. Build, run, deploy

```bash
flutter create --org com.appexbusiness --platforms=android,ios,web .   # first time only
flutter pub get
dart run flutter_launcher_icons        # app icons from assets/branding/apna_ledger_logo.png
dart run flutter_native_splash:create  # native splash
flutter gen-l10n                       # (auto on build)

flutter run -d chrome                  # dev
flutter build web                      # icons are const now -> no --no-tree-shake-icons needed
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

**Firebase (both QA & Prod projects):** enable **Anonymous** + **Google** sign-in; Firestore
in `asia-south1`; rules allow authenticated read/write; add SHA-1/256 (Android) & the web
`google-signin-client_id` meta (already in `web/index.html`) + authorized JS origins/domains.

**Flavors:** QA `com.appexbusiness.apnaledgerqa`, Prod `com.appexbusiness.apnaledger`
(see FIREBASE_AND_BUILD_SETUP.md for gradle flavor config + google-services placement).

---

## 4. Conventions for contributors / AI
- Never construct dynamic `IconData` — use `iconFromCode` / `kCategoryIcons` (keeps web
  tree-shaking working).
- Money display → `AnimatedMoney` or `Formatters.moneySmart`, always inside a bounded/
  `Flexible` parent.
- Input dialogs → `showAppSheet` (bottom sheet); confirmations → `showAppConfirm`.
- Colours by transaction type → `context.semantic.byTypeKey(key)`, never hard-coded.
- New user-facing strings → add to `lib/l10n/app_en.arb` (others fall back), then `gen-l10n`.
- Buttons use `AppButton` (already debounced) to prevent double-submit.
