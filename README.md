# Stillscreen

Focus timer and app blocker for students and working professionals.
Android first, Windows later. Flutter UI, native Kotlin for blocking.

> Working name. Before publishing, confirm the name on Google Play search,
> the App Store, a domain, social handles, and a trademark search.

## First run in GitHub Codespaces

Use a 4-core machine or larger.

1. Create a GitHub repo, upload this folder, open it in a Codespace.
   The dev container installs Flutter, Java 17 and the Android SDK tools.
2. Open a new terminal and run:
   `bash scripts/bootstrap.sh`
   This runs `flutter create`, then copies `overlay/` on top (our code,
   manifest and Kotlin files). Commit everything it generates.
3. Preview the UI in the browser (blocking is stubbed on web):
   `flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0`
   Open the forwarded port 8080.
4. Build an APK:
   `flutter build apk --debug`
   Download `build/app/outputs/flutter-apk/app-debug.apk`, or push to `main`
   and take `stillscreen-debug-apk` from the GitHub Actions run.

## Testing blocking on a real phone

Codespaces cannot run the Android emulator usefully, and blocking needs a
real device anyway.

1. Copy the APK to your phone and install it.
2. Android 13+: for sideloaded apps, open Settings > Apps > Stillscreen >
   the three-dot menu > Allow restricted settings.
3. In Stillscreen tap "Turn on blocking", then Settings > Accessibility >
   Installed apps > Stillscreen blocker > turn on.
4. Choose apps to block, start a 25 minute session, open a blocked app.
   You should see the pause screen.

## What is in this scaffold

- Onboarding: pick student or working professional (stored locally)
- Home: focus ring, 25 / 50 / 90 minute sessions, blocked-app picker
- `BlockingEngine` interface (Dart) with Android and preview implementations
- Android: accessibility service (window changes only), pause screen,
  platform channel. Session end time is stored as a timestamp, so no
  foreground service is needed yet.

## Not built yet

Strict Mode, streaks and stats, accounts and sync (Supabase), groups and
leaderboards, Reels/Shorts blocking, battery-optimization guidance, paywall,
Windows. The onboarding copy lists planned features per mode, so edit it to
match what ships.

## Before Play submission

- Fill the Accessibility permission declaration honestly (blocking apps the
  user chose; no screen content read) and keep the in-app disclosure.
- Replace the debug build with a signed release build.
- Set the real application ID if you change it from `app.stillscreen.focus`.
