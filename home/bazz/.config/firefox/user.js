/****************************************************************************
 * My custom user js                                                       *
 * Based on: https://github.com/yokoffing/Betterfox                        *
* Copy or symlink this file in root of your current firefox profile        *
****************************************************************************/

/** ANNOYANCES ***/
user_pref("identity.fxaccounts.enabled", false); // disable Firefox Sync
user_pref("media.hardware-video-decoding.enabled", false); // disable harware acceleration on video content. Reason: AMD gpu crashes
user_pref("browser.ml.chat.enabled", false); // I don't want AI nonsence to my browser
user_pref("browser.ml.chat.sidebar", false); // I don't want AI nonsence to my sidebar
user_pref("extensions.pocket.enabled", false); // Disable pocket
user_pref("browser.translations.automaticallyPopup", false); // Disable translations popup
user_pref("browser.aboutConfig.showWarning", false); // I want to live dangerously
user_pref("browser.preferences.moreFromMozilla", false); // NO
user_pref("browser.aboutwelcome.enabled", false); // NO
user_pref("browser.privatebrowsing.vpnpromourl", ""); // I won't buy your VPN
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false); // No recommendations
user_pref("browser.download.manager.addToRecentDocs", false); // Put them where they belong
user_pref("browser.tabs.tabmanager.enabled", false); // disable all tabs dropdown menu
user_pref("media.autoplay.default", 5); // Disable media autoplay

/** URL BAR ***/
user_pref("browser.urlbar.unitConversion.enabled", false);
user_pref("browser.urlbar.trending.featureGate", false);
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.quicksuggest.enabled", false);
user_pref("browser.urlbar.groupLabels.enabled", false);
user_pref("browser.formfill.enable", false);

/** NEW TAB PAGE ***/
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.showWeather", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);

/** THEME ADJUSTMENTS ***/
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.compactmode.show", true);
user_pref("browser.privateWindowSeparation.enabled", false); // WINDOWS

/** FULLSCREEN NOTICE ***/
user_pref("full-screen-api.warning.timeout", 0);

/** TELEMETRY ***/
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.server", "data:,");
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.coverage.opt-out", true);
user_pref("toolkit.coverage.opt-out", true);
user_pref("toolkit.coverage.endpoint.base", "");
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);

/** EXPERIMENTS ***/
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");

/** TRACKING PROTECTION ***/
user_pref("browser.contentblocking.category", "strict");
user_pref("urlclassifier.trackingSkipURLs", "*.reddit.com, *.twitter.com, *.twimg.com, *.tiktok.com");
user_pref("urlclassifier.features.socialtracking.skipURLs", "*.instagram.com, *.twitter.com, *.twimg.com");
user_pref("browser.download.start_downloads_in_tmp_dir", true);
user_pref("browser.helperApps.deleteTempFileOnExit", true);
user_pref("browser.uitour.enabled", false);
user_pref("privacy.globalprivacycontrol.enabled", true);

/** FINGER PRINTING PROTECT ***/
user_pref("privacy.fingerprintingProtection", true);
user_pref("privacy.fingerprintingProtection.pbmode", true);
user_pref("privacy.fingerprintingProtection.overrides", "+AllTargets,-CSSPrefersColorScheme");
