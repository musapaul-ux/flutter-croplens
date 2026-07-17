# CropLens Mobile App

Flutter frontend for **CropLens**, an AI-powered crop disease detection app.
Material 3, MVVM via Riverpod, Go Router navigation, dark mode, and a green
agricultural visual identity.

## Tech Stack

- **Flutter / Dart**, Material 3
- **State management:** flutter_riverpod (StateNotifier-based ViewModels)
- **Navigation:** go_router, with an auth-aware redirect guard and a persistent
  bottom-nav `ShellRoute`
- **Networking:** dio, with a JWT interceptor that auto-refreshes expired
  access tokens and retries the original request
- **Secure storage:** flutter_secure_storage (tokens never touch SharedPreferences)
- **Camera:** the `camera` package for a live preview + capture, `image_picker`
  for gallery selection
- **Polish:** google_fonts, flutter_animate, cached_network_image

## Folder Structure

```
lib/
├── main.dart                        # App entry point
├── core/
│   ├── theme/                        # Colors + Material 3 ThemeData (light/dark)
│   ├── constants/                     # App-wide constants
│   ├── routing/app_router.dart        # go_router config + auth redirect guard
│   ├── network/                       # Dio client, secure storage, ApiException
│   ├── utils/validators.dart          # Form validation rules
│   └── widgets/                       # Reusable PrimaryButton, AppTextField, EmptyState
├── data/
│   ├── models/                        # UserModel, ScanModel, DashboardStats
│   └── repositories/                  # AuthRepository, UserRepository, ScanRepository
├── providers/                         # Riverpod ViewModels (auth, scan, history, dashboard, theme)
└── features/                          # One folder per screen/flow
    ├── welcome/                        # Screen 1
    ├── auth/                           # Screens 2–4 (signup, login, forgot/reset password)
    ├── shell/                          # Persistent bottom-nav shell
    ├── dashboard/                      # Screen 5
    ├── scan/                           # Screens 6–7 (camera capture + results)
    ├── history/                        # Screen 8
    └── profile/                        # Screen 9
```

## Getting Started

```bash
cd croplens_app
flutter pub get
cp .env.example .env   # point API_BASE_URL at your running croplens-backend
flutter run
```

**Note on API_BASE_URL:**
- Android emulator → `http://10.0.2.2:5000/api` (maps to your host machine's localhost)
- iOS simulator → `http://localhost:5000/api`
- Physical device → your machine's LAN IP, e.g. `http://192.168.1.10:5000/api`

## Required Native Permissions

The camera and photo library features need platform permission entries that
aren't part of `lib/` — add these before running on a device:

**Android** — `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

**iOS** — `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>CropLens needs camera access to scan your crops for disease detection.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>CropLens needs photo library access so you can select crop images to scan.</string>
```

## Screens Implemented

| # | Screen | Notes |
|---|---|---|
| 1 | Welcome | Gradient hero, feature highlights, "Get Started" → Sign Up |
| 2 | Sign Up | Full name / email / password / confirm, password visibility toggle |
| 3 | Login | Email or username / password, Remember Me, Forgot Password |
| 4 | Forgot / Reset Password | Request link → email → reset with token from deep link |
| 5 | Dashboard | Stat cards (total/healthy/infected), recent scans, floating Scan button |
| 6 | Crop Scan | Live camera preview, flash toggle, gallery picker, capture |
| 7 | Results | Crop/disease/confidence/diagnosis/treatment/prevention, scan again / share |
| 8 | History | Search, sort (bottom sheet), infinite scroll, swipe-to-delete |
| 9 | Profile | Avatar upload, edit name, change password, dark mode toggle, logout |

Bottom navigation (Home / Scan / History / Profile) persists via a `ShellRoute`
and is only shown once authenticated; the Scan tab jumps straight into the
camera, per the spec.

## State Management Pattern

Each feature's "ViewModel" is a Riverpod `StateNotifier` in `lib/providers/`:
- `authProvider` — session state, login/register/logout, token-aware bootstrap on app start
- `scanUploadProvider` — drives the capture → upload → AI prediction → Results flow
- `historyProvider` — search/sort/pagination/delete for the History screen
- `dashboardStatsProvider` — `FutureProvider.autoDispose`, refreshed after every new scan
- `themeModeProvider` — light/dark/system toggle, read by `MaterialApp.router`

Screens are `ConsumerWidget`/`ConsumerStatefulWidget`s that watch these
providers and stay dumb — no direct API calls from widget code.

## Known Gaps / Next Steps

- `share_plus` isn't wired in yet — the Results screen's Share button shows a
  placeholder snackbar; add the dependency and a couple of lines to go live.
- No local image caching/offline queueing for scans taken with poor connectivity.
- Widget/golden tests aren't included — `test/validators_test.dart` covers the
  form-validation logic as a starting point.
- This code could not be compiled against a real Flutter SDK in the environment
  it was written in (no `pub.dev` network access there); it's been carefully
  reviewed for syntax and API correctness, but run `flutter pub get && flutter analyze`
  as your first step after unzipping.
"# flutter-croplens" 
