# Closed testing runbook

For a personal developer account created after 13 November 2023, Play requires
a closed test with at least 12 testers opted in for 14 continuous days before
you can apply for production access. Confirm the current rule in Play Console.

## A. Build the signed bundle

    bash scripts/make_upload_key.sh
    python3 scripts/enable_release_signing.py
    flutter build appbundle --release

Check it is signed with YOUR key and not the debug key:

    keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | head -5

"Owner" should show your name. If it says "Android Debug", the signing step
did not take effect, so stop and do not upload.

Download `build/app/outputs/bundle/release/app-release.aab` from the Explorer
(right-click, Download). Download `~/stillscreen-upload.jks` too, and store it
with its password outside GitHub. If you lose the upload key, Play can reset it
through support, but it costs time.

## B. Create the app in Play Console

1. All apps, then Create app. Name: Stillscreen (you can change this later).
   App, Free, accept the declarations.
2. Work through the "Set up your app" checklist on the dashboard:
   - Privacy policy: your hosted page (see PRIVACY_POLICY.md)
   - App access: all functionality available without login
   - Ads: no ads
   - Content rating: answer the questionnaire honestly
   - Target audience: choose deliberately (students may include minors)
   - Data safety: the app collects no data and has no network access today
   - Anything else listed, including the Accessibility Service declaration
3. Main store listing: use PLAY_LISTING.md. Add the icon (512 x 512), a feature
   graphic (1024 x 500) and at least 2 phone screenshots.

## C. Start the closed test

1. Testing, then Closed testing, then create or use the default track.
2. Create new release, upload the .aab. The first upload fixes the application
   ID `app.stillscreen.focus` permanently.
3. Testers tab: create an email list, or better, a Google Group, and add the
   group's address, so you can add or remove people without editing Play.
4. Save, review, start rollout to closed testing.
5. Copy the opt-in link and send it to your testers.

Each tester must open the link on their phone, accept, and install from Play.
The 14 days only count while they stay opted in.

## D. Recruit 15 to 20 testers

You need 12 who stay the whole time, so over-recruit. Classmates, friends,
family and colleagues are the most reliable. Online developer communities also
swap tests. Do not pay for tester services: they can violate policy and give
you nothing useful.

Message to send:

    Hi! I'm testing a focus app called Stillscreen before launch. Could you
    help for two weeks? Open this link on your Android phone, accept the
    invite and install: [opt-in link]. Please keep it installed until
    [date] and try a focus session or two. If anything feels broken, message
    me with your phone model. Thank you!

## E. During the 14 days

- Ship fixes as new versions on the same track. Raise the number after the +
  in pubspec.yaml each time. Do not pause or halt the track.
- Ask testers for phone model and what happened, especially Xiaomi, Oppo, vivo
  and Samsung users, since background behavior differs on those.
- After day 14 (add a couple of days buffer), apply for production access in
  Play Console and answer the questions about what you tested and changed.
