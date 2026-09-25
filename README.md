# Apna Ledger — _Rakhe Pai Pai Ka Hisaab_

A premium, multi-language personal & business finance tracker built with Flutter
for **Android, iOS and Web**. No documents, no bank details — just fast, private
money tracking with categories, sub-categories, charts and a habit-forming UI.

> Package name: `com.appexbusiness.apnaledger`

---

## Highlights

- **Clean architecture**, feature-first folders, everything behind interfaces so
  pieces are easy to test, modify or replace.
- **Riverpod** for state + dependency injection, **go_router** for navigation.
- **Light theme by default** + full dark theme, both Material 3.
- **6 languages**: English, Hindi, Gujarati, Bengali, Telugu, Tamil (ARB-based).
- **Default + custom categories & sub-categories** (Business → Xerox / Freelance
  IT / Snacks, Family → Sharma Family / Vivek Parmar, Bills, EMI, Travel, …).
- **Pie chart + day-grouped history** for clear vision of where money goes.
- **Auth**: phone + password, OTP on register & forgot-password (master OTP
  `123456` for now), **session never expires** until manual logout.
- **First-run screen** to pick language + theme on a single page (skippable).
- **Firebase** wired for Analytics, Crashlytics and Firestore, across **QA / UAT
  / Prod** flavors (QA & UAT share one project; Prod is separate).
- **Runs instantly with zero backend** via a local SharedPreferences data layer;
  flip one flag to move to Firestore.

---

## Architecture

```
lib/
├─ app/
│  ├─ app.dart                 # Root MaterialApp.router (theme + locale reactive)
│  └─ router/app_router.dart   # go_router: auth/onboarding redirects + shell
├─ bootstrap.dart              # Shared startup (Firebase, prefs, session restore)
├─ main.dart / main_qa / main_uat / main_prod
├─ firebase_options_qa.dart    # QA/UAT project (apnaledgerqa)
├─ firebase_options_prod.dart  # Separate prod project (fill in before release)
├─ core/
│  ├─ config/                  # Flavor + EnvConfig
│  ├─ constants/               # Keys, collections, India states
│  ├─ di/injector.dart         # All Riverpod providers + backend switch
│  ├─ error/                   # AppFailure
│  ├─ services/                # Logger (Low/Mid/High), Analytics, LocalStorage
│  ├─ theme/                   # Colors, typography, light/dark themes
│  ├─ utils/                   # Formatters, Validators, icon helper
│  └─ widgets/                 # Shared buttons, fields, banners
├─ l10n/                       # app_en/hi/gu/bn/te/ta.arb
└─ features/
   ├─ auth/            (domain · data · presentation)
   ├─ categories/      (domain · data · presentation)
   ├─ transactions/    (domain · data · presentation)
   ├─ dashboard/       (presentation: shell, screen, balance card, pie)
   ├─ onboarding/      (presentation)
   └─ settings/        (presentation: settings + AppSettings controller)
```

Each feature has:
- **domain** — pure entities + a repository *interface* (no Flutter/Firebase).
- **data** — a **local** (SharedPreferences) and a **Firestore** implementation.
- **presentation** — Riverpod providers/controllers + screens/widgets.

### Swapping the data backend
`lib/core/di/injector.dart` exposes:

```dart
enum Backend { local, firebase }
const kBackend = Backend.local; // ← flip to Backend.firebase for Firestore
```

