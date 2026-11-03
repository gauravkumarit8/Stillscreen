# Blocking test checklist

Run these on a real phone before every release that touches blocking. Start a
session with one app in the blocked list (use YouTube or any app you can open
easily). After each step, a good result is: **the block screen appears and the
app cannot be used.**

After any new install, first switch Stillscreen off and on in Accessibility,
and confirm the health check says **Blocking service: Running**.

## Opening the blocked app

- [ ] App not running (swiped away earlier), open it from the launcher.
- [ ] App running in the background, open it from recent apps.
- [ ] App running in the background, tap its icon on the home screen.
- [ ] Open it from a link or notification in another app.
- [ ] Open it from the app drawer search or the Google search box.
- [ ] Open it from a home-screen shortcut or widget.

## Opening it again and again

- [ ] Block screen shown, tap "Back to focus", open the app again. Blocks again.
- [ ] Do that three times in a row.
- [ ] Block screen shown, press the Home gesture, open the app again. Blocks again.
- [ ] Block screen shown, press Back. Goes home and the app stays blocked.
- [ ] Block screen shown, open recent apps and pick the blocked app. Blocks again.

## Session behaviour

- [ ] The blocked app was already open when the session started. Switch away and back. It blocks.
- [ ] Screen off and back on during a session. Open the app. It blocks.
- [ ] Wait 10 minutes with the phone unlocked, then open the app. It blocks.
- [ ] End the session early. The app opens normally.
- [ ] Let the session run to its end. The app opens normally.
- [ ] Extend the session with +5. Blocking continues past the old end time.
- [ ] Strict mode on: the session cannot be ended early.

## What the block screen shows

- [ ] It names the blocked app ("YouTube is blocked during your focus session").
- [ ] It shows how long you have focused and how long is left.
- [ ] With an exam set, it shows the countdown ("NEET in 42 days"). With none set, no exam line.
- [ ] Tap "Back to focus" a few times. "You have chosen focus N times today." grows by one each time.
- [ ] The same text appears on the overlay version (see "Last block attempt").
- [ ] A wind-down block shows no session progress and no counter.
- [ ] A breathing circle grows for about 4 seconds ("Breathe in") and shrinks for about 6 ("Breathe out"). The label changes with it.
- [ ] The circle stops when you leave the block screen (no battery use in the background).
- [ ] On a short screen (under about 640 dp tall) the circle is left out and nothing overflows.
- [ ] With animations turned off in Developer options, the circle stays still and nothing crashes.
- [ ] With a streak, the screen says "Finish this session to keep your N day streak." or "N day streak. Today's goal is done."
- [ ] With no streak and a long enough session, it says "Finish this session to start a streak."
- [ ] Start a session after a long break. The streak line reflects the break (the streak resets after a missed full day).

## Stats and suggestions

- [ ] After tapping "Back to focus" a few times, Stats > This week says "You chose focus N times when an app pulled at you."
- [ ] After two finished sessions, with the mindful pause off, the home screen shows "Try a mindful pause" once. "Set it up" opens the pause settings. "Not now" hides it for good.
- [ ] With the mindful pause on, the suggestion never appears.
- [ ] The suggestion and the rating card never show at the same time.

## Stillscreen itself

- [ ] While a session runs, Stillscreen is not in the recent apps list. It reappears after the session ends.
- [ ] Open Stillscreen from its icon during a session. The timer is still running.
- [ ] YouTube was running in the background. Open it from recent apps five times in a row. It blocks every time.

- [ ] Lock Stillscreen in recent apps, then close other apps. Open the blocked app. It blocks.
- [ ] Swipe Stillscreen away during a session. Reopen Stillscreen. A "Blocking has stopped" card appears.
- [ ] After switching Accessibility off and on, blocking works again.
- [ ] Restart the phone during a session. Check the health check afterwards.
- [ ] Install an update. Switch Accessibility off and on, then test again.

## Mindful pause

- [ ] Turn Mindful pause on and add an app that is **not** in the blocked list.
- [ ] Open that app with no session running. The pause screen appears.
- [ ] "Continue" stays locked until the countdown ends, then opens the app.
- [ ] Open the app again right away. No second pause (the grace period).
- [ ] "Not now" goes home.
- [ ] Open the app from recent apps, not the launcher. The pause still appears.
- [ ] An app in **both** lists shows the block screen during a session, not the pause.

## Other situations

- [ ] Blocked app in a floating window, split screen, or picture-in-picture (known limits; note what happens).
- [ ] Battery saver on.
- [ ] Wind-down schedule: a work app is blocked inside the hours and open outside them.
- [ ] Phone calls and Settings are never blocked.
- [ ] Repeat the main steps on a phone from a different brand.

## If something fails

Open Stillscreen, go to the blocking health check, and screenshot the top
(Blocking service, Blocking state) and Recent activity. They say whether the
service was running, what it decided, and what it tried to show.
