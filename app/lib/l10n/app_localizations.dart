import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ReplyWise'**
  String get appTitle;

  /// About page row that opens the privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// About page row that opens the terms of service.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Short description of the app shown on the About page.
  ///
  /// In en, this message translates to:
  /// **'Your AI assistant for replies, polished writing, and clear explanations.'**
  String get appDescription;

  /// Copyright line shown at the bottom of the About page.
  ///
  /// In en, this message translates to:
  /// **'© NovaAI Studio'**
  String get aboutCopyright;

  /// Shown when an external link fails to open.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link. Please try again.'**
  String get couldNotOpenLink;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get chooseLanguage;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and app preferences'**
  String get settingsSubtitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @explain.
  ///
  /// In en, this message translates to:
  /// **'Explain'**
  String get explain;

  /// No description provided for @polish.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get polish;

  /// No description provided for @yourAiReplyAssistant.
  ///
  /// In en, this message translates to:
  /// **'Your AI reply assistant'**
  String get yourAiReplyAssistant;

  /// No description provided for @generateThoughtfulReplies.
  ///
  /// In en, this message translates to:
  /// **'Generate thoughtful replies instantly.'**
  String get generateThoughtfulReplies;

  /// No description provided for @makeWritingClear.
  ///
  /// In en, this message translates to:
  /// **'Make your writing clear and natural.'**
  String get makeWritingClear;

  /// No description provided for @understandTone.
  ///
  /// In en, this message translates to:
  /// **'Understand tone and hidden meaning.'**
  String get understandTone;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @reuseInstructions.
  ///
  /// In en, this message translates to:
  /// **'Reuse your favorite AI instructions.'**
  String get reuseInstructions;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @nothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get nothingHereYet;

  /// No description provided for @recentEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your recent replies, polished text, and explanations will appear here.'**
  String get recentEmptyMessage;

  /// No description provided for @createFirstReply.
  ///
  /// In en, this message translates to:
  /// **'Create your first reply'**
  String get createFirstReply;

  /// No description provided for @tipOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Tip of the day'**
  String get tipOfTheDay;

  /// No description provided for @tipShortEmails.
  ///
  /// In en, this message translates to:
  /// **'Keep emails under 120 words for higher response rates.'**
  String get tipShortEmails;

  /// No description provided for @tipLeadWithAsk.
  ///
  /// In en, this message translates to:
  /// **'Lead with your ask — put the key request in the first line.'**
  String get tipLeadWithAsk;

  /// No description provided for @tipMatchTone.
  ///
  /// In en, this message translates to:
  /// **'Match the other person\'s tone to build rapport faster.'**
  String get tipMatchTone;

  /// No description provided for @tipClearSubject.
  ///
  /// In en, this message translates to:
  /// **'A clear subject line gets more replies than a clever one.'**
  String get tipClearSubject;

  /// No description provided for @tipReadAloud.
  ///
  /// In en, this message translates to:
  /// **'Read your reply aloud once — it catches awkward phrasing.'**
  String get tipReadAloud;

  /// No description provided for @tipClearNextStep.
  ///
  /// In en, this message translates to:
  /// **'End with one clear next step so the reader knows what to do.'**
  String get tipClearNextStep;

  /// No description provided for @yourPlan.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get yourPlan;

  /// No description provided for @plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plans;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @totalCredits.
  ///
  /// In en, this message translates to:
  /// **'Total credits'**
  String get totalCredits;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch ad'**
  String get watchAd;

  /// No description provided for @watchAdReward.
  ///
  /// In en, this message translates to:
  /// **'+2 credits'**
  String get watchAdReward;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get freePlan;

  /// No description provided for @freeRepliesPerDay.
  ///
  /// In en, this message translates to:
  /// **'{count} free replies per day'**
  String freeRepliesPerDay(int count);

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportDescription.
  ///
  /// In en, this message translates to:
  /// **'Help center / Contact us'**
  String get supportDescription;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Version, Privacy, Terms'**
  String get aboutDescription;

  /// No description provided for @guidance.
  ///
  /// In en, this message translates to:
  /// **'Guidance'**
  String get guidance;

  /// No description provided for @guidanceLibrary.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get guidanceLibrary;

  /// No description provided for @languageAndInput.
  ///
  /// In en, this message translates to:
  /// **'Language & input'**
  String get languageAndInput;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @voiceGuidanceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Voice guidance language'**
  String get voiceGuidanceLanguage;

  /// No description provided for @autoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto Detect'**
  String get autoDetect;

  /// No description provided for @staticPreview.
  ///
  /// In en, this message translates to:
  /// **'{label} is a static preview.'**
  String staticPreview(String label);

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @environment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environment;

  /// No description provided for @developerTesting.
  ///
  /// In en, this message translates to:
  /// **'Developer Testing'**
  String get developerTesting;

  /// No description provided for @resetFreeUsage.
  ///
  /// In en, this message translates to:
  /// **'Reset free usage'**
  String get resetFreeUsage;

  /// No description provided for @addCredits.
  ///
  /// In en, this message translates to:
  /// **'Add {count} credits'**
  String addCredits(int count);

  /// No description provided for @simulatePremiumOn.
  ///
  /// In en, this message translates to:
  /// **'Simulate Premium On'**
  String get simulatePremiumOn;

  /// No description provided for @simulatePremiumOff.
  ///
  /// In en, this message translates to:
  /// **'Simulate Premium Off'**
  String get simulatePremiumOff;

  /// No description provided for @refreshAccountState.
  ///
  /// In en, this message translates to:
  /// **'Refresh account state'**
  String get refreshAccountState;

  /// No description provided for @secureSession.
  ///
  /// In en, this message translates to:
  /// **'Secure session'**
  String get secureSession;

  /// No description provided for @anonymousSessionReady.
  ///
  /// In en, this message translates to:
  /// **'Anonymous session ready'**
  String get anonymousSessionReady;

  /// No description provided for @connectingAnonymousSession.
  ///
  /// In en, this message translates to:
  /// **'Connecting anonymous session…'**
  String get connectingAnonymousSession;

  /// No description provided for @refreshingSecureSession.
  ///
  /// In en, this message translates to:
  /// **'Refreshing secure session…'**
  String get refreshingSecureSession;

  /// No description provided for @restoringAnonymousSession.
  ///
  /// In en, this message translates to:
  /// **'Restoring anonymous session…'**
  String get restoringAnonymousSession;

  /// No description provided for @anonymousSessionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Anonymous session unavailable'**
  String get anonymousSessionUnavailable;

  /// No description provided for @anonymousSessionNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Anonymous session not started'**
  String get anonymousSessionNotStarted;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @localBackendConnection.
  ///
  /// In en, this message translates to:
  /// **'Local backend connection'**
  String get localBackendConnection;

  /// No description provided for @refreshBackendStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh backend status'**
  String get refreshBackendStatus;

  /// No description provided for @checkingBackend.
  ///
  /// In en, this message translates to:
  /// **'Checking backend…'**
  String get checkingBackend;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @serviceUnreachable.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t reach the service. Check your connection and try again.'**
  String get serviceUnreachable;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @manageLibrary.
  ///
  /// In en, this message translates to:
  /// **'Manage templates'**
  String get manageLibrary;

  /// No description provided for @newGuidance.
  ///
  /// In en, this message translates to:
  /// **'New Guidance'**
  String get newGuidance;

  /// No description provided for @quickGuidance.
  ///
  /// In en, this message translates to:
  /// **'Quick guidance'**
  String get quickGuidance;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'View plans'**
  String get viewPlans;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @premiumUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Premium · Unlimited'**
  String get premiumUnlimited;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get updating;

  /// No description provided for @updatingBalance.
  ///
  /// In en, this message translates to:
  /// **'Updating balance…'**
  String get updatingBalance;

  /// No description provided for @balanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Balance unavailable'**
  String get balanceUnavailable;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get checking;

  /// No description provided for @checkingBalance.
  ///
  /// In en, this message translates to:
  /// **'Checking balance…'**
  String get checkingBalance;

  /// No description provided for @freeCount.
  ///
  /// In en, this message translates to:
  /// **'{free} free'**
  String freeCount(int free);

  /// No description provided for @usageBalance.
  ///
  /// In en, this message translates to:
  /// **'{free} free · {credits} credits'**
  String usageBalance(int free, int credits);

  /// No description provided for @copyPreview.
  ///
  /// In en, this message translates to:
  /// **'Copy preview'**
  String get copyPreview;

  /// No description provided for @copyResult.
  ///
  /// In en, this message translates to:
  /// **'Copy result'**
  String get copyResult;

  /// No description provided for @staticPreviewCaption.
  ///
  /// In en, this message translates to:
  /// **'Static preview'**
  String get staticPreviewCaption;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history?'**
  String get clearHistory;

  /// No description provided for @clearHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'This removes all recent items on this device. This cannot be undone.'**
  String get clearHistoryDescription;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @messageReceived.
  ///
  /// In en, this message translates to:
  /// **'Message received'**
  String get messageReceived;

  /// No description provided for @messageYouReceived.
  ///
  /// In en, this message translates to:
  /// **'Message you received'**
  String get messageYouReceived;

  /// No description provided for @pasteOriginalMessage.
  ///
  /// In en, this message translates to:
  /// **'Paste the original message here…'**
  String get pasteOriginalMessage;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @helpAiUnderstandIntent.
  ///
  /// In en, this message translates to:
  /// **'Help AI understand your intent'**
  String get helpAiUnderstandIntent;

  /// No description provided for @addReplyInstructions.
  ///
  /// In en, this message translates to:
  /// **'Add your reply instructions…'**
  String get addReplyInstructions;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get generating;

  /// No description provided for @generateReply.
  ///
  /// In en, this message translates to:
  /// **'Generate Reply'**
  String get generateReply;

  /// No description provided for @creatingNaturalOptions.
  ///
  /// In en, this message translates to:
  /// **'Creating a few natural options…'**
  String get creatingNaturalOptions;

  /// No description provided for @replyOptionsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your reply options will appear here.'**
  String get replyOptionsAppearHere;

  /// No description provided for @yourReplies.
  ///
  /// In en, this message translates to:
  /// **'Your replies'**
  String get yourReplies;

  /// No description provided for @whyThisWorks.
  ///
  /// In en, this message translates to:
  /// **'Why this works'**
  String get whyThisWorks;

  /// No description provided for @regenerateReplies.
  ///
  /// In en, this message translates to:
  /// **'Regenerate replies'**
  String get regenerateReplies;

  /// No description provided for @regenerateUsageNote.
  ///
  /// In en, this message translates to:
  /// **'Regenerating creates new replies and uses 1 generation.'**
  String get regenerateUsageNote;

  /// No description provided for @couldNotExplain.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t explain this message'**
  String get couldNotExplain;

  /// No description provided for @explainMessage.
  ///
  /// In en, this message translates to:
  /// **'Explain message'**
  String get explainMessage;

  /// No description provided for @copyExplanation.
  ///
  /// In en, this message translates to:
  /// **'Copy explanation'**
  String get copyExplanation;

  /// No description provided for @meaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get meaning;

  /// No description provided for @tone.
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get tone;

  /// No description provided for @hiddenMeaning.
  ///
  /// In en, this message translates to:
  /// **'Hidden Meaning'**
  String get hiddenMeaning;

  /// No description provided for @noHiddenMeaning.
  ///
  /// In en, this message translates to:
  /// **'No hidden meaning detected.'**
  String get noHiddenMeaning;

  /// No description provided for @suggestedReplies.
  ///
  /// In en, this message translates to:
  /// **'Suggested Replies'**
  String get suggestedReplies;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @audience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get audience;

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// No description provided for @channel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get channel;

  /// No description provided for @describeTone.
  ///
  /// In en, this message translates to:
  /// **'Describe the tone'**
  String get describeTone;

  /// No description provided for @toneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. warm but professional'**
  String get toneHint;

  /// No description provided for @describeRelationship.
  ///
  /// In en, this message translates to:
  /// **'Describe the relationship'**
  String get describeRelationship;

  /// No description provided for @relationshipHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. my friend'**
  String get relationshipHint;

  /// No description provided for @customizeStyleToneFormat.
  ///
  /// In en, this message translates to:
  /// **'Customize style, tone and format'**
  String get customizeStyleToneFormat;

  /// No description provided for @bePolite.
  ///
  /// In en, this message translates to:
  /// **'Be polite'**
  String get bePolite;

  /// No description provided for @keepItShort.
  ///
  /// In en, this message translates to:
  /// **'Keep it short'**
  String get keepItShort;

  /// No description provided for @professional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professional;

  /// No description provided for @friendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get friendly;

  /// No description provided for @declinePolitely.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declinePolitely;

  /// No description provided for @sayThankYou.
  ///
  /// In en, this message translates to:
  /// **'Say thank you'**
  String get sayThankYou;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @natural.
  ///
  /// In en, this message translates to:
  /// **'Natural'**
  String get natural;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @coworker.
  ///
  /// In en, this message translates to:
  /// **'Coworker'**
  String get coworker;

  /// No description provided for @manager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get manager;

  /// No description provided for @short.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get short;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @detailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get detailed;

  /// No description provided for @textChannel.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textChannel;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @textToPolish.
  ///
  /// In en, this message translates to:
  /// **'Text to polish'**
  String get textToPolish;

  /// No description provided for @pasteTextToImprove.
  ///
  /// In en, this message translates to:
  /// **'Paste the text you\'d like to improve'**
  String get pasteTextToImprove;

  /// No description provided for @pasteYourText.
  ///
  /// In en, this message translates to:
  /// **'Paste your text here…'**
  String get pasteYourText;

  /// No description provided for @improvingClarity.
  ///
  /// In en, this message translates to:
  /// **'Improving clarity while keeping your meaning…'**
  String get improvingClarity;

  /// No description provided for @polishedTextAppearsHere.
  ///
  /// In en, this message translates to:
  /// **'Your polished text will appear here.'**
  String get polishedTextAppearsHere;

  /// No description provided for @polishedResult.
  ///
  /// In en, this message translates to:
  /// **'Polished result'**
  String get polishedResult;

  /// No description provided for @whatChanged.
  ///
  /// In en, this message translates to:
  /// **'What changed?'**
  String get whatChanged;

  /// No description provided for @polishAgain.
  ///
  /// In en, this message translates to:
  /// **'Polish again'**
  String get polishAgain;

  /// No description provided for @polishAgainUsageNote.
  ///
  /// In en, this message translates to:
  /// **'Polishing again creates a new result and uses 1 generation.'**
  String get polishAgainUsageNote;

  /// No description provided for @messageToUnderstand.
  ///
  /// In en, this message translates to:
  /// **'Message to understand'**
  String get messageToUnderstand;

  /// No description provided for @pasteMessageReceived.
  ///
  /// In en, this message translates to:
  /// **'Paste the message you received'**
  String get pasteMessageReceived;

  /// No description provided for @explainThisMessage.
  ///
  /// In en, this message translates to:
  /// **'Explain this message'**
  String get explainThisMessage;

  /// No description provided for @explaining.
  ///
  /// In en, this message translates to:
  /// **'Explaining…'**
  String get explaining;

  /// No description provided for @readingBetweenLines.
  ///
  /// In en, this message translates to:
  /// **'Reading between the lines…'**
  String get readingBetweenLines;

  /// No description provided for @explanationAppearsHere.
  ///
  /// In en, this message translates to:
  /// **'Your explanation will appear here.'**
  String get explanationAppearsHere;

  /// No description provided for @noSuggestedReplies.
  ///
  /// In en, this message translates to:
  /// **'No suggested replies returned.'**
  String get noSuggestedReplies;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @enterMessageFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter a message to explain first.'**
  String get enterMessageFirst;

  /// No description provided for @explainRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You’ve reached the explain limit for now. Please try again later.'**
  String get explainRateLimited;

  /// No description provided for @explainParseError.
  ///
  /// In en, this message translates to:
  /// **'We could not read the explanation clearly. Please try again.'**
  String get explainParseError;

  /// No description provided for @explainUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Explain is temporarily unavailable. Please try again shortly.'**
  String get explainUnavailable;

  /// No description provided for @unableToExplain.
  ///
  /// In en, this message translates to:
  /// **'Unable to explain this message.'**
  String get unableToExplain;

  /// No description provided for @replyCtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Want a reply that better matches your intention?'**
  String get replyCtaTitle;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'ReplyWise Premium'**
  String get premiumTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @threeDaysFree.
  ///
  /// In en, this message translates to:
  /// **'3 days free'**
  String get threeDaysFree;

  /// No description provided for @unlimitedReply.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Reply generations'**
  String get unlimitedReply;

  /// No description provided for @unlimitedPolish.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Polish generations'**
  String get unlimitedPolish;

  /// No description provided for @balancesPreserved.
  ///
  /// In en, this message translates to:
  /// **'Free and credit balances stay preserved'**
  String get balancesPreserved;

  /// No description provided for @loadingSubscriptionOptions.
  ///
  /// In en, this message translates to:
  /// **'Loading subscription options…'**
  String get loadingSubscriptionOptions;

  /// No description provided for @startFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Start 3-day Free Trial'**
  String get startFreeTrial;

  /// No description provided for @startYearlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Start Yearly Plan'**
  String get startYearlyPlan;

  /// No description provided for @trialTerms.
  ///
  /// In en, this message translates to:
  /// **'Free for 3 days, then {price}/year. Cancel anytime.'**
  String trialTerms(String price);

  /// No description provided for @yearlyTerms.
  ///
  /// In en, this message translates to:
  /// **'{price}/year. Cancel anytime.'**
  String yearlyTerms(String price);

  /// No description provided for @displayedPrice.
  ///
  /// In en, this message translates to:
  /// **'the displayed price'**
  String get displayedPrice;

  /// No description provided for @topUpCredits.
  ///
  /// In en, this message translates to:
  /// **'Top-up Credits'**
  String get topUpCredits;

  /// No description provided for @pricePerCredit.
  ///
  /// In en, this message translates to:
  /// **'{price} per credit'**
  String pricePerCredit(String price);

  /// No description provided for @creditDescription.
  ///
  /// In en, this message translates to:
  /// **'Each credit covers one Reply or Polish. Credits never expire.'**
  String get creditDescription;

  /// No description provided for @loadingCreditPackages.
  ///
  /// In en, this message translates to:
  /// **'Loading credit packages…'**
  String get loadingCreditPackages;

  /// No description provided for @creditPackagesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Credit packages are unavailable right now.'**
  String get creditPackagesUnavailable;

  /// No description provided for @refreshPackages.
  ///
  /// In en, this message translates to:
  /// **'Refresh packages'**
  String get refreshPackages;

  /// No description provided for @buyCreditPackage.
  ///
  /// In en, this message translates to:
  /// **'Buy {credits} Credits — {price}'**
  String buyCreditPackage(int credits, String price);

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get restoring;

  /// No description provided for @restorePremium.
  ///
  /// In en, this message translates to:
  /// **'Restore Premium subscription'**
  String get restorePremium;

  /// No description provided for @purchaseVerification.
  ///
  /// In en, this message translates to:
  /// **'Premium and credit purchases are verified by ReplyWise. Credit purchases are reconciled automatically.'**
  String get purchaseVerification;

  /// No description provided for @newGuidanceTooltip.
  ///
  /// In en, this message translates to:
  /// **'New guidance'**
  String get newGuidanceTooltip;

  /// No description provided for @builtIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get builtIn;

  /// No description provided for @myGuidance.
  ///
  /// In en, this message translates to:
  /// **'My Guidance'**
  String get myGuidance;

  /// No description provided for @useInReply.
  ///
  /// In en, this message translates to:
  /// **'Use in Reply'**
  String get useInReply;

  /// No description provided for @useInPolish.
  ///
  /// In en, this message translates to:
  /// **'Use in Polish'**
  String get useInPolish;

  /// No description provided for @deleteGuidance.
  ///
  /// In en, this message translates to:
  /// **'Delete this guidance?'**
  String get deleteGuidance;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @guidanceTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Short name for this guidance…'**
  String get guidanceTitleHint;

  /// No description provided for @guidanceHint.
  ///
  /// In en, this message translates to:
  /// **'Describe how the AI should shape the reply…'**
  String get guidanceHint;

  /// No description provided for @writeAnyLanguage.
  ///
  /// In en, this message translates to:
  /// **'Write in any language'**
  String get writeAnyLanguage;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @saveGuidance.
  ///
  /// In en, this message translates to:
  /// **'Save guidance'**
  String get saveGuidance;

  /// No description provided for @couldNotSaveGuidance.
  ///
  /// In en, this message translates to:
  /// **'Could not save this guidance. Please try again.'**
  String get couldNotSaveGuidance;

  /// No description provided for @concise.
  ///
  /// In en, this message translates to:
  /// **'Concise'**
  String get concise;

  /// No description provided for @moreNatural.
  ///
  /// In en, this message translates to:
  /// **'More natural'**
  String get moreNatural;

  /// No description provided for @improveGrammar.
  ///
  /// In en, this message translates to:
  /// **'Improve grammar'**
  String get improveGrammar;

  /// No description provided for @fixSpelling.
  ///
  /// In en, this message translates to:
  /// **'Fix spelling'**
  String get fixSpelling;

  /// No description provided for @morePersuasive.
  ///
  /// In en, this message translates to:
  /// **'More persuasive'**
  String get morePersuasive;

  /// No description provided for @moreConfident.
  ///
  /// In en, this message translates to:
  /// **'More confident'**
  String get moreConfident;

  /// No description provided for @simplifyWording.
  ///
  /// In en, this message translates to:
  /// **'Simplify wording'**
  String get simplifyWording;

  /// No description provided for @betterFlow.
  ///
  /// In en, this message translates to:
  /// **'Better flow'**
  String get betterFlow;

  /// No description provided for @describePolish.
  ///
  /// In en, this message translates to:
  /// **'Describe how you want the draft polished'**
  String get describePolish;

  /// No description provided for @describeAudience.
  ///
  /// In en, this message translates to:
  /// **'Describe the audience'**
  String get describeAudience;

  /// No description provided for @audienceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. my friend'**
  String get audienceHint;

  /// No description provided for @extraInstruction.
  ///
  /// In en, this message translates to:
  /// **'Extra instruction'**
  String get extraInstruction;

  /// No description provided for @extraPolishHint.
  ///
  /// In en, this message translates to:
  /// **'Add any other polishing preference'**
  String get extraPolishHint;

  /// No description provided for @polishing.
  ///
  /// In en, this message translates to:
  /// **'Polishing…'**
  String get polishing;

  /// No description provided for @polishText.
  ///
  /// In en, this message translates to:
  /// **'Polish Text'**
  String get polishText;

  /// No description provided for @adjustToneLengthFormat.
  ///
  /// In en, this message translates to:
  /// **'Adjust tone, length and format'**
  String get adjustToneLengthFormat;

  /// No description provided for @instructionProfessional.
  ///
  /// In en, this message translates to:
  /// **'Make the writing sound professional.'**
  String get instructionProfessional;

  /// No description provided for @instructionFriendly.
  ///
  /// In en, this message translates to:
  /// **'Make the writing warmer and friendlier.'**
  String get instructionFriendly;

  /// No description provided for @instructionConcise.
  ///
  /// In en, this message translates to:
  /// **'Make the writing concise and direct.'**
  String get instructionConcise;

  /// No description provided for @instructionNatural.
  ///
  /// In en, this message translates to:
  /// **'Make the wording sound natural and fluent.'**
  String get instructionNatural;

  /// No description provided for @instructionGrammar.
  ///
  /// In en, this message translates to:
  /// **'Correct the grammar while preserving the meaning.'**
  String get instructionGrammar;

  /// No description provided for @instructionSpelling.
  ///
  /// In en, this message translates to:
  /// **'Correct all spelling errors.'**
  String get instructionSpelling;

  /// No description provided for @instructionPersuasive.
  ///
  /// In en, this message translates to:
  /// **'Make the writing more persuasive and compelling.'**
  String get instructionPersuasive;

  /// No description provided for @instructionConfident.
  ///
  /// In en, this message translates to:
  /// **'Make the writing sound clear and confident.'**
  String get instructionConfident;

  /// No description provided for @instructionSimple.
  ///
  /// In en, this message translates to:
  /// **'Use simpler, easier-to-read wording.'**
  String get instructionSimple;

  /// No description provided for @instructionFlow.
  ///
  /// In en, this message translates to:
  /// **'Improve sentence flow and transitions.'**
  String get instructionFlow;

  /// No description provided for @shorter.
  ///
  /// In en, this message translates to:
  /// **'Shorter'**
  String get shorter;

  /// No description provided for @sameLength.
  ///
  /// In en, this message translates to:
  /// **'Same'**
  String get sameLength;

  /// No description provided for @longer.
  ///
  /// In en, this message translates to:
  /// **'Longer'**
  String get longer;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @createGuidanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Create your own guidance to reuse it later.'**
  String get createGuidanceEmpty;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @useTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use “{title}”'**
  String useTemplate(String title);

  /// No description provided for @chooseGuidance.
  ///
  /// In en, this message translates to:
  /// **'Choose guidance'**
  String get chooseGuidance;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @thanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks'**
  String get thanks;

  /// No description provided for @followUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get followUp;

  /// No description provided for @editGuidance.
  ///
  /// In en, this message translates to:
  /// **'Edit Guidance'**
  String get editGuidance;

  /// No description provided for @makeProfessional.
  ///
  /// In en, this message translates to:
  /// **'Make it professional'**
  String get makeProfessional;

  /// No description provided for @makeFriendly.
  ///
  /// In en, this message translates to:
  /// **'Make it friendly'**
  String get makeFriendly;

  /// No description provided for @askMoreTime.
  ///
  /// In en, this message translates to:
  /// **'Ask for more time'**
  String get askMoreTime;

  /// No description provided for @soundConfident.
  ///
  /// In en, this message translates to:
  /// **'Sound confident'**
  String get soundConfident;

  /// No description provided for @guidancePoliteContent.
  ///
  /// In en, this message translates to:
  /// **'Make the reply polite and respectful.'**
  String get guidancePoliteContent;

  /// No description provided for @guidanceShortContent.
  ///
  /// In en, this message translates to:
  /// **'Keep the reply short and clear.'**
  String get guidanceShortContent;

  /// No description provided for @guidanceProfessionalContent.
  ///
  /// In en, this message translates to:
  /// **'Make the reply sound professional and appropriate for work.'**
  String get guidanceProfessionalContent;

  /// No description provided for @guidanceFriendlyContent.
  ///
  /// In en, this message translates to:
  /// **'Make the reply warm and friendly.'**
  String get guidanceFriendlyContent;

  /// No description provided for @guidanceDeclineContent.
  ///
  /// In en, this message translates to:
  /// **'Politely decline the request without sounding rude.'**
  String get guidanceDeclineContent;

  /// No description provided for @guidanceThanksContent.
  ///
  /// In en, this message translates to:
  /// **'Add appreciation and a polite thank-you.'**
  String get guidanceThanksContent;

  /// No description provided for @guidanceMoreTimeContent.
  ///
  /// In en, this message translates to:
  /// **'Ask for more time while sounding responsible and polite.'**
  String get guidanceMoreTimeContent;

  /// No description provided for @guidanceConfidentContent.
  ///
  /// In en, this message translates to:
  /// **'Make the reply sound confident but not aggressive.'**
  String get guidanceConfidentContent;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today · {time}'**
  String todayAt(String time);

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday · {time}'**
  String yesterdayAt(String time);

  /// No description provided for @dateAt.
  ///
  /// In en, this message translates to:
  /// **'{date} · {time}'**
  String dateAt(String date, String time);

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium subscription active'**
  String get premiumActive;

  /// No description provided for @creditsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} credits remaining'**
  String creditsRemaining(String count);

  /// No description provided for @adIsLoading.
  ///
  /// In en, this message translates to:
  /// **'Ad is loading. Please try again.'**
  String get adIsLoading;

  /// No description provided for @creditAdded.
  ///
  /// In en, this message translates to:
  /// **'Credit added.'**
  String get creditAdded;

  /// No description provided for @outOfCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re out of credits'**
  String get outOfCreditsTitle;

  /// No description provided for @outOfCreditsMessage.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad to get 2 free credits, or upgrade for more access.'**
  String get outOfCreditsMessage;

  /// No description provided for @buyCredits.
  ///
  /// In en, this message translates to:
  /// **'Buy Credits'**
  String get buyCredits;

  /// No description provided for @creditAddedTapGenerateAgain.
  ///
  /// In en, this message translates to:
  /// **'Credit added. Tap Generate again.'**
  String get creditAddedTapGenerateAgain;

  /// No description provided for @adDailyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily ad reward limit reached.'**
  String get adDailyLimitReached;

  /// No description provided for @adLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load ad. Please try again later.'**
  String get adLoadFailed;

  /// No description provided for @adRewardCooldown.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment before watching another ad.'**
  String get adRewardCooldown;

  /// No description provided for @adRewardFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t add your credit. Please try again.'**
  String get adRewardFailed;

  /// No description provided for @recentDetail.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get recentDetail;

  /// No description provided for @useAgain.
  ///
  /// In en, this message translates to:
  /// **'Use again'**
  String get useAgain;

  /// No description provided for @useATemplate.
  ///
  /// In en, this message translates to:
  /// **'Use template'**
  String get useATemplate;

  /// No description provided for @acceptPolitely.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptPolitely;

  /// No description provided for @askForClarification.
  ///
  /// In en, this message translates to:
  /// **'Clarify'**
  String get askForClarification;

  /// No description provided for @explainTheReason.
  ///
  /// In en, this message translates to:
  /// **'Explain'**
  String get explainTheReason;

  /// No description provided for @offerAnAlternative.
  ///
  /// In en, this message translates to:
  /// **'Alternative'**
  String get offerAnAlternative;

  /// No description provided for @suggestACompromise.
  ///
  /// In en, this message translates to:
  /// **'Compromise'**
  String get suggestACompromise;

  /// No description provided for @showAppreciation.
  ///
  /// In en, this message translates to:
  /// **'Appreciate'**
  String get showAppreciation;

  /// No description provided for @apologizeBriefly.
  ///
  /// In en, this message translates to:
  /// **'Apologize'**
  String get apologizeBriefly;

  /// No description provided for @beFirmButKind.
  ///
  /// In en, this message translates to:
  /// **'Firm'**
  String get beFirmButKind;

  /// No description provided for @appStatusMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get appStatusMaintenanceTitle;

  /// No description provided for @appStatusServerUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'We’re having trouble connecting to the server. Please try again later.'**
  String get appStatusServerUnavailableMessage;

  /// No description provided for @appStatusUpdateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get appStatusUpdateRequiredTitle;

  /// No description provided for @appStatusUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get appStatusUpdateNow;

  /// No description provided for @appStatusUpdateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get appStatusUpdateAvailableTitle;

  /// No description provided for @appStatusUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get appStatusUpdate;

  /// No description provided for @appStatusLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appStatusLater;

  /// No description provided for @appStatusFeatureUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable'**
  String get appStatusFeatureUnavailableTitle;

  /// No description provided for @appStatusFeatureUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature is temporarily unavailable. Please try again later.'**
  String get appStatusFeatureUnavailableMessage;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @getCredits.
  ///
  /// In en, this message translates to:
  /// **'Get credits'**
  String get getCredits;

  /// No description provided for @errorEmptyInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a message first'**
  String get errorEmptyInputTitle;

  /// No description provided for @errorEmptyInputMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter the message you want help with.'**
  String get errorEmptyInputMessage;

  /// No description provided for @errorConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection problem'**
  String get errorConnectionTitle;

  /// No description provided for @errorConnectionMessage.
  ///
  /// In en, this message translates to:
  /// **'We’re having trouble connecting to the server. Please check your internet and try again.'**
  String get errorConnectionMessage;

  /// No description provided for @errorServiceUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Service unavailable'**
  String get errorServiceUnavailableTitle;

  /// No description provided for @errorServiceUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'ReplyWise is temporarily unavailable. Please try again later.'**
  String get errorServiceUnavailableMessage;

  /// No description provided for @errorCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'No credits left'**
  String get errorCreditsTitle;

  /// No description provided for @errorCreditsMessage.
  ///
  /// In en, this message translates to:
  /// **'You need credits to continue.'**
  String get errorCreditsMessage;

  /// No description provided for @errorRateLimitedTitle.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get errorRateLimitedTitle;

  /// No description provided for @errorRateLimitedMessage.
  ///
  /// In en, this message translates to:
  /// **'You’re sending requests too quickly. Please try again in a moment.'**
  String get errorRateLimitedMessage;

  /// No description provided for @errorAiBusyTitle.
  ///
  /// In en, this message translates to:
  /// **'AI is busy'**
  String get errorAiBusyTitle;

  /// No description provided for @errorAiBusyMessage.
  ///
  /// In en, this message translates to:
  /// **'The AI service is temporarily unavailable. Please try again later.'**
  String get errorAiBusyMessage;

  /// No description provided for @errorUnexpectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorUnexpectedTitle;

  /// No description provided for @errorUnexpectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get errorUnexpectedMessage;

  /// No description provided for @formal.
  ///
  /// In en, this message translates to:
  /// **'Formal'**
  String get formal;

  /// No description provided for @casual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get casual;

  /// No description provided for @shareReply.
  ///
  /// In en, this message translates to:
  /// **'Share reply'**
  String get shareReply;

  /// No description provided for @shareExplanation.
  ///
  /// In en, this message translates to:
  /// **'Share explanation'**
  String get shareExplanation;

  /// No description provided for @sharePolishedText.
  ///
  /// In en, this message translates to:
  /// **'Share polished text'**
  String get sharePolishedText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'it',
    'ja',
    'ko',
    'nl',
    'pl',
    'pt',
    'ru',
    'th',
    'tr',
    'uk',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
