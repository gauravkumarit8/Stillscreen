# Store assets guide

Specs below are from memory of Play's current rules. Play Console shows the
exact limits next to each upload box, so trust that over this table.

| Asset | Size | Notes |
|---|---|---|
| App icon | 512 x 512 PNG | `store/icon-512.png` is ready |
| Feature graphic | 1024 x 500 PNG or JPEG | `store/feature-graphic.png` is ready |
| Phone screenshots | 2 to 8 images | JPEG or PNG, each side 320 to 3840 px, longer side no more than 2x the shorter |

Real phones are usually taller than 2:1 (a 1080 x 2400 screenshot is 2.2:1), so
raw screenshots can be rejected. `scripts/frame_screenshots.py` puts each one on
a 1080 x 1920 canvas (16:9) with a caption.

## 1. Prepare the phone

- Install the debug APK (`flutter build apk --debug`). Demo data only exists in
  debug builds. Release builds do not contain the menu.
- Phone tidy-up: turn on Do Not Disturb, clear notifications, full battery if you can,
  no personal account names or contacts visible.
- In Stillscreen, tap the flask icon in the top bar, then "Load demo data".
  This fills 15 days of sample sessions (6-day streak, 9-day best) and a sample
  exam 42 days away.

## 2. Take the screenshots (Power + Volume Down)

Name them so they sort in this order.

| File | What to show | How to stage it |
|---|---|---|
| `01-onboarding.png` | "How will you use Stillscreen?" with one card selected | Clear app data (Settings > Apps > Stillscreen > Storage), reopen, tap Student |
| `02-focus.png` | Timer ring partway through a session | Start a 25 min session, wait a minute, capture |
| `03-apps.png` | Apps picker with pack chips and Select all | Open Apps to block, tap Social media |
| `04-pause.png` | The "Take a breath" pause screen | During a session, open a blocked app |
| `05-stats.png` | Streak, totals and 7-day chart | Open the chart icon (after loading demo data) |
| `06-exam.png` | Student home with the exam countdown | Student mode, demo data loaded |
| `07-winddown.png` | End-of-day wind-down settings | Switch to Working professional, open the wind-down card, turn it on |

Seven is plenty. Play accepts 2 to 8. Put the strongest first: Play shows the
first two or three before anyone scrolls.

## 3. Frame them

1. Upload the screenshots into `store/raw/` in the Codespace (drag them onto
   the Explorer).
2. Edit `store/captions.txt` if you want different wording. One line per
   screenshot, same order as the file names.
3. Run:

        pip install pillow
        python3 scripts/frame_screenshots.py

4. Download everything in `store/screens/` and upload it to Play Console.

## 4. Check before uploading

- No personal information in any screenshot.
- The text on screen matches what the app really does.
- No other company's logos shown large. The apps picker lists names only, which
  is fine.
