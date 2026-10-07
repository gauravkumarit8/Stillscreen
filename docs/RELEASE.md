# Release checklist

## 0. Know the timeline

If your Play developer account is personal and was created after
13 November 2023, you must run a closed test with at least 12 testers opted in
for 14 continuous days before applying for production access. Plan about three
weeks from first upload to launch. Organization accounts are exempt, but need
business verification. Confirm the current rule in Play Console before you
plan around it, because Google has changed it before.

Start the closed test as early as you can. The 14 days only count while the
testers stay opted in, so recruit 15 to 20 people to cover drop-outs.

## 1. Keep secrets out of git

    printf 'android/key.properties\n*.jks\n*.keystore\n' >> .gitignore

## 2. Create an upload key (once)

Run this in the Codespace, then download the file and back it up somewhere
safe outside GitHub. Losing it makes updates painful.

    keytool -genkey -v -keystore ~/stillscreen-upload.jks \
      -keyalg RSA -keysize 2048 -validity 10000 -alias upload

Create `android/key.properties` (not committed):

    storePassword=YOUR_PASSWORD
    keyPassword=YOUR_PASSWORD
    keyAlias=upload
    storeFile=/home/codespace/stillscreen-upload.jks

## 3. Wire up signing

In `android/app/build.gradle.kts`, add at the top:

    import java.util.Properties
    import java.io.FileInputStream

    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

Inside the `android { ... }` block, add before `buildTypes`:

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

and change the release build type to use it:

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

The generated file may differ slightly between Flutter versions. If the
snippet does not fit, paste your file to me.

## 4. Build

Raise `version:` in `pubspec.yaml` (for example `0.1.0+2`) every upload. Then:

    flutter build appbundle --release

Upload `build/app/outputs/bundle/release/app-release.aab`.

## 5. Play Console

- Create the app and fill the store listing from `PLAY_LISTING.md`.
- Privacy policy: host `PRIVACY_POLICY.md` as a public page (GitHub Pages
  works) and paste the link.
- Data safety: the app currently collects no data and makes no network calls.
  Answer accordingly, and revisit the form when you add sync.
- Accessibility declaration: use `ACCESSIBILITY_DECLARATION.md`.
- Target audience: student users may include minors. Pick the age range
  deliberately and read Google's Families policy if you include under 13.
- Content rating questionnaire, then upload to the Closed testing track.

## 6. Before every release

    flutter analyze && flutter test

Install the signed build on a real phone and test blocking, strict mode and
wind-down before sending it to testers.
