# Accessibility Service declaration (Play Console)

Play reviews apps that use the Accessibility API closely, and an app that is
not an accessibility tool must explain why the API is core to its function.
Expect questions, and possibly a request for a short video. Keep the app
honest and minimal: it should never ask for more than it needs.

## What the service does (use this wording)

Stillscreen is a focus and app-blocking app. Its core feature is showing a
pause screen when the user opens an app they chose to block, during a focus
session or during wind-down hours they scheduled, and a short breathing pause
before apps the user chose for the optional Mindful pause feature. The Accessibility Service
is used only to receive the window-change event that says which app came to
the front. Without it the app cannot do its single main job.

## What it does not do

- It does not read screen content (`canRetrieveWindowContent` is false).
- It does not read typed text, passwords or notifications.
- It does not perform gestures or click on the user's behalf.
- It does not collect, store off-device or share any data from the service.

## In-app prominent disclosure

The user sees this dialog, with "Not now" and "Agree and continue", before
being sent to Android's Accessibility settings. The text lives in
`lib/features/home/accessibility_disclosure.dart`. Keep it identical to what
you submit.

## Video (if requested)

Record a short screen capture that shows, in order:
1. First launch and picking Student or Working professional.
2. Tapping "Turn on blocking" and the disclosure dialog appearing.
3. Tapping "Agree and continue" and enabling Stillscreen in Accessibility.
4. Choosing apps to block and starting a session.
5. Opening a blocked app and the pause screen appearing.
6. Ending the session and the app opening normally.

## Before you submit

- Confirm the service config still has `canRetrieveWindowContent="false"`.
- If you ever add Reels/Shorts detection, it will need to read window content.
  That changes this declaration, the disclosure text and the privacy policy,
  and it is a much harder review. Treat it as a separate project.
