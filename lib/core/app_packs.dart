import 'package:flutter/material.dart';

import 'blocking/blocking_engine.dart';

// Android ApplicationInfo.category values (API 26+).
const _catGame = 0;
const _catVideo = 2;
const _catSocial = 4;

/// A one-tap group of apps. An app belongs to a pack if its package name is
/// in [packages], or Android reports one of [categories] for it. Only apps
/// that are actually installed are ever selected.
class AppPack {
  const AppPack({
    required this.id,
    required this.name,
    required this.icon,
    this.packages = const {},
    this.categories = const {},
  });

  final String id;
  final String name;
  final IconData icon;
  final Set<String> packages;
  final Set<int> categories;

  bool matches(InstalledApp app) =>
      packages.contains(app.package) || categories.contains(app.category);
}

const socialPack = AppPack(
  id: 'social',
  name: 'Social media',
  icon: Icons.groups_outlined,
  categories: {_catSocial},
  packages: {
    'com.instagram.android',
    'com.instagram.lite',
    'com.instagram.barcelona',
    'com.facebook.katana',
    'com.facebook.lite',
    'com.snapchat.android',
    'com.twitter.android',
    'com.zhiliaoapp.musically',
    'com.ss.android.ugc.trill',
    'com.reddit.frontpage',
    'com.pinterest',
    'com.tumblr',
    'in.mohalla.sharechat',
    'in.mohalla.video',
    'xyz.blueskyweb.app',
  },
);

const videoPack = AppPack(
  id: 'video',
  name: 'Video & streaming',
  icon: Icons.play_circle_outline,
  categories: {_catVideo},
  packages: {
    'com.google.android.youtube',
    'com.netflix.mediaclient',
    'com.amazon.avod.thirdpartyclient',
    'in.startv.hotstar',
    'com.disney.disneyplus',
    'com.hulu.plus',
    'tv.twitch.android.app',
    'com.sonyliv',
    'com.graymatrix.did',
    'com.jio.media.ondemand',
    'com.mxtech.videoplayer.ad',
  },
);

const gamesPack = AppPack(
  id: 'games',
  name: 'Games',
  icon: Icons.sports_esports_outlined,
  categories: {_catGame},
);

const messagingPack = AppPack(
  id: 'messaging',
  name: 'Messaging',
  icon: Icons.chat_bubble_outline,
  packages: {
    'com.whatsapp',
    'com.whatsapp.w4b',
    'org.telegram.messenger',
    'com.facebook.orca',
    'com.discord',
    'org.thoughtcrime.securesms',
  },
);

const shoppingPack = AppPack(
  id: 'shopping',
  name: 'Shopping & delivery',
  icon: Icons.shopping_bag_outlined,
  packages: {
    'com.amazon.mShop.android.shopping',
    'com.flipkart.android',
    'com.myntra.android',
    'com.meesho.supply',
    'com.alibaba.aliexpresshd',
    'com.ril.ajio',
    'com.fsn.nykaa',
    'in.swiggy.android',
    'com.application.zomato',
    'com.grofers.customerapp',
    'com.zeptoconsumerapp',
  },
);

const workPack = AppPack(
  id: 'work',
  name: 'Work apps',
  icon: Icons.work_outline,
  packages: {
    'com.Slack',
    'com.microsoft.teams',
    'com.microsoft.office.outlook',
    'com.google.android.gm',
    'us.zoom.videomeetings',
    'com.google.android.apps.dynamite',
    'com.google.android.apps.tachyon',
    'com.linkedin.android',
    'com.atlassian.android.jira.core',
    'com.trello',
    'com.asana.app',
    'notion.id',
  },
);

const focusPacks = [socialPack, videoPack, gamesPack, messagingPack, shoppingPack];
const windDownPacks = [workPack, messagingPack, socialPack];
