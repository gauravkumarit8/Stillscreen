# Responsive layout test checklist

Run this before every release. A broken first screen means lost users.

## Set up the phone
1. Settings > Display > **Font size: Largest** (and **Display size: Largest** if offered).
2. Repeat once with the defaults.
3. Repeat once in **landscape** (turn auto-rotate on).
4. If you can, repeat on a small phone (about 5 inch) and a tablet or emulator.

## Check every screen
For each item: nothing is cut off, no yellow/black overflow stripes, every
button can be reached (scroll if needed), text is readable.

- [ ] First run: "How will you use Stillscreen?" (Continue button reachable)
- [ ] Setup / permission screen
- [ ] Home: streak row, level row, exam or wind-down card, timer, chips, Start
- [ ] Apps to block: search, filter chips, list
- [ ] Your focus (stats): tiles, weekly bars, heatmap, achievements
- [ ] Settings and each sub-screen (reminder, wind-down, mindful pause, goal)
- [ ] Break screen
- [ ] Dialogs: custom length, end session early, add offline time, exam date,
      daily goal, reason (open the keyboard in these two)
- [ ] Block screen (start a session, open a blocked app)
- [ ] Mindful pause screen
- [ ] Blocking health check and battery guide

## Tablet / wide screens
- [ ] Content stays in a centred column (about 600 dp), not stretched edge to edge.

## What the app does automatically
- Content width is capped at 600 dp (ResponsiveFrame in lib/app/responsive_frame.dart).
- Text follows the system font size up to 1.6x. Beyond that it stops growing.
- Screens scroll, and their main buttons stay reachable.