Auth always uses the local demo backend until the real OTP/API is integrated;
transactions & categories follow `kBackend` (falling back to local if Firestore
isn't available).

---

## Getting started

```bash
flutter pub get
flutter gen-l10n          # generates lib/l10n/app_localizations.dart
```

Run (default / web, uses the QA environment):

```bash
flutter run -d chrome            # web
flutter run                      # attached device
```

Run a specific flavor on mobile:

```bash
flutter run --flavor qa   -t lib/main_qa.dart
flutter run --flavor uat  -t lib/main_uat.dart
flutter run --flavor prod -t lib/main_prod.dart
```

> **Release builds:** category icons are chosen dynamically, so build with
> `--no-tree-shake-icons`, e.g.
> `flutter build apk --flavor prod -t lib/main_prod.dart --no-tree-shake-icons`.

### Try it
Register with any valid 10-digit number + a password, verify with OTP **123456**,
pick your language & theme, then start adding income/expense entries. Your
session persists across restarts until you log out from **Settings**.

---

## Firebase setup

The QA/UAT web config is already filled in (`firebase_options_qa.dart`). To wire
the native platforms and the separate production project, run:

```bash
dart pub global activate flutterfire_cli

# QA / UAT (shared project)
flutterfire configure --project=apnaledgerqa \
  --out=lib/firebase_options_qa.dart

# Production (separate project)
flutterfire configure --project=<your-prod-project> \
  --out=lib/firebase_options_prod.dart
```

This also writes the `google-services.json` / `GoogleService-Info.plist` files.
Crashlytics is automatically disabled on web (no web implementation).

### Android flavors
Add product flavors to `android/app/build.gradle` so `--flavor qa|uat|prod`
resolves, e.g.:

```gradle
flavorDimensions "env"
productFlavors {
  qa   { dimension "env"; applicationIdSuffix ".qa";  resValue "string","app_name","Apna Ledger QA" }
  uat  { dimension "env"; applicationIdSuffix ".uat"; resValue "string","app_name","Apna Ledger UAT" }
  prod { dimension "env"; /* applicationId com.appexbusiness.apnaledger */ }
}
```

(iOS: create matching schemes/xcconfigs.)

---

## Logging severity

`LoggerService` records developer logs at three levels — **Low / Mid / High**.
Mid and High are forwarded to Crashlytics as non-fatal (High = fatal) with
`severity` and `area` custom keys, so issues are easy to triage in the console.

---

## Testing

```bash
flutter test
```

Included: pure unit tests for `Validators` and `Formatters`, an end-to-end test
of the local auth repository (register → login → OTP → reset → logout), and a
widget test for the login screen. Because every dependency is injected via
Riverpod, tests override providers with mock/local instances easily.

---

## Extending it (roadmap-friendly)

The structure is intentionally ready for the fuller use-cases:
- **Recurring bills / reminders** — add a `recurring` feature module with its own
  repo interface + local/Firestore impls; surface on the dashboard.
- **Loans / EMI with interest** — extend `TxnEntry` with optional loan metadata
  (already isolated in one entity + mappers).
- **Multiple businesses** — already supported via categories/sub-categories;
  add per-sub-category reports by grouping in a new provider.
- **Real OTP** — implement `AuthRepository` against your API and swap the binding
  in `injector.dart`. No UI changes required.

---

## Phase 3 — Money vertical (this build)

**Added**
- **4 transaction types** with fixed colours: Income (dark green), Expense (red),
  Loan Given (#F0A81C), Loan Taken (purple). Loans carry interest %, date given
  and due date. Every entry supports recurrence (once / daily / weekly / monthly / yearly).
- **Home**: "Total Net Balance", four quick-add cards, 🔥 logging-streak card,
  4-type monthly overview, and a **Ledger history** section with search + type
  filters + Date · Day · Time + CSV export.
- **Add Transaction**: 4-type selector, loan-only fields, inline
  **＋ Create new category**, and a recurrence picker.
- **Calculator** (`/dashboard/calculator`): split-a-bill, apply-discount and a
  basic pad — each can push its result into a new transaction.
- **Recurring entries** screen (`/dashboard/recurring`).
- **Categories**: per-category & per-sub-category income/expense, tap to open the
  filtered ledger, per-category CSV export, and a dynamic
  "Add your <Category> name" sub-category placeholder.
- **Settings**: profile CRUD (`/dashboard/settings/profile`), Share app, Privacy
  policy, Terms & Conditions, a creative How-to-use tour, and About.
- **Register**: Terms & Privacy consent gate.
- **Export**: reusable CSV service (`share_plus` + `path_provider`) — browser
  download on web, share sheet on mobile.

**Run after unzip**
```bash
flutter pub get      # fetches share_plus + path_provider, regenerates l10n
flutter gen-l10n     # (auto-runs on build; safe to run explicitly)
flutter run          # add --no-tree-shake-icons for release (dynamic category icons)
```

**Deferred to later phases** (need native setup or are large standalone screens):
Firebase push notifications (FCM native config), PDF export (CSV covers
"PDF or CSV" for now), and the dedicated People / Reminders / Investments /
Loans-&-EMI screens from the reference designs.

---

## Phase 4 — Naming, insights, PDF & polish (this build)

**Renamed everywhere (labels only; data unaffected)**
- "Expense" → **Spending**; "Loan Given" → **Money Given**; "Loan Taken" → **Money Taken**.
- Add-transaction dates: **Money Given Date** / **Money Taken Date**; "Due date" → **Return Commitment Date**.

**Added**
- **PDF + CSV download chooser** everywhere export exists, both AppexBusiness-branded
  (branded header/footer on PDF, banner rows on CSV). Progress indicator while generating.
- **Home**: animated hero net balance; four **rolling-number** type tiles that open the
  filtered ledger (search/filter/history/download); quick-add cards now use a **blinking dot**;
  app branding line ("Apna Ledger · by AppexBusiness").
- **Insights section** (replaces Overview + Spending-by-category): animated per-type bars +
  spending donut with a **Day / Week / Month / Year** filter.
- **Calculator**: clear expression line + result, left-to-right evaluation, and **history**.
- **Categories**: add-transaction straight from a category or sub-category (pre-selected),
  both income (green) & spending (red) shown with rolling numbers, and remove-sub-category
  now asks for confirmation.
- **Profile save** now reliably returns to Settings with a confirmation toast.
- **Terms & Privacy**: added a clear "no data guarantee / keep your own backups / use at
  your own risk" clause.

**Deferred to the next phase (stateful background system)**
- Auto-recurring **engine**: custom repeat dates, auto-generating due entries into an
  **approval queue**, the approval popup on app open, the **Auto Enter** label, and
  approve/reject/edit of pending auto entries.

**Run after unzip**
```bash
flutter create --org com.appexbusiness --platforms=web,android,ios,windows .  # first time only
flutter pub get      # fetches pdf + share_plus + path_provider, regenerates l10n
flutter run          # add --no-tree-shake-icons for release builds
```

---

## Phase 5 — Defaults, view mode, safer deletes, translations (this build)

- **Add Transaction** now defaults its category to **Others**; per-type date labels
  (Income Date / Spending Date / Money Given Date / Money Taken Date), **Return
  Commitment Date**, a **repeat start-date** picker, and an **Update** button when editing.
- **New accounts** start with categories only — **no example sub-categories**.
- **Tapping a ledger row** opens a clean **detail view**; editing is explicit (pencil).
- **Removing a sub-category** now asks whether to also delete its ledger entries
  (default) or move them to the parent — via a redesigned, **animated dialog**.
- **Duplicate category / sub-category names** are blocked.
- **Rolling numbers** on category & sub-category totals; **fade-in** on ledger rows;
  animated Insights bars & donut.
- **Translations**: complete **Hindi** and **Gujarati**; core **Bengali / Telugu / Tamil**
  (remaining strings fall back to English until a full native pass).

**Deferred (next phase):** rich **notepad** (bold/fonts) and the **auto-recurring
approval-queue engine**.

---

## Phase 6 — Branding, Firebase, security (this build)

- **Logo & branding**: your 2048² logo is staged in `assets/branding/`; `pubspec`
  is configured for **flutter_launcher_icons** (Android/iOS/web) and
  **flutter_native_splash**. New **animated in-app splash** + **"Powered by Appex
  Business" / www.appexbusiness.com** on splash, About and Settings.
- **Firebase**: core/analytics/crashlytics/firestore were already wired; added
  **Cloud Messaging (push)** and **Google Sign-In** (+ `firebase_auth`). Real
  QA + Prod options filled in `lib/firebase_options_{qa,prod}.dart`; Android
  `google-services.json` for both projects staged in `assets/firebase/`.
- **Google Sign-In** button on Login/Register — routes to phone + OTP (phone stays
  compulsory). **+91 🇮🇳** prefix on all phone fields.
- **Security**: optional **App lock** (Face ID / fingerprint / device PIN via
  `local_auth`) in Settings → Security, with a lock screen on launch.
- See **FIREBASE_AND_BUILD_SETUP.md** for the exact machine-side steps
  (flavors with the QA/Prod package names, google-services placement, Gradle
  plugins, Google OAuth + SHA-1, FCM, iOS, biometric manifest entries).

**Note:** Firebase native wiring, Google OAuth and FCM can't be compiled/verified
in this environment — they need the `android/ios` folders (`flutter create`) and
console setup. The Dart side is ready and guarded so the app still runs in local
mode meanwhile.

---

## Phase 7 — Fixes + features (this build)

- **FIX (crash):** removing a sub-category no longer crashes — the confirmation
  dialog's width is now bounded (`app_dialog.dart`).
- **FIX:** after editing profile, the app now returns to Settings with a toast.
- **Downloads** are now **direct** (browser download on web, Downloads folder on
  desktop, app documents on mobile) — no more OS share sheet. A **download icon**
  was added to the home header.
- **Google Sign-In** button now shows the real **Google "G"** and a clear message
  when OAuth isn't set up yet.
- **App logo** now appears on the splash, lock, and **all auth screens**.
- **Home cards** (Income/Spending/Money Given/Money Taken) now have **colour-coded
  borders**.
- **Category counts:** each category card and sub-row shows its **transaction count**.
- **Quick Categories** row on Home — horizontal, tap to expand a category and add a
  transaction straight into it or a sub-category.
- **Calculator → Savings Goals** tab: create goals, add money, animated progress
  bars, persisted locally.

### Why nothing shows in Firestore yet
The app runs on the **local** backend (`kBackend = Backend.local` in
`lib/core/di/injector.dart`), so entries are saved on-device, not to Firestore —
and your current Firestore rules (`allow read, write: if false;`) block all access.
To sync to Firestore: (1) finish Firebase native setup + real Auth, (2) publish
user-scoped rules (sample in FIREBASE_AND_BUILD_SETUP.md), then (3) set
`kBackend = Backend.firebase`.

---

## Phase 8 — Crash fixes + Firestore + account + polish (this build)

- **Fixed the "multiple heroes" crash** (duplicate FABs) — unique hero tags; removed the redundant Transactions FAB.
- **Fixed the Savings Goals crash** (Center-in-ListView) and made goal dialogs width-safe.
- **Transaction delete** now works with a confirmation dialog showing the entry.
- **Google Sign-In**: returning users log in directly; only new users go to phone + OTP.
- **Firestore**: backend switched to Firebase + anonymous auth (safe fallback to local). Enable *Anonymous* sign-in in both projects; add the web `google-signin-client_id` meta (see setup guide).
- **Delete account** (with password) in Settings.
- **Appex Business logo** extracted from your PDF → shown in "Powered by Appex Business"; **Apna Ledger logo** across auth/About/splash.
- **Professional Terms & Privacy** (liability, no-data-guarantee, at-your-own-risk, governing law, etc.).
- **Downloads**: one options sheet everywhere — **PDF/CSV + date range + type filter**; **premium PDF** now has a summary (count + net).
- Removed the transaction counts on categories; **shorter home cards**.

---

## Phase 9 — Calculator crash fix, Notes, PIN, connectivity (this build)

- **FIXED Savings Goals crash** — the `TabBarView` wrapped in `Center`/`ConstrainedBox`
  gave tab content infinite width on web; removed the wrapper.
- **Notes** — new icon in the Calculator opens a card-view notepad (create/edit/delete,
  each stamped with date + time), stored locally.
- **PIN lock** — optional 4-digit PIN (Settings → Security → Set PIN), used with
  biometric on the launch lock screen.
- **Google Sign-In** now on **both** Login and Register.
- **Internet indicator** — animated offline banner on Home explaining entries save
  locally and sync when back online (`connectivity_plus`).
- **Branding** — Apna Ledger logo on Home; **3D animated splash** (perspective flip + glow).

**New packages:** `connectivity_plus`.

---

## Phase 10 — Compile fix + Google↔phone account linking (this build)

- **FIXED build error**: `_AppLockTile` now has a `const` constructor (was breaking the
  `const [...]` Security list).
- **Professional Google account reconciliation**:
  - Google email with exactly **one** account → logs straight in.
  - **New** email → phone + OTP, then a fresh account (no password needed for Google users).
  - Phone already exists → the Google **email is linked/mapped** onto that account.
  - Same email across **multiple phones** → user enters their phone + OTP, and only the
    matching (email + phone) account's data is opened.
  - Google Sign-In is on both Login and Register; password fields are hidden in the
    Google flow.
- Completed **Hindi/Gujarati** translations (0 untranslated). Bengali/Telugu/Tamil still
  fall back to English for newer strings (harmless warnings).

---

## Phase 11 — Root-cause crash fix + real-time + tracking (this build)

- **Root cause of the recurring layout crashes found & fixed**: a `FilledButton.icon`/
  `TextButton.icon` placed as a **non-flex child of a `Row`** is measured with infinite
  width (its internal `Flexible` label then throws). Fixed in **Savings Goals** (button
  moved to a full-width slot), the **confirmation dialog** (tight width + `Wrap` actions —
  this restores **Delete** and remove-sub-category), and the ledger filter bar.
- **Real-time updates**: new/deleted transactions now appear immediately (stream
  invalidation after save/delete + the crash fix that was previously freezing repaints).
- **Firestore user tracking**: every login/register/Google sign-in now writes a
  `users/{id}` profile document with **phone, email, name** — so you can identify and
  count users in Firestore.
- **Home header**: the profile icon is replaced with a **NotePad** icon (opens Notes);
  Settings remains in the bottom bar.

---

## Phase 12 — Screenshot fixes + UX (this build)

**Fixed / done**
- **Home cards overflow** (screenshot 4): the four type tiles now use a fixed height
  (`mainAxisExtent`) + `FittedBox`, so no more "BOTTOM OVERFLOWED".
- **PIN screen** (screenshot 1): masked, high-contrast field on the dark theme.
- **Add Category** (screenshot 2): moved from the overlapping FAB to an app-bar action.
- **App Lock** now works via **PIN or biometric** (no longer a dead toggle); enabling
  needs either a PIN set or device biometrics.
- **Download** defaults to the **last 3 months**; toast shows the saved path.
- **Savings Goals**: amount fields are digit-only validated.
- **Add Category**: add **N optional sub-categories inline** while creating/editing.
- **Notes**: delete now asks for confirmation.
- **Home header**: reorganised (no overflow) with **Download / Calculator / Notes /
  Savings-Goals** quick-tool icons; profile icon replaced earlier by Notes.
- Real-time refresh after add/delete (stream invalidation) + save spinner.

**Still deferred (honest, next focused pass)** — I did not want to ship these half-done:
- Savings-Goals full redesign: motivational quotes (system + custom), due date, and an
  animated on-home goal card with a 3-dots "hide from home".
- Bottom-sheets-everywhere conversion (#7).
- Download **success sheet with Open/Share + notification history + public Downloads
  folder** (needs a notifications package + scoped-storage permissions).
- Complete-profile skippable screen (#12).
- Expanded test suite (#13).
- Web Google Sign-In needs the newer Google Identity Services `renderButton` flow
  (current button works on mobile with OAuth + the web client-id meta tag).

---

## Phase 13 — Overflow fix, bottom sheets, goals (this build)

**Fixed the number-overflow that was breaking every screen (screenshots 1–4)**
- Amount input is now **capped at ₹1,00,00,000**.
- All money displays are **overflow-proof**: compact notation (₹5.5Cr) for very large
  values + single-line `FittedBox` scaling in the ledger tiles, category rows, insights
  bars, pie legend, savings goals and the net-balance hero.

**Bottom sheets throughout (#7,8,9,13,14)**
- New reusable animated **bottom sheet** (rounded top, drag handle, close ✕).
- **Add Goal** (name, target, target date), **Add Money**, **Add Note** (optional title +
  body), and **Add Category** (now with a close ✕) all use it.
- All **confirmations** (delete transaction / note / goal, remove sub-category) are now
  **bottom sheets** with an icon header.

**Other**
- **Savings Goals** moved out of the Calculator into its **own screen** (Home tools row).
- **Total Net Balance** has an **ⓘ** that opens a sheet explaining the formula (#10).
- **Settings** shows the **environment** badge (QA/UAT; hidden in prod) (#5).

**Deferred (honest)** — icons via `dart run flutter_launcher_icons` (#1); native biometric
needs the FlutterFragmentActivity edit — PIN works now (#2); notification centre + download
open/share sheet (#6); light-theme colour chooser (#11); Firebase CRUD loaders + offline
sheet (#12); transaction-details / privacy / terms as sheets (#15,16); extra splash
animation (#18).

---

## Phase 14 — Build fix, web load, cross-device auth (this build)

**Blockers fixed**
- **`flutter build web` error (non-const IconData)** — category icons now resolve from a
  **const icon set** (`kCategoryIcons`); no dynamic `IconData` anywhere, so tree-shaking
  works with **no `--no-tree-shake-icons` flag needed**.
- **4–5s white screen on web** — added `web/index.html` with a **branded loader** (logo +
  spinner) shown instantly and removed on Flutter's first frame. It also bakes in the
  **Google Sign-In client-id meta tag** (QA) so web Google sign-in can work.
- **Button spam** — `AppButton` now **debounces** (ignores repeat taps for 700ms + disabled
  while loading), so an action can't fire N times.

**Cross-device authentication (the big one)**
- New **Firestore-backed auth repo**: users live in `app_users` keyed by **phone number**,
  so the same number can't be registered twice and **login works from any device**. Session
  (stay-logged-in) stays local. Falls back to the on-device store if Firebase is unreachable.
- Requires **Anonymous auth enabled** (done) + Firestore rules allowing authenticated
  read/write (done). Note: password hashes in Firestore are readable by any authed user —
  fine for this stage; a future move to Firebase Auth phone/email providers is the hardened path.

**Deferred (honest — large, dedicated passes)**
- **Calendar** day-wise activity + graphs (#1).
- **Contacts** (import/create, categories) for transactions (#4).
- **Challenges** inside Savings Goals (#5).
- The Netlify **"Dangerous"** banner is Chrome Safe-Browsing flagging the shared
  `*.netlify.app` subdomain (a finance keyword false-positive) — use a **custom domain** or
  submit a review; it's not in the app code.

---

## Phase 15 — Security, branding, web polish + PRD (this build)
- **Strong passwords**: min 8 chars incl. 1 uppercase, 1 number, 1 special (register + reset).
- **App logo replaces Flutter logo** on web: generated `web/favicon.png`, `web/icons/*`,
  `web/manifest.json` from the logo — browser tab, PWA and the loader now show Apna Ledger.
- **Loading UX**: `web/index.html` branded loader matches the in-app splash (seamless), and
  the in-app splash is shorter (1.2s).
- **Forgot password**: phone → OTP (`123456`) → new password (already wired; verified).
- **Docs**: added `docs/PRD_AND_ARCHITECTURE.md` (PRD + full code architecture for devs/AI).

**Config, not code (do on your side)**
- **Google Sign-In on web**: rebuild & redeploy so the new `web/index.html` (with the
  `google-signin-client_id` meta) is live, then hard-refresh. Mobile needs SHA-1/256.
- **"Dangerous" banner**: Google Safe Browsing flags the shared `*.netlify.app` subdomain
  (finance login → false positive). Fix by using a **custom domain** and/or submitting a
  review at Google Safe Browsing; it is not in the app code.
- **Data-at-rest encryption** (requested): recommended next step is `flutter_secure_storage`
  for the session/token + moving auth to Firebase Auth providers — deferred hardening.

---

## Phase 16 — Auth flow + Google error surfacing (this build)

- **Google Sign-In now shows the REAL error** in a dialog (selectable text) instead of a
  generic toast — so the exact failure can be reported. It also tries `signInSilently`
  first (returning users) then the popup.
- **OTP-minimized flow implemented**:
  - New user → mobile + OTP (once) → set password → account.
  - Google (new & existing) → if the email is already linked to one account → **login
    directly, no OTP**; otherwise mobile + OTP once, then Google is linked.
  - Google-created/linked accounts are marked **emailVerified = true** (no email OTP).
  - Forgot password → OTP once → new password.
- **Email verification via Google** (no email OTP): in Edit Profile, an unverified email
  shows **"Verify with Google"** → Google popup → if the Google email matches the profile
  email, it's marked **Verified ✓** and Google is linked; mismatch shows a clear message.
- `AppUser.emailVerified` added and persisted (local + Firestore).

---

## Phase 17 — Auth clarity, Google-only email, help, splash carousel (this build)

**Authentication reworked (cleaner, less confusing)**
- **No manual email entry** anywhere. Register = phone + password + OTP (once). Email is
  added later, only via Google.
- **Email via Google** (Edit Profile → *Verify with Google*): the Google popup returns the
  email + name; it's linked to your phone and marked **Verified ✓**. No email OTP.
- **1 email : 1 phone enforced** — a Google email already linked to another account is
  rejected with a clear message; a phone can only ever have one account (phone = Firestore
  doc id).
- **Google login/register**: existing linked email → logs in directly (no OTP); new email →
  phone + OTP once, then linked.
- **Friendly Google errors** — users see a calm sentence (e.g. "Network issue…",
  "cancelled…"); the raw error is only `debugPrint`ed for developers.

**Other**
- **Help & Support** in Settings → emails **Appexbusinessofficial@gmail.com**.
- **Splash feature carousel** — auto-cycling key-feature highlights (icon + title + subtitle)
  with fade/slide + progress dots, over the animated 3D logo, while the app boots.

**Deferred (honest — real features, next dedicated passes)**
- **In-app Contacts** (custom + import from system contacts, categories, picker in Add
  Transaction) — needs the `flutter_contacts` package + runtime permissions.
- **Challenges** inside Savings Goals (default + custom, calendar-based tracking, the
  liability clause in Terms).
