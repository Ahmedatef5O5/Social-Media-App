import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App bar title of the Settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Subtitle under the Settings title
  ///
  /// In en, this message translates to:
  /// **'Manage your preferences'**
  String get settingsSubtitle;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsSectionPrivacy;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Artificial Intelligence'**
  String get settingsSectionAi;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSectionSupport;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get settingsEditProfile;

  /// No description provided for @settingsEditProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your info and photo'**
  String get settingsEditProfileSubtitle;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get settingsChangePasswordSubtitle;

  /// No description provided for @settingsEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get settingsEmailAddress;

  /// No description provided for @settingsEmailAddressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage linked email'**
  String get settingsEmailAddressSubtitle;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsPushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable all notifications'**
  String get settingsPushNotificationsSubtitle;

  /// No description provided for @settingsMessagePreviews.
  ///
  /// In en, this message translates to:
  /// **'Message Previews'**
  String get settingsMessagePreviews;

  /// No description provided for @settingsMessagePreviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show content in notifications'**
  String get settingsMessagePreviewsSubtitle;

  /// No description provided for @settingsCallNotifications.
  ///
  /// In en, this message translates to:
  /// **'Call Notifications'**
  String get settingsCallNotifications;

  /// No description provided for @settingsCallNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming call alerts'**
  String get settingsCallNotificationsSubtitle;

  /// No description provided for @settingsReadReceipts.
  ///
  /// In en, this message translates to:
  /// **'Read Receipts'**
  String get settingsReadReceipts;

  /// No description provided for @settingsReadReceiptsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show when you’ve read messages'**
  String get settingsReadReceiptsSubtitle;

  /// No description provided for @settingsOnlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online Status'**
  String get settingsOnlineStatus;

  /// No description provided for @settingsOnlineStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let others see when you’re active'**
  String get settingsOnlineStatusSubtitle;

  /// No description provided for @settingsOnlineStatusVisibility.
  ///
  /// In en, this message translates to:
  /// **'Online Status Visibility'**
  String get settingsOnlineStatusVisibility;

  /// Presence audience option
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get presenceEveryone;

  /// Presence audience option
  ///
  /// In en, this message translates to:
  /// **'My Friends'**
  String get presenceFriends;

  /// Presence audience option
  ///
  /// In en, this message translates to:
  /// **'Specific People'**
  String get presenceSpecific;

  /// Presence audience option
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get presenceNobody;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get settingsAppLock;

  /// No description provided for @settingsAppLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require fingerprint / Face ID to open app'**
  String get settingsAppLockSubtitle;

  /// No description provided for @settingsTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Auth'**
  String get settingsTwoFactor;

  /// No description provided for @settingsTwoFactorOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Extra layer of security'**
  String get settingsTwoFactorOffSubtitle;

  /// No description provided for @settingsTwoFactorOnAuthenticator.
  ///
  /// In en, this message translates to:
  /// **'On • Authenticator app'**
  String get settingsTwoFactorOnAuthenticator;

  /// Two-factor status line with the number of recovery codes left
  ///
  /// In en, this message translates to:
  /// **'On • {count, plural, =1{1 recovery code} other{{count} recovery codes}} remaining'**
  String settingsTwoFactorOnRecoveryCodes(int count);

  /// No description provided for @settingsBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get settingsBlockedUsers;

  /// No description provided for @settingsBlockedUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage blocked accounts'**
  String get settingsBlockedUsersSubtitle;

  /// No description provided for @settingsAiSettings.
  ///
  /// In en, this message translates to:
  /// **'AI Settings'**
  String get settingsAiSettings;

  /// No description provided for @settingsAiSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personalize your AI-powered experience'**
  String get settingsAiSettingsSubtitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personalize your app colors'**
  String get settingsThemeSubtitle;

  /// Settings row label and language sheet title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used across the app'**
  String get languageSheetSubtitle;

  /// No description provided for @settingsAboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get settingsAboutUs;

  /// No description provided for @settingsAboutUsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Our story and mission'**
  String get settingsAboutUsSubtitle;

  /// No description provided for @settingsHelpFaq.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get settingsHelpFaq;

  /// No description provided for @settingsHelpFaqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get answers to common questions'**
  String get settingsHelpFaqSubtitle;

  /// No description provided for @settingsSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get settingsSendFeedback;

  /// No description provided for @settingsSendFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you think'**
  String get settingsSendFeedbackSubtitle;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get settingsPrivacyPolicySubtitle;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsTermsOfServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Platform rules & community guidelines'**
  String get settingsTermsOfServiceSubtitle;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @logOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get logOutSubtitle;

  /// No description provided for @loggedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get loggedOutSuccessfully;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action is permanent and cannot be undone.'**
  String get deleteAccountConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @settingsErrorPrivacyUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update privacy setting.'**
  String get settingsErrorPrivacyUpdate;

  /// No description provided for @settingsErrorVisibilityUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update visibility list.'**
  String get settingsErrorVisibilityUpdate;

  /// No description provided for @settingsErrorIdentityNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Your identity has not been verified; please try again.'**
  String get settingsErrorIdentityNotVerified;

  /// No description provided for @settingsErrorBiometricNoHardware.
  ///
  /// In en, this message translates to:
  /// **'This device doesn’t have a fingerprint or Face ID sensor, so App Lock isn’t available.'**
  String get settingsErrorBiometricNoHardware;

  /// No description provided for @settingsErrorBiometricNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No fingerprint or Face ID is set up on this device yet. Add one in your device settings, then try again.'**
  String get settingsErrorBiometricNotEnrolled;

  /// No description provided for @settingsErrorBiometricLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please wait a moment before trying again.'**
  String get settingsErrorBiometricLockedOut;

  /// No description provided for @settingsErrorBiometricPermanentlyLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is locked. Unlock your device with its PIN, pattern, or password first.'**
  String get settingsErrorBiometricPermanentlyLockedOut;

  /// No description provided for @settingsErrorBiometricPasscodeNotSet.
  ///
  /// In en, this message translates to:
  /// **'Set up a screen lock (PIN, pattern, or password) on your device before enabling App Lock.'**
  String get settingsErrorBiometricPasscodeNotSet;

  /// No description provided for @settingsErrorBiometricUnknown.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t verify your device’s biometric setup. Please try again.'**
  String get settingsErrorBiometricUnknown;

  /// No description provided for @themesTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themesTitle;

  /// No description provided for @themesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a look that feels like you. Changes apply instantly.'**
  String get themesSubtitle;

  /// Name of the "Ocean" color theme
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get themeNameOcean;

  /// Name of the "Sunset" color theme
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get themeNameSunset;

  /// Name of the "Forest" color theme
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get themeNameForest;

  /// Name of the "Midnight" color theme
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get themeNameMidnight;

  /// Name of the "Gold" color theme
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get themeNameGold;

  /// Name of the "Glass" color theme
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get themeNameGlass;

  /// Name of the "Lavender" color theme
  ///
  /// In en, this message translates to:
  /// **'Lavender'**
  String get themeNameLavender;

  /// Name of the "Carbon" color theme
  ///
  /// In en, this message translates to:
  /// **'Carbon'**
  String get themeNameCarbon;

  /// Name of the "Emerald" color theme
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get themeNameEmerald;

  /// Name of the "Nordic" color theme
  ///
  /// In en, this message translates to:
  /// **'Nordic'**
  String get themeNameNordic;

  /// Name of the "Grape" color theme
  ///
  /// In en, this message translates to:
  /// **'Grape'**
  String get themeNameGrape;

  /// Name of the "Sahara" color theme
  ///
  /// In en, this message translates to:
  /// **'Sahara'**
  String get themeNameSahara;

  /// No description provided for @connectivityOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get connectivityOffline;

  /// No description provided for @connectivityRestored.
  ///
  /// In en, this message translates to:
  /// **'Back to internet'**
  String get connectivityRestored;

  /// Foreground-service notification title during a call
  ///
  /// In en, this message translates to:
  /// **'Ongoing Call'**
  String get callOngoingTitle;

  /// Foreground-service notification text during a call
  ///
  /// In en, this message translates to:
  /// **'Tap to return to the call'**
  String get callReturnHint;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @sticker.
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get sticker;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @slideToCancel.
  ///
  /// In en, this message translates to:
  /// **'Slide to cancel'**
  String get slideToCancel;

  /// No description provided for @archivedChats.
  ///
  /// In en, this message translates to:
  /// **'Archived Chats'**
  String get archivedChats;

  /// No description provided for @noArchivedChats.
  ///
  /// In en, this message translates to:
  /// **'No archived chats.'**
  String get noArchivedChats;

  /// No description provided for @messageInfo.
  ///
  /// In en, this message translates to:
  /// **'Message info'**
  String get messageInfo;

  /// No description provided for @voiceNote.
  ///
  /// In en, this message translates to:
  /// **'Voice note'**
  String get voiceNote;

  /// No description provided for @reportMessage.
  ///
  /// In en, this message translates to:
  /// **'Report message'**
  String get reportMessage;

  /// No description provided for @reportSpamAbusiveContent.
  ///
  /// In en, this message translates to:
  /// **'Report spam, abusive content, or inappropriate messages'**
  String get reportSpamAbusiveContent;

  /// No description provided for @growYourNetwork.
  ///
  /// In en, this message translates to:
  /// **'Grow Your Network'**
  String get growYourNetwork;

  /// No description provided for @youHaventAddedAny.
  ///
  /// In en, this message translates to:
  /// **'You haven’t added any connections yet.\nDiscover people nearby or explore suggested profiles to start chatting.'**
  String get youHaventAddedAny;

  /// No description provided for @discoverPeople.
  ///
  /// In en, this message translates to:
  /// **'Discover People'**
  String get discoverPeople;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @searchFriendsGroups.
  ///
  /// In en, this message translates to:
  /// **'Search friends & groups...'**
  String get searchFriendsGroups;

  /// No description provided for @sharedMedia.
  ///
  /// In en, this message translates to:
  /// **'Shared Media'**
  String get sharedMedia;

  /// No description provided for @starredMessages.
  ///
  /// In en, this message translates to:
  /// **'Starred Messages'**
  String get starredMessages;

  /// No description provided for @searchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get searchMessages;

  /// No description provided for @couldntOpenThatFile.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open that file.'**
  String get couldntOpenThatFile;

  /// No description provided for @noLinksSharedYet.
  ///
  /// In en, this message translates to:
  /// **'No links shared yet'**
  String get noLinksSharedYet;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @mediaLinksAndDocs.
  ///
  /// In en, this message translates to:
  /// **'Media, links, and docs'**
  String get mediaLinksAndDocs;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @previewNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Preview not available'**
  String get previewNotAvailable;

  /// No description provided for @couldNotTrimThis.
  ///
  /// In en, this message translates to:
  /// **'Could not trim this video. Please try again.'**
  String get couldNotTrimThis;

  /// No description provided for @trimVideo.
  ///
  /// In en, this message translates to:
  /// **'Trim video'**
  String get trimVideo;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @trimming.
  ///
  /// In en, this message translates to:
  /// **'Trimming…'**
  String get trimming;

  /// No description provided for @couldNotLoadThis.
  ///
  /// In en, this message translates to:
  /// **'Could not load this video.'**
  String get couldNotLoadThis;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @whoCanSeeYour.
  ///
  /// In en, this message translates to:
  /// **'Who can see your online status'**
  String get whoCanSeeYour;

  /// No description provided for @thisControlsYourGreen.
  ///
  /// In en, this message translates to:
  /// **'This controls your green dot and \"last seen\" everywhere in the app.'**
  String get thisControlsYourGreen;

  /// No description provided for @lastSeenRecently.
  ///
  /// In en, this message translates to:
  /// **'Last seen recently'**
  String get lastSeenRecently;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @yourProfileIsStill.
  ///
  /// In en, this message translates to:
  /// **'Your profile is still loading — try again in a second.'**
  String get yourProfileIsStill;

  /// No description provided for @storiesDontSupportDocuments.
  ///
  /// In en, this message translates to:
  /// **'Stories don’t support documents yet.'**
  String get storiesDontSupportDocuments;

  /// No description provided for @aiDoesntSupportVideo.
  ///
  /// In en, this message translates to:
  /// **'AI doesn’t support video yet'**
  String get aiDoesntSupportVideo;

  /// No description provided for @shareToStory.
  ///
  /// In en, this message translates to:
  /// **'Share to Story'**
  String get shareToStory;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @askSyncraAi.
  ///
  /// In en, this message translates to:
  /// **'Ask Syncra AI'**
  String get askSyncraAi;

  /// No description provided for @recentChats.
  ///
  /// In en, this message translates to:
  /// **'Recent Chats'**
  String get recentChats;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @sendTo.
  ///
  /// In en, this message translates to:
  /// **'Send to...'**
  String get sendTo;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @failedToForwardTry.
  ///
  /// In en, this message translates to:
  /// **'Failed to forward. Try again.'**
  String get failedToForwardTry;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @forwardToChat.
  ///
  /// In en, this message translates to:
  /// **'Forward to Chat'**
  String get forwardToChat;

  /// No description provided for @shareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via...'**
  String get shareVia;

  /// No description provided for @pleaseEndYourCurrent.
  ///
  /// In en, this message translates to:
  /// **'Please end your current call before starting another.'**
  String get pleaseEndYourCurrent;

  /// No description provided for @areYouSureYou.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to quit ?'**
  String get areYouSureYou;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to gallery'**
  String get saveToGallery;

  /// No description provided for @whatWeOffer.
  ///
  /// In en, this message translates to:
  /// **'What We Offer'**
  String get whatWeOffer;

  /// No description provided for @builtMaintainedBy.
  ///
  /// In en, this message translates to:
  /// **'Built & Maintained By'**
  String get builtMaintainedBy;

  /// No description provided for @connectWithUs.
  ///
  /// In en, this message translates to:
  /// **'Connect With Us'**
  String get connectWithUs;

  /// No description provided for @connectingPeopleBuildingCommunities.
  ///
  /// In en, this message translates to:
  /// **'Connecting people, building communities'**
  String get connectingPeopleBuildingCommunities;

  /// No description provided for @ourMission.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get ourMission;

  /// No description provided for @weBelieveMeaningfulConnections.
  ///
  /// In en, this message translates to:
  /// **'We believe meaningful connections change lives. Our platform is built to bring people closer — through conversations, shared moments, and real-time experiences that matter.'**
  String get weBelieveMeaningfulConnections;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @version100.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0  •  Made with ❤️'**
  String get version100;

  /// No description provided for @theSmartReplyTo.
  ///
  /// In en, this message translates to:
  /// **'The smart reply to images service is currently busy. Please try again later or write your reply manually.'**
  String get theSmartReplyTo;

  /// No description provided for @anErrorOccurredWith.
  ///
  /// In en, this message translates to:
  /// **'An error occurred with the AI suggestion. Please try again.'**
  String get anErrorOccurredWith;

  /// No description provided for @copiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Copied successfully'**
  String get copiedSuccessfully;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @todaysAiUsage.
  ///
  /// In en, this message translates to:
  /// **'Today’s AI Usage'**
  String get todaysAiUsage;

  /// No description provided for @estimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimated;

  /// No description provided for @failedToDeleteThis.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete this chat. Please try again.'**
  String get failedToDeleteThis;

  /// No description provided for @failedToForwardPlease.
  ///
  /// In en, this message translates to:
  /// **'Failed to forward. Please try again.'**
  String get failedToForwardPlease;

  /// No description provided for @theresNoTextTo.
  ///
  /// In en, this message translates to:
  /// **'There’s no text to share in this selection.'**
  String get theresNoTextTo;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @audioChat.
  ///
  /// In en, this message translates to:
  /// **'Audio Chat'**
  String get audioChat;

  /// No description provided for @chatFiles.
  ///
  /// In en, this message translates to:
  /// **'Chat Files'**
  String get chatFiles;

  /// No description provided for @stillGettingSyncraReady.
  ///
  /// In en, this message translates to:
  /// **'Still getting Syncra ready — try again in a second.'**
  String get stillGettingSyncraReady;

  /// No description provided for @failedToSendYour.
  ///
  /// In en, this message translates to:
  /// **'Failed to send your message. Please try again.'**
  String get failedToSendYour;

  /// No description provided for @couldntLoadThatPhoto.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load that photo. Please try again.'**
  String get couldntLoadThatPhoto;

  /// No description provided for @addACaption.
  ///
  /// In en, this message translates to:
  /// **'Add a caption...'**
  String get addACaption;

  /// No description provided for @howCanIHelp.
  ///
  /// In en, this message translates to:
  /// **'How can I help you?'**
  String get howCanIHelp;

  /// No description provided for @voiceDictationIsntAvailable.
  ///
  /// In en, this message translates to:
  /// **'Voice dictation isn’t available on this device.'**
  String get voiceDictationIsntAvailable;

  /// No description provided for @messageSyncra.
  ///
  /// In en, this message translates to:
  /// **'Message Syncra...'**
  String get messageSyncra;

  /// No description provided for @failedToShareThis.
  ///
  /// In en, this message translates to:
  /// **'Failed to share this chat. Please try again.'**
  String get failedToShareThis;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @chooseAModel.
  ///
  /// In en, this message translates to:
  /// **'Choose a model'**
  String get chooseAModel;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @aLinkWasJust.
  ///
  /// In en, this message translates to:
  /// **'A link was just sent to this address. Please wait.'**
  String get aLinkWasJust;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @enterYourRegisteredEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email address and we will send you a recovery link.'**
  String get enterYourRegisteredEmail;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @ifAnAccountExists.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, we’ve sent you a password reset link.'**
  String get ifAnAccountExists;

  /// No description provided for @returnToLogin.
  ///
  /// In en, this message translates to:
  /// **'Return to Login'**
  String get returnToLogin;

  /// No description provided for @theRecoverySessionIs.
  ///
  /// In en, this message translates to:
  /// **'The recovery session is invalid or has expired. Please request a new link.'**
  String get theRecoverySessionIs;

  /// No description provided for @createNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createNewPassword;

  /// No description provided for @yourNewPasswordMust.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be at least 6 characters long.'**
  String get yourNewPasswordMust;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @reEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reEnterYourPassword;

  /// No description provided for @passwordUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdatedSuccessfully;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter Email'**
  String get enterEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @loginSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Login Successfully'**
  String get loginSuccessfully;

  /// No description provided for @orSignInWith.
  ///
  /// In en, this message translates to:
  /// **'Or Sign in with'**
  String get orSignInWith;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @yourFullName.
  ///
  /// In en, this message translates to:
  /// **'Your Full Name'**
  String get yourFullName;

  /// No description provided for @enterNewEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter New Email'**
  String get enterNewEmail;

  /// No description provided for @typeYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Type your password'**
  String get typeYourPassword;

  /// No description provided for @retypeYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Retype your password'**
  String get retypeYourPassword;

  /// No description provided for @signUpSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Sign up Successfully'**
  String get signUpSuccessfully;

  /// No description provided for @orSignUpWith.
  ///
  /// In en, this message translates to:
  /// **'Or Sign up with'**
  String get orSignUpWith;

  /// No description provided for @facebookLogInIs.
  ///
  /// In en, this message translates to:
  /// **'Facebook log in is in Dev Mode (Test accounts and admin only). Continue?'**
  String get facebookLogInIs;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUser;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @manageTheAccountsYouve.
  ///
  /// In en, this message translates to:
  /// **'Manage the accounts you’ve blocked'**
  String get manageTheAccountsYouve;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @searchPeopleOrGroups.
  ///
  /// In en, this message translates to:
  /// **'Search people or groups...'**
  String get searchPeopleOrGroups;

  /// No description provided for @askTheAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'Ask the AI assistant about this'**
  String get askTheAiAssistant;

  /// No description provided for @editingComment.
  ///
  /// In en, this message translates to:
  /// **'Editing comment'**
  String get editingComment;

  /// No description provided for @voice2.
  ///
  /// In en, this message translates to:
  /// **'🎤 voice'**
  String get voice2;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @recordingVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Recording voice message'**
  String get recordingVoiceMessage;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @deleteThisComment.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment ?'**
  String get deleteThisComment;

  /// No description provided for @commentDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted successfully'**
  String get commentDeletedSuccessfully;

  /// No description provided for @youMentionedYourselfIn.
  ///
  /// In en, this message translates to:
  /// **'You mentioned yourself in this comment'**
  String get youMentionedYourselfIn;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'· Edited'**
  String get edited;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noCommentsYet;

  /// No description provided for @searchPeople.
  ///
  /// In en, this message translates to:
  /// **'Search people...'**
  String get searchPeople;

  /// No description provided for @tryADifferentName.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or username'**
  String get tryADifferentName;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @peopleYouMayKnow.
  ///
  /// In en, this message translates to:
  /// **'People you may know'**
  String get peopleYouMayKnow;

  /// No description provided for @somethingWentWrongPlease.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrongPlease;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @followsYou.
  ///
  /// In en, this message translates to:
  /// **'Follows you'**
  String get followsYou;

  /// No description provided for @couldNotLoadThe.
  ///
  /// In en, this message translates to:
  /// **'Could not load the image.'**
  String get couldNotLoadThe;

  /// No description provided for @responseWithin24Hours.
  ///
  /// In en, this message translates to:
  /// **'Response within 24 hours (max 3 days).'**
  String get responseWithin24Hours;

  /// No description provided for @yourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get yourMessage;

  /// No description provided for @ourTeamHasReviewed.
  ///
  /// In en, this message translates to:
  /// **'Our team has reviewed this feedback. Thank you for helping us improve!'**
  String get ourTeamHasReviewed;

  /// No description provided for @weAreWorkingOn.
  ///
  /// In en, this message translates to:
  /// **'We are working on this. You will be notified when we reply.'**
  String get weAreWorkingOn;

  /// No description provided for @socialMateSupport.
  ///
  /// In en, this message translates to:
  /// **'Social Mate Support'**
  String get socialMateSupport;

  /// No description provided for @official.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get official;

  /// No description provided for @myFeedbacks.
  ///
  /// In en, this message translates to:
  /// **'My Feedbacks'**
  String get myFeedbacks;

  /// No description provided for @trackTheStatusOf.
  ///
  /// In en, this message translates to:
  /// **'Track the status of your submissions'**
  String get trackTheStatusOf;

  /// No description provided for @couldNotLoadYour.
  ///
  /// In en, this message translates to:
  /// **'Could not load your feedbacks'**
  String get couldNotLoadYour;

  /// No description provided for @noFeedbackYet.
  ///
  /// In en, this message translates to:
  /// **'No feedback yet'**
  String get noFeedbackYet;

  /// No description provided for @anythingYouSendUs.
  ///
  /// In en, this message translates to:
  /// **'Anything you send us will show up here with its status.'**
  String get anythingYouSendUs;

  /// No description provided for @replyReceived.
  ///
  /// In en, this message translates to:
  /// **'Reply received'**
  String get replyReceived;

  /// No description provided for @responseWithin24Hours2.
  ///
  /// In en, this message translates to:
  /// **'Response within 24 hours (max 3 days)'**
  String get responseWithin24Hours2;

  /// No description provided for @imageIsTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large (max 10 MB).'**
  String get imageIsTooLarge;

  /// No description provided for @couldNotOpenYour.
  ///
  /// In en, this message translates to:
  /// **'Could not open your gallery.'**
  String get couldNotOpenYour;

  /// No description provided for @editedImageIsToo.
  ///
  /// In en, this message translates to:
  /// **'Edited image is too large (max 10 MB).'**
  String get editedImageIsToo;

  /// No description provided for @feedbackSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Feedback Submitted Successfully'**
  String get feedbackSubmittedSuccessfully;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @ourTeamTypicallyResponds.
  ///
  /// In en, this message translates to:
  /// **'Our team typically responds within 24 hours (up to 3 business days).'**
  String get ourTeamTypicallyResponds;

  /// No description provided for @feedbackSupport.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Support'**
  String get feedbackSupport;

  /// No description provided for @helpUsImproveSocial.
  ///
  /// In en, this message translates to:
  /// **'Help us improve Social Mate'**
  String get helpUsImproveSocial;

  /// No description provided for @emailOrPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number'**
  String get emailOrPhoneNumber;

  /// No description provided for @responseTime.
  ///
  /// In en, this message translates to:
  /// **'Response time'**
  String get responseTime;

  /// No description provided for @myFeedbacks2.
  ///
  /// In en, this message translates to:
  /// **'My feedbacks'**
  String get myFeedbacks2;

  /// No description provided for @attachAScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Attach a screenshot'**
  String get attachAScreenshot;

  /// No description provided for @microphonePermissionIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record.'**
  String get microphonePermissionIsRequired;

  /// No description provided for @couldNotStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording.'**
  String get couldNotStartRecording;

  /// No description provided for @recordingWasTooShort.
  ///
  /// In en, this message translates to:
  /// **'Recording was too short.'**
  String get recordingWasTooShort;

  /// No description provided for @deleteVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Delete voice note'**
  String get deleteVoiceNote;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @noGifsFound.
  ///
  /// In en, this message translates to:
  /// **'No GIFs found'**
  String get noGifsFound;

  /// No description provided for @searchGifs.
  ///
  /// In en, this message translates to:
  /// **'Search GIFs...'**
  String get searchGifs;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @ongoingGroupCall.
  ///
  /// In en, this message translates to:
  /// **'Ongoing Group Call'**
  String get ongoingGroupCall;

  /// No description provided for @theCallCouldNot.
  ///
  /// In en, this message translates to:
  /// **'The call could not be initiated.'**
  String get theCallCouldNot;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @flip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get flip;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Group Members'**
  String get groupMembers;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @inCall.
  ///
  /// In en, this message translates to:
  /// **'In Call'**
  String get inCall;

  /// No description provided for @syncraCantReadMedia.
  ///
  /// In en, this message translates to:
  /// **'Syncra can’t read media messages yet — try a text message.'**
  String get syncraCantReadMedia;

  /// No description provided for @deleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get deleteForMe;

  /// No description provided for @deleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get deleteForEveryone;

  /// No description provided for @failedToAddMembers.
  ///
  /// In en, this message translates to:
  /// **'Failed to add members. Please try again.'**
  String get failedToAddMembers;

  /// No description provided for @addMembers.
  ///
  /// In en, this message translates to:
  /// **'Add Members'**
  String get addMembers;

  /// No description provided for @noNewConnectionsTo.
  ///
  /// In en, this message translates to:
  /// **'No new connections to add'**
  String get noNewConnectionsTo;

  /// No description provided for @noPeopleFound.
  ///
  /// In en, this message translates to:
  /// **'No people found'**
  String get noPeopleFound;

  /// No description provided for @buildYourCommunity.
  ///
  /// In en, this message translates to:
  /// **'Build Your Community'**
  String get buildYourCommunity;

  /// No description provided for @youHaventAddedAny2.
  ///
  /// In en, this message translates to:
  /// **'You haven’t added any connections yet.\nDiscover people nearby or explore suggested profiles to create your first group.'**
  String get youHaventAddedAny2;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get newGroup;

  /// No description provided for @fileSent.
  ///
  /// In en, this message translates to:
  /// **'File sent'**
  String get fileSent;

  /// No description provided for @failedToUpdateGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to update group photo'**
  String get failedToUpdateGroup;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMember;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @failedToLoadMembers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load members'**
  String get failedToLoadMembers;

  /// No description provided for @groupNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group name updated'**
  String get groupNameUpdated;

  /// No description provided for @groupTitleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group title updated'**
  String get groupTitleUpdated;

  /// No description provided for @removeGroupPhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Group Photo'**
  String get removeGroupPhoto;

  /// No description provided for @groupPhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Group photo removed'**
  String get groupPhotoRemoved;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get leaveGroup;

  /// No description provided for @blockGroup.
  ///
  /// In en, this message translates to:
  /// **'Block Group'**
  String get blockGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @groupSettings.
  ///
  /// In en, this message translates to:
  /// **'Group Settings'**
  String get groupSettings;

  /// No description provided for @tapToJoin.
  ///
  /// In en, this message translates to:
  /// **'Tap to Join'**
  String get tapToJoin;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @groupInfo.
  ///
  /// In en, this message translates to:
  /// **'group info'**
  String get groupInfo;

  /// No description provided for @pleaseEndYourCurrent2.
  ///
  /// In en, this message translates to:
  /// **'Please end your current call before joining another call.'**
  String get pleaseEndYourCurrent2;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice call'**
  String get voiceCall;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get videoCall;

  /// No description provided for @youAreNoLonger.
  ///
  /// In en, this message translates to:
  /// **'You are no longer a member of this group'**
  String get youAreNoLonger;

  /// No description provided for @editingMessage.
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get editingMessage;

  /// No description provided for @enterGroupName.
  ///
  /// In en, this message translates to:
  /// **'Enter group name'**
  String get enterGroupName;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @online2.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get online2;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @thisGroupIsNo.
  ///
  /// In en, this message translates to:
  /// **'This group is no longer available'**
  String get thisGroupIsNo;

  /// No description provided for @failedToOpenGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to open group chat'**
  String get failedToOpenGroup;

  /// No description provided for @linkExpiration.
  ///
  /// In en, this message translates to:
  /// **'Link Expiration'**
  String get linkExpiration;

  /// No description provided for @neverExpires.
  ///
  /// In en, this message translates to:
  /// **'Never expires'**
  String get neverExpires;

  /// No description provided for @t24Hours.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get t24Hours;

  /// No description provided for @t2Days.
  ///
  /// In en, this message translates to:
  /// **'2 days'**
  String get t2Days;

  /// No description provided for @t1Week.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get t1Week;

  /// No description provided for @revokeInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Revoke Invite Link'**
  String get revokeInviteLink;

  /// No description provided for @inviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied'**
  String get inviteLinkCopied;

  /// No description provided for @createALinkTo.
  ///
  /// In en, this message translates to:
  /// **'Create a link to let others join this group.'**
  String get createALinkTo;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @revokeLink.
  ///
  /// In en, this message translates to:
  /// **'Revoke Link'**
  String get revokeLink;

  /// No description provided for @inviteLink.
  ///
  /// In en, this message translates to:
  /// **'Invite Link'**
  String get inviteLink;

  /// No description provided for @addACaption2.
  ///
  /// In en, this message translates to:
  /// **'Add a caption…'**
  String get addACaption2;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get noMessagesYet;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @groupName2.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName2;

  /// No description provided for @saveName.
  ///
  /// In en, this message translates to:
  /// **'Save Name'**
  String get saveName;

  /// No description provided for @groupTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Title'**
  String get groupTitle;

  /// No description provided for @addATitleFor.
  ///
  /// In en, this message translates to:
  /// **'Add a title for this group'**
  String get addATitleFor;

  /// No description provided for @saveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Title'**
  String get saveTitle;

  /// No description provided for @groupOwner.
  ///
  /// In en, this message translates to:
  /// **'Group Owner'**
  String get groupOwner;

  /// No description provided for @groupAdmins.
  ///
  /// In en, this message translates to:
  /// **'Group Admins'**
  String get groupAdmins;

  /// No description provided for @removeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove Admin'**
  String get removeAdmin;

  /// No description provided for @removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get removeFromGroup;

  /// No description provided for @youMentionedAllGroup.
  ///
  /// In en, this message translates to:
  /// **'You mentioned all group members'**
  String get youMentionedAllGroup;

  /// No description provided for @youMentionedYourselfIn2.
  ///
  /// In en, this message translates to:
  /// **'You mentioned yourself in this message'**
  String get youMentionedYourselfIn2;

  /// No description provided for @searchPeople2.
  ///
  /// In en, this message translates to:
  /// **'Search people'**
  String get searchPeople2;

  /// No description provided for @edited2.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get edited2;

  /// No description provided for @loadingMorePosts.
  ///
  /// In en, this message translates to:
  /// **'Loading more posts...'**
  String get loadingMorePosts;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get markRead;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @thisPostIsNo.
  ///
  /// In en, this message translates to:
  /// **'This post is no longer available.'**
  String get thisPostIsNo;

  /// No description provided for @uploadCanceled.
  ///
  /// In en, this message translates to:
  /// **'Upload canceled'**
  String get uploadCanceled;

  /// No description provided for @postPublishedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Post Published Successfully'**
  String get postPublishedSuccessfully;

  /// No description provided for @writeSomethingOrAttach.
  ///
  /// In en, this message translates to:
  /// **'Write something or attach a file to share your post.'**
  String get writeSomethingOrAttach;

  /// No description provided for @contentNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Content not available'**
  String get contentNotAvailable;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// No description provided for @savedPosts.
  ///
  /// In en, this message translates to:
  /// **'Saved Posts'**
  String get savedPosts;

  /// No description provided for @thisFeatureIsComing.
  ///
  /// In en, this message translates to:
  /// **'this feature is coming soon'**
  String get thisFeatureIsComing;

  /// No description provided for @noSavedPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No saved posts yet'**
  String get noSavedPostsYet;

  /// No description provided for @tapTheBookmarkIcon.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon on any post to save it here for later.'**
  String get tapTheBookmarkIcon;

  /// No description provided for @backgroundColorIsComing.
  ///
  /// In en, this message translates to:
  /// **'Background Color is coming soon'**
  String get backgroundColorIsComing;

  /// No description provided for @addGifIsComing.
  ///
  /// In en, this message translates to:
  /// **'Add GIF is coming soon'**
  String get addGifIsComing;

  /// No description provided for @liveVideoIsComing.
  ///
  /// In en, this message translates to:
  /// **'Live Video is coming soon'**
  String get liveVideoIsComing;

  /// No description provided for @createAPost.
  ///
  /// In en, this message translates to:
  /// **'Create a Post'**
  String get createAPost;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @whatsOnYourHead.
  ///
  /// In en, this message translates to:
  /// **'What’s on your head?'**
  String get whatsOnYourHead;

  /// No description provided for @pinnedPost.
  ///
  /// In en, this message translates to:
  /// **'Pinned Post'**
  String get pinnedPost;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get reportPost;

  /// No description provided for @postPinnedToYour.
  ///
  /// In en, this message translates to:
  /// **'Post pinned to your profile'**
  String get postPinnedToYour;

  /// No description provided for @postUnpinned.
  ///
  /// In en, this message translates to:
  /// **'Post unpinned'**
  String get postUnpinned;

  /// No description provided for @openOriginalPost.
  ///
  /// In en, this message translates to:
  /// **'Open original post'**
  String get openOriginalPost;

  /// No description provided for @suggestedForYou.
  ///
  /// In en, this message translates to:
  /// **'Suggested for you'**
  String get suggestedForYou;

  /// No description provided for @failedToLoadReactions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reactions.'**
  String get failedToLoadReactions;

  /// No description provided for @noReactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No reactions yet.'**
  String get noReactionsYet;

  /// No description provided for @youMentionedYourselfIn3.
  ///
  /// In en, this message translates to:
  /// **'You mentioned yourself in this post'**
  String get youMentionedYourselfIn3;

  /// No description provided for @videoUnavailableOffline.
  ///
  /// In en, this message translates to:
  /// **'Video unavailable offline'**
  String get videoUnavailableOffline;

  /// No description provided for @videoIsStillProcessing.
  ///
  /// In en, this message translates to:
  /// **'Video is still processing…'**
  String get videoIsStillProcessing;

  /// No description provided for @couldntLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load video'**
  String get couldntLoadVideo;

  /// No description provided for @whatsOnYourMind.
  ///
  /// In en, this message translates to:
  /// **'What’s on your mind?'**
  String get whatsOnYourMind;

  /// No description provided for @noPostsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No posts available.'**
  String get noPostsAvailable;

  /// No description provided for @openPostDetails.
  ///
  /// In en, this message translates to:
  /// **'Open post details'**
  String get openPostDetails;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile Updated Successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @youHaveUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get youHaveUnsavedChanges;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @deletedAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleted Account'**
  String get deletedAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterNewName.
  ///
  /// In en, this message translates to:
  /// **'Enter New Name'**
  String get enterNewName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'UserName'**
  String get username;

  /// No description provided for @enterNewUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter New UserName'**
  String get enterNewUsername;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @enterNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter New Title'**
  String get enterNewTitle;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @enterNewBio.
  ///
  /// In en, this message translates to:
  /// **'Enter New Bio'**
  String get enterNewBio;

  /// No description provided for @socialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMedia;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takeAPhoto;

  /// No description provided for @cropEdit.
  ///
  /// In en, this message translates to:
  /// **'Crop & edit'**
  String get cropEdit;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @stories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get stories;

  /// No description provided for @friendsList.
  ///
  /// In en, this message translates to:
  /// **'Friends List'**
  String get friendsList;

  /// No description provided for @declineRequest.
  ///
  /// In en, this message translates to:
  /// **'Decline request'**
  String get declineRequest;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @reportProfile.
  ///
  /// In en, this message translates to:
  /// **'Report profile'**
  String get reportProfile;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @linkedinProfile.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn Profile'**
  String get linkedinProfile;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @aShortQuoteMood.
  ///
  /// In en, this message translates to:
  /// **'A short quote, mood or emoji statement'**
  String get aShortQuoteMood;

  /// No description provided for @thisAccountHasBeen.
  ///
  /// In en, this message translates to:
  /// **'This account has been deleted'**
  String get thisAccountHasBeen;

  /// No description provided for @reactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get reactions;

  /// No description provided for @tapToRemove.
  ///
  /// In en, this message translates to:
  /// **'Tap to remove'**
  String get tapToRemove;

  /// No description provided for @whatDoYouLike.
  ///
  /// In en, this message translates to:
  /// **'What do you like?'**
  String get whatDoYouLike;

  /// No description provided for @chooseTheTopicsThat.
  ///
  /// In en, this message translates to:
  /// **'Choose the topics that interest you so we can personalize your reels experience.'**
  String get chooseTheTopicsThat;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @shareRemoved.
  ///
  /// In en, this message translates to:
  /// **'Share removed'**
  String get shareRemoved;

  /// No description provided for @reelSharedToYour.
  ///
  /// In en, this message translates to:
  /// **'Reel shared to your feed'**
  String get reelSharedToYour;

  /// No description provided for @couldNotShareThis.
  ///
  /// In en, this message translates to:
  /// **'Could not share this reel. Please try again.'**
  String get couldNotShareThis;

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopiedToClipboard;

  /// No description provided for @couldNotShareThis2.
  ///
  /// In en, this message translates to:
  /// **'Could not share this link. Please try again.'**
  String get couldNotShareThis2;

  /// No description provided for @reshare.
  ///
  /// In en, this message translates to:
  /// **'Reshare'**
  String get reshare;

  /// No description provided for @learnHowToPlay.
  ///
  /// In en, this message translates to:
  /// **'Learn how to play this video'**
  String get learnHowToPlay;

  /// No description provided for @openOnYoutube.
  ///
  /// In en, this message translates to:
  /// **'Open on YouTube'**
  String get openOnYoutube;

  /// No description provided for @reels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get reels;

  /// No description provided for @thanksForReportingOur.
  ///
  /// In en, this message translates to:
  /// **'Thanks for reporting. Our team will review it.'**
  String get thanksForReportingOur;

  /// No description provided for @whyAreYouReporting.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this? Your report is confidential.'**
  String get whyAreYouReporting;

  /// No description provided for @reelsForYou.
  ///
  /// In en, this message translates to:
  /// **'Reels for you'**
  String get reelsForYou;

  /// No description provided for @peopleYouAddAs.
  ///
  /// In en, this message translates to:
  /// **'People you add as friends will show up here.'**
  String get peopleYouAddAs;

  /// No description provided for @searchAccountsPostsReels.
  ///
  /// In en, this message translates to:
  /// **'Search accounts, posts, reels...'**
  String get searchAccountsPostsReels;

  /// No description provided for @featuresLanguageUsage.
  ///
  /// In en, this message translates to:
  /// **'Features, language & usage'**
  String get featuresLanguageUsage;

  /// No description provided for @aiFeatures.
  ///
  /// In en, this message translates to:
  /// **'AI Features'**
  String get aiFeatures;

  /// No description provided for @aiAutoComplete.
  ///
  /// In en, this message translates to:
  /// **'AI Auto Complete'**
  String get aiAutoComplete;

  /// No description provided for @tapTheAiIcon.
  ///
  /// In en, this message translates to:
  /// **'Tap the AI icon to generate captions & replies'**
  String get tapTheAiIcon;

  /// No description provided for @aiAutoDetect.
  ///
  /// In en, this message translates to:
  /// **'AI Auto Detect'**
  String get aiAutoDetect;

  /// No description provided for @automaticSpellingSuggestionsWhile.
  ///
  /// In en, this message translates to:
  /// **'Automatic spelling suggestions while you type'**
  String get automaticSpellingSuggestionsWhile;

  /// No description provided for @aiCommentSuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI Comment Suggestions'**
  String get aiCommentSuggestions;

  /// No description provided for @quickAiSuggestedReplies.
  ///
  /// In en, this message translates to:
  /// **'Quick AI-suggested replies under posts'**
  String get quickAiSuggestedReplies;

  /// No description provided for @autoCompleteLanguage.
  ///
  /// In en, this message translates to:
  /// **'Auto Complete Language'**
  String get autoCompleteLanguage;

  /// No description provided for @replyTone.
  ///
  /// In en, this message translates to:
  /// **'Reply Tone'**
  String get replyTone;

  /// No description provided for @replyLength.
  ///
  /// In en, this message translates to:
  /// **'Reply Length'**
  String get replyLength;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link?'**
  String get sendResetLink;

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendLink;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @updateYourAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your account password securely'**
  String get updateYourAccountPassword;

  /// No description provided for @pleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get pleaseSignInAgain;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @enterYourCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get enterYourCurrentPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @reEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get reEnterNewPassword;

  /// No description provided for @yourEmailAddressWas.
  ///
  /// In en, this message translates to:
  /// **'Your email address was updated'**
  String get yourEmailAddressWas;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerified;

  /// No description provided for @confirmationLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation link sent'**
  String get confirmationLinkSent;

  /// No description provided for @confirmationLinkSentAgain.
  ///
  /// In en, this message translates to:
  /// **'Confirmation link sent again'**
  String get confirmationLinkSentAgain;

  /// No description provided for @emailChangeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Email change cancelled'**
  String get emailChangeCancelled;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get verificationEmailSent;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @cancelEmailChange.
  ///
  /// In en, this message translates to:
  /// **'Cancel email change?'**
  String get cancelEmailChange;

  /// No description provided for @manageAndUpdateYour.
  ///
  /// In en, this message translates to:
  /// **'Manage and update your linked email address'**
  String get manageAndUpdateYour;

  /// No description provided for @setAPasswordFirst.
  ///
  /// In en, this message translates to:
  /// **'Set a password first'**
  String get setAPasswordFirst;

  /// No description provided for @changeEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Change email address'**
  String get changeEmailAddress;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @newEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'New Email Address'**
  String get newEmailAddress;

  /// No description provided for @enterYourNewEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your new email'**
  String get enterYourNewEmail;

  /// No description provided for @whichLanguageShouldAi.
  ///
  /// In en, this message translates to:
  /// **'Which language should AI captions, replies, and corrections use?'**
  String get whichLanguageShouldAi;

  /// No description provided for @howLongShouldAi.
  ///
  /// In en, this message translates to:
  /// **'How long should AI-generated captions and replies be?'**
  String get howLongShouldAi;

  /// No description provided for @whatToneShouldAi.
  ///
  /// In en, this message translates to:
  /// **'What tone should AI-generated captions and replies use?'**
  String get whatToneShouldAi;

  /// No description provided for @theAppIsLocked.
  ///
  /// In en, this message translates to:
  /// **'The app is locked.'**
  String get theAppIsLocked;

  /// No description provided for @useYourFingerprintOr.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint or Face ID to open the app.'**
  String get useYourFingerprintOr;

  /// No description provided for @openTheApp.
  ///
  /// In en, this message translates to:
  /// **'Open the app'**
  String get openTheApp;

  /// No description provided for @searchProfile.
  ///
  /// In en, this message translates to:
  /// **'Search Profile'**
  String get searchProfile;

  /// No description provided for @yourChats.
  ///
  /// In en, this message translates to:
  /// **'Your Chats'**
  String get yourChats;

  /// No description provided for @yourThemes.
  ///
  /// In en, this message translates to:
  /// **'Your Themes'**
  String get yourThemes;

  /// No description provided for @logOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Log out Successfully'**
  String get logOutSuccessfully;

  /// No description provided for @isCallingYou.
  ///
  /// In en, this message translates to:
  /// **'is calling you...'**
  String get isCallingYou;

  /// No description provided for @returnToCall.
  ///
  /// In en, this message translates to:
  /// **'Return to call'**
  String get returnToCall;

  /// No description provided for @sharedGroups.
  ///
  /// In en, this message translates to:
  /// **'Shared Groups'**
  String get sharedGroups;

  /// No description provided for @addAnOptionalCaption.
  ///
  /// In en, this message translates to:
  /// **'Add an optional caption...'**
  String get addAnOptionalCaption;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteMessage;

  /// No description provided for @youCannotSendMessages.
  ///
  /// In en, this message translates to:
  /// **'You cannot send messages to a deleted account.'**
  String get youCannotSendMessages;

  /// No description provided for @t5Sec.
  ///
  /// In en, this message translates to:
  /// **'-5 sec'**
  String get t5Sec;

  /// No description provided for @t5Sec2.
  ///
  /// In en, this message translates to:
  /// **'+5 sec'**
  String get t5Sec2;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @archivedChats2.
  ///
  /// In en, this message translates to:
  /// **'Archived chats'**
  String get archivedChats2;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @repliedToStory.
  ///
  /// In en, this message translates to:
  /// **'Replied to Story'**
  String get repliedToStory;

  /// No description provided for @selectPeople.
  ///
  /// In en, this message translates to:
  /// **'Select People'**
  String get selectPeople;

  /// No description provided for @searchFriends.
  ///
  /// In en, this message translates to:
  /// **'Search friends...'**
  String get searchFriends;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get noFriendsYet;

  /// No description provided for @couldntLoadMoreTap.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load more · Tap to retry'**
  String get couldntLoadMoreTap;

  /// No description provided for @unfriend.
  ///
  /// In en, this message translates to:
  /// **'Unfriend'**
  String get unfriend;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @packName.
  ///
  /// In en, this message translates to:
  /// **'Pack Name'**
  String get packName;

  /// No description provided for @createStickerPack.
  ///
  /// In en, this message translates to:
  /// **'Create Sticker Pack'**
  String get createStickerPack;

  /// No description provided for @noStickersYet.
  ///
  /// In en, this message translates to:
  /// **'No Stickers Yet'**
  String get noStickersYet;

  /// No description provided for @discoverAndDownloadAmazing.
  ///
  /// In en, this message translates to:
  /// **'Discover and download amazing sticker packs from the library to express yourself.'**
  String get discoverAndDownloadAmazing;

  /// No description provided for @exploreLibrary.
  ///
  /// In en, this message translates to:
  /// **'Explore Library'**
  String get exploreLibrary;

  /// No description provided for @stickerLibrary.
  ///
  /// In en, this message translates to:
  /// **'Sticker Library'**
  String get stickerLibrary;

  /// No description provided for @createPack.
  ///
  /// In en, this message translates to:
  /// **'Create Pack'**
  String get createPack;

  /// No description provided for @createYourOwnSticker.
  ///
  /// In en, this message translates to:
  /// **'Create Your Own\nSticker Pack'**
  String get createYourOwnSticker;

  /// No description provided for @privacyAudience.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Audience'**
  String get privacyAudience;

  /// No description provided for @tapToChangeAudience.
  ///
  /// In en, this message translates to:
  /// **'Tap to change audience'**
  String get tapToChangeAudience;

  /// No description provided for @stickers.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get stickers;

  /// No description provided for @nameYourPack.
  ///
  /// In en, this message translates to:
  /// **'Name your pack...'**
  String get nameYourPack;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @noFriendsFound.
  ///
  /// In en, this message translates to:
  /// **'No friends found.'**
  String get noFriendsFound;

  /// No description provided for @browseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Browse Library'**
  String get browseLibrary;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @couldNotLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not load video'**
  String get couldNotLoadVideo;

  /// No description provided for @storyAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Story Added Successfully'**
  String get storyAddedSuccessfully;

  /// No description provided for @thisStoryIsNo.
  ///
  /// In en, this message translates to:
  /// **'This story is no longer available'**
  String get thisStoryIsNo;

  /// No description provided for @replySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent ✓'**
  String get replySent;

  /// No description provided for @youMentionedYourselfIn4.
  ///
  /// In en, this message translates to:
  /// **'You mentioned yourself in this story'**
  String get youMentionedYourselfIn4;

  /// No description provided for @couldNotLoadStories.
  ///
  /// In en, this message translates to:
  /// **'Could not load stories'**
  String get couldNotLoadStories;

  /// No description provided for @noStoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No stories yet'**
  String get noStoriesYet;

  /// No description provided for @createStory.
  ///
  /// In en, this message translates to:
  /// **'Create\nStory'**
  String get createStory;

  /// No description provided for @shareStory.
  ///
  /// In en, this message translates to:
  /// **'Share Story'**
  String get shareStory;

  /// No description provided for @deleteStory.
  ///
  /// In en, this message translates to:
  /// **'Delete Story'**
  String get deleteStory;

  /// No description provided for @reportStory.
  ///
  /// In en, this message translates to:
  /// **'Report Story'**
  String get reportStory;

  /// No description provided for @addToStory.
  ///
  /// In en, this message translates to:
  /// **'Add to Story'**
  String get addToStory;

  /// No description provided for @textStory.
  ///
  /// In en, this message translates to:
  /// **'Text Story'**
  String get textStory;

  /// No description provided for @photoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo from Gallery'**
  String get photoFromGallery;

  /// No description provided for @videoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Video from Gallery'**
  String get videoFromGallery;

  /// No description provided for @max60Seconds.
  ///
  /// In en, this message translates to:
  /// **'Max 60 seconds'**
  String get max60Seconds;

  /// No description provided for @recordAVideo.
  ///
  /// In en, this message translates to:
  /// **'Record a Video'**
  String get recordAVideo;

  /// No description provided for @yourStory.
  ///
  /// In en, this message translates to:
  /// **'Your Story'**
  String get yourStory;

  /// No description provided for @writeYourThoughtWith.
  ///
  /// In en, this message translates to:
  /// **'Write your thought with others'**
  String get writeYourThoughtWith;

  /// No description provided for @couldntLoadViews.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load views.'**
  String get couldntLoadViews;

  /// No description provided for @noViewsYet.
  ///
  /// In en, this message translates to:
  /// **'No views yet'**
  String get noViewsYet;

  /// No description provided for @weCouldntLoadThis.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load this content. Please try again later.'**
  String get weCouldntLoadThis;

  /// No description provided for @searchForAQuestion.
  ///
  /// In en, this message translates to:
  /// **'Search for a question…'**
  String get searchForAQuestion;

  /// No description provided for @tableOfContents.
  ///
  /// In en, this message translates to:
  /// **'Table of Contents'**
  String get tableOfContents;

  /// No description provided for @stillNeedHelpContact.
  ///
  /// In en, this message translates to:
  /// **'Still need help? Contact Support'**
  String get stillNeedHelpContact;

  /// No description provided for @twoFactorWasTurned.
  ///
  /// In en, this message translates to:
  /// **'Two-factor was turned off after you used a recovery code.'**
  String get twoFactorWasTurned;

  /// No description provided for @twoStepVerification.
  ///
  /// In en, this message translates to:
  /// **'Two-step verification'**
  String get twoStepVerification;

  /// No description provided for @pasteCode.
  ///
  /// In en, this message translates to:
  /// **'Paste code'**
  String get pasteCode;

  /// No description provided for @notYouSignOut.
  ///
  /// In en, this message translates to:
  /// **'Not you? Sign out'**
  String get notYouSignOut;

  /// No description provided for @leaveWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get leaveWithoutSaving;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @saveYourRecoveryCodes.
  ///
  /// In en, this message translates to:
  /// **'Save your recovery codes'**
  String get saveYourRecoveryCodes;

  /// No description provided for @codesCopiedClipboardClears.
  ///
  /// In en, this message translates to:
  /// **'Codes copied. Clipboard clears in 60s.'**
  String get codesCopiedClipboardClears;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get copyAll;

  /// No description provided for @saveShare.
  ///
  /// In en, this message translates to:
  /// **'Save / Share'**
  String get saveShare;

  /// No description provided for @iSavedTheseCodes.
  ///
  /// In en, this message translates to:
  /// **'I saved these codes in a safe place'**
  String get iSavedTheseCodes;

  /// No description provided for @twoFactorAuthenticationIs.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication is off'**
  String get twoFactorAuthenticationIs;

  /// No description provided for @turnOffTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Turn off two-factor?'**
  String get turnOffTwoFactor;

  /// No description provided for @currentPassword2.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword2;

  /// No description provided for @protectYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Protect your account'**
  String get protectYourAccount;

  /// No description provided for @noAuthenticatorAppFound.
  ///
  /// In en, this message translates to:
  /// **'No authenticator app found. Copy the secret key instead.'**
  String get noAuthenticatorAppFound;

  /// No description provided for @scanThisQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code'**
  String get scanThisQrCode;

  /// No description provided for @openYourAuthenticatorApp.
  ///
  /// In en, this message translates to:
  /// **'Open your authenticator app, add a new account and scan the code.'**
  String get openYourAuthenticatorApp;

  /// No description provided for @cantScanEnterThis.
  ///
  /// In en, this message translates to:
  /// **'Can’t scan? Enter this key manually'**
  String get cantScanEnterThis;

  /// No description provided for @copySecret.
  ///
  /// In en, this message translates to:
  /// **'Copy secret'**
  String get copySecret;

  /// No description provided for @secretCopiedItWill.
  ///
  /// In en, this message translates to:
  /// **'Secret copied. It will be cleared in 60s.'**
  String get secretCopiedItWill;

  /// No description provided for @openInAuthenticatorApp.
  ///
  /// In en, this message translates to:
  /// **'Open in authenticator app'**
  String get openInAuthenticatorApp;

  /// No description provided for @enterThe6Digit.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterThe6Digit;

  /// No description provided for @backToQrCode.
  ///
  /// In en, this message translates to:
  /// **'Back to QR code'**
  String get backToQrCode;

  /// No description provided for @thisClearsTheChat.
  ///
  /// In en, this message translates to:
  /// **'This clears the chat history on this device only. Other participants keep their own copy.'**
  String get thisClearsTheChat;

  /// No description provided for @openThisFromA.
  ///
  /// In en, this message translates to:
  /// **'Open this from a chat to jump to the message'**
  String get openThisFromA;

  /// No description provided for @failedToDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete message'**
  String get failedToDeleteMessage;

  /// No description provided for @readBy.
  ///
  /// In en, this message translates to:
  /// **'Read by ({length})'**
  String readBy(Object length);

  /// No description provided for @noGroupMembersHave.
  ///
  /// In en, this message translates to:
  /// **'No group members have read this message yet'**
  String get noGroupMembersHave;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @deliveredToGroupMembers.
  ///
  /// In en, this message translates to:
  /// **'Delivered to group members'**
  String get deliveredToGroupMembers;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @sentToServer.
  ///
  /// In en, this message translates to:
  /// **'Sent to server'**
  String get sentToServer;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @aiEngine.
  ///
  /// In en, this message translates to:
  /// **'AI Engine'**
  String get aiEngine;

  /// No description provided for @noResultsFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{searchQuery}\"'**
  String noResultsFoundFor(Object searchQuery);

  /// No description provided for @noStarredMessages.
  ///
  /// In en, this message translates to:
  /// **'No starred messages'**
  String get noStarredMessages;

  /// No description provided for @tapAndHoldOn.
  ///
  /// In en, this message translates to:
  /// **'Tap and hold on any message to star it, so you can find it here later.'**
  String get tapAndHoldOn;

  /// No description provided for @noSharedYet.
  ///
  /// In en, this message translates to:
  /// **'No {tab} shared yet'**
  String noSharedYet(Object tab);

  /// No description provided for @showInChat.
  ///
  /// In en, this message translates to:
  /// **'Show in chat'**
  String get showInChat;

  /// No description provided for @sStory.
  ///
  /// In en, this message translates to:
  /// **'{authorName}’s Story'**
  String sStory(Object authorName);

  /// No description provided for @imageFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image file not found.'**
  String get imageFileNotFound;

  /// No description provided for @couldNotSaveYour.
  ///
  /// In en, this message translates to:
  /// **'Could not save your edit. Please try again.'**
  String get couldNotSaveYour;

  /// No description provided for @videoFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Video file not found.'**
  String get videoFileNotFound;

  /// No description provided for @selected2.
  ///
  /// In en, this message translates to:
  /// **'Selected {selectedMs}'**
  String selected2(Object selectedMs);

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total {totalMs}'**
  String total(Object totalMs);

  /// No description provided for @maxLengthIs.
  ///
  /// In en, this message translates to:
  /// **'Max length is {maxMs}'**
  String maxLengthIs(Object maxMs);

  /// No description provided for @thisCallHasAlready.
  ///
  /// In en, this message translates to:
  /// **'This call has already ended'**
  String get thisCallHasAlready;

  /// No description provided for @failedToOpenStory.
  ///
  /// In en, this message translates to:
  /// **'Failed to open story'**
  String get failedToOpenStory;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {lastSeenStr}'**
  String lastSeen(Object lastSeenStr);

  /// No description provided for @navigationError.
  ///
  /// In en, this message translates to:
  /// **'Navigation Error'**
  String get navigationError;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route: {name}'**
  String route(Object name);

  /// No description provided for @savedToGallerySuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved to gallery successfully! ✅'**
  String get savedToGallerySuccessfully;

  /// No description provided for @pleaseAllowStorageAccess.
  ///
  /// In en, this message translates to:
  /// **'Please allow storage access from settings ⚙️'**
  String get pleaseAllowStorageAccess;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {e} ❌'**
  String failedToSave(Object e);

  /// No description provided for @enableMicrophoneCameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Enable microphone/camera access in Settings to call'**
  String get enableMicrophoneCameraAccess;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission required'**
  String get permissionRequired;

  /// No description provided for @accessIsTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'{what} access is turned off for this app. Enable it in Settings to make or join calls.'**
  String accessIsTurnedOff(Object what);

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @forwardedToChatS.
  ///
  /// In en, this message translates to:
  /// **'Forwarded to {length} chat(s)'**
  String forwardedToChatS(Object length);

  /// No description provided for @isBusyOnAnother.
  ///
  /// In en, this message translates to:
  /// **'{receiverName} is busy on another call'**
  String isBusyOnAnother(Object receiverName);

  /// No description provided for @socialAppAllRights.
  ///
  /// In en, this message translates to:
  /// **'© {year} Social App. All rights reserved.'**
  String socialAppAllRights(Object year);

  /// No description provided for @resetsAt.
  ///
  /// In en, this message translates to:
  /// **'Resets at {resetTimeLabel}'**
  String resetsAt(Object resetTimeLabel);

  /// No description provided for @bonus.
  ///
  /// In en, this message translates to:
  /// **'~{bonus} Bonus'**
  String bonus(Object bonus);

  /// No description provided for @sharingThisWithSyncra.
  ///
  /// In en, this message translates to:
  /// **'Sharing this with Syncra is coming soon.'**
  String get sharingThisWithSyncra;

  /// No description provided for @imageFileNotFound2.
  ///
  /// In en, this message translates to:
  /// **'Image file not found. Please try picking it again.'**
  String get imageFileNotFound2;

  /// No description provided for @fileNotFoundPlease.
  ///
  /// In en, this message translates to:
  /// **'File not found. Please try picking it again.'**
  String get fileNotFoundPlease;

  /// No description provided for @filesLargerThan20mb.
  ///
  /// In en, this message translates to:
  /// **'Files larger than 20MB aren’t supported yet.'**
  String get filesLargerThan20mb;

  /// No description provided for @voiceMessageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Voice message not found. Please try recording again.'**
  String get voiceMessageNotFound;

  /// No description provided for @failedToSendThe.
  ///
  /// In en, this message translates to:
  /// **'Failed to send the voice message. Please try again.'**
  String get failedToSendThe;

  /// No description provided for @failedToSendThe2.
  ///
  /// In en, this message translates to:
  /// **'Failed to send the file. Please try again.'**
  String get failedToSendThe2;

  /// No description provided for @failedToUploadPlease.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload. Please try again.'**
  String get failedToUploadPlease;

  /// No description provided for @failedToSendThe3.
  ///
  /// In en, this message translates to:
  /// **'Failed to send the photo. Please try again.'**
  String get failedToSendThe3;

  /// No description provided for @couldntLoadThatFile.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load that file. Please try again.'**
  String get couldntLoadThatFile;

  /// No description provided for @couldntLoadThisConversation.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load this conversation.\n{message}'**
  String couldntLoadThisConversation(Object message);

  /// No description provided for @deleteThisChat.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat?'**
  String get deleteThisChat;

  /// No description provided for @deleteThisPermanentlyRemoves.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This permanently removes it from Syncra and can’t be undone.'**
  String deleteThisPermanentlyRemoves(Object title);

  /// No description provided for @hi.
  ///
  /// In en, this message translates to:
  /// **'Hi, {userName} !'**
  String hi(Object userName);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @bonus2.
  ///
  /// In en, this message translates to:
  /// **'+~{bonusGranted} Bonus'**
  String bonus2(Object bonusGranted);

  /// No description provided for @usedOfYourDaily.
  ///
  /// In en, this message translates to:
  /// **'{percentLabel} used of your {effectiveUserLimit} daily requests ({usedLabel})'**
  String usedOfYourDaily(
    Object percentLabel,
    Object effectiveUserLimit,
    Object usedLabel,
  );

  /// No description provided for @yourAccountHasBeen.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted successfully.'**
  String get yourAccountHasBeen;

  /// No description provided for @noConnectionCheckYour.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet, then tap the link in the email again.'**
  String get noConnectionCheckYour;

  /// No description provided for @somethingWentWrongPlease2.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please request a new link.'**
  String get somethingWentWrongPlease2;

  /// No description provided for @unblockTheyWillBe.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}? They will be able to message you again.'**
  String unblockTheyWillBe(Object name);

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No Blocked Users'**
  String get noBlockedUsers;

  /// No description provided for @accountsYouBlockWill.
  ///
  /// In en, this message translates to:
  /// **'Accounts you block will show up here so you can manage them anytime.'**
  String get accountsYouBlockWill;

  /// No description provided for @selected3.
  ///
  /// In en, this message translates to:
  /// **'{totalSelected} selected'**
  String selected3(Object totalSelected);

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResultsFound;

  /// No description provided for @nowhereToForwardYet.
  ///
  /// In en, this message translates to:
  /// **'Nowhere to forward yet'**
  String get nowhereToForwardYet;

  /// No description provided for @addFriendsFollowPeople.
  ///
  /// In en, this message translates to:
  /// **'Add friends, follow people, or join a group first.'**
  String get addFriendsFollowPeople;

  /// No description provided for @mentionedYouInThis.
  ///
  /// In en, this message translates to:
  /// **'{authorName} mentioned you in this comment'**
  String mentionedYouInThis(Object authorName);

  /// No description provided for @mutualFriends.
  ///
  /// In en, this message translates to:
  /// **'{mutualFriendsCount} mutual friends'**
  String mutualFriends(Object mutualFriendsCount);

  /// No description provided for @friends2.
  ///
  /// In en, this message translates to:
  /// **'{totalFriendsCount} friends'**
  String friends2(Object totalFriendsCount);

  /// No description provided for @mutualGroups.
  ///
  /// In en, this message translates to:
  /// **'{mutualGroupsCount} mutual groups'**
  String mutualGroups(Object mutualGroupsCount);

  /// No description provided for @mutual.
  ///
  /// In en, this message translates to:
  /// **'{mutualFriendsCount} Mutual'**
  String mutual(Object mutualFriendsCount);

  /// No description provided for @mutual2.
  ///
  /// In en, this message translates to:
  /// **'{totalMutualCount} mutual'**
  String mutual2(Object totalMutualCount);

  /// No description provided for @sent2.
  ///
  /// In en, this message translates to:
  /// **'Sent {createdAt}'**
  String sent2(Object createdAt);

  /// No description provided for @recordAVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Record a voice note (up to {maxSeconds} min)'**
  String recordAVoiceNote(Object maxSeconds);

  /// No description provided for @isCalling.
  ///
  /// In en, this message translates to:
  /// **'{initiatorName} is calling...'**
  String isCalling(Object initiatorName);

  /// No description provided for @isComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} is coming soon'**
  String isComingSoon(Object feature);

  /// No description provided for @selected4.
  ///
  /// In en, this message translates to:
  /// **'{length} selected'**
  String selected4(Object length);

  /// No description provided for @noResultsFoundFor2.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String noResultsFoundFor2(Object query);

  /// No description provided for @membersSelected.
  ///
  /// In en, this message translates to:
  /// **'{length} members selected'**
  String membersSelected(Object length);

  /// No description provided for @removeFromTheGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove {userName} from the group?'**
  String removeFromTheGroup(Object userName);

  /// No description provided for @isNowAnAdmin.
  ///
  /// In en, this message translates to:
  /// **'{userName} is now an admin'**
  String isNowAnAdmin(Object userName);

  /// No description provided for @isNoLongerAn.
  ///
  /// In en, this message translates to:
  /// **'{userName} is no longer an admin'**
  String isNoLongerAn(Object userName);

  /// No description provided for @removedFromTheGroup.
  ///
  /// In en, this message translates to:
  /// **'{userName} removed from the group'**
  String removedFromTheGroup(Object userName);

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make Admin'**
  String get makeAdmin;

  /// No description provided for @joinedViaThisLink.
  ///
  /// In en, this message translates to:
  /// **'{joinCount} joined via this link'**
  String joinedViaThisLink(Object joinCount);

  /// No description provided for @members2.
  ///
  /// In en, this message translates to:
  /// **'{count} Members'**
  String members2(Object count);

  /// No description provided for @mentionedAllGroupMembers.
  ///
  /// In en, this message translates to:
  /// **'{senderName} mentioned all group members'**
  String mentionedAllGroupMembers(Object senderName);

  /// No description provided for @mentionedYouInThis2.
  ///
  /// In en, this message translates to:
  /// **'{senderName} mentioned you in this message'**
  String mentionedYouInThis2(Object senderName);

  /// No description provided for @tapToOpenGroup.
  ///
  /// In en, this message translates to:
  /// **'Tap to open group chat'**
  String get tapToOpenGroup;

  /// No description provided for @selected5.
  ///
  /// In en, this message translates to:
  /// **'{selectedCount} selected'**
  String selected5(Object selectedCount);

  /// No description provided for @selected6.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selected6(Object count);

  /// No description provided for @youreAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You’re all caught up!'**
  String get youreAllCaughtUp;

  /// No description provided for @pinLimitReachedUnpin.
  ///
  /// In en, this message translates to:
  /// **'Pin limit reached. Unpin a post first.'**
  String get pinLimitReachedUnpin;

  /// No description provided for @couldNotUpdateThe.
  ///
  /// In en, this message translates to:
  /// **'Could not update the pin. Please try again.'**
  String get couldNotUpdateThe;

  /// No description provided for @reactions2.
  ///
  /// In en, this message translates to:
  /// **'{length} Reactions'**
  String reactions2(Object length);

  /// No description provided for @mentionedYouInThis3.
  ///
  /// In en, this message translates to:
  /// **'{authorName} mentioned you in this post'**
  String mentionedYouInThis3(Object authorName);

  /// No description provided for @thisAccountHasBeen2.
  ///
  /// In en, this message translates to:
  /// **'This account has been deleted and its profile is no longer available.'**
  String get thisAccountHasBeen2;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open {label} link'**
  String couldNotOpenLink(Object label);

  /// No description provided for @viewProfessionalProfileOn.
  ///
  /// In en, this message translates to:
  /// **'View professional profile on LinkedIn'**
  String get viewProfessionalProfileOn;

  /// No description provided for @yourStatusWillBe.
  ///
  /// In en, this message translates to:
  /// **'Your status will be hidden from your profile until you switch this back on.'**
  String get yourStatusWillBe;

  /// No description provided for @tooManyReportsIn.
  ///
  /// In en, this message translates to:
  /// **'Too many reports in a short time. Please try again later.'**
  String get tooManyReportsIn;

  /// No description provided for @thisContentIsNo.
  ///
  /// In en, this message translates to:
  /// **'This content is no longer available.'**
  String get thisContentIsNo;

  /// No description provided for @youCantReportThis.
  ///
  /// In en, this message translates to:
  /// **'You can’t report this content.'**
  String get youCantReportThis;

  /// No description provided for @report2.
  ///
  /// In en, this message translates to:
  /// **'Report {label}'**
  String report2(Object label);

  /// No description provided for @thisFeatureChecksYour.
  ///
  /// In en, this message translates to:
  /// **'This feature checks your typing continuously, so it may use up your daily AI quota faster.'**
  String get thisFeatureChecksYour;

  /// No description provided for @sendAPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Send a password reset link to {email}?\n\nYou will stay signed in on this device.'**
  String sendAPasswordReset(Object email);

  /// No description provided for @resetLinkSentTo.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to {email}. Check your inbox.'**
  String resetLinkSentTo(Object email);

  /// No description provided for @linkedTo.
  ///
  /// In en, this message translates to:
  /// **'Linked to {oauthLabel}'**
  String linkedTo(Object oauthLabel);

  /// No description provided for @yourAccountIsLinked.
  ///
  /// In en, this message translates to:
  /// **'Your account is linked to {oauthLabel}. You can set a password to enable email login.'**
  String yourAccountIsLinked(Object oauthLabel);

  /// No description provided for @youWillStaySigned.
  ///
  /// In en, this message translates to:
  /// **'You will stay signed in on this device. Any other devices will be signed out.'**
  String get youWillStaySigned;

  /// No description provided for @yourEmailStaysThe.
  ///
  /// In en, this message translates to:
  /// **'Your email stays {currentEmail}. The link sent to {pendingEmail} will no longer work.'**
  String yourEmailStaysThe(Object currentEmail, Object pendingEmail);

  /// No description provided for @forYourSecurityWe.
  ///
  /// In en, this message translates to:
  /// **'For your security, we will ask for your password before changing your email.'**
  String get forYourSecurityWe;

  /// No description provided for @toChangeYourEmail.
  ///
  /// In en, this message translates to:
  /// **'To change your email address you first need a password on this account, so we can confirm it is really you.'**
  String get toChangeYourEmail;

  /// No description provided for @currentEmail.
  ///
  /// In en, this message translates to:
  /// **'CURRENT EMAIL'**
  String get currentEmail;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @unverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get unverified;

  /// No description provided for @verifyThisAddressSo.
  ///
  /// In en, this message translates to:
  /// **'Verify this address so you can recover your account and receive important notices.'**
  String get verifyThisAddressSo;

  /// No description provided for @signInMethod.
  ///
  /// In en, this message translates to:
  /// **'Sign-in method'**
  String get signInMethod;

  /// No description provided for @confirmYourNewEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new email'**
  String get confirmYourNewEmail;

  /// No description provided for @confirmationLinkSentTo.
  ///
  /// In en, this message translates to:
  /// **'Confirmation link sent to {pendingEmail}. Please click the link to confirm your new address. Your current email remains active until confirmed.'**
  String confirmationLinkSentTo(Object pendingEmail);

  /// No description provided for @cannotFindItCheck.
  ///
  /// In en, this message translates to:
  /// **'Cannot find it? Check your spam folder. You may also be asked to approve the change from your current inbox.'**
  String get cannotFindItCheck;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @enterYourPasswordAnd.
  ///
  /// In en, this message translates to:
  /// **'Enter your password and the new address. We’ll email a confirmation link, and your current email stays active until you confirm.'**
  String get enterYourPasswordAnd;

  /// No description provided for @yourProfileWillBe.
  ///
  /// In en, this message translates to:
  /// **'Your profile will be anonymized as \"Deleted Account\" and you will be signed out on all devices. Your posts, comments and messages stay visible to others under that name. This cannot be undone.'**
  String get yourProfileWillBe;

  /// No description provided for @thisAccountHasBeen3.
  ///
  /// In en, this message translates to:
  /// **'This account has been deleted.'**
  String get thisAccountHasBeen3;

  /// No description provided for @noConnectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No Connections Yet'**
  String get noConnectionsYet;

  /// No description provided for @addSomeFriendsOr.
  ///
  /// In en, this message translates to:
  /// **'Add some friends or followers first so you can share private posts with them.'**
  String get addSomeFriendsOr;

  /// No description provided for @noUsersFound2.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get noUsersFound2;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @anyoneOnTheApp.
  ///
  /// In en, this message translates to:
  /// **'Anyone on the app can see this'**
  String get anyoneOnTheApp;

  /// No description provided for @onlyYourFriendsCan.
  ///
  /// In en, this message translates to:
  /// **'Only your friends can see this'**
  String get onlyYourFriendsCan;

  /// No description provided for @specificPeople.
  ///
  /// In en, this message translates to:
  /// **'Specific people'**
  String get specificPeople;

  /// No description provided for @onlySpecificPeopleYou.
  ///
  /// In en, this message translates to:
  /// **'Only specific people you choose'**
  String get onlySpecificPeopleYou;

  /// No description provided for @removeFromYourFriends.
  ///
  /// In en, this message translates to:
  /// **'Remove {friendName} from your friends?'**
  String removeFromYourFriends(Object friendName);

  /// No description provided for @couldNotDeleteThe.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the pack, please try again.'**
  String get couldNotDeleteThe;

  /// No description provided for @couldNotOpenThe.
  ///
  /// In en, this message translates to:
  /// **'Could not open the gallery, please try again.'**
  String get couldNotOpenThe;

  /// No description provided for @thisPackAlreadyHas.
  ///
  /// In en, this message translates to:
  /// **'This pack already has the maximum of {maxStickers} stickers.'**
  String thisPackAlreadyHas(Object maxStickers);

  /// No description provided for @onlyTheFirstImage.
  ///
  /// In en, this message translates to:
  /// **'Only the first {remainingSlots} image(s) were added — a pack can hold at most {maxStickers} stickers.'**
  String onlyTheFirstImage(Object remainingSlots, Object maxStickers);

  /// No description provided for @thisSelectionPushesThe.
  ///
  /// In en, this message translates to:
  /// **'This selection pushes the pack past the 25 MB limit — pick fewer or smaller images.'**
  String get thisSelectionPushesThe;

  /// No description provided for @giveYourPackA.
  ///
  /// In en, this message translates to:
  /// **'Give your pack a name first.'**
  String get giveYourPackA;

  /// No description provided for @addAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Add at least one sticker.'**
  String get addAtLeastOne;

  /// No description provided for @pickAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one friend, or change the privacy setting.'**
  String get pickAtLeastOne;

  /// No description provided for @couldNotVerifyYour.
  ///
  /// In en, this message translates to:
  /// **'Could not verify your pack quota, please try again.'**
  String get couldNotVerifyYour;

  /// No description provided for @uploadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Upload cancelled.'**
  String get uploadCancelled;

  /// No description provided for @couldNotCreateThe.
  ///
  /// In en, this message translates to:
  /// **'Could not create the pack, please try again.'**
  String get couldNotCreateThe;

  /// No description provided for @youAlreadyOwn3.
  ///
  /// In en, this message translates to:
  /// **'You already own 3 sticker packs — the maximum allowed. Remove one below to create a new pack.'**
  String get youAlreadyOwn3;

  /// No description provided for @stickers2.
  ///
  /// In en, this message translates to:
  /// **'{stickerCount} stickers'**
  String stickers2(Object stickerCount);

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading  •  {label}'**
  String uploading(Object label);

  /// No description provided for @packCreated.
  ///
  /// In en, this message translates to:
  /// **'Pack \"{title}\" created!'**
  String packCreated(Object title);

  /// No description provided for @t25Mb.
  ///
  /// In en, this message translates to:
  /// **'{length}/{maxStickers}  •  {sizeMb}/25 MB'**
  String t25Mb(Object length, Object maxStickers, Object sizeMb);

  /// No description provided for @defaultStoryPrivacySet.
  ///
  /// In en, this message translates to:
  /// **'Default story privacy set to {label}'**
  String defaultStoryPrivacySet(Object label);

  /// No description provided for @mentionedYouInThis4.
  ///
  /// In en, this message translates to:
  /// **'{authorName} mentioned you in this story'**
  String mentionedYouInThis4(Object authorName);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(Object message);

  /// No description provided for @failedToSendReply.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reply: {message}'**
  String failedToSendReply(Object message);

  /// No description provided for @replyToSStory.
  ///
  /// In en, this message translates to:
  /// **'Reply to {authorName}’s story…'**
  String replyToSStory(Object authorName);

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'{count} Views'**
  String views(Object count);

  /// No description provided for @couldNotOpenYour2.
  ///
  /// In en, this message translates to:
  /// **'Could not open your email app.'**
  String get couldNotOpenYour2;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(Object query);

  /// No description provided for @tooManyAttemptsTry.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {lockRemaining}.'**
  String tooManyAttemptsTry(Object lockRemaining);

  /// No description provided for @stillNotWorkingMake.
  ///
  /// In en, this message translates to:
  /// **'Still not working? Make sure your phone’s date and time are set to automatic in your device settings.'**
  String get stillNotWorkingMake;

  /// No description provided for @yourRecoveryCodesWill.
  ///
  /// In en, this message translates to:
  /// **'Your recovery codes will not be shown again. Two-factor stays on, and you can generate new codes later from Settings.'**
  String get yourRecoveryCodesWill;

  /// No description provided for @stepOf4.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 4'**
  String stepOf4(Object step);

  /// No description provided for @twoFactorAuthenticationIs2.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication is on'**
  String get twoFactorAuthenticationIs2;

  /// No description provided for @couldNotStartSetup.
  ///
  /// In en, this message translates to:
  /// **'Could not start setup'**
  String get couldNotStartSetup;

  /// No description provided for @twoFactorIsOn.
  ///
  /// In en, this message translates to:
  /// **'Two-factor is on, but codes failed'**
  String get twoFactorIsOn;

  /// No description provided for @yourAccountIsAlready.
  ///
  /// In en, this message translates to:
  /// **'{generated}\n\nYour account is already protected. Retry now, or generate codes later from Settings.'**
  String yourAccountIsAlready(Object generated);

  /// No description provided for @keepTheseCodesIn.
  ///
  /// In en, this message translates to:
  /// **'Keep these codes in a safe place to recover your account if you lose your phone. Each code works once and they will not be shown again.'**
  String get keepTheseCodesIn;

  /// No description provided for @yourAccountWillBe.
  ///
  /// In en, this message translates to:
  /// **'Your account will be protected by your password only. Your recovery codes will be deleted. Confirm it is you to continue.'**
  String get yourAccountWillBe;

  /// No description provided for @evenIfSomeoneLearns.
  ///
  /// In en, this message translates to:
  /// **'Even if someone learns your password, they cannot sign in without a code from your phone.'**
  String get evenIfSomeoneLearns;

  /// No description provided for @typeTheCodeYour.
  ///
  /// In en, this message translates to:
  /// **'Type the code your authenticator app shows for Social Mate to confirm it is linked.'**
  String get typeTheCodeYour;

  /// No description provided for @mutualFriendsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mutual friend} other{{count} mutual friends}}'**
  String mutualFriendsCount(int count);

  /// No description provided for @mutualGroupsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mutual group} other{{count} mutual groups}}'**
  String mutualGroupsCount(int count);

  /// No description provided for @newPostsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 New Post} other{{count} New Posts}}'**
  String newPostsCount(int count);

  /// No description provided for @starsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String starsCount(int count);

  /// No description provided for @forwardNMessages.
  ///
  /// In en, this message translates to:
  /// **'Forward {count, plural, =1{message} other{{count} messages}}'**
  String forwardNMessages(int count);

  /// No description provided for @videoIsSMax.
  ///
  /// In en, this message translates to:
  /// **'Video is {inSeconds}s — max allowed is {inSeconds2}s.'**
  String videoIsSMax(Object inSeconds, Object inSeconds2);

  /// No description provided for @deleteNChats.
  ///
  /// In en, this message translates to:
  /// **'Delete {count, plural, =1{1 chat} other{{count} chats}}?'**
  String deleteNChats(int count);

  /// No description provided for @deleteNMessages.
  ///
  /// In en, this message translates to:
  /// **'Delete {count, plural, =1{1 message} other{{count} messages}}?'**
  String deleteNMessages(int count);

  /// No description provided for @membersCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String membersCountPlural(int count);

  /// No description provided for @onboardingOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Friends & Get Inspiration'**
  String get onboardingOneTitle;

  /// No description provided for @onboardingOneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover creative content, explore new ideas, and connect with a global community that shares your interests.'**
  String get onboardingOneSubtitle;

  /// No description provided for @onboardingTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'Meet Awesome People & Enjoy yourself'**
  String get onboardingTwoTitle;

  /// No description provided for @onboardingTwoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expand your social network, engage in meaningful conversations, and share your favorite moments with others.'**
  String get onboardingTwoSubtitle;

  /// No description provided for @onboardingThreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hangout with Friends'**
  String get onboardingThreeTitle;

  /// No description provided for @onboardingThreeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay close to your loved ones through seamless video, voice, and text chats no matter where you are.'**
  String get onboardingThreeSubtitle;

  /// No description provided for @deletedForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Deleted for everyone'**
  String get deletedForEveryone;

  /// No description provided for @deletedForYou.
  ///
  /// In en, this message translates to:
  /// **'Deleted for you'**
  String get deletedForYou;

  /// No description provided for @photo2.
  ///
  /// In en, this message translates to:
  /// **'📷 Photo'**
  String get photo2;

  /// No description provided for @video2.
  ///
  /// In en, this message translates to:
  /// **'🎥 Video'**
  String get video2;

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'🎤 Voice message'**
  String get voiceMessage;

  /// No description provided for @gif.
  ///
  /// In en, this message translates to:
  /// **'🖼️ GIF'**
  String get gif;

  /// No description provided for @sticker2.
  ///
  /// In en, this message translates to:
  /// **'🏷️ Sticker'**
  String get sticker2;

  /// No description provided for @call2.
  ///
  /// In en, this message translates to:
  /// **'📞 Call'**
  String get call2;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'📎 Attachment'**
  String get attachment;

  /// No description provided for @reactWithTo.
  ///
  /// In en, this message translates to:
  /// **'{actor} react with {emoji} to {snippet}'**
  String reactWithTo(Object actor, Object emoji, Object snippet);

  /// No description provided for @reactWithTo2.
  ///
  /// In en, this message translates to:
  /// **'{actor} react with {emoji} to \"{snippet}\"'**
  String reactWithTo2(Object actor, Object emoji, Object snippet);

  /// No description provided for @seenBy.
  ///
  /// In en, this message translates to:
  /// **'Seen by {receiverName}'**
  String seenBy(Object receiverName);

  /// No description provided for @notReadYet.
  ///
  /// In en, this message translates to:
  /// **'Not read yet'**
  String get notReadYet;

  /// No description provided for @deliveredTo.
  ///
  /// In en, this message translates to:
  /// **'Delivered to {receiverName}'**
  String deliveredTo(Object receiverName);

  /// No description provided for @deliveredToAi.
  ///
  /// In en, this message translates to:
  /// **'Delivered to AI'**
  String get deliveredToAi;

  /// No description provided for @responseCreated.
  ///
  /// In en, this message translates to:
  /// **'Response created'**
  String get responseCreated;

  /// No description provided for @noConversationsYet2.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.'**
  String get noConversationsYet2;

  /// No description provided for @noChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet.'**
  String get noChatsYet;

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No groups yet.'**
  String get noGroupsYet;

  /// No description provided for @noFavoriteChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No favorite chats yet.'**
  String get noFavoriteChatsYet;

  /// No description provided for @noUnreadChats.
  ///
  /// In en, this message translates to:
  /// **'No unread chats.'**
  String get noUnreadChats;

  /// No description provided for @bringYourFriendsTogether.
  ///
  /// In en, this message translates to:
  /// **'Bring your friends together.\nCreate a space to share moments.'**
  String get bringYourFriendsTogether;

  /// No description provided for @yourInboxIsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your inbox is waiting.\nStart a conversation and explore new connections.'**
  String get yourInboxIsWaiting;

  /// No description provided for @startChat.
  ///
  /// In en, this message translates to:
  /// **'Start Chat'**
  String get startChat;

  /// No description provided for @voiceMessages.
  ///
  /// In en, this message translates to:
  /// **'voice messages'**
  String get voiceMessages;

  /// No description provided for @viewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get viewPhoto;

  /// No description provided for @playVideo.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get playVideo;

  /// No description provided for @playVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Play voice message'**
  String get playVoiceMessage;

  /// No description provided for @mixedSelection.
  ///
  /// In en, this message translates to:
  /// **'Mixed selection'**
  String get mixedSelection;

  /// No description provided for @deleteThisMessageFor.
  ///
  /// In en, this message translates to:
  /// **'Delete this message for everyone?'**
  String get deleteThisMessageFor;

  /// No description provided for @deleteThisMessageFor2.
  ///
  /// In en, this message translates to:
  /// **'Delete this message for you?'**
  String get deleteThisMessageFor2;

  /// No description provided for @deleteFromMe.
  ///
  /// In en, this message translates to:
  /// **'Delete from me'**
  String get deleteFromMe;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'{inMinutes} min'**
  String min(Object inMinutes);

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAt(Object time);

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {time}'**
  String yesterdayAt(Object time);

  /// No description provided for @allAllMembers.
  ///
  /// In en, this message translates to:
  /// **'all (@all members)'**
  String get allAllMembers;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more...'**
  String get readMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @youHaveReachedThe.
  ///
  /// In en, this message translates to:
  /// **'You have reached the daily limit for free AI usage. Please try again tomorrow.'**
  String get youHaveReachedThe;

  /// No description provided for @youHaveUsedUp.
  ///
  /// In en, this message translates to:
  /// **'You have used up your daily quota of AI suggestions. It will reset tomorrow.'**
  String get youHaveUsedUp;

  /// No description provided for @spellingCorrection.
  ///
  /// In en, this message translates to:
  /// **'Spelling Correction'**
  String get spellingCorrection;

  /// No description provided for @smartReplyToImages.
  ///
  /// In en, this message translates to:
  /// **'Smart reply to images is currently unavailable'**
  String get smartReplyToImages;

  /// No description provided for @aiSuggestion.
  ///
  /// In en, this message translates to:
  /// **'AI Suggestion'**
  String get aiSuggestion;

  /// No description provided for @chatSummary.
  ///
  /// In en, this message translates to:
  /// **'Chat Summary'**
  String get chatSummary;

  /// No description provided for @detailedSummary.
  ///
  /// In en, this message translates to:
  /// **'Detailed Summary'**
  String get detailedSummary;

  /// No description provided for @whatIsTheTopic.
  ///
  /// In en, this message translates to:
  /// **'What is the topic?'**
  String get whatIsTheTopic;

  /// No description provided for @thereArentEnoughMessages.
  ///
  /// In en, this message translates to:
  /// **'There aren’t enough messages in the chat to summarize.'**
  String get thereArentEnoughMessages;

  /// No description provided for @youHaveUsedUp2.
  ///
  /// In en, this message translates to:
  /// **'You have used up your daily AI quota. Please try again tomorrow.'**
  String get youHaveUsedUp2;

  /// No description provided for @anErrorOccurredPlease.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again later.'**
  String get anErrorOccurredPlease;

  /// No description provided for @usedOfYourDaily2.
  ///
  /// In en, this message translates to:
  /// **'used of your {dailyLimit} daily requests'**
  String usedOfYourDaily2(Object dailyLimit);

  /// No description provided for @forwardedFile.
  ///
  /// In en, this message translates to:
  /// **'Forwarded File'**
  String get forwardedFile;

  /// No description provided for @youveReachedTodaysSyncra.
  ///
  /// In en, this message translates to:
  /// **'You’ve reached today’s Syncra limit — try again tomorrow.'**
  String get youveReachedTodaysSyncra;

  /// No description provided for @syncraIsABit.
  ///
  /// In en, this message translates to:
  /// **'Syncra is a bit busy right now — please try again shortly.'**
  String get syncraIsABit;

  /// No description provided for @syncraCouldntReachAny.
  ///
  /// In en, this message translates to:
  /// **'Syncra couldn’t reach any AI provider — please try again.'**
  String get syncraCouldntReachAny;

  /// No description provided for @voiceMessage2.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get voiceMessage2;

  /// No description provided for @voiceMessage3.
  ///
  /// In en, this message translates to:
  /// **'Voice message · {seconds}'**
  String voiceMessage3(Object seconds);

  /// No description provided for @couldntLoadYourConversations.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your conversations.'**
  String get couldntLoadYourConversations;

  /// No description provided for @noConversationsYetStart.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet — start one above.'**
  String get noConversationsYetStart;

  /// No description provided for @thisLinkWasAlready.
  ///
  /// In en, this message translates to:
  /// **'This link was already used'**
  String get thisLinkWasAlready;

  /// No description provided for @thisLinkIsNo.
  ///
  /// In en, this message translates to:
  /// **'This link is no longer valid'**
  String get thisLinkIsNo;

  /// No description provided for @yourPasswordWasAlready.
  ///
  /// In en, this message translates to:
  /// **'Your password was already updated and you’re signed in.'**
  String get yourPasswordWasAlready;

  /// No description provided for @thisLinkHasExpired.
  ///
  /// In en, this message translates to:
  /// **'This link has expired or has already been used. Please request a new one.'**
  String get thisLinkHasExpired;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @requestNewLink.
  ///
  /// In en, this message translates to:
  /// **'Request new link'**
  String get requestNewLink;

  /// No description provided for @signIn2.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn2;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @resendInS.
  ///
  /// In en, this message translates to:
  /// **'Resend in {secondsRemaining}s'**
  String resendInS(Object secondsRemaining);

  /// No description provided for @sendResetLink2.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink2;

  /// No description provided for @failedToLoadYour.
  ///
  /// In en, this message translates to:
  /// **'Failed to load your chats.'**
  String get failedToLoadYour;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send ({totalSelected})'**
  String send(Object totalSelected);

  /// No description provided for @forwardedFrom.
  ///
  /// In en, this message translates to:
  /// **'Forwarded from '**
  String get forwardedFrom;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to '**
  String get replyingTo;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'{name} and {name2}'**
  String and(Object name, Object name2);

  /// No description provided for @andOthers.
  ///
  /// In en, this message translates to:
  /// **'{name} and {length} others'**
  String andOthers(Object name, Object length);

  /// No description provided for @isWritingAComment.
  ///
  /// In en, this message translates to:
  /// **' is writing a comment...'**
  String get isWritingAComment;

  /// No description provided for @areWritingAComment.
  ///
  /// In en, this message translates to:
  /// **' are writing a comment...'**
  String get areWritingAComment;

  /// No description provided for @microphonePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get microphonePermissionDenied;

  /// No description provided for @couldNotStartRecording2.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording'**
  String get couldNotStartRecording2;

  /// No description provided for @hideReplies.
  ///
  /// In en, this message translates to:
  /// **'Hide replies'**
  String get hideReplies;

  /// No description provided for @stickerReadyToSend.
  ///
  /// In en, this message translates to:
  /// **'Sticker ready to send'**
  String get stickerReadyToSend;

  /// No description provided for @replyTo.
  ///
  /// In en, this message translates to:
  /// **'Reply to @{replyingToAuthorName}...'**
  String replyTo(Object replyingToAuthorName);

  /// No description provided for @writeAComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeAComment;

  /// No description provided for @noSuggestionsRightNow.
  ///
  /// In en, this message translates to:
  /// **'No suggestions right now'**
  String get noSuggestionsRightNow;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback #{shortId}'**
  String feedback(Object shortId);

  /// No description provided for @supportConversation.
  ///
  /// In en, this message translates to:
  /// **'Support conversation'**
  String get supportConversation;

  /// No description provided for @couldNotLoadThis2.
  ///
  /// In en, this message translates to:
  /// **'Could not load this feedback.'**
  String get couldNotLoadThis2;

  /// No description provided for @thisFeedbackIsNo.
  ///
  /// In en, this message translates to:
  /// **'This feedback is no longer available.'**
  String get thisFeedbackIsNo;

  /// No description provided for @pleaseTellUsWhat.
  ///
  /// In en, this message translates to:
  /// **'Please tell us what is on your mind.'**
  String get pleaseTellUsWhat;

  /// No description provided for @pleaseWriteAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Please write at least {minMessageLength} characters.'**
  String pleaseWriteAtLeast(Object minMessageLength);

  /// No description provided for @enterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email or phone number.'**
  String get enterAValidEmail;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating *'**
  String get yourRating;

  /// No description provided for @yourRatingOptional.
  ///
  /// In en, this message translates to:
  /// **'Your rating (optional)'**
  String get yourRatingOptional;

  /// No description provided for @dailyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get dailyLimitReached;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get submitFeedback;

  /// No description provided for @whatWentWrongWhat.
  ///
  /// In en, this message translates to:
  /// **'What went wrong? What did you expect to happen?'**
  String get whatWentWrongWhat;

  /// No description provided for @describeTheFeatureYou.
  ///
  /// In en, this message translates to:
  /// **'Describe the feature you would love to see…'**
  String get describeTheFeatureYou;

  /// No description provided for @whatWouldYouLike.
  ///
  /// In en, this message translates to:
  /// **'What would you like to know?'**
  String get whatWouldYouLike;

  /// No description provided for @shareYourExperienceWith.
  ///
  /// In en, this message translates to:
  /// **'Share your experience with Social Mate…'**
  String get shareYourExperienceWith;

  /// No description provided for @tellUsWhatYou.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you enjoy!'**
  String get tellUsWhatYou;

  /// No description provided for @writeYourMessageHere.
  ///
  /// In en, this message translates to:
  /// **'Write your message here…'**
  String get writeYourMessageHere;

  /// No description provided for @dailyLimitReachedNext.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached · next feedback in {left}'**
  String dailyLimitReachedNext(Object left);

  /// No description provided for @ofFeedbacksLeftToday.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {limit} feedbacks left today'**
  String ofFeedbacksLeftToday(Object remaining, Object limit);

  /// No description provided for @couldNotLoadGifs.
  ///
  /// In en, this message translates to:
  /// **'Could not load GIFs'**
  String get couldNotLoadGifs;

  /// No description provided for @incomingGroupVideo.
  ///
  /// In en, this message translates to:
  /// **'Incoming Group Video'**
  String get incomingGroupVideo;

  /// No description provided for @incomingGroupVoice.
  ///
  /// In en, this message translates to:
  /// **'Incoming Group Voice'**
  String get incomingGroupVoice;

  /// No description provided for @tapToReturnTo.
  ///
  /// In en, this message translates to:
  /// **'Tap to return to the group call'**
  String get tapToReturnTo;

  /// No description provided for @groupVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Group Video Call'**
  String get groupVideoCall;

  /// No description provided for @groupVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Group Voice Call'**
  String get groupVoiceCall;

  /// No description provided for @callingGroupVideo.
  ///
  /// In en, this message translates to:
  /// **'Calling group (Video)...'**
  String get callingGroupVideo;

  /// No description provided for @callingGroupAudio.
  ///
  /// In en, this message translates to:
  /// **'Calling group (Audio)...'**
  String get callingGroupAudio;

  /// No description provided for @inTheCall.
  ///
  /// In en, this message translates to:
  /// **'In the call'**
  String get inTheCall;

  /// No description provided for @notInTheCall.
  ///
  /// In en, this message translates to:
  /// **'Not in the call'**
  String get notInTheCall;

  /// No description provided for @ringing.
  ///
  /// In en, this message translates to:
  /// **'Ringing…'**
  String get ringing;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'{actor} added {target}'**
  String added(Object actor, Object target);

  /// No description provided for @removed.
  ///
  /// In en, this message translates to:
  /// **'{actor} removed {target}'**
  String removed(Object actor, Object target);

  /// No description provided for @leftTheGroup.
  ///
  /// In en, this message translates to:
  /// **'{actor} left the group'**
  String leftTheGroup(Object actor);

  /// No description provided for @noMessagesYet2.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet2;

  /// No description provided for @photo3.
  ///
  /// In en, this message translates to:
  /// **'{senderName}: 📷 Photo'**
  String photo3(Object senderName);

  /// No description provided for @video3.
  ///
  /// In en, this message translates to:
  /// **'{senderName}: 🎬 Video'**
  String video3(Object senderName);

  /// No description provided for @gif2.
  ///
  /// In en, this message translates to:
  /// **'{senderName}: 🎞️ GIF'**
  String gif2(Object senderName);

  /// No description provided for @sticker3.
  ///
  /// In en, this message translates to:
  /// **'{senderName}: 😊 Sticker'**
  String sticker3(Object senderName);

  /// No description provided for @voiceMessage4.
  ///
  /// In en, this message translates to:
  /// **'{senderName}: 🎤 Voice message'**
  String voiceMessage4(Object senderName);

  /// No description provided for @groupCall.
  ///
  /// In en, this message translates to:
  /// **'{senderName}: 📞 Group Call'**
  String groupCall(Object senderName);

  /// No description provided for @addedOnePersonIsnt.
  ///
  /// In en, this message translates to:
  /// **'Added {length}. One person isn’t available to join right now.'**
  String addedOnePersonIsnt(Object length);

  /// No description provided for @addedPeopleArentAvailable.
  ///
  /// In en, this message translates to:
  /// **'Added {length}. {length2} people aren’t available to join right now.'**
  String addedPeopleArentAvailable(Object length, Object length2);

  /// No description provided for @thisPersonIsntAvailable.
  ///
  /// In en, this message translates to:
  /// **'This person isn’t available to join the group right now.'**
  String get thisPersonIsntAvailable;

  /// No description provided for @thesePeopleArentAvailable.
  ///
  /// In en, this message translates to:
  /// **'These people aren’t available to join the group right now.'**
  String get thesePeopleArentAvailable;

  /// No description provided for @addMembers2.
  ///
  /// In en, this message translates to:
  /// **'Add {length} Members'**
  String addMembers2(Object length);

  /// No description provided for @createGroup2.
  ///
  /// In en, this message translates to:
  /// **'Create Group ({length})'**
  String createGroup2(Object length);

  /// No description provided for @youWillLeaveThe.
  ///
  /// In en, this message translates to:
  /// **'You will leave \"{name}\", the chat history on this device will be cleared, and you won’t be able to be re-added to this group. Continue?'**
  String youWillLeaveThe(Object name);

  /// No description provided for @theChatHistoryOn.
  ///
  /// In en, this message translates to:
  /// **'The chat history on this device will be cleared, and you won’t be able to be re-added to this group. Continue?'**
  String get theChatHistoryOn;

  /// No description provided for @missedVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Missed voice call'**
  String get missedVoiceCall;

  /// No description provided for @missedVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Missed video call'**
  String get missedVideoCall;

  /// No description provided for @endedCall.
  ///
  /// In en, this message translates to:
  /// **'Ended call'**
  String get endedCall;

  /// No description provided for @groupVoiceCall2.
  ///
  /// In en, this message translates to:
  /// **'Group voice call'**
  String get groupVoiceCall2;

  /// No description provided for @groupVideoCall2.
  ///
  /// In en, this message translates to:
  /// **'Group video call'**
  String get groupVideoCall2;

  /// No description provided for @missedCall.
  ///
  /// In en, this message translates to:
  /// **'Missed Call'**
  String get missedCall;

  /// No description provided for @ongoingTapToJoin.
  ///
  /// In en, this message translates to:
  /// **'Ongoing • Tap to Join'**
  String get ongoingTapToJoin;

  /// No description provided for @ended.
  ///
  /// In en, this message translates to:
  /// **'Ended • {duration}'**
  String ended(Object duration);

  /// No description provided for @thisInviteLinkIs.
  ///
  /// In en, this message translates to:
  /// **'This invite link is no longer valid'**
  String get thisInviteLinkIs;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get openChat;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroup;

  /// No description provided for @joinOnSocialMedia.
  ///
  /// In en, this message translates to:
  /// **'Join \"{groupName}\" on Social Media App: {hash}'**
  String joinOnSocialMedia(Object groupName, Object hash);

  /// No description provided for @expiresInDH.
  ///
  /// In en, this message translates to:
  /// **'Expires in {inDays}d {remainder}h'**
  String expiresInDH(Object inDays, Object remainder);

  /// No description provided for @expiresInHM.
  ///
  /// In en, this message translates to:
  /// **'Expires in {inHours}h {remainder}m'**
  String expiresInHM(Object inHours, Object remainder);

  /// No description provided for @expiresInM.
  ///
  /// In en, this message translates to:
  /// **'Expires in {inMinutes}m'**
  String expiresInM(Object inMinutes);

  /// No description provided for @recordingAudio.
  ///
  /// In en, this message translates to:
  /// **'{userName} recording audio...'**
  String recordingAudio(Object userName);

  /// No description provided for @peopleRecordingAudio.
  ///
  /// In en, this message translates to:
  /// **'{length} people recording audio...'**
  String peopleRecordingAudio(Object length);

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No {name} notifications'**
  String noNotifications(Object name);

  /// No description provided for @followBack.
  ///
  /// In en, this message translates to:
  /// **'Follow Back'**
  String get followBack;

  /// No description provided for @sharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Shared successfully'**
  String get sharedSuccessfully;

  /// No description provided for @postRemovedFromSaves.
  ///
  /// In en, this message translates to:
  /// **'Post removed from saves'**
  String get postRemovedFromSaves;

  /// No description provided for @postSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Post saved successfully'**
  String get postSavedSuccessfully;

  /// No description provided for @publishingPost.
  ///
  /// In en, this message translates to:
  /// **'Publishing Post...'**
  String get publishingPost;

  /// No description provided for @unpinPost.
  ///
  /// In en, this message translates to:
  /// **'Unpin Post'**
  String get unpinPost;

  /// No description provided for @pinPost.
  ///
  /// In en, this message translates to:
  /// **'Pin Post'**
  String get pinPost;

  /// No description provided for @removeShare.
  ///
  /// In en, this message translates to:
  /// **'Remove Share'**
  String get removeShare;

  /// No description provided for @removeThisShareFrom.
  ///
  /// In en, this message translates to:
  /// **'Remove this share from your profile?'**
  String get removeThisShareFrom;

  /// No description provided for @areYouSureYou2.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get areYouSureYou2;

  /// No description provided for @postDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Post deleted successfully'**
  String get postDeletedSuccessfully;

  /// No description provided for @reshareRemoved.
  ///
  /// In en, this message translates to:
  /// **'Reshare removed'**
  String get reshareRemoved;

  /// No description provided for @resharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Reshared successfully'**
  String get resharedSuccessfully;

  /// No description provided for @aReel.
  ///
  /// In en, this message translates to:
  /// **'a reel'**
  String get aReel;

  /// No description provided for @aPost.
  ///
  /// In en, this message translates to:
  /// **'a post'**
  String get aPost;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @shared.
  ///
  /// In en, this message translates to:
  /// **'  shared {contentLabel}'**
  String shared(Object contentLabel);

  /// No description provided for @editProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile Picture'**
  String get editProfilePicture;

  /// No description provided for @editCoverPhoto.
  ///
  /// In en, this message translates to:
  /// **'Edit Cover Photo'**
  String get editCoverPhoto;

  /// No description provided for @optionalShownAsRich.
  ///
  /// In en, this message translates to:
  /// **'Optional — shown as rich cards on your profile.'**
  String get optionalShownAsRich;

  /// No description provided for @noProvidedYet.
  ///
  /// In en, this message translates to:
  /// **'No {title} provided yet.'**
  String noProvidedYet(Object title);

  /// No description provided for @isFriendsWithBoth.
  ///
  /// In en, this message translates to:
  /// **'{names} is friends with both of you'**
  String isFriendsWithBoth(Object names);

  /// No description provided for @andAreFriendsWith.
  ///
  /// In en, this message translates to:
  /// **'{names} and {second} are friends with both of you'**
  String andAreFriendsWith(Object names, Object second);

  /// No description provided for @andOthersAreFriends.
  ///
  /// In en, this message translates to:
  /// **'{names} and {others} others are friends with both of you'**
  String andOthersAreFriends(Object names, Object others);

  /// No description provided for @noPostsToShow.
  ///
  /// In en, this message translates to:
  /// **'No posts to show yet'**
  String get noPostsToShow;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// No description provided for @shareYourThoughtsWith.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts with your friends.'**
  String get shareYourThoughtsWith;

  /// No description provided for @thisPersonHasntShared.
  ///
  /// In en, this message translates to:
  /// **'This person hasn’t shared anything yet.'**
  String get thisPersonHasntShared;

  /// No description provided for @addAStatus.
  ///
  /// In en, this message translates to:
  /// **'Add a status ✨'**
  String get addAStatus;

  /// No description provided for @showOnProfile.
  ///
  /// In en, this message translates to:
  /// **'Show on profile'**
  String get showOnProfile;

  /// No description provided for @hideFromProfile.
  ///
  /// In en, this message translates to:
  /// **'Hide from profile'**
  String get hideFromProfile;

  /// No description provided for @doneSelected.
  ///
  /// In en, this message translates to:
  /// **'Done ({length} selected)'**
  String doneSelected(Object length);

  /// No description provided for @tellUsWhatIs.
  ///
  /// In en, this message translates to:
  /// **'Tell us what is wrong (required)'**
  String get tellUsWhatIs;

  /// No description provided for @addDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Add details (optional)'**
  String get addDetailsOptional;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @noAccountsToDiscover.
  ///
  /// In en, this message translates to:
  /// **'No accounts to discover yet'**
  String get noAccountsToDiscover;

  /// No description provided for @noAccountsFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No accounts found for \"{query}\"'**
  String noAccountsFoundFor(Object query);

  /// No description provided for @nothingToShowYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get nothingToShowYet;

  /// No description provided for @noFriendsFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No friends found for \"{query}\"'**
  String noFriendsFoundFor(Object query);

  /// No description provided for @youHaventJoinedAny.
  ///
  /// In en, this message translates to:
  /// **'You haven’t joined any groups yet'**
  String get youHaventJoinedAny;

  /// No description provided for @searchForGroups.
  ///
  /// In en, this message translates to:
  /// **'Search for groups'**
  String get searchForGroups;

  /// No description provided for @noGroupsFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No groups found for \"{query}\"'**
  String noGroupsFoundFor(Object query);

  /// No description provided for @noReelsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No reels available'**
  String get noReelsAvailable;

  /// No description provided for @noReelsFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No reels found for \"{query}\"'**
  String noReelsFoundFor(Object query);

  /// No description provided for @currentPasswordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordIsRequired;

  /// No description provided for @resetLinkSentResend.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent · resend in {secs}s'**
  String resetLinkSentResend(Object secs);

  /// No description provided for @forgotYourCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your current password?'**
  String get forgotYourCurrentPassword;

  /// No description provided for @newPasswordMustBe.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current password'**
  String get newPasswordMustBe;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get setPassword;

  /// No description provided for @noEmailOnFile.
  ///
  /// In en, this message translates to:
  /// **'No email on file'**
  String get noEmailOnFile;

  /// No description provided for @isAlsoLinkedTo.
  ///
  /// In en, this message translates to:
  /// **'{oauthLabel} is also linked to this account. Changing your email here does not change your {oauthLabel2} account.'**
  String isAlsoLinkedTo(Object oauthLabel, Object oauthLabel2);

  /// No description provided for @yourPrimarySignIn.
  ///
  /// In en, this message translates to:
  /// **'Your primary sign-in is managed by {oauthLabel}. Your email is tied to that provider.'**
  String yourPrimarySignIn(Object oauthLabel);

  /// No description provided for @resendInS2.
  ///
  /// In en, this message translates to:
  /// **'Resend in {secs}s'**
  String resendInS2(Object secs);

  /// No description provided for @resendVerification.
  ///
  /// In en, this message translates to:
  /// **'Resend Verification'**
  String get resendVerification;

  /// No description provided for @resendLink.
  ///
  /// In en, this message translates to:
  /// **'Resend Link'**
  String get resendLink;

  /// No description provided for @passwordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordIsRequired;

  /// No description provided for @newEmailMustBe.
  ///
  /// In en, this message translates to:
  /// **'New email must be different from your current email'**
  String get newEmailMustBe;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @oneLastConfirmation.
  ///
  /// In en, this message translates to:
  /// **'One last confirmation'**
  String get oneLastConfirmation;

  /// No description provided for @typeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type {confirmationWord} to confirm'**
  String typeToConfirm(Object confirmationWord);

  /// No description provided for @videoCall2.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get videoCall2;

  /// No description provided for @voiceCall2.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get voiceCall2;

  /// No description provided for @callingVideo.
  ///
  /// In en, this message translates to:
  /// **'Calling (Video)...'**
  String get callingVideo;

  /// No description provided for @callingAudio.
  ///
  /// In en, this message translates to:
  /// **'Calling (Audio)...'**
  String get callingAudio;

  /// No description provided for @incomingVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming Video Call'**
  String get incomingVideoCall;

  /// No description provided for @incomingVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming Voice Call'**
  String get incomingVoiceCall;

  /// No description provided for @youCantMessageUntil.
  ///
  /// In en, this message translates to:
  /// **'You can’t message {name} until you unblock them.'**
  String youCantMessageUntil(Object name);

  /// No description provided for @youCantReplyTo.
  ///
  /// In en, this message translates to:
  /// **'You can’t reply to this conversation.'**
  String get youCantReplyTo;

  /// No description provided for @youBlocked.
  ///
  /// In en, this message translates to:
  /// **'You blocked {otherUserName}'**
  String youBlocked(Object otherUserName);

  /// No description provided for @blockedYou.
  ///
  /// In en, this message translates to:
  /// **'{otherUserName} blocked you'**
  String blockedYou(Object otherUserName);

  /// No description provided for @youUnblocked.
  ///
  /// In en, this message translates to:
  /// **'You unblocked {otherUserName}'**
  String youUnblocked(Object otherUserName);

  /// No description provided for @unblockedYou.
  ///
  /// In en, this message translates to:
  /// **'{otherUserName} unblocked you'**
  String unblockedYou(Object otherUserName);

  /// No description provided for @sentYouAMessage.
  ///
  /// In en, this message translates to:
  /// **'{receiverUser} sent you a message request. Reply to accept, or decline.'**
  String sentYouAMessage(Object receiverUser);

  /// No description provided for @youAreNotFriends.
  ///
  /// In en, this message translates to:
  /// **'You are not friends or followers. Sending a message will send a message request.'**
  String get youAreNotFriends;

  /// No description provided for @recordingAudio2.
  ///
  /// In en, this message translates to:
  /// **'recording audio...'**
  String get recordingAudio2;

  /// No description provided for @unblock2.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}'**
  String unblock2(Object name);

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block {name}'**
  String block(Object name);

  /// No description provided for @calling.
  ///
  /// In en, this message translates to:
  /// **'Calling…'**
  String get calling;

  /// No description provided for @videoCalling.
  ///
  /// In en, this message translates to:
  /// **'Video calling…'**
  String get videoCalling;

  /// No description provided for @youBlocked2.
  ///
  /// In en, this message translates to:
  /// **'You blocked {name}'**
  String youBlocked2(Object name);

  /// No description provided for @blockedYou2.
  ///
  /// In en, this message translates to:
  /// **'{name} blocked you'**
  String blockedYou2(Object name);

  /// No description provided for @youUnblocked2.
  ///
  /// In en, this message translates to:
  /// **'You unblocked {name}'**
  String youUnblocked2(Object name);

  /// No description provided for @unblockedYou2.
  ///
  /// In en, this message translates to:
  /// **'{name} unblocked you'**
  String unblockedYou2(Object name);

  /// No description provided for @textStatus.
  ///
  /// In en, this message translates to:
  /// **'Text status'**
  String get textStatus;

  /// No description provided for @failedToLoadYour2.
  ///
  /// In en, this message translates to:
  /// **'Failed to load your connections.'**
  String get failedToLoadYour2;

  /// No description provided for @done2.
  ///
  /// In en, this message translates to:
  /// **'Done ({length})'**
  String done2(Object length);

  /// No description provided for @whoCanSeeThis.
  ///
  /// In en, this message translates to:
  /// **'Who can see this pack?'**
  String get whoCanSeeThis;

  /// No description provided for @whoCanSeeThis2.
  ///
  /// In en, this message translates to:
  /// **'Who can see this?'**
  String get whoCanSeeThis2;

  /// No description provided for @chooseYourAudienceFor.
  ///
  /// In en, this message translates to:
  /// **'Choose your audience for this sticker pack'**
  String get chooseYourAudienceFor;

  /// No description provided for @chooseYourAudienceFor2.
  ///
  /// In en, this message translates to:
  /// **'Choose your audience for this story'**
  String get chooseYourAudienceFor2;

  /// No description provided for @chooseYourAudienceFor3.
  ///
  /// In en, this message translates to:
  /// **'Choose your audience for this post'**
  String get chooseYourAudienceFor3;

  /// No description provided for @stickers3.
  ///
  /// In en, this message translates to:
  /// **'{stickerCount} Stickers  •  {asReadableSize}'**
  String stickers3(Object stickerCount, Object asReadableSize);

  /// No description provided for @stickers4.
  ///
  /// In en, this message translates to:
  /// **'{stickerCount} Stickers'**
  String stickers4(Object stickerCount);

  /// No description provided for @mbStickers.
  ///
  /// In en, this message translates to:
  /// **'{toStringAsFixed}/{toStringAsFixed2} MB  •  {stickerCount} Stickers'**
  String mbStickers(
    Object toStringAsFixed,
    Object toStringAsFixed2,
    Object stickerCount,
  );

  /// No description provided for @noFriendsSelected.
  ///
  /// In en, this message translates to:
  /// **'No friends selected'**
  String get noFriendsSelected;

  /// No description provided for @friendSSelected.
  ///
  /// In en, this message translates to:
  /// **'{length} friend(s) selected'**
  String friendSSelected(Object length);

  /// No description provided for @stickers5.
  ///
  /// In en, this message translates to:
  /// **'{stickerCount} stickers  •  {asReadableSize}'**
  String stickers5(Object stickerCount, Object asReadableSize);

  /// No description provided for @videoPreview.
  ///
  /// In en, this message translates to:
  /// **'Video Preview'**
  String get videoPreview;

  /// No description provided for @photoPreview.
  ///
  /// In en, this message translates to:
  /// **'Photo Preview'**
  String get photoPreview;

  /// No description provided for @myStories.
  ///
  /// In en, this message translates to:
  /// **'My Stories'**
  String get myStories;

  /// No description provided for @sStories.
  ///
  /// In en, this message translates to:
  /// **'{authorName}’s Stories'**
  String sStories(Object authorName);

  /// No description provided for @textStory2.
  ///
  /// In en, this message translates to:
  /// **'Text story'**
  String get textStory2;

  /// No description provided for @videoStory.
  ///
  /// In en, this message translates to:
  /// **'Video story'**
  String get videoStory;

  /// No description provided for @photoStory.
  ///
  /// In en, this message translates to:
  /// **'Photo story'**
  String get photoStory;

  /// No description provided for @deleteStories.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} stories?'**
  String deleteStories(Object count);

  /// No description provided for @deleteThisStory.
  ///
  /// In en, this message translates to:
  /// **'Delete this story?'**
  String get deleteThisStory;

  /// No description provided for @gifAnimation.
  ///
  /// In en, this message translates to:
  /// **'GIF Animation'**
  String get gifAnimation;

  /// No description provided for @enterThe6Digit2.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app.'**
  String get enterThe6Digit2;

  /// No description provided for @enterOneOfThe.
  ///
  /// In en, this message translates to:
  /// **'Enter one of the recovery codes you saved. Using it turns two-factor off.'**
  String get enterOneOfThe;

  /// No description provided for @useABackupCode.
  ///
  /// In en, this message translates to:
  /// **'Use a backup code'**
  String get useABackupCode;

  /// No description provided for @useAuthenticatorCode.
  ///
  /// In en, this message translates to:
  /// **'Use authenticator code'**
  String get useAuthenticatorCode;

  /// No description provided for @preparingYourSecureKey.
  ///
  /// In en, this message translates to:
  /// **'Preparing your secure key...'**
  String get preparingYourSecureKey;

  /// No description provided for @generatingRecoveryCodes.
  ///
  /// In en, this message translates to:
  /// **'Generating recovery codes...'**
  String get generatingRecoveryCodes;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get pleaseTryAgain;

  /// No description provided for @recoveryCodesCouldNot.
  ///
  /// In en, this message translates to:
  /// **'Recovery codes could not be generated.'**
  String get recoveryCodesCouldNot;

  /// No description provided for @codeAboutToChange.
  ///
  /// In en, this message translates to:
  /// **'Code about to change, wait for next'**
  String get codeAboutToChange;

  /// No description provided for @codeUpdatesInS.
  ///
  /// In en, this message translates to:
  /// **'Code updates in {remaining}s'**
  String codeUpdatesInS(Object remaining);

  /// No description provided for @useAnAuthenticatorCode.
  ///
  /// In en, this message translates to:
  /// **'Use an authenticator code instead'**
  String get useAnAuthenticatorCode;

  /// No description provided for @useMyPasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Use my password instead'**
  String get useMyPasswordInstead;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparing;

  /// No description provided for @joining.
  ///
  /// In en, this message translates to:
  /// **'Joining...'**
  String get joining;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @ringing2.
  ///
  /// In en, this message translates to:
  /// **'Ringing...'**
  String get ringing2;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @someone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weak;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @send2.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send2;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @feedback2.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback2;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @ring.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get ring;

  /// No description provided for @ended2.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get ended2;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @trim.
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get trim;

  /// No description provided for @posted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get posted;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @attachment2.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment2;

  /// No description provided for @aiLangAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto (Based on Context)'**
  String get aiLangAutoTitle;

  /// No description provided for @aiLangAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically detects the language of your message or reply'**
  String get aiLangAutoDesc;

  /// No description provided for @aiLangArabicTitle.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get aiLangArabicTitle;

  /// No description provided for @aiLangArabicDesc.
  ///
  /// In en, this message translates to:
  /// **'AI captions, replies, and corrections are always generated in Arabic'**
  String get aiLangArabicDesc;

  /// No description provided for @aiLangEnglishTitle.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get aiLangEnglishTitle;

  /// No description provided for @aiLangEnglishDesc.
  ///
  /// In en, this message translates to:
  /// **'AI captions, replies, and corrections are always generated in English'**
  String get aiLangEnglishDesc;

  /// No description provided for @aiToneDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get aiToneDefaultTitle;

  /// No description provided for @aiToneDefaultDesc.
  ///
  /// In en, this message translates to:
  /// **'Lets the AI choose the tone based on context'**
  String get aiToneDefaultDesc;

  /// No description provided for @aiToneFormalTitle.
  ///
  /// In en, this message translates to:
  /// **'Formal'**
  String get aiToneFormalTitle;

  /// No description provided for @aiToneFormalDesc.
  ///
  /// In en, this message translates to:
  /// **'Polished, professional wording'**
  String get aiToneFormalDesc;

  /// No description provided for @aiToneEnthusiasticTitle.
  ///
  /// In en, this message translates to:
  /// **'Enthusiastic'**
  String get aiToneEnthusiasticTitle;

  /// No description provided for @aiToneEnthusiasticDesc.
  ///
  /// In en, this message translates to:
  /// **'Energetic and upbeat wording'**
  String get aiToneEnthusiasticDesc;

  /// No description provided for @aiToneCasualTitle.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get aiToneCasualTitle;

  /// No description provided for @aiToneCasualDesc.
  ///
  /// In en, this message translates to:
  /// **'Relaxed, spontaneous everyday wording'**
  String get aiToneCasualDesc;

  /// No description provided for @aiToneEncouragingTitle.
  ///
  /// In en, this message translates to:
  /// **'Encouraging'**
  String get aiToneEncouragingTitle;

  /// No description provided for @aiToneEncouragingDesc.
  ///
  /// In en, this message translates to:
  /// **'Warm and supportive wording'**
  String get aiToneEncouragingDesc;

  /// No description provided for @aiLengthDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get aiLengthDefaultTitle;

  /// No description provided for @aiLengthDefaultDesc.
  ///
  /// In en, this message translates to:
  /// **'Natural, everyday length'**
  String get aiLengthDefaultDesc;

  /// No description provided for @aiLengthShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get aiLengthShortTitle;

  /// No description provided for @aiLengthShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Brief and to the point'**
  String get aiLengthShortDesc;

  /// No description provided for @aiLengthDetailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get aiLengthDetailedTitle;

  /// No description provided for @aiLengthDetailedDesc.
  ///
  /// In en, this message translates to:
  /// **'Longer and more thorough'**
  String get aiLengthDetailedDesc;

  /// No description provided for @dateAtTime.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String dateAtTime(Object date, Object time);

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'typing...'**
  String get typing;

  /// No description provided for @isTyping.
  ///
  /// In en, this message translates to:
  /// **'{userName} is typing...'**
  String isTyping(String userName);

  /// No description provided for @peopleTyping.
  ///
  /// In en, this message translates to:
  /// **'{length} people are typing...'**
  String peopleTyping(num length);

  /// No description provided for @valNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get valNameRequired;

  /// No description provided for @valNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid name (letters only)'**
  String get valNameInvalid;

  /// No description provided for @valNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get valNameMinLength;

  /// No description provided for @valEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get valEmailRequired;

  /// No description provided for @valEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get valEmailInvalid;

  /// No description provided for @valPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get valPasswordRequired;

  /// No description provided for @valPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get valPasswordMinLength;

  /// No description provided for @valConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password is required'**
  String get valConfirmPasswordRequired;

  /// No description provided for @valPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get valPasswordsDoNotMatch;

  /// No description provided for @authErrIncorrectCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get authErrIncorrectCredentials;

  /// No description provided for @authErrNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get authErrNoInternet;

  /// No description provided for @authErrEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try signing in instead.'**
  String get authErrEmailAlreadyRegistered;

  /// No description provided for @authErrEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Your email is not verified yet. Please check your inbox.'**
  String get authErrEmailNotVerified;

  /// No description provided for @authErrGeneral.
  ///
  /// In en, this message translates to:
  /// **'An authentication error occurred. Please try again.'**
  String get authErrGeneral;

  /// No description provided for @joinNow.
  ///
  /// In en, this message translates to:
  /// **'Join Now'**
  String get joinNow;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Do not have an account? '**
  String get dontHaveAnAccount;

  /// No description provided for @byUsingAppAgree.
  ///
  /// In en, this message translates to:
  /// **'By using this app you agree with the\n'**
  String get byUsingAppAgree;

  /// No description provided for @twoFactorStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Open your authenticator app'**
  String get twoFactorStep1Title;

  /// No description provided for @twoFactorStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Google Authenticator, Microsoft Authenticator, Authy or Apple Passwords all work.'**
  String get twoFactorStep1Desc;

  /// No description provided for @twoFactorStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code'**
  String get twoFactorStep2Title;

  /// No description provided for @twoFactorStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Or type the secret key by hand if you are on the same phone.'**
  String get twoFactorStep2Desc;

  /// No description provided for @twoFactorStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Save your recovery codes'**
  String get twoFactorStep3Title;

  /// No description provided for @twoFactorStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'They are the only way back in if you lose your phone.'**
  String get twoFactorStep3Desc;

  /// No description provided for @iveAddedIt.
  ///
  /// In en, this message translates to:
  /// **'I\'\'ve added it'**
  String get iveAddedIt;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyCode;

  /// No description provided for @feedbackWhatIsThisAbout.
  ///
  /// In en, this message translates to:
  /// **'What is this about?'**
  String get feedbackWhatIsThisAbout;

  /// No description provided for @feedbackTellUsMore.
  ///
  /// In en, this message translates to:
  /// **'Tell us more'**
  String get feedbackTellUsMore;

  /// No description provided for @feedbackAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get feedbackAttachments;

  /// No description provided for @feedbackReachYouOptional.
  ///
  /// In en, this message translates to:
  /// **'How can we reach you? (optional)'**
  String get feedbackReachYouOptional;

  /// No description provided for @feedbackCatBug.
  ///
  /// In en, this message translates to:
  /// **'Bug / Issue'**
  String get feedbackCatBug;

  /// No description provided for @feedbackCatFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get feedbackCatFeature;

  /// No description provided for @feedbackCatInquiry.
  ///
  /// In en, this message translates to:
  /// **'Inquiry'**
  String get feedbackCatInquiry;

  /// No description provided for @feedbackCatRating.
  ///
  /// In en, this message translates to:
  /// **'Rating & Review'**
  String get feedbackCatRating;

  /// No description provided for @feedbackCatAppreciation.
  ///
  /// In en, this message translates to:
  /// **'Appreciation'**
  String get feedbackCatAppreciation;

  /// No description provided for @feedbackCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackCatOther;

  /// No description provided for @feedbackStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get feedbackStatusPending;

  /// No description provided for @feedbackStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get feedbackStatusInProgress;

  /// No description provided for @feedbackStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved & Answered'**
  String get feedbackStatusResolved;

  /// No description provided for @feedbackStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get feedbackStatusClosed;

  /// No description provided for @aboutStatUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get aboutStatUsers;

  /// No description provided for @aboutStatMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get aboutStatMessages;

  /// No description provided for @aboutStatPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get aboutStatPosts;

  /// No description provided for @aboutStatUptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get aboutStatUptime;

  /// No description provided for @aboutFeatCallsTitle.
  ///
  /// In en, this message translates to:
  /// **'HD Voice & Video'**
  String get aboutFeatCallsTitle;

  /// No description provided for @aboutFeatCallsDesc.
  ///
  /// In en, this message translates to:
  /// **'Crystal clear calls anytime'**
  String get aboutFeatCallsDesc;

  /// No description provided for @aboutFeatChatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time Chats'**
  String get aboutFeatChatsTitle;

  /// No description provided for @aboutFeatChatsDesc.
  ///
  /// In en, this message translates to:
  /// **'Instant messaging with read receipts'**
  String get aboutFeatChatsDesc;

  /// No description provided for @aboutFeatStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get aboutFeatStoriesTitle;

  /// No description provided for @aboutFeatStoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Share your daily moments'**
  String get aboutFeatStoriesDesc;

  /// No description provided for @aboutFeatGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Chats'**
  String get aboutFeatGroupsTitle;

  /// No description provided for @aboutFeatGroupsDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect with communities'**
  String get aboutFeatGroupsDesc;

  /// No description provided for @aboutFeatPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy First'**
  String get aboutFeatPrivacyTitle;

  /// No description provided for @aboutFeatPrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your data stays yours'**
  String get aboutFeatPrivacyDesc;

  /// No description provided for @aboutFeatAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Alerts'**
  String get aboutFeatAlertsTitle;

  /// No description provided for @aboutFeatAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Never miss what matters'**
  String get aboutFeatAlertsDesc;

  /// No description provided for @targetProfile.
  ///
  /// In en, this message translates to:
  /// **'profile'**
  String get targetProfile;

  /// No description provided for @targetPost.
  ///
  /// In en, this message translates to:
  /// **'post'**
  String get targetPost;

  /// No description provided for @targetComment.
  ///
  /// In en, this message translates to:
  /// **'comment'**
  String get targetComment;

  /// No description provided for @targetStory.
  ///
  /// In en, this message translates to:
  /// **'story'**
  String get targetStory;

  /// No description provided for @targetMessage.
  ///
  /// In en, this message translates to:
  /// **'message'**
  String get targetMessage;

  /// No description provided for @reportReasonViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence or threats'**
  String get reportReasonViolence;

  /// No description provided for @reportReasonViolenceDesc.
  ///
  /// In en, this message translates to:
  /// **'Threats, incitement or graphic violence'**
  String get reportReasonViolenceDesc;

  /// No description provided for @reportReasonNsfw.
  ///
  /// In en, this message translates to:
  /// **'Nudity or sexual content'**
  String get reportReasonNsfw;

  /// No description provided for @reportReasonNsfwDesc.
  ///
  /// In en, this message translates to:
  /// **'Explicit or adult material'**
  String get reportReasonNsfwDesc;

  /// No description provided for @reportReasonChildSafety.
  ///
  /// In en, this message translates to:
  /// **'Child safety'**
  String get reportReasonChildSafety;

  /// No description provided for @reportReasonChildSafetyDesc.
  ///
  /// In en, this message translates to:
  /// **'Involves or endangers a minor'**
  String get reportReasonChildSafetyDesc;

  /// No description provided for @reportReasonHateHarassment.
  ///
  /// In en, this message translates to:
  /// **'Hate or harassment'**
  String get reportReasonHateHarassment;

  /// No description provided for @reportReasonHateHarassmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Bullying, abuse or discrimination'**
  String get reportReasonHateHarassmentDesc;

  /// No description provided for @reportReasonSpamScam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reportReasonSpamScam;

  /// No description provided for @reportReasonSpamScamDesc.
  ///
  /// In en, this message translates to:
  /// **'Fake offers, phishing or repeated ads'**
  String get reportReasonSpamScamDesc;

  /// No description provided for @reportReasonMisinformation.
  ///
  /// In en, this message translates to:
  /// **'False information'**
  String get reportReasonMisinformation;

  /// No description provided for @reportReasonMisinformationDesc.
  ///
  /// In en, this message translates to:
  /// **'Misleading or fabricated content'**
  String get reportReasonMisinformationDesc;

  /// No description provided for @reportReasonImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Impersonation or privacy'**
  String get reportReasonImpersonation;

  /// No description provided for @reportReasonImpersonationDesc.
  ///
  /// In en, this message translates to:
  /// **'Pretending to be someone or sharing private info'**
  String get reportReasonImpersonationDesc;

  /// No description provided for @reportReasonSelfHarm.
  ///
  /// In en, this message translates to:
  /// **'Self-harm'**
  String get reportReasonSelfHarm;

  /// No description provided for @reportReasonSelfHarmDesc.
  ///
  /// In en, this message translates to:
  /// **'Promotes or shows self-injury'**
  String get reportReasonSelfHarmDesc;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;

  /// No description provided for @reportReasonOtherDesc.
  ///
  /// In en, this message translates to:
  /// **'Tell us what is wrong'**
  String get reportReasonOtherDesc;

  /// No description provided for @fieldUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get fieldUsername;

  /// No description provided for @fieldJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get fieldJobTitle;

  /// No description provided for @fieldBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get fieldBio;

  /// No description provided for @fieldJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get fieldJoined;

  /// No description provided for @reactionsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reactionsFilterAll;

  /// No description provided for @sharedTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get sharedTabAll;

  /// No description provided for @sharedTabImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get sharedTabImages;

  /// No description provided for @sharedTabVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get sharedTabVideos;

  /// No description provided for @sharedTabLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get sharedTabLinks;

  /// No description provided for @sharedLabelMedia.
  ///
  /// In en, this message translates to:
  /// **'media'**
  String get sharedLabelMedia;

  /// No description provided for @sharedLabelImages.
  ///
  /// In en, this message translates to:
  /// **'images'**
  String get sharedLabelImages;

  /// No description provided for @sharedLabelVideos.
  ///
  /// In en, this message translates to:
  /// **'videos'**
  String get sharedLabelVideos;

  /// No description provided for @sharedLabelLinks.
  ///
  /// In en, this message translates to:
  /// **'links'**
  String get sharedLabelLinks;

  /// No description provided for @sharedDateRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sharedDateRecent;

  /// No description provided for @sharedDateLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get sharedDateLastWeek;

  /// No description provided for @sharedDateLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get sharedDateLastMonth;

  /// No description provided for @btnFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get btnFollow;

  /// No description provided for @btnFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get btnFollowing;

  /// No description provided for @btnAddFriend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get btnAddFriend;

  /// No description provided for @btnRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get btnRequested;

  /// No description provided for @tabChatsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabChatsAll;

  /// No description provided for @tabChatsDirect.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get tabChatsDirect;

  /// No description provided for @tabChatsGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get tabChatsGroups;

  /// No description provided for @tabChatsFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabChatsFavorites;

  /// No description provided for @tabChatsUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get tabChatsUnread;

  /// No description provided for @notifFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notifFilterAll;

  /// No description provided for @notifFilterMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notifFilterMessages;

  /// No description provided for @notifFilterCalls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get notifFilterCalls;

  /// No description provided for @notifFilterLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get notifFilterLikes;

  /// No description provided for @notifFilterComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get notifFilterComments;

  /// No description provided for @notifFilterFollows.
  ///
  /// In en, this message translates to:
  /// **'Follows'**
  String get notifFilterFollows;

  /// No description provided for @notifFilterFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get notifFilterFriendRequests;

  /// No description provided for @searchTabForYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get searchTabForYou;

  /// No description provided for @searchTabAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get searchTabAccounts;

  /// No description provided for @searchTabGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get searchTabGroups;

  /// No description provided for @searchTabReels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get searchTabReels;

  /// No description provided for @searchTabFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get searchTabFriends;

  /// No description provided for @aiModelGeminiTagline.
  ///
  /// In en, this message translates to:
  /// **'Fast, and great with images'**
  String get aiModelGeminiTagline;

  /// No description provided for @aiModelLlamaTagline.
  ///
  /// In en, this message translates to:
  /// **'Open-weight and efficient'**
  String get aiModelLlamaTagline;

  /// No description provided for @aiModelOpenRouterTagline.
  ///
  /// In en, this message translates to:
  /// **'Auto-picks a free model for you'**
  String get aiModelOpenRouterTagline;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @addVideo.
  ///
  /// In en, this message translates to:
  /// **'Add Video'**
  String get addVideo;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add a Document'**
  String get addDocument;

  /// No description provided for @addGif.
  ///
  /// In en, this message translates to:
  /// **'Add GIF'**
  String get addGif;

  /// No description provided for @liveVideo.
  ///
  /// In en, this message translates to:
  /// **'Live Video'**
  String get liveVideo;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortOldest;

  /// No description provided for @sortTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get sortTop;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @viewRepliesCount.
  ///
  /// In en, this message translates to:
  /// **'View {count} {count, plural, =1{reply} other{replies}}'**
  String viewRepliesCount(num count);

  /// No description provided for @revokeInviteBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the current link will no longer be able to join using it. Continue?'**
  String get revokeInviteBody;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @tapForGroupInfo.
  ///
  /// In en, this message translates to:
  /// **'Tap for group info'**
  String get tapForGroupInfo;

  /// No description provided for @retryAgain.
  ///
  /// In en, this message translates to:
  /// **'Retry Again'**
  String get retryAgain;

  /// No description provided for @presenceEveryoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Anyone using the app can see your status'**
  String get presenceEveryoneDesc;

  /// No description provided for @presenceFriendsDesc.
  ///
  /// In en, this message translates to:
  /// **'Only accepted friends can see your status'**
  String get presenceFriendsDesc;

  /// No description provided for @presenceSpecificDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose exactly who can see your status'**
  String get presenceSpecificDesc;

  /// No description provided for @presenceNobodyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your online status stays private'**
  String get presenceNobodyDesc;

  /// No description provided for @aiChatPrevious7Days.
  ///
  /// In en, this message translates to:
  /// **'Previous 7 Days'**
  String get aiChatPrevious7Days;

  /// No description provided for @aiChatPrevious30Days.
  ///
  /// In en, this message translates to:
  /// **'Previous 30 Days'**
  String get aiChatPrevious30Days;

  /// No description provided for @aiChatOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get aiChatOlder;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
