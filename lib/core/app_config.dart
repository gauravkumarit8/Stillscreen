/// The app's Google Play ID. It is part of the store link below.
const playPackageId = 'app.stillscreen.focus';

/// Your Google Play link. It is added to the text that goes with a shared
/// streak, and it is where the rating button sends people.
const storeLink =
    'https://play.google.com/store/apps/details?id=$playPackageId';

/// Opens the Play Store app straight on the listing.
const playMarketUri = 'market://details?id=$playPackageId';

/// Where the "Send feedback" button sends email.
const feedbackEmail = 'gaurav954624@gmail.com';

/// Opened from Settings. Keep it identical to the link in Play Console.
const privacyPolicyUrl =
    'https://gauravkumarit8.github.io/stillscreen/privacy-policy.html';

/// The GitHub build number, set when the app is built by CI. It shows in the
/// health check, so a screenshot says exactly which build it came from. A build
/// made by hand reads "local".
const buildNumber = String.fromEnvironment('BUILD_NUMBER', defaultValue: 'local');
