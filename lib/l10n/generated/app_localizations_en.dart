// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Manage your preferences';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsSectionAi => 'Artificial Intelligence';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsEditProfile => 'Edit Profile';

  @override
  String get settingsEditProfileSubtitle => 'Update your info and photo';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsChangePasswordSubtitle => 'Update your account password';

  @override
  String get settingsEmailAddress => 'Email Address';

  @override
  String get settingsEmailAddressSubtitle => 'Manage linked email';

  @override
  String get settingsPushNotifications => 'Push Notifications';

  @override
  String get settingsPushNotificationsSubtitle => 'Enable all notifications';

  @override
  String get settingsMessagePreviews => 'Message Previews';

  @override
  String get settingsMessagePreviewsSubtitle => 'Show content in notifications';

  @override
  String get settingsCallNotifications => 'Call Notifications';

  @override
  String get settingsCallNotificationsSubtitle => 'Incoming call alerts';

  @override
  String get settingsReadReceipts => 'Read Receipts';

  @override
  String get settingsReadReceiptsSubtitle => 'Show when you’ve read messages';

  @override
  String get settingsOnlineStatus => 'Online Status';

  @override
  String get settingsOnlineStatusSubtitle =>
      'Let others see when you’re active';

  @override
  String get settingsOnlineStatusVisibility => 'Online Status Visibility';

  @override
  String get presenceEveryone => 'Everyone';

  @override
  String get presenceFriends => 'My Friends';

  @override
  String get presenceSpecific => 'Specific People';

  @override
  String get presenceNobody => 'Nobody';

  @override
  String get settingsAppLock => 'App Lock';

  @override
  String get settingsAppLockSubtitle =>
      'Require fingerprint / Face ID to open app';

  @override
  String get settingsTwoFactor => 'Two-Factor Auth';

  @override
  String get settingsTwoFactorOffSubtitle => 'Extra layer of security';

  @override
  String get settingsTwoFactorOnAuthenticator => 'On • Authenticator app';

  @override
  String settingsTwoFactorOnRecoveryCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recovery codes',
      one: '1 recovery code',
    );
    return 'On • $_temp0 remaining';
  }

  @override
  String get settingsBlockedUsers => 'Blocked Users';

  @override
  String get settingsBlockedUsersSubtitle => 'Manage blocked accounts';

  @override
  String get settingsAiSettings => 'AI Settings';

  @override
  String get settingsAiSettingsSubtitle =>
      'Personalize your AI-powered experience';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSubtitle => 'Personalize your app colors';

  @override
  String get language => 'Language';

  @override
  String get languageSheetSubtitle => 'Choose the language used across the app';

  @override
  String get settingsAboutUs => 'About Us';

  @override
  String get settingsAboutUsSubtitle => 'Our story and mission';

  @override
  String get settingsHelpFaq => 'Help & FAQ';

  @override
  String get settingsHelpFaqSubtitle => 'Get answers to common questions';

  @override
  String get settingsSendFeedback => 'Send Feedback';

  @override
  String get settingsSendFeedbackSubtitle => 'Tell us what you think';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicySubtitle => 'How we handle your data';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsTermsOfServiceSubtitle =>
      'Platform rules & community guidelines';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get logOut => 'Log Out';

  @override
  String get logOutSubtitle => 'Sign out of your account';

  @override
  String get loggedOutSuccessfully => 'Logged out successfully';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountSubtitle => 'Permanently remove your account';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete your account? This action is permanent and cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get settingsErrorPrivacyUpdate => 'Failed to update privacy setting.';

  @override
  String get settingsErrorVisibilityUpdate =>
      'Failed to update visibility list.';

  @override
  String get settingsErrorIdentityNotVerified =>
      'Your identity has not been verified; please try again.';

  @override
  String get settingsErrorBiometricNoHardware =>
      'This device doesn’t have a fingerprint or Face ID sensor, so App Lock isn’t available.';

  @override
  String get settingsErrorBiometricNotEnrolled =>
      'No fingerprint or Face ID is set up on this device yet. Add one in your device settings, then try again.';

  @override
  String get settingsErrorBiometricLockedOut =>
      'Too many failed attempts. Please wait a moment before trying again.';

  @override
  String get settingsErrorBiometricPermanentlyLockedOut =>
      'Biometric authentication is locked. Unlock your device with its PIN, pattern, or password first.';

  @override
  String get settingsErrorBiometricPasscodeNotSet =>
      'Set up a screen lock (PIN, pattern, or password) on your device before enabling App Lock.';

  @override
  String get settingsErrorBiometricUnknown =>
      'We couldn’t verify your device’s biometric setup. Please try again.';

  @override
  String get themesTitle => 'Appearance';

  @override
  String get themesSubtitle =>
      'Pick a look that feels like you. Changes apply instantly.';

  @override
  String get themeNameOcean => 'Ocean';

  @override
  String get themeNameSunset => 'Sunset';

  @override
  String get themeNameForest => 'Forest';

  @override
  String get themeNameMidnight => 'Midnight';

  @override
  String get themeNameGold => 'Gold';

  @override
  String get themeNameGlass => 'Glass';

  @override
  String get themeNameLavender => 'Lavender';

  @override
  String get themeNameCarbon => 'Carbon';

  @override
  String get themeNameEmerald => 'Emerald';

  @override
  String get themeNameNordic => 'Nordic';

  @override
  String get themeNameGrape => 'Grape';

  @override
  String get themeNameSahara => 'Sahara';

  @override
  String get connectivityOffline => 'No internet connection';

  @override
  String get connectivityRestored => 'Back to internet';

  @override
  String get callOngoingTitle => 'Ongoing Call';

  @override
  String get callReturnHint => 'Tap to return to the call';

  @override
  String get gallery => 'Gallery';

  @override
  String get video => 'Video';

  @override
  String get file => 'File';

  @override
  String get voice => 'Voice';

  @override
  String get sticker => 'Sticker';

  @override
  String get camera => 'Camera';

  @override
  String get resume => 'Resume';

  @override
  String get slideToCancel => 'Slide to cancel';

  @override
  String get archivedChats => 'Archived Chats';

  @override
  String get noArchivedChats => 'No archived chats.';

  @override
  String get messageInfo => 'Message info';

  @override
  String get voiceNote => 'Voice note';

  @override
  String get reportMessage => 'Report message';

  @override
  String get reportSpamAbusiveContent =>
      'Report spam, abusive content, or inappropriate messages';

  @override
  String get growYourNetwork => 'Grow Your Network';

  @override
  String get youHaventAddedAny =>
      'You haven’t added any connections yet.\nDiscover people nearby or explore suggested profiles to start chatting.';

  @override
  String get discoverPeople => 'Discover People';

  @override
  String get newChat => 'New Chat';

  @override
  String get searchFriendsGroups => 'Search friends & groups...';

  @override
  String get sharedMedia => 'Shared Media';

  @override
  String get starredMessages => 'Starred Messages';

  @override
  String get searchMessages => 'Search messages';

  @override
  String get couldntOpenThatFile => 'Couldn’t open that file.';

  @override
  String get noLinksSharedYet => 'No links shared yet';

  @override
  String get group => 'Group';

  @override
  String get selected => 'selected';

  @override
  String get mediaLinksAndDocs => 'Media, links, and docs';

  @override
  String get seeAll => 'See all';

  @override
  String get previewNotAvailable => 'Preview not available';

  @override
  String get couldNotTrimThis => 'Could not trim this video. Please try again.';

  @override
  String get trimVideo => 'Trim video';

  @override
  String get done => 'Done';

  @override
  String get trimming => 'Trimming…';

  @override
  String get couldNotLoadThis => 'Could not load this video.';

  @override
  String get searching => 'Searching...';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get whoCanSeeYour => 'Who can see your online status';

  @override
  String get thisControlsYourGreen =>
      'This controls your green dot and \"last seen\" everywhere in the app.';

  @override
  String get lastSeenRecently => 'Last seen recently';

  @override
  String get online => 'Online';

  @override
  String get yourProfileIsStill =>
      'Your profile is still loading — try again in a second.';

  @override
  String get storiesDontSupportDocuments =>
      'Stories don’t support documents yet.';

  @override
  String get aiDoesntSupportVideo => 'AI doesn’t support video yet';

  @override
  String get shareToStory => 'Share to Story';

  @override
  String get createPost => 'Create Post';

  @override
  String get askSyncraAi => 'Ask Syncra AI';

  @override
  String get recentChats => 'Recent Chats';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get sendTo => 'Send to...';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get failedToForwardTry => 'Failed to forward. Try again.';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get forwardToChat => 'Forward to Chat';

  @override
  String get shareVia => 'Share via...';

  @override
  String get pleaseEndYourCurrent =>
      'Please end your current call before starting another.';

  @override
  String get areYouSureYou => 'Are you sure you want to quit ?';

  @override
  String get edit => 'Edit';

  @override
  String get saveToGallery => 'Save to gallery';

  @override
  String get whatWeOffer => 'What We Offer';

  @override
  String get builtMaintainedBy => 'Built & Maintained By';

  @override
  String get connectWithUs => 'Connect With Us';

  @override
  String get connectingPeopleBuildingCommunities =>
      'Connecting people, building communities';

  @override
  String get ourMission => 'Our Mission';

  @override
  String get weBelieveMeaningfulConnections =>
      'We believe meaningful connections change lives. Our platform is built to bring people closer — through conversations, shared moments, and real-time experiences that matter.';

  @override
  String get website => 'Website';

  @override
  String get portfolio => 'Portfolio';

  @override
  String get email => 'Email';

  @override
  String get version100 => 'Version 1.0.0  •  Made with ❤️';

  @override
  String get theSmartReplyTo =>
      'The smart reply to images service is currently busy. Please try again later or write your reply manually.';

  @override
  String get anErrorOccurredWith =>
      'An error occurred with the AI suggestion. Please try again.';

  @override
  String get copiedSuccessfully => 'Copied successfully';

  @override
  String get copy => 'Copy';

  @override
  String get todaysAiUsage => 'Today’s AI Usage';

  @override
  String get estimated => 'Estimated';

  @override
  String get failedToDeleteThis =>
      'Failed to delete this chat. Please try again.';

  @override
  String get failedToForwardPlease => 'Failed to forward. Please try again.';

  @override
  String get theresNoTextTo => 'There’s no text to share in this selection.';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get image => 'Image';

  @override
  String get translate => 'Translate';

  @override
  String get audioChat => 'Audio Chat';

  @override
  String get chatFiles => 'Chat Files';

  @override
  String get stillGettingSyncraReady =>
      'Still getting Syncra ready — try again in a second.';

  @override
  String get failedToSendYour =>
      'Failed to send your message. Please try again.';

  @override
  String get couldntLoadThatPhoto =>
      'Couldn’t load that photo. Please try again.';

  @override
  String get addACaption => 'Add a caption...';

  @override
  String get howCanIHelp => 'How can I help you?';

  @override
  String get voiceDictationIsntAvailable =>
      'Voice dictation isn’t available on this device.';

  @override
  String get messageSyncra => 'Message Syncra...';

  @override
  String get failedToShareThis =>
      'Failed to share this chat. Please try again.';

  @override
  String get loadMore => 'Load more';

  @override
  String get chooseAModel => 'Choose a model';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get aLinkWasJust =>
      'A link was just sent to this address. Please wait.';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get enterYourRegisteredEmail =>
      'Enter your registered email address and we will send you a recovery link.';

  @override
  String get changeEmail => 'Change email';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get ifAnAccountExists =>
      'If an account exists for this email, we’ve sent you a password reset link.';

  @override
  String get returnToLogin => 'Return to Login';

  @override
  String get theRecoverySessionIs =>
      'The recovery session is invalid or has expired. Please request a new link.';

  @override
  String get createNewPassword => 'Create New Password';

  @override
  String get yourNewPasswordMust =>
      'Your new password must be at least 6 characters long.';

  @override
  String get newPassword => 'New Password';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get reEnterYourPassword => 'Re-enter your password';

  @override
  String get passwordUpdatedSuccessfully => 'Password updated successfully';

  @override
  String get enterEmail => 'Enter Email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get loginSuccessfully => 'Login Successfully';

  @override
  String get orSignInWith => 'Or Sign in with';

  @override
  String get fullName => 'Full Name';

  @override
  String get yourFullName => 'Your Full Name';

  @override
  String get enterNewEmail => 'Enter New Email';

  @override
  String get typeYourPassword => 'Type your password';

  @override
  String get retypeYourPassword => 'Retype your password';

  @override
  String get signUpSuccessfully => 'Sign up Successfully';

  @override
  String get orSignUpWith => 'Or Sign up with';

  @override
  String get facebookLogInIs =>
      'Facebook log in is in Dev Mode (Test accounts and admin only). Continue?';

  @override
  String get continueLabel => 'Continue';

  @override
  String get unblockUser => 'Unblock User';

  @override
  String get unblock => 'Unblock';

  @override
  String get manageTheAccountsYouve => 'Manage the accounts you’ve blocked';

  @override
  String get blocked => 'Blocked';

  @override
  String get searchPeopleOrGroups => 'Search people or groups...';

  @override
  String get askTheAiAssistant => 'Ask the AI assistant about this';

  @override
  String get editingComment => 'Editing comment';

  @override
  String get voice2 => '🎤 voice';

  @override
  String get photo => 'Photo';

  @override
  String get close => 'Close';

  @override
  String get recordingVoiceMessage => 'Recording voice message';

  @override
  String get delete => 'Delete';

  @override
  String get report => 'Report';

  @override
  String get deleteThisComment => 'Delete this comment ?';

  @override
  String get commentDeletedSuccessfully => 'Comment deleted successfully';

  @override
  String get youMentionedYourselfIn => 'You mentioned yourself in this comment';

  @override
  String get edited => '· Edited';

  @override
  String get reply => 'Reply';

  @override
  String get comments => 'Comments';

  @override
  String get noCommentsYet => 'No comments yet.';

  @override
  String get searchPeople => 'Search people...';

  @override
  String get tryADifferentName => 'Try a different name or username';

  @override
  String get retry => 'Retry';

  @override
  String get peopleYouMayKnow => 'People you may know';

  @override
  String get somethingWentWrongPlease =>
      'Something went wrong. Please try again.';

  @override
  String get accept => 'Accept';

  @override
  String get friends => 'Friends';

  @override
  String get followsYou => 'Follows you';

  @override
  String get couldNotLoadThe => 'Could not load the image.';

  @override
  String get responseWithin24Hours => 'Response within 24 hours (max 3 days).';

  @override
  String get yourMessage => 'Your message';

  @override
  String get ourTeamHasReviewed =>
      'Our team has reviewed this feedback. Thank you for helping us improve!';

  @override
  String get weAreWorkingOn =>
      'We are working on this. You will be notified when we reply.';

  @override
  String get socialMateSupport => 'Social Mate Support';

  @override
  String get official => 'Official';

  @override
  String get myFeedbacks => 'My Feedbacks';

  @override
  String get trackTheStatusOf => 'Track the status of your submissions';

  @override
  String get couldNotLoadYour => 'Could not load your feedbacks';

  @override
  String get noFeedbackYet => 'No feedback yet';

  @override
  String get anythingYouSendUs =>
      'Anything you send us will show up here with its status.';

  @override
  String get replyReceived => 'Reply received';

  @override
  String get responseWithin24Hours2 => 'Response within 24 hours (max 3 days)';

  @override
  String get imageIsTooLarge => 'Image is too large (max 10 MB).';

  @override
  String get couldNotOpenYour => 'Could not open your gallery.';

  @override
  String get editedImageIsToo => 'Edited image is too large (max 10 MB).';

  @override
  String get feedbackSubmittedSuccessfully => 'Feedback Submitted Successfully';

  @override
  String get underReview => 'Under Review';

  @override
  String get ourTeamTypicallyResponds =>
      'Our team typically responds within 24 hours (up to 3 business days).';

  @override
  String get feedbackSupport => 'Feedback & Support';

  @override
  String get helpUsImproveSocial => 'Help us improve Social Mate';

  @override
  String get emailOrPhoneNumber => 'Email or phone number';

  @override
  String get responseTime => 'Response time';

  @override
  String get myFeedbacks2 => 'My feedbacks';

  @override
  String get attachAScreenshot => 'Attach a screenshot';

  @override
  String get microphonePermissionIsRequired =>
      'Microphone permission is required to record.';

  @override
  String get couldNotStartRecording => 'Could not start recording.';

  @override
  String get recordingWasTooShort => 'Recording was too short.';

  @override
  String get deleteVoiceNote => 'Delete voice note';

  @override
  String get stop => 'Stop';

  @override
  String get noGifsFound => 'No GIFs found';

  @override
  String get searchGifs => 'Search GIFs...';

  @override
  String get decline => 'Decline';

  @override
  String get ongoingGroupCall => 'Ongoing Group Call';

  @override
  String get theCallCouldNot => 'The call could not be initiated.';

  @override
  String get back => 'Back';

  @override
  String get flip => 'Flip';

  @override
  String get end => 'End';

  @override
  String get groupMembers => 'Group Members';

  @override
  String get admin => 'Admin';

  @override
  String get inCall => 'In Call';

  @override
  String get syncraCantReadMedia =>
      'Syncra can’t read media messages yet — try a text message.';

  @override
  String get deleteForMe => 'Delete for me';

  @override
  String get deleteForEveryone => 'Delete for everyone';

  @override
  String get failedToAddMembers => 'Failed to add members. Please try again.';

  @override
  String get addMembers => 'Add Members';

  @override
  String get noNewConnectionsTo => 'No new connections to add';

  @override
  String get noPeopleFound => 'No people found';

  @override
  String get buildYourCommunity => 'Build Your Community';

  @override
  String get youHaventAddedAny2 =>
      'You haven’t added any connections yet.\nDiscover people nearby or explore suggested profiles to create your first group.';

  @override
  String get newGroup => 'New Group';

  @override
  String get fileSent => 'File sent';

  @override
  String get failedToUpdateGroup => 'Failed to update group photo';

  @override
  String get removeMember => 'Remove Member';

  @override
  String get remove => 'Remove';

  @override
  String get failedToLoadMembers => 'Failed to load members';

  @override
  String get groupNameUpdated => 'Group name updated';

  @override
  String get groupTitleUpdated => 'Group title updated';

  @override
  String get removeGroupPhoto => 'Remove Group Photo';

  @override
  String get groupPhotoRemoved => 'Group photo removed';

  @override
  String get leaveGroup => 'Leave Group';

  @override
  String get blockGroup => 'Block Group';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get groupSettings => 'Group Settings';

  @override
  String get tapToJoin => 'Tap to Join';

  @override
  String get search => 'Search';

  @override
  String get groupInfo => 'group info';

  @override
  String get pleaseEndYourCurrent2 =>
      'Please end your current call before joining another call.';

  @override
  String get join => 'Join';

  @override
  String get voiceCall => 'Voice call';

  @override
  String get videoCall => 'Video call';

  @override
  String get youAreNoLonger => 'You are no longer a member of this group';

  @override
  String get editingMessage => 'Editing message';

  @override
  String get enterGroupName => 'Enter group name';

  @override
  String get members => 'Members';

  @override
  String get online2 => 'online';

  @override
  String get owner => 'Owner';

  @override
  String get message => 'Message';

  @override
  String get call => 'Call';

  @override
  String get typeAMessage => 'Type a message...';

  @override
  String get thisGroupIsNo => 'This group is no longer available';

  @override
  String get failedToOpenGroup => 'Failed to open group chat';

  @override
  String get linkExpiration => 'Link Expiration';

  @override
  String get neverExpires => 'Never expires';

  @override
  String get t24Hours => '24 hours';

  @override
  String get t2Days => '2 days';

  @override
  String get t1Week => '1 week';

  @override
  String get revokeInviteLink => 'Revoke Invite Link';

  @override
  String get inviteLinkCopied => 'Invite link copied';

  @override
  String get createALinkTo => 'Create a link to let others join this group.';

  @override
  String get generate => 'Generate';

  @override
  String get forward => 'Forward';

  @override
  String get revokeLink => 'Revoke Link';

  @override
  String get inviteLink => 'Invite Link';

  @override
  String get addACaption2 => 'Add a caption…';

  @override
  String get add => 'Add';

  @override
  String get noMessagesYet => 'No messages yet.';

  @override
  String get groupName => 'Group Name';

  @override
  String get groupName2 => 'Group name';

  @override
  String get saveName => 'Save Name';

  @override
  String get groupTitle => 'Group Title';

  @override
  String get addATitleFor => 'Add a title for this group';

  @override
  String get saveTitle => 'Save Title';

  @override
  String get groupOwner => 'Group Owner';

  @override
  String get groupAdmins => 'Group Admins';

  @override
  String get removeAdmin => 'Remove Admin';

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String get youMentionedAllGroup => 'You mentioned all group members';

  @override
  String get youMentionedYourselfIn2 =>
      'You mentioned yourself in this message';

  @override
  String get searchPeople2 => 'Search people';

  @override
  String get edited2 => 'Edited';

  @override
  String get loadingMorePosts => 'Loading more posts...';

  @override
  String get markRead => 'Mark read';

  @override
  String get reject => 'Reject';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get thisPostIsNo => 'This post is no longer available.';

  @override
  String get uploadCanceled => 'Upload canceled';

  @override
  String get postPublishedSuccessfully => 'Post Published Successfully';

  @override
  String get writeSomethingOrAttach =>
      'Write something or attach a file to share your post.';

  @override
  String get contentNotAvailable => 'Content not available';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get savedPosts => 'Saved Posts';

  @override
  String get thisFeatureIsComing => 'this feature is coming soon';

  @override
  String get noSavedPostsYet => 'No saved posts yet';

  @override
  String get tapTheBookmarkIcon =>
      'Tap the bookmark icon on any post to save it here for later.';

  @override
  String get backgroundColorIsComing => 'Background Color is coming soon';

  @override
  String get addGifIsComing => 'Add GIF is coming soon';

  @override
  String get liveVideoIsComing => 'Live Video is coming soon';

  @override
  String get createAPost => 'Create a Post';

  @override
  String get post => 'Post';

  @override
  String get whatsOnYourHead => 'What’s on your head?';

  @override
  String get pinnedPost => 'Pinned Post';

  @override
  String get reportPost => 'Report Post';

  @override
  String get postPinnedToYour => 'Post pinned to your profile';

  @override
  String get postUnpinned => 'Post unpinned';

  @override
  String get openOriginalPost => 'Open original post';

  @override
  String get suggestedForYou => 'Suggested for you';

  @override
  String get failedToLoadReactions => 'Failed to load reactions.';

  @override
  String get noReactionsYet => 'No reactions yet.';

  @override
  String get youMentionedYourselfIn3 => 'You mentioned yourself in this post';

  @override
  String get videoUnavailableOffline => 'Video unavailable offline';

  @override
  String get videoIsStillProcessing => 'Video is still processing…';

  @override
  String get couldntLoadVideo => 'Couldn’t load video';

  @override
  String get whatsOnYourMind => 'What’s on your mind?';

  @override
  String get noPostsAvailable => 'No posts available.';

  @override
  String get openPostDetails => 'Open post details';

  @override
  String get profileUpdatedSuccessfully => 'Profile Updated Successfully';

  @override
  String get youHaveUnsavedChanges =>
      'You have unsaved changes. Do you want to discard them?';

  @override
  String get discard => 'Discard';

  @override
  String get deletedAccount => 'Deleted Account';

  @override
  String get name => 'Name';

  @override
  String get enterNewName => 'Enter New Name';

  @override
  String get username => 'UserName';

  @override
  String get enterNewUsername => 'Enter New UserName';

  @override
  String get title => 'Title';

  @override
  String get enterNewTitle => 'Enter New Title';

  @override
  String get bio => 'Bio';

  @override
  String get enterNewBio => 'Enter New Bio';

  @override
  String get socialMedia => 'Social Media';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get takeAPhoto => 'Take a Photo';

  @override
  String get cropEdit => 'Crop & edit';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get stories => 'Stories';

  @override
  String get friendsList => 'Friends List';

  @override
  String get declineRequest => 'Decline request';

  @override
  String get sendMessage => 'Send message';

  @override
  String get reportProfile => 'Report profile';

  @override
  String get posts => 'Posts';

  @override
  String get media => 'Media';

  @override
  String get followers => 'Followers';

  @override
  String get following => 'Following';

  @override
  String get linkedinProfile => 'LinkedIn Profile';

  @override
  String get status => 'Status';

  @override
  String get aShortQuoteMood => 'A short quote, mood or emoji statement';

  @override
  String get thisAccountHasBeen => 'This account has been deleted';

  @override
  String get reactions => 'Reactions';

  @override
  String get tapToRemove => 'Tap to remove';

  @override
  String get whatDoYouLike => 'What do you like?';

  @override
  String get chooseTheTopicsThat =>
      'Choose the topics that interest you so we can personalize your reels experience.';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get shareRemoved => 'Share removed';

  @override
  String get reelSharedToYour => 'Reel shared to your feed';

  @override
  String get couldNotShareThis =>
      'Could not share this reel. Please try again.';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard';

  @override
  String get couldNotShareThis2 =>
      'Could not share this link. Please try again.';

  @override
  String get reshare => 'Reshare';

  @override
  String get learnHowToPlay => 'Learn how to play this video';

  @override
  String get openOnYoutube => 'Open on YouTube';

  @override
  String get reels => 'Reels';

  @override
  String get thanksForReportingOur =>
      'Thanks for reporting. Our team will review it.';

  @override
  String get whyAreYouReporting =>
      'Why are you reporting this? Your report is confidential.';

  @override
  String get reelsForYou => 'Reels for you';

  @override
  String get peopleYouAddAs => 'People you add as friends will show up here.';

  @override
  String get searchAccountsPostsReels => 'Search accounts, posts, reels...';

  @override
  String get featuresLanguageUsage => 'Features, language & usage';

  @override
  String get aiFeatures => 'AI Features';

  @override
  String get aiAutoComplete => 'AI Auto Complete';

  @override
  String get tapTheAiIcon => 'Tap the AI icon to generate captions & replies';

  @override
  String get aiAutoDetect => 'AI Auto Detect';

  @override
  String get automaticSpellingSuggestionsWhile =>
      'Automatic spelling suggestions while you type';

  @override
  String get aiCommentSuggestions => 'AI Comment Suggestions';

  @override
  String get quickAiSuggestedReplies =>
      'Quick AI-suggested replies under posts';

  @override
  String get autoCompleteLanguage => 'Auto Complete Language';

  @override
  String get replyTone => 'Reply Tone';

  @override
  String get replyLength => 'Reply Length';

  @override
  String get sendResetLink => 'Send reset link?';

  @override
  String get sendLink => 'Send link';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get updateYourAccountPassword =>
      'Update your account password securely';

  @override
  String get pleaseSignInAgain => 'Please sign in again to continue.';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get enterYourCurrentPassword => 'Enter your current password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get reEnterNewPassword => 'Re-enter new password';

  @override
  String get yourEmailAddressWas => 'Your email address was updated';

  @override
  String get emailVerified => 'Email verified';

  @override
  String get confirmationLinkSent => 'Confirmation link sent';

  @override
  String get confirmationLinkSentAgain => 'Confirmation link sent again';

  @override
  String get emailChangeCancelled => 'Email change cancelled';

  @override
  String get verificationEmailSent => 'Verification email sent';

  @override
  String get keep => 'Keep';

  @override
  String get cancelEmailChange => 'Cancel email change?';

  @override
  String get manageAndUpdateYour =>
      'Manage and update your linked email address';

  @override
  String get setAPasswordFirst => 'Set a password first';

  @override
  String get changeEmailAddress => 'Change email address';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get newEmailAddress => 'New Email Address';

  @override
  String get enterYourNewEmail => 'Enter your new email';

  @override
  String get whichLanguageShouldAi =>
      'Which language should AI captions, replies, and corrections use?';

  @override
  String get howLongShouldAi =>
      'How long should AI-generated captions and replies be?';

  @override
  String get whatToneShouldAi =>
      'What tone should AI-generated captions and replies use?';

  @override
  String get theAppIsLocked => 'The app is locked.';

  @override
  String get useYourFingerprintOr =>
      'Use your fingerprint or Face ID to open the app.';

  @override
  String get openTheApp => 'Open the app';

  @override
  String get searchProfile => 'Search Profile';

  @override
  String get yourChats => 'Your Chats';

  @override
  String get yourThemes => 'Your Themes';

  @override
  String get logOutSuccessfully => 'Log out Successfully';

  @override
  String get isCallingYou => 'is calling you...';

  @override
  String get returnToCall => 'Return to call';

  @override
  String get sharedGroups => 'Shared Groups';

  @override
  String get addAnOptionalCaption => 'Add an optional caption...';

  @override
  String get editMessage => 'Edit message';

  @override
  String get deleteMessage => 'Delete message';

  @override
  String get youCannotSendMessages =>
      'You cannot send messages to a deleted account.';

  @override
  String get t5Sec => '-5 sec';

  @override
  String get t5Sec2 => '+5 sec';

  @override
  String get messages => 'Messages';

  @override
  String get archivedChats2 => 'Archived chats';

  @override
  String get createGroup => 'Create Group';

  @override
  String get repliedToStory => 'Replied to Story';

  @override
  String get selectPeople => 'Select People';

  @override
  String get searchFriends => 'Search friends...';

  @override
  String get noFriendsYet => 'No friends yet';

  @override
  String get couldntLoadMoreTap => 'Couldn’t load more · Tap to retry';

  @override
  String get unfriend => 'Unfriend';

  @override
  String get skip => 'Skip';

  @override
  String get signIn => 'Sign In';

  @override
  String get packName => 'Pack Name';

  @override
  String get createStickerPack => 'Create Sticker Pack';

  @override
  String get noStickersYet => 'No Stickers Yet';

  @override
  String get discoverAndDownloadAmazing =>
      'Discover and download amazing sticker packs from the library to express yourself.';

  @override
  String get exploreLibrary => 'Explore Library';

  @override
  String get stickerLibrary => 'Sticker Library';

  @override
  String get createPack => 'Create Pack';

  @override
  String get createYourOwnSticker => 'Create Your Own\nSticker Pack';

  @override
  String get privacyAudience => 'Privacy & Audience';

  @override
  String get tapToChangeAudience => 'Tap to change audience';

  @override
  String get stickers => 'Stickers';

  @override
  String get nameYourPack => 'Name your pack...';

  @override
  String get download => 'Download';

  @override
  String get noFriendsFound => 'No friends found.';

  @override
  String get browseLibrary => 'Browse Library';

  @override
  String get share => 'Share';

  @override
  String get couldNotLoadVideo => 'Could not load video';

  @override
  String get storyAddedSuccessfully => 'Story Added Successfully';

  @override
  String get thisStoryIsNo => 'This story is no longer available';

  @override
  String get replySent => 'Reply sent ✓';

  @override
  String get youMentionedYourselfIn4 => 'You mentioned yourself in this story';

  @override
  String get couldNotLoadStories => 'Could not load stories';

  @override
  String get noStoriesYet => 'No stories yet';

  @override
  String get createStory => 'Create\nStory';

  @override
  String get shareStory => 'Share Story';

  @override
  String get deleteStory => 'Delete Story';

  @override
  String get reportStory => 'Report Story';

  @override
  String get addToStory => 'Add to Story';

  @override
  String get textStory => 'Text Story';

  @override
  String get photoFromGallery => 'Photo from Gallery';

  @override
  String get videoFromGallery => 'Video from Gallery';

  @override
  String get max60Seconds => 'Max 60 seconds';

  @override
  String get recordAVideo => 'Record a Video';

  @override
  String get yourStory => 'Your Story';

  @override
  String get writeYourThoughtWith => 'Write your thought with others';

  @override
  String get couldntLoadViews => 'Couldn’t load views.';

  @override
  String get noViewsYet => 'No views yet';

  @override
  String get weCouldntLoadThis =>
      'We couldn’t load this content. Please try again later.';

  @override
  String get searchForAQuestion => 'Search for a question…';

  @override
  String get tableOfContents => 'Table of Contents';

  @override
  String get stillNeedHelpContact => 'Still need help? Contact Support';

  @override
  String get twoFactorWasTurned =>
      'Two-factor was turned off after you used a recovery code.';

  @override
  String get twoStepVerification => 'Two-step verification';

  @override
  String get pasteCode => 'Paste code';

  @override
  String get notYouSignOut => 'Not you? Sign out';

  @override
  String get leaveWithoutSaving => 'Leave without saving?';

  @override
  String get stay => 'Stay';

  @override
  String get leave => 'Leave';

  @override
  String get saveYourRecoveryCodes => 'Save your recovery codes';

  @override
  String get codesCopiedClipboardClears =>
      'Codes copied. Clipboard clears in 60s.';

  @override
  String get copyAll => 'Copy all';

  @override
  String get saveShare => 'Save / Share';

  @override
  String get iSavedTheseCodes => 'I saved these codes in a safe place';

  @override
  String get twoFactorAuthenticationIs => 'Two-factor authentication is off';

  @override
  String get turnOffTwoFactor => 'Turn off two-factor?';

  @override
  String get currentPassword2 => 'Current password';

  @override
  String get protectYourAccount => 'Protect your account';

  @override
  String get noAuthenticatorAppFound =>
      'No authenticator app found. Copy the secret key instead.';

  @override
  String get scanThisQrCode => 'Scan this QR code';

  @override
  String get openYourAuthenticatorApp =>
      'Open your authenticator app, add a new account and scan the code.';

  @override
  String get cantScanEnterThis => 'Can’t scan? Enter this key manually';

  @override
  String get copySecret => 'Copy secret';

  @override
  String get secretCopiedItWill => 'Secret copied. It will be cleared in 60s.';

  @override
  String get openInAuthenticatorApp => 'Open in authenticator app';

  @override
  String get enterThe6Digit => 'Enter the 6-digit code';

  @override
  String get backToQrCode => 'Back to QR code';

  @override
  String get thisClearsTheChat =>
      'This clears the chat history on this device only. Other participants keep their own copy.';

  @override
  String get openThisFromA => 'Open this from a chat to jump to the message';

  @override
  String get failedToDeleteMessage => 'Failed to delete message';

  @override
  String readBy(Object length) {
    return 'Read by ($length)';
  }

  @override
  String get noGroupMembersHave =>
      'No group members have read this message yet';

  @override
  String get delivered => 'Delivered';

  @override
  String get deliveredToGroupMembers => 'Delivered to group members';

  @override
  String get sent => 'Sent';

  @override
  String get sentToServer => 'Sent to server';

  @override
  String get read => 'Read';

  @override
  String get model => 'Model';

  @override
  String get aiEngine => 'AI Engine';

  @override
  String noResultsFoundFor(Object searchQuery) {
    return 'No results found for \"$searchQuery\"';
  }

  @override
  String get noStarredMessages => 'No starred messages';

  @override
  String get tapAndHoldOn =>
      'Tap and hold on any message to star it, so you can find it here later.';

  @override
  String noSharedYet(Object tab) {
    return 'No $tab shared yet';
  }

  @override
  String get showInChat => 'Show in chat';

  @override
  String sStory(Object authorName) {
    return '$authorName’s Story';
  }

  @override
  String get imageFileNotFound => 'Image file not found.';

  @override
  String get couldNotSaveYour => 'Could not save your edit. Please try again.';

  @override
  String get videoFileNotFound => 'Video file not found.';

  @override
  String selected2(Object selectedMs) {
    return 'Selected $selectedMs';
  }

  @override
  String total(Object totalMs) {
    return 'Total $totalMs';
  }

  @override
  String maxLengthIs(Object maxMs) {
    return 'Max length is $maxMs';
  }

  @override
  String get thisCallHasAlready => 'This call has already ended';

  @override
  String get failedToOpenStory => 'Failed to open story';

  @override
  String lastSeen(Object lastSeenStr) {
    return 'Last seen $lastSeenStr';
  }

  @override
  String get navigationError => 'Navigation Error';

  @override
  String route(Object name) {
    return 'Route: $name';
  }

  @override
  String get savedToGallerySuccessfully => 'Saved to gallery successfully! ✅';

  @override
  String get pleaseAllowStorageAccess =>
      'Please allow storage access from settings ⚙️';

  @override
  String failedToSave(Object e) {
    return 'Failed to save: $e ❌';
  }

  @override
  String get enableMicrophoneCameraAccess =>
      'Enable microphone/camera access in Settings to call';

  @override
  String get permissionRequired => 'Permission required';

  @override
  String accessIsTurnedOff(Object what) {
    return '$what access is turned off for this app. Enable it in Settings to make or join calls.';
  }

  @override
  String get notNow => 'Not now';

  @override
  String get openSettings => 'Open Settings';

  @override
  String forwardedToChatS(Object length) {
    return 'Forwarded to $length chat(s)';
  }

  @override
  String isBusyOnAnother(Object receiverName) {
    return '$receiverName is busy on another call';
  }

  @override
  String socialAppAllRights(Object year) {
    return '© $year Social App. All rights reserved.';
  }

  @override
  String resetsAt(Object resetTimeLabel) {
    return 'Resets at $resetTimeLabel';
  }

  @override
  String bonus(Object bonus) {
    return '~$bonus Bonus';
  }

  @override
  String get sharingThisWithSyncra =>
      'Sharing this with Syncra is coming soon.';

  @override
  String get imageFileNotFound2 =>
      'Image file not found. Please try picking it again.';

  @override
  String get fileNotFoundPlease =>
      'File not found. Please try picking it again.';

  @override
  String get filesLargerThan20mb =>
      'Files larger than 20MB aren’t supported yet.';

  @override
  String get voiceMessageNotFound =>
      'Voice message not found. Please try recording again.';

  @override
  String get failedToSendThe =>
      'Failed to send the voice message. Please try again.';

  @override
  String get failedToSendThe2 => 'Failed to send the file. Please try again.';

  @override
  String get failedToUploadPlease => 'Failed to upload. Please try again.';

  @override
  String get failedToSendThe3 => 'Failed to send the photo. Please try again.';

  @override
  String get couldntLoadThatFile =>
      'Couldn’t load that file. Please try again.';

  @override
  String couldntLoadThisConversation(Object message) {
    return 'Couldn’t load this conversation.\n$message';
  }

  @override
  String get deleteThisChat => 'Delete this chat?';

  @override
  String deleteThisPermanentlyRemoves(Object title) {
    return 'Delete \"$title\"? This permanently removes it from Syncra and can’t be undone.';
  }

  @override
  String hi(Object userName) {
    return 'Hi, $userName !';
  }

  @override
  String get open => 'Open';

  @override
  String bonus2(Object bonusGranted) {
    return '+~$bonusGranted Bonus';
  }

  @override
  String usedOfYourDaily(
    Object percentLabel,
    Object effectiveUserLimit,
    Object usedLabel,
  ) {
    return '$percentLabel used of your $effectiveUserLimit daily requests ($usedLabel)';
  }

  @override
  String get yourAccountHasBeen =>
      'Your account has been deleted successfully.';

  @override
  String get noConnectionCheckYour =>
      'No connection. Check your internet, then tap the link in the email again.';

  @override
  String get somethingWentWrongPlease2 =>
      'Something went wrong. Please request a new link.';

  @override
  String unblockTheyWillBe(Object name) {
    return 'Unblock $name? They will be able to message you again.';
  }

  @override
  String get noBlockedUsers => 'No Blocked Users';

  @override
  String get accountsYouBlockWill =>
      'Accounts you block will show up here so you can manage them anytime.';

  @override
  String selected3(Object totalSelected) {
    return '$totalSelected selected';
  }

  @override
  String get noResultsFound => 'No results found.';

  @override
  String get nowhereToForwardYet => 'Nowhere to forward yet';

  @override
  String get addFriendsFollowPeople =>
      'Add friends, follow people, or join a group first.';

  @override
  String mentionedYouInThis(Object authorName) {
    return '$authorName mentioned you in this comment';
  }

  @override
  String mutualFriends(Object mutualFriendsCount) {
    return '$mutualFriendsCount mutual friends';
  }

  @override
  String friends2(Object totalFriendsCount) {
    return '$totalFriendsCount friends';
  }

  @override
  String mutualGroups(Object mutualGroupsCount) {
    return '$mutualGroupsCount mutual groups';
  }

  @override
  String mutual(Object mutualFriendsCount) {
    return '$mutualFriendsCount Mutual';
  }

  @override
  String mutual2(Object totalMutualCount) {
    return '$totalMutualCount mutual';
  }

  @override
  String sent2(Object createdAt) {
    return 'Sent $createdAt';
  }

  @override
  String recordAVoiceNote(Object maxSeconds) {
    return 'Record a voice note (up to $maxSeconds min)';
  }

  @override
  String isCalling(Object initiatorName) {
    return '$initiatorName is calling...';
  }

  @override
  String isComingSoon(Object feature) {
    return '$feature is coming soon';
  }

  @override
  String selected4(Object length) {
    return '$length selected';
  }

  @override
  String noResultsFoundFor2(Object query) {
    return 'No results found for \"$query\"';
  }

  @override
  String membersSelected(Object length) {
    return '$length members selected';
  }

  @override
  String removeFromTheGroup(Object userName) {
    return 'Remove $userName from the group?';
  }

  @override
  String isNowAnAdmin(Object userName) {
    return '$userName is now an admin';
  }

  @override
  String isNoLongerAn(Object userName) {
    return '$userName is no longer an admin';
  }

  @override
  String removedFromTheGroup(Object userName) {
    return '$userName removed from the group';
  }

  @override
  String get ongoing => 'Ongoing';

  @override
  String get save => 'Save';

  @override
  String get makeAdmin => 'Make Admin';

  @override
  String joinedViaThisLink(Object joinCount) {
    return '$joinCount joined via this link';
  }

  @override
  String members2(Object count) {
    return '$count Members';
  }

  @override
  String mentionedAllGroupMembers(Object senderName) {
    return '$senderName mentioned all group members';
  }

  @override
  String mentionedYouInThis2(Object senderName) {
    return '$senderName mentioned you in this message';
  }

  @override
  String get tapToOpenGroup => 'Tap to open group chat';

  @override
  String selected5(Object selectedCount) {
    return '$selectedCount selected';
  }

  @override
  String selected6(Object count) {
    return '$count selected';
  }

  @override
  String get youreAllCaughtUp => 'You’re all caught up!';

  @override
  String get pinLimitReachedUnpin => 'Pin limit reached. Unpin a post first.';

  @override
  String get couldNotUpdateThe => 'Could not update the pin. Please try again.';

  @override
  String reactions2(Object length) {
    return '$length Reactions';
  }

  @override
  String mentionedYouInThis3(Object authorName) {
    return '$authorName mentioned you in this post';
  }

  @override
  String get thisAccountHasBeen2 =>
      'This account has been deleted and its profile is no longer available.';

  @override
  String couldNotOpenLink(Object label) {
    return 'Could not open $label link';
  }

  @override
  String get viewProfessionalProfileOn =>
      'View professional profile on LinkedIn';

  @override
  String get yourStatusWillBe =>
      'Your status will be hidden from your profile until you switch this back on.';

  @override
  String get tooManyReportsIn =>
      'Too many reports in a short time. Please try again later.';

  @override
  String get thisContentIsNo => 'This content is no longer available.';

  @override
  String get youCantReportThis => 'You can’t report this content.';

  @override
  String report2(Object label) {
    return 'Report $label';
  }

  @override
  String get thisFeatureChecksYour =>
      'This feature checks your typing continuously, so it may use up your daily AI quota faster.';

  @override
  String sendAPasswordReset(Object email) {
    return 'Send a password reset link to $email?\n\nYou will stay signed in on this device.';
  }

  @override
  String resetLinkSentTo(Object email) {
    return 'Reset link sent to $email. Check your inbox.';
  }

  @override
  String linkedTo(Object oauthLabel) {
    return 'Linked to $oauthLabel';
  }

  @override
  String yourAccountIsLinked(Object oauthLabel) {
    return 'Your account is linked to $oauthLabel. You can set a password to enable email login.';
  }

  @override
  String get youWillStaySigned =>
      'You will stay signed in on this device. Any other devices will be signed out.';

  @override
  String yourEmailStaysThe(Object currentEmail, Object pendingEmail) {
    return 'Your email stays $currentEmail. The link sent to $pendingEmail will no longer work.';
  }

  @override
  String get forYourSecurityWe =>
      'For your security, we will ask for your password before changing your email.';

  @override
  String get toChangeYourEmail =>
      'To change your email address you first need a password on this account, so we can confirm it is really you.';

  @override
  String get currentEmail => 'CURRENT EMAIL';

  @override
  String get verified => 'Verified';

  @override
  String get unverified => 'Unverified';

  @override
  String get verifyThisAddressSo =>
      'Verify this address so you can recover your account and receive important notices.';

  @override
  String get signInMethod => 'Sign-in method';

  @override
  String get confirmYourNewEmail => 'Confirm your new email';

  @override
  String confirmationLinkSentTo(Object pendingEmail) {
    return 'Confirmation link sent to $pendingEmail. Please click the link to confirm your new address. Your current email remains active until confirmed.';
  }

  @override
  String get cannotFindItCheck =>
      'Cannot find it? Check your spam folder. You may also be asked to approve the change from your current inbox.';

  @override
  String get cancelRequest => 'Cancel Request';

  @override
  String get enterYourPasswordAnd =>
      'Enter your password and the new address. We’ll email a confirmation link, and your current email stays active until you confirm.';

  @override
  String get yourProfileWillBe =>
      'Your profile will be anonymized as \"Deleted Account\" and you will be signed out on all devices. Your posts, comments and messages stay visible to others under that name. This cannot be undone.';

  @override
  String get thisAccountHasBeen3 => 'This account has been deleted.';

  @override
  String get noConnectionsYet => 'No Connections Yet';

  @override
  String get addSomeFriendsOr =>
      'Add some friends or followers first so you can share private posts with them.';

  @override
  String get noUsersFound2 => 'No users found.';

  @override
  String get public => 'Public';

  @override
  String get anyoneOnTheApp => 'Anyone on the app can see this';

  @override
  String get onlyYourFriendsCan => 'Only your friends can see this';

  @override
  String get specificPeople => 'Specific people';

  @override
  String get onlySpecificPeopleYou => 'Only specific people you choose';

  @override
  String removeFromYourFriends(Object friendName) {
    return 'Remove $friendName from your friends?';
  }

  @override
  String get couldNotDeleteThe =>
      'Could not delete the pack, please try again.';

  @override
  String get couldNotOpenThe => 'Could not open the gallery, please try again.';

  @override
  String thisPackAlreadyHas(Object maxStickers) {
    return 'This pack already has the maximum of $maxStickers stickers.';
  }

  @override
  String onlyTheFirstImage(Object remainingSlots, Object maxStickers) {
    return 'Only the first $remainingSlots image(s) were added — a pack can hold at most $maxStickers stickers.';
  }

  @override
  String get thisSelectionPushesThe =>
      'This selection pushes the pack past the 25 MB limit — pick fewer or smaller images.';

  @override
  String get giveYourPackA => 'Give your pack a name first.';

  @override
  String get addAtLeastOne => 'Add at least one sticker.';

  @override
  String get pickAtLeastOne =>
      'Pick at least one friend, or change the privacy setting.';

  @override
  String get couldNotVerifyYour =>
      'Could not verify your pack quota, please try again.';

  @override
  String get uploadCancelled => 'Upload cancelled.';

  @override
  String get couldNotCreateThe =>
      'Could not create the pack, please try again.';

  @override
  String get youAlreadyOwn3 =>
      'You already own 3 sticker packs — the maximum allowed. Remove one below to create a new pack.';

  @override
  String stickers2(Object stickerCount) {
    return '$stickerCount stickers';
  }

  @override
  String uploading(Object label) {
    return 'Uploading  •  $label';
  }

  @override
  String packCreated(Object title) {
    return 'Pack \"$title\" created!';
  }

  @override
  String t25Mb(Object length, Object maxStickers, Object sizeMb) {
    return '$length/$maxStickers  •  $sizeMb/25 MB';
  }

  @override
  String defaultStoryPrivacySet(Object label) {
    return 'Default story privacy set to $label';
  }

  @override
  String mentionedYouInThis4(Object authorName) {
    return '$authorName mentioned you in this story';
  }

  @override
  String error(Object message) {
    return 'Error: $message';
  }

  @override
  String failedToSendReply(Object message) {
    return 'Failed to send reply: $message';
  }

  @override
  String replyToSStory(Object authorName) {
    return 'Reply to $authorName’s story…';
  }

  @override
  String views(Object count) {
    return '$count Views';
  }

  @override
  String get couldNotOpenYour2 => 'Could not open your email app.';

  @override
  String noResultsFor(Object query) {
    return 'No results for \"$query\"';
  }

  @override
  String tooManyAttemptsTry(Object lockRemaining) {
    return 'Too many attempts. Try again in $lockRemaining.';
  }

  @override
  String get stillNotWorkingMake =>
      'Still not working? Make sure your phone’s date and time are set to automatic in your device settings.';

  @override
  String get yourRecoveryCodesWill =>
      'Your recovery codes will not be shown again. Two-factor stays on, and you can generate new codes later from Settings.';

  @override
  String stepOf4(Object step) {
    return 'Step $step of 4';
  }

  @override
  String get twoFactorAuthenticationIs2 => 'Two-factor authentication is on';

  @override
  String get couldNotStartSetup => 'Could not start setup';

  @override
  String get twoFactorIsOn => 'Two-factor is on, but codes failed';

  @override
  String yourAccountIsAlready(Object generated) {
    return '$generated\n\nYour account is already protected. Retry now, or generate codes later from Settings.';
  }

  @override
  String get keepTheseCodesIn =>
      'Keep these codes in a safe place to recover your account if you lose your phone. Each code works once and they will not be shown again.';

  @override
  String get yourAccountWillBe =>
      'Your account will be protected by your password only. Your recovery codes will be deleted. Confirm it is you to continue.';

  @override
  String get evenIfSomeoneLearns =>
      'Even if someone learns your password, they cannot sign in without a code from your phone.';

  @override
  String get typeTheCodeYour =>
      'Type the code your authenticator app shows for Social Mate to confirm it is linked.';

  @override
  String mutualFriendsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mutual friends',
      one: '1 mutual friend',
    );
    return '$_temp0';
  }

  @override
  String mutualGroupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mutual groups',
      one: '1 mutual group',
    );
    return '$_temp0';
  }

  @override
  String newPostsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count New Posts',
      one: '1 New Post',
    );
    return '$_temp0';
  }

  @override
  String starsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String forwardNMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: 'message',
    );
    return 'Forward $_temp0';
  }

  @override
  String videoIsSMax(Object inSeconds, Object inSeconds2) {
    return 'Video is ${inSeconds}s — max allowed is ${inSeconds2}s.';
  }

  @override
  String deleteNChats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chats',
      one: '1 chat',
    );
    return 'Delete $_temp0?';
  }

  @override
  String deleteNMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return 'Delete $_temp0?';
  }

  @override
  String membersCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get onboardingOneTitle => 'Find Friends & Get Inspiration';

  @override
  String get onboardingOneSubtitle =>
      'Discover creative content, explore new ideas, and connect with a global community that shares your interests.';

  @override
  String get onboardingTwoTitle => 'Meet Awesome People & Enjoy yourself';

  @override
  String get onboardingTwoSubtitle =>
      'Expand your social network, engage in meaningful conversations, and share your favorite moments with others.';

  @override
  String get onboardingThreeTitle => 'Hangout with Friends';

  @override
  String get onboardingThreeSubtitle =>
      'Stay close to your loved ones through seamless video, voice, and text chats no matter where you are.';

  @override
  String get deletedForEveryone => 'Deleted for everyone';

  @override
  String get deletedForYou => 'Deleted for you';

  @override
  String get photo2 => '📷 Photo';

  @override
  String get video2 => '🎥 Video';

  @override
  String get voiceMessage => '🎤 Voice message';

  @override
  String get gif => '🖼️ GIF';

  @override
  String get sticker2 => '🏷️ Sticker';

  @override
  String get call2 => '📞 Call';

  @override
  String get attachment => '📎 Attachment';

  @override
  String reactWithTo(Object actor, Object emoji, Object snippet) {
    return '$actor react with $emoji to $snippet';
  }

  @override
  String reactWithTo2(Object actor, Object emoji, Object snippet) {
    return '$actor react with $emoji to \"$snippet\"';
  }

  @override
  String seenBy(Object receiverName) {
    return 'Seen by $receiverName';
  }

  @override
  String get notReadYet => 'Not read yet';

  @override
  String deliveredTo(Object receiverName) {
    return 'Delivered to $receiverName';
  }

  @override
  String get deliveredToAi => 'Delivered to AI';

  @override
  String get responseCreated => 'Response created';

  @override
  String get noConversationsYet2 => 'No conversations yet.';

  @override
  String get noChatsYet => 'No chats yet.';

  @override
  String get noGroupsYet => 'No groups yet.';

  @override
  String get noFavoriteChatsYet => 'No favorite chats yet.';

  @override
  String get noUnreadChats => 'No unread chats.';

  @override
  String get bringYourFriendsTogether =>
      'Bring your friends together.\nCreate a space to share moments.';

  @override
  String get yourInboxIsWaiting =>
      'Your inbox is waiting.\nStart a conversation and explore new connections.';

  @override
  String get startChat => 'Start Chat';

  @override
  String get voiceMessages => 'voice messages';

  @override
  String get viewPhoto => 'View photo';

  @override
  String get playVideo => 'Play video';

  @override
  String get playVoiceMessage => 'Play voice message';

  @override
  String get mixedSelection => 'Mixed selection';

  @override
  String get deleteThisMessageFor => 'Delete this message for everyone?';

  @override
  String get deleteThisMessageFor2 => 'Delete this message for you?';

  @override
  String get deleteFromMe => 'Delete from me';

  @override
  String get justNow => 'Just now';

  @override
  String min(Object inMinutes) {
    return '$inMinutes min';
  }

  @override
  String todayAt(Object time) {
    return 'Today at $time';
  }

  @override
  String yesterdayAt(Object time) {
    return 'Yesterday at $time';
  }

  @override
  String get allAllMembers => 'all (@all members)';

  @override
  String get readMore => 'Read more...';

  @override
  String get showLess => 'Show less';

  @override
  String get youHaveReachedThe =>
      'You have reached the daily limit for free AI usage. Please try again tomorrow.';

  @override
  String get youHaveUsedUp =>
      'You have used up your daily quota of AI suggestions. It will reset tomorrow.';

  @override
  String get spellingCorrection => 'Spelling Correction';

  @override
  String get smartReplyToImages =>
      'Smart reply to images is currently unavailable';

  @override
  String get aiSuggestion => 'AI Suggestion';

  @override
  String get chatSummary => 'Chat Summary';

  @override
  String get detailedSummary => 'Detailed Summary';

  @override
  String get whatIsTheTopic => 'What is the topic?';

  @override
  String get thereArentEnoughMessages =>
      'There aren’t enough messages in the chat to summarize.';

  @override
  String get youHaveUsedUp2 =>
      'You have used up your daily AI quota. Please try again tomorrow.';

  @override
  String get anErrorOccurredPlease =>
      'An error occurred. Please try again later.';

  @override
  String usedOfYourDaily2(Object dailyLimit) {
    return 'used of your $dailyLimit daily requests';
  }

  @override
  String get forwardedFile => 'Forwarded File';

  @override
  String get youveReachedTodaysSyncra =>
      'You’ve reached today’s Syncra limit — try again tomorrow.';

  @override
  String get syncraIsABit =>
      'Syncra is a bit busy right now — please try again shortly.';

  @override
  String get syncraCouldntReachAny =>
      'Syncra couldn’t reach any AI provider — please try again.';

  @override
  String get voiceMessage2 => 'Voice message';

  @override
  String voiceMessage3(Object seconds) {
    return 'Voice message · $seconds';
  }

  @override
  String get couldntLoadYourConversations =>
      'Couldn’t load your conversations.';

  @override
  String get noConversationsYetStart =>
      'No conversations yet — start one above.';

  @override
  String get thisLinkWasAlready => 'This link was already used';

  @override
  String get thisLinkIsNo => 'This link is no longer valid';

  @override
  String get yourPasswordWasAlready =>
      'Your password was already updated and you’re signed in.';

  @override
  String get thisLinkHasExpired =>
      'This link has expired or has already been used. Please request a new one.';

  @override
  String get goToHome => 'Go to Home';

  @override
  String get requestNewLink => 'Request new link';

  @override
  String get signIn2 => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String resendInS(Object secondsRemaining) {
    return 'Resend in ${secondsRemaining}s';
  }

  @override
  String get sendResetLink2 => 'Send Reset Link';

  @override
  String get failedToLoadYour => 'Failed to load your chats.';

  @override
  String send(Object totalSelected) {
    return 'Send ($totalSelected)';
  }

  @override
  String get forwardedFrom => 'Forwarded from ';

  @override
  String get replyingTo => 'Replying to ';

  @override
  String and(Object name, Object name2) {
    return '$name and $name2';
  }

  @override
  String andOthers(Object name, Object length) {
    return '$name and $length others';
  }

  @override
  String get isWritingAComment => ' is writing a comment...';

  @override
  String get areWritingAComment => ' are writing a comment...';

  @override
  String get microphonePermissionDenied => 'Microphone permission denied';

  @override
  String get couldNotStartRecording2 => 'Could not start recording';

  @override
  String get hideReplies => 'Hide replies';

  @override
  String get stickerReadyToSend => 'Sticker ready to send';

  @override
  String replyTo(Object replyingToAuthorName) {
    return 'Reply to @$replyingToAuthorName...';
  }

  @override
  String get writeAComment => 'Write a comment...';

  @override
  String get noSuggestionsRightNow => 'No suggestions right now';

  @override
  String feedback(Object shortId) {
    return 'Feedback #$shortId';
  }

  @override
  String get supportConversation => 'Support conversation';

  @override
  String get couldNotLoadThis2 => 'Could not load this feedback.';

  @override
  String get thisFeedbackIsNo => 'This feedback is no longer available.';

  @override
  String get pleaseTellUsWhat => 'Please tell us what is on your mind.';

  @override
  String pleaseWriteAtLeast(Object minMessageLength) {
    return 'Please write at least $minMessageLength characters.';
  }

  @override
  String get enterAValidEmail => 'Enter a valid email or phone number.';

  @override
  String get yourRating => 'Your rating *';

  @override
  String get yourRatingOptional => 'Your rating (optional)';

  @override
  String get dailyLimitReached => 'Daily limit reached';

  @override
  String get submitFeedback => 'Submit Feedback';

  @override
  String get whatWentWrongWhat =>
      'What went wrong? What did you expect to happen?';

  @override
  String get describeTheFeatureYou =>
      'Describe the feature you would love to see…';

  @override
  String get whatWouldYouLike => 'What would you like to know?';

  @override
  String get shareYourExperienceWith =>
      'Share your experience with Social Mate…';

  @override
  String get tellUsWhatYou => 'Tell us what you enjoy!';

  @override
  String get writeYourMessageHere => 'Write your message here…';

  @override
  String dailyLimitReachedNext(Object left) {
    return 'Daily limit reached · next feedback in $left';
  }

  @override
  String ofFeedbacksLeftToday(Object remaining, Object limit) {
    return '$remaining of $limit feedbacks left today';
  }

  @override
  String get couldNotLoadGifs => 'Could not load GIFs';

  @override
  String get incomingGroupVideo => 'Incoming Group Video';

  @override
  String get incomingGroupVoice => 'Incoming Group Voice';

  @override
  String get tapToReturnTo => 'Tap to return to the group call';

  @override
  String get groupVideoCall => 'Group Video Call';

  @override
  String get groupVoiceCall => 'Group Voice Call';

  @override
  String get callingGroupVideo => 'Calling group (Video)...';

  @override
  String get callingGroupAudio => 'Calling group (Audio)...';

  @override
  String get inTheCall => 'In the call';

  @override
  String get notInTheCall => 'Not in the call';

  @override
  String get ringing => 'Ringing…';

  @override
  String added(Object actor, Object target) {
    return '$actor added $target';
  }

  @override
  String removed(Object actor, Object target) {
    return '$actor removed $target';
  }

  @override
  String leftTheGroup(Object actor) {
    return '$actor left the group';
  }

  @override
  String get noMessagesYet2 => 'No messages yet';

  @override
  String photo3(Object senderName) {
    return '$senderName: 📷 Photo';
  }

  @override
  String video3(Object senderName) {
    return '$senderName: 🎬 Video';
  }

  @override
  String gif2(Object senderName) {
    return '$senderName: 🎞️ GIF';
  }

  @override
  String sticker3(Object senderName) {
    return '$senderName: 😊 Sticker';
  }

  @override
  String voiceMessage4(Object senderName) {
    return '$senderName: 🎤 Voice message';
  }

  @override
  String groupCall(Object senderName) {
    return '$senderName: 📞 Group Call';
  }

  @override
  String addedOnePersonIsnt(Object length) {
    return 'Added $length. One person isn’t available to join right now.';
  }

  @override
  String addedPeopleArentAvailable(Object length, Object length2) {
    return 'Added $length. $length2 people aren’t available to join right now.';
  }

  @override
  String get thisPersonIsntAvailable =>
      'This person isn’t available to join the group right now.';

  @override
  String get thesePeopleArentAvailable =>
      'These people aren’t available to join the group right now.';

  @override
  String addMembers2(Object length) {
    return 'Add $length Members';
  }

  @override
  String createGroup2(Object length) {
    return 'Create Group ($length)';
  }

  @override
  String youWillLeaveThe(Object name) {
    return 'You will leave \"$name\", the chat history on this device will be cleared, and you won’t be able to be re-added to this group. Continue?';
  }

  @override
  String get theChatHistoryOn =>
      'The chat history on this device will be cleared, and you won’t be able to be re-added to this group. Continue?';

  @override
  String get missedVoiceCall => 'Missed voice call';

  @override
  String get missedVideoCall => 'Missed video call';

  @override
  String get endedCall => 'Ended call';

  @override
  String get groupVoiceCall2 => 'Group voice call';

  @override
  String get groupVideoCall2 => 'Group video call';

  @override
  String get missedCall => 'Missed Call';

  @override
  String get ongoingTapToJoin => 'Ongoing • Tap to Join';

  @override
  String ended(Object duration) {
    return 'Ended • $duration';
  }

  @override
  String get thisInviteLinkIs => 'This invite link is no longer valid';

  @override
  String get openChat => 'Open Chat';

  @override
  String get joinGroup => 'Join Group';

  @override
  String joinOnSocialMedia(Object groupName, Object hash) {
    return 'Join \"$groupName\" on Social Media App: $hash';
  }

  @override
  String expiresInDH(Object inDays, Object remainder) {
    return 'Expires in ${inDays}d ${remainder}h';
  }

  @override
  String expiresInHM(Object inHours, Object remainder) {
    return 'Expires in ${inHours}h ${remainder}m';
  }

  @override
  String expiresInM(Object inMinutes) {
    return 'Expires in ${inMinutes}m';
  }

  @override
  String recordingAudio(Object userName) {
    return '$userName recording audio...';
  }

  @override
  String peopleRecordingAudio(Object length) {
    return '$length people recording audio...';
  }

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String noNotifications(Object name) {
    return 'No $name notifications';
  }

  @override
  String get followBack => 'Follow Back';

  @override
  String get sharedSuccessfully => 'Shared successfully';

  @override
  String get postRemovedFromSaves => 'Post removed from saves';

  @override
  String get postSavedSuccessfully => 'Post saved successfully';

  @override
  String get publishingPost => 'Publishing Post...';

  @override
  String get unpinPost => 'Unpin Post';

  @override
  String get pinPost => 'Pin Post';

  @override
  String get removeShare => 'Remove Share';

  @override
  String get removeThisShareFrom => 'Remove this share from your profile?';

  @override
  String get areYouSureYou2 => 'Are you sure you want to delete this post?';

  @override
  String get postDeletedSuccessfully => 'Post deleted successfully';

  @override
  String get reshareRemoved => 'Reshare removed';

  @override
  String get resharedSuccessfully => 'Reshared successfully';

  @override
  String get aReel => 'a reel';

  @override
  String get aPost => 'a post';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String shared(Object contentLabel) {
    return '  shared $contentLabel';
  }

  @override
  String get editProfilePicture => 'Edit Profile Picture';

  @override
  String get editCoverPhoto => 'Edit Cover Photo';

  @override
  String get optionalShownAsRich =>
      'Optional — shown as rich cards on your profile.';

  @override
  String noProvidedYet(Object title) {
    return 'No $title provided yet.';
  }

  @override
  String isFriendsWithBoth(Object names) {
    return '$names is friends with both of you';
  }

  @override
  String andAreFriendsWith(Object names, Object second) {
    return '$names and $second are friends with both of you';
  }

  @override
  String andOthersAreFriends(Object names, Object others) {
    return '$names and $others others are friends with both of you';
  }

  @override
  String get noPostsToShow => 'No posts to show yet';

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get shareYourThoughtsWith => 'Share your thoughts with your friends.';

  @override
  String get thisPersonHasntShared => 'This person hasn’t shared anything yet.';

  @override
  String get addAStatus => 'Add a status ✨';

  @override
  String get showOnProfile => 'Show on profile';

  @override
  String get hideFromProfile => 'Hide from profile';

  @override
  String doneSelected(Object length) {
    return 'Done ($length selected)';
  }

  @override
  String get tellUsWhatIs => 'Tell us what is wrong (required)';

  @override
  String get addDetailsOptional => 'Add details (optional)';

  @override
  String get submitReport => 'Submit report';

  @override
  String get noAccountsToDiscover => 'No accounts to discover yet';

  @override
  String noAccountsFoundFor(Object query) {
    return 'No accounts found for \"$query\"';
  }

  @override
  String get nothingToShowYet => 'Nothing to show yet';

  @override
  String noFriendsFoundFor(Object query) {
    return 'No friends found for \"$query\"';
  }

  @override
  String get youHaventJoinedAny => 'You haven’t joined any groups yet';

  @override
  String get searchForGroups => 'Search for groups';

  @override
  String noGroupsFoundFor(Object query) {
    return 'No groups found for \"$query\"';
  }

  @override
  String get noReelsAvailable => 'No reels available';

  @override
  String noReelsFoundFor(Object query) {
    return 'No reels found for \"$query\"';
  }

  @override
  String get currentPasswordIsRequired => 'Current password is required';

  @override
  String resetLinkSentResend(Object secs) {
    return 'Reset link sent · resend in ${secs}s';
  }

  @override
  String get forgotYourCurrentPassword => 'Forgot your current password?';

  @override
  String get newPasswordMustBe =>
      'New password must be different from current password';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get setPassword => 'Set Password';

  @override
  String get noEmailOnFile => 'No email on file';

  @override
  String isAlsoLinkedTo(Object oauthLabel, Object oauthLabel2) {
    return '$oauthLabel is also linked to this account. Changing your email here does not change your $oauthLabel2 account.';
  }

  @override
  String yourPrimarySignIn(Object oauthLabel) {
    return 'Your primary sign-in is managed by $oauthLabel. Your email is tied to that provider.';
  }

  @override
  String resendInS2(Object secs) {
    return 'Resend in ${secs}s';
  }

  @override
  String get resendVerification => 'Resend Verification';

  @override
  String get resendLink => 'Resend Link';

  @override
  String get passwordIsRequired => 'Password is required';

  @override
  String get newEmailMustBe =>
      'New email must be different from your current email';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get oneLastConfirmation => 'One last confirmation';

  @override
  String typeToConfirm(Object confirmationWord) {
    return 'Type $confirmationWord to confirm';
  }

  @override
  String get videoCall2 => 'Video Call';

  @override
  String get voiceCall2 => 'Voice Call';

  @override
  String get callingVideo => 'Calling (Video)...';

  @override
  String get callingAudio => 'Calling (Audio)...';

  @override
  String get incomingVideoCall => 'Incoming Video Call';

  @override
  String get incomingVoiceCall => 'Incoming Voice Call';

  @override
  String youCantMessageUntil(Object name) {
    return 'You can’t message $name until you unblock them.';
  }

  @override
  String get youCantReplyTo => 'You can’t reply to this conversation.';

  @override
  String youBlocked(Object otherUserName) {
    return 'You blocked $otherUserName';
  }

  @override
  String blockedYou(Object otherUserName) {
    return '$otherUserName blocked you';
  }

  @override
  String youUnblocked(Object otherUserName) {
    return 'You unblocked $otherUserName';
  }

  @override
  String unblockedYou(Object otherUserName) {
    return '$otherUserName unblocked you';
  }

  @override
  String sentYouAMessage(Object receiverUser) {
    return '$receiverUser sent you a message request. Reply to accept, or decline.';
  }

  @override
  String get youAreNotFriends =>
      'You are not friends or followers. Sending a message will send a message request.';

  @override
  String get recordingAudio2 => 'recording audio...';

  @override
  String unblock2(Object name) {
    return 'Unblock $name';
  }

  @override
  String block(Object name) {
    return 'Block $name';
  }

  @override
  String get calling => 'Calling…';

  @override
  String get videoCalling => 'Video calling…';

  @override
  String youBlocked2(Object name) {
    return 'You blocked $name';
  }

  @override
  String blockedYou2(Object name) {
    return '$name blocked you';
  }

  @override
  String youUnblocked2(Object name) {
    return 'You unblocked $name';
  }

  @override
  String unblockedYou2(Object name) {
    return '$name unblocked you';
  }

  @override
  String get textStatus => 'Text status';

  @override
  String get failedToLoadYour2 => 'Failed to load your connections.';

  @override
  String done2(Object length) {
    return 'Done ($length)';
  }

  @override
  String get whoCanSeeThis => 'Who can see this pack?';

  @override
  String get whoCanSeeThis2 => 'Who can see this?';

  @override
  String get chooseYourAudienceFor =>
      'Choose your audience for this sticker pack';

  @override
  String get chooseYourAudienceFor2 => 'Choose your audience for this story';

  @override
  String get chooseYourAudienceFor3 => 'Choose your audience for this post';

  @override
  String stickers3(Object stickerCount, Object asReadableSize) {
    return '$stickerCount Stickers  •  $asReadableSize';
  }

  @override
  String stickers4(Object stickerCount) {
    return '$stickerCount Stickers';
  }

  @override
  String mbStickers(
    Object toStringAsFixed,
    Object toStringAsFixed2,
    Object stickerCount,
  ) {
    return '$toStringAsFixed/$toStringAsFixed2 MB  •  $stickerCount Stickers';
  }

  @override
  String get noFriendsSelected => 'No friends selected';

  @override
  String friendSSelected(Object length) {
    return '$length friend(s) selected';
  }

  @override
  String stickers5(Object stickerCount, Object asReadableSize) {
    return '$stickerCount stickers  •  $asReadableSize';
  }

  @override
  String get videoPreview => 'Video Preview';

  @override
  String get photoPreview => 'Photo Preview';

  @override
  String get myStories => 'My Stories';

  @override
  String sStories(Object authorName) {
    return '$authorName’s Stories';
  }

  @override
  String get textStory2 => 'Text story';

  @override
  String get videoStory => 'Video story';

  @override
  String get photoStory => 'Photo story';

  @override
  String deleteStories(Object count) {
    return 'Delete $count stories?';
  }

  @override
  String get deleteThisStory => 'Delete this story?';

  @override
  String get gifAnimation => 'GIF Animation';

  @override
  String get enterThe6Digit2 =>
      'Enter the 6-digit code from your authenticator app.';

  @override
  String get enterOneOfThe =>
      'Enter one of the recovery codes you saved. Using it turns two-factor off.';

  @override
  String get useABackupCode => 'Use a backup code';

  @override
  String get useAuthenticatorCode => 'Use authenticator code';

  @override
  String get preparingYourSecureKey => 'Preparing your secure key...';

  @override
  String get generatingRecoveryCodes => 'Generating recovery codes...';

  @override
  String get pleaseTryAgain => 'Please try again.';

  @override
  String get recoveryCodesCouldNot => 'Recovery codes could not be generated.';

  @override
  String get codeAboutToChange => 'Code about to change, wait for next';

  @override
  String codeUpdatesInS(Object remaining) {
    return 'Code updates in ${remaining}s';
  }

  @override
  String get useAnAuthenticatorCode => 'Use an authenticator code instead';

  @override
  String get useMyPasswordInstead => 'Use my password instead';

  @override
  String get preparing => 'Preparing...';

  @override
  String get joining => 'Joining...';

  @override
  String get connecting => 'Connecting...';

  @override
  String get ringing2 => 'Ringing...';

  @override
  String get you => 'You';

  @override
  String get someone => 'Someone';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get summary => 'Summary';

  @override
  String get weak => 'Weak';

  @override
  String get fair => 'Fair';

  @override
  String get good => 'Good';

  @override
  String get strong => 'Strong';

  @override
  String get send2 => 'Send';

  @override
  String get unknown => 'Unknown';

  @override
  String get feedback2 => 'Feedback';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get off => 'Off';

  @override
  String get member => 'Member';

  @override
  String get ring => 'Ring';

  @override
  String get ended2 => 'Ended';

  @override
  String get expired => 'Expired';

  @override
  String get trim => 'Trim';

  @override
  String get posted => 'Posted';

  @override
  String get details => 'Details';

  @override
  String get attachment2 => 'Attachment';

  @override
  String get aiLangAutoTitle => 'Auto (Based on Context)';

  @override
  String get aiLangAutoDesc =>
      'Automatically detects the language of your message or reply';

  @override
  String get aiLangArabicTitle => 'Arabic';

  @override
  String get aiLangArabicDesc =>
      'AI captions, replies, and corrections are always generated in Arabic';

  @override
  String get aiLangEnglishTitle => 'English';

  @override
  String get aiLangEnglishDesc =>
      'AI captions, replies, and corrections are always generated in English';

  @override
  String get aiToneDefaultTitle => 'Default';

  @override
  String get aiToneDefaultDesc =>
      'Lets the AI choose the tone based on context';

  @override
  String get aiToneFormalTitle => 'Formal';

  @override
  String get aiToneFormalDesc => 'Polished, professional wording';

  @override
  String get aiToneEnthusiasticTitle => 'Enthusiastic';

  @override
  String get aiToneEnthusiasticDesc => 'Energetic and upbeat wording';

  @override
  String get aiToneCasualTitle => 'Casual';

  @override
  String get aiToneCasualDesc => 'Relaxed, spontaneous everyday wording';

  @override
  String get aiToneEncouragingTitle => 'Encouraging';

  @override
  String get aiToneEncouragingDesc => 'Warm and supportive wording';

  @override
  String get aiLengthDefaultTitle => 'Default';

  @override
  String get aiLengthDefaultDesc => 'Natural, everyday length';

  @override
  String get aiLengthShortTitle => 'Short';

  @override
  String get aiLengthShortDesc => 'Brief and to the point';

  @override
  String get aiLengthDetailedTitle => 'Detailed';

  @override
  String get aiLengthDetailedDesc => 'Longer and more thorough';

  @override
  String dateAtTime(Object date, Object time) {
    return '$date at $time';
  }

  @override
  String get typing => 'typing...';

  @override
  String isTyping(String userName) {
    return '$userName is typing...';
  }

  @override
  String peopleTyping(num length) {
    return '$length people are typing...';
  }

  @override
  String get valNameRequired => 'Name is required';

  @override
  String get valNameInvalid => 'Please enter a valid name (letters only)';

  @override
  String get valNameMinLength => 'Name must be at least 2 characters';

  @override
  String get valEmailRequired => 'Email is required';

  @override
  String get valEmailInvalid => 'Please enter a valid email address';

  @override
  String get valPasswordRequired => 'Password is required';

  @override
  String get valPasswordMinLength => 'Password must be at least 6 characters';

  @override
  String get valConfirmPasswordRequired => 'Confirm Password is required';

  @override
  String get valPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authErrIncorrectCredentials =>
      'Incorrect email or password. Please try again.';

  @override
  String get authErrNoInternet =>
      'No internet connection. Please check your network.';

  @override
  String get authErrEmailAlreadyRegistered =>
      'This email is already registered. Try signing in instead.';

  @override
  String get authErrEmailNotVerified =>
      'Your email is not verified yet. Please check your inbox.';

  @override
  String get authErrGeneral =>
      'An authentication error occurred. Please try again.';

  @override
  String get joinNow => 'Join Now';

  @override
  String get dontHaveAnAccount => 'Do not have an account? ';

  @override
  String get byUsingAppAgree => 'By using this app you agree with the\n';

  @override
  String get twoFactorStep1Title => 'Open your authenticator app';

  @override
  String get twoFactorStep1Desc =>
      'Google Authenticator, Microsoft Authenticator, Authy or Apple Passwords all work.';

  @override
  String get twoFactorStep2Title => 'Scan a QR code';

  @override
  String get twoFactorStep2Desc =>
      'Or type the secret key by hand if you are on the same phone.';

  @override
  String get twoFactorStep3Title => 'Save your recovery codes';

  @override
  String get twoFactorStep3Desc =>
      'They are the only way back in if you lose your phone.';

  @override
  String get iveAddedIt => 'I\'ve added it';

  @override
  String get verifyCode => 'Verify';

  @override
  String get feedbackWhatIsThisAbout => 'What is this about?';

  @override
  String get feedbackTellUsMore => 'Tell us more';

  @override
  String get feedbackAttachments => 'Attachments';

  @override
  String get feedbackReachYouOptional => 'How can we reach you? (optional)';

  @override
  String get feedbackCatBug => 'Bug / Issue';

  @override
  String get feedbackCatFeature => 'Feature Request';

  @override
  String get feedbackCatInquiry => 'Inquiry';

  @override
  String get feedbackCatRating => 'Rating & Review';

  @override
  String get feedbackCatAppreciation => 'Appreciation';

  @override
  String get feedbackCatOther => 'Other';

  @override
  String get feedbackStatusPending => 'Pending Review';

  @override
  String get feedbackStatusInProgress => 'In Progress';

  @override
  String get feedbackStatusResolved => 'Resolved & Answered';

  @override
  String get feedbackStatusClosed => 'Closed';

  @override
  String get aboutStatUsers => 'Users';

  @override
  String get aboutStatMessages => 'Messages';

  @override
  String get aboutStatPosts => 'Posts';

  @override
  String get aboutStatUptime => 'Uptime';

  @override
  String get aboutFeatCallsTitle => 'HD Voice & Video';

  @override
  String get aboutFeatCallsDesc => 'Crystal clear calls anytime';

  @override
  String get aboutFeatChatsTitle => 'Real-time Chats';

  @override
  String get aboutFeatChatsDesc => 'Instant messaging with read receipts';

  @override
  String get aboutFeatStoriesTitle => 'Stories';

  @override
  String get aboutFeatStoriesDesc => 'Share your daily moments';

  @override
  String get aboutFeatGroupsTitle => 'Group Chats';

  @override
  String get aboutFeatGroupsDesc => 'Connect with communities';

  @override
  String get aboutFeatPrivacyTitle => 'Privacy First';

  @override
  String get aboutFeatPrivacyDesc => 'Your data stays yours';

  @override
  String get aboutFeatAlertsTitle => 'Smart Alerts';

  @override
  String get aboutFeatAlertsDesc => 'Never miss what matters';

  @override
  String get targetProfile => 'profile';

  @override
  String get targetPost => 'post';

  @override
  String get targetComment => 'comment';

  @override
  String get targetStory => 'story';

  @override
  String get targetMessage => 'message';

  @override
  String get reportReasonViolence => 'Violence or threats';

  @override
  String get reportReasonViolenceDesc =>
      'Threats, incitement or graphic violence';

  @override
  String get reportReasonNsfw => 'Nudity or sexual content';

  @override
  String get reportReasonNsfwDesc => 'Explicit or adult material';

  @override
  String get reportReasonChildSafety => 'Child safety';

  @override
  String get reportReasonChildSafetyDesc => 'Involves or endangers a minor';

  @override
  String get reportReasonHateHarassment => 'Hate or harassment';

  @override
  String get reportReasonHateHarassmentDesc =>
      'Bullying, abuse or discrimination';

  @override
  String get reportReasonSpamScam => 'Spam or scam';

  @override
  String get reportReasonSpamScamDesc =>
      'Fake offers, phishing or repeated ads';

  @override
  String get reportReasonMisinformation => 'False information';

  @override
  String get reportReasonMisinformationDesc =>
      'Misleading or fabricated content';

  @override
  String get reportReasonImpersonation => 'Impersonation or privacy';

  @override
  String get reportReasonImpersonationDesc =>
      'Pretending to be someone or sharing private info';

  @override
  String get reportReasonSelfHarm => 'Self-harm';

  @override
  String get reportReasonSelfHarmDesc => 'Promotes or shows self-injury';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get reportReasonOtherDesc => 'Tell us what is wrong';

  @override
  String get fieldUsername => 'Username';

  @override
  String get fieldJobTitle => 'Job Title';

  @override
  String get fieldBio => 'Bio';

  @override
  String get fieldJoined => 'Joined';

  @override
  String get reactionsFilterAll => 'All';

  @override
  String get sharedTabAll => 'All';

  @override
  String get sharedTabImages => 'Images';

  @override
  String get sharedTabVideos => 'Videos';

  @override
  String get sharedTabLinks => 'Links';

  @override
  String get sharedLabelMedia => 'media';

  @override
  String get sharedLabelImages => 'images';

  @override
  String get sharedLabelVideos => 'videos';

  @override
  String get sharedLabelLinks => 'links';

  @override
  String get sharedDateRecent => 'Recent';

  @override
  String get sharedDateLastWeek => 'Last Week';

  @override
  String get sharedDateLastMonth => 'Last Month';

  @override
  String get btnFollow => 'Follow';

  @override
  String get btnFollowing => 'Following';

  @override
  String get btnAddFriend => 'Add Friend';

  @override
  String get btnRequested => 'Requested';

  @override
  String get tabChatsAll => 'All';

  @override
  String get tabChatsDirect => 'Chats';

  @override
  String get tabChatsGroups => 'Groups';

  @override
  String get tabChatsFavorites => 'Favorites';

  @override
  String get tabChatsUnread => 'Unread';

  @override
  String get notifFilterAll => 'All';

  @override
  String get notifFilterMessages => 'Messages';

  @override
  String get notifFilterCalls => 'Calls';

  @override
  String get notifFilterLikes => 'Likes';

  @override
  String get notifFilterComments => 'Comments';

  @override
  String get notifFilterFollows => 'Follows';

  @override
  String get notifFilterFriendRequests => 'Friend Requests';

  @override
  String get searchTabForYou => 'For You';

  @override
  String get searchTabAccounts => 'Accounts';

  @override
  String get searchTabGroups => 'Groups';

  @override
  String get searchTabReels => 'Reels';

  @override
  String get searchTabFriends => 'Friends';

  @override
  String get aiModelGeminiTagline => 'Fast, and great with images';

  @override
  String get aiModelLlamaTagline => 'Open-weight and efficient';

  @override
  String get aiModelOpenRouterTagline => 'Auto-picks a free model for you';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get addVideo => 'Add Video';

  @override
  String get addDocument => 'Add a Document';

  @override
  String get addGif => 'Add GIF';

  @override
  String get liveVideo => 'Live Video';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortTop => 'Top';

  @override
  String get like => 'Like';

  @override
  String viewRepliesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'replies',
      one: 'reply',
    );
    return 'View $count $_temp0';
  }

  @override
  String get revokeInviteBody =>
      'Anyone with the current link will no longer be able to join using it. Continue?';

  @override
  String get revoke => 'Revoke';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get tapForGroupInfo => 'Tap for group info';

  @override
  String get retryAgain => 'Retry Again';

  @override
  String get presenceEveryoneDesc => 'Anyone using the app can see your status';

  @override
  String get presenceFriendsDesc => 'Only accepted friends can see your status';

  @override
  String get presenceSpecificDesc => 'Choose exactly who can see your status';

  @override
  String get presenceNobodyDesc => 'Your online status stays private';

  @override
  String get aiChatPrevious7Days => 'Previous 7 Days';

  @override
  String get aiChatPrevious30Days => 'Previous 30 Days';

  @override
  String get aiChatOlder => 'Older';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get groups => 'Groups';

  @override
  String get people => 'People';
}
