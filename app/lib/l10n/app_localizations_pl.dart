// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Odpowiedz mądrze';

  @override
  String get systemDefault => 'Domyślny systemu';

  @override
  String get chooseLanguage => 'Wybierz język aplikacji';

  @override
  String get settings => 'Ustawienia';

  @override
  String get home => 'Strona główna';

  @override
  String get reply => 'Odpowiedz';

  @override
  String get explain => 'Wyjaśnij';

  @override
  String get polish => 'Popraw';

  @override
  String get yourAiReplyAssistant => 'Twój asystent odpowiedzi AI';

  @override
  String get generateThoughtfulReplies =>
      'Natychmiast generuj przemyślane odpowiedzi.';

  @override
  String get makeWritingClear => 'Spraw, aby Twój tekst był jasny i naturalny.';

  @override
  String get understandTone => 'Zrozum ton i ukryte znaczenie.';

  @override
  String get templates => 'Szablony';

  @override
  String get reuseInstructions =>
      'Wykorzystaj ponownie swoje ulubione instrukcje AI.';

  @override
  String get recent => 'Ostatnie';

  @override
  String get viewAll => 'Zobacz wszystko';

  @override
  String get nothingHereYet => 'Jeszcze nic tu nie ma';

  @override
  String get recentEmptyMessage =>
      'Tutaj pojawią się Twoje najnowsze odpowiedzi, dopracowany tekst i wyjaśnienia.';

  @override
  String get createFirstReply => 'Utwórz pierwszą odpowiedź';

  @override
  String get tipOfTheDay => 'Porada dnia';

  @override
  String get tipShortEmails =>
      'Trzymaj e-maile poniżej 120 słów, aby uzyskać wyższy współczynnik odpowiedzi.';

  @override
  String get tipLeadWithAsk =>
      'Prowadź swoim pytaniem — umieść kluczową prośbę w pierwszym wierszu.';

  @override
  String get tipMatchTone =>
      'Dopasuj ton drugiej osoby, aby szybciej budować relację.';

  @override
  String get tipClearSubject => 'Jasny temat daje więcej odpowiedzi niż mądry.';

  @override
  String get tipReadAloud =>
      'Przeczytaj raz na głos swoją odpowiedź – zawiera ona niezręczne sformułowania.';

  @override
  String get tipClearNextStep =>
      'Zakończ jednym wyraźnym kolejnym krokiem, aby czytelnik wiedział, co robić.';

  @override
  String get yourPlan => 'Twój plan';

  @override
  String get plans => 'Plany';

  @override
  String get credits => 'Kredyty';

  @override
  String get totalCredits => 'Suma kredytów';

  @override
  String get watchAd => 'Obejrzyj reklamę';

  @override
  String get watchAdReward => '+1 kredyt';

  @override
  String get currentPlan => 'Aktualny plan';

  @override
  String get freePlan => 'Darmowy plan';

  @override
  String freeRepliesPerDay(int count) {
    return '$count bezpłatnych odpowiedzi dziennie';
  }

  @override
  String get upgrade => 'Ulepsz';

  @override
  String get support => 'Wsparcie';

  @override
  String get supportDescription => 'Centrum pomocy / Skontaktuj się z nami';

  @override
  String get aboutDescription => 'Wersja, prywatność, warunki';

  @override
  String get guidance => 'Wskazówki';

  @override
  String get guidanceLibrary => 'Biblioteka wskazówek';

  @override
  String get languageAndInput => 'Język i wprowadzanie';

  @override
  String get appLanguage => 'Język aplikacji';

  @override
  String get voiceGuidanceLanguage => 'Język wskazówek głosowych';

  @override
  String get autoDetect => 'Automatyczne wykrywanie';

  @override
  String staticPreview(String label) {
    return '$label to podgląd statyczny.';
  }

  @override
  String get about => 'Informacje';

  @override
  String get version => 'Wersja';

  @override
  String get environment => 'Środowisko';

  @override
  String get developerTesting => 'Testowanie programistów';

  @override
  String get resetFreeUsage => 'Zresetuj bezpłatne użytkowanie';

  @override
  String addCredits(int count) {
    return 'Dodaj $count kredytów';
  }

  @override
  String get simulatePremiumOn => 'Symuluj Premium włączone';

  @override
  String get simulatePremiumOff => 'Symuluj wyłączenie premium';

  @override
  String get refreshAccountState => 'Odśwież stan konta';

  @override
  String get secureSession => 'Bezpieczna sesja';

  @override
  String get anonymousSessionReady => 'Sesja anonimowa gotowa';

  @override
  String get connectingAnonymousSession => 'Łączę sesję anonimową…';

  @override
  String get refreshingSecureSession => 'Odświeżanie bezpiecznej sesji…';

  @override
  String get restoringAnonymousSession => 'Przywracam sesję anonimową…';

  @override
  String get anonymousSessionUnavailable => 'Sesja anonimowa niedostępna';

  @override
  String get anonymousSessionNotStarted =>
      'Sesja anonimowa nie została rozpoczęta';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get developer => 'Wywoływacz';

  @override
  String get localBackendConnection => 'Lokalne połączenie z backendem';

  @override
  String get refreshBackendStatus => 'Odśwież stan backendu';

  @override
  String get checkingBackend => 'Sprawdzam zaplecze…';

  @override
  String get connected => 'Połączony';

  @override
  String get connectionFailed => 'Połączenie nie powiodło się';

  @override
  String get serviceUnreachable =>
      'Nie mogliśmy skontaktować się z serwisem. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get copied => 'Skopiowano';

  @override
  String get close => 'Zamknąć';

  @override
  String get tryAgain => 'Spróbuj ponownie';

  @override
  String get cancel => 'Anuluj';

  @override
  String get delete => 'Usuń';

  @override
  String get edit => 'Edytuj';

  @override
  String get use => 'Użyj';

  @override
  String get save => 'Zapisz';

  @override
  String get done => 'Gotowe';

  @override
  String get manageLibrary => 'Zarządzaj biblioteką';

  @override
  String get newGuidance => 'Nowe wytyczne';

  @override
  String get quickGuidance => 'Szybkie wskazówki';

  @override
  String get viewPlans => 'Zobacz plany';

  @override
  String get restore => 'Przywrócić';

  @override
  String get loading => 'Załadunek…';

  @override
  String get premium => 'Premium';

  @override
  String get premiumUnlimited => 'Premium · Nieograniczony';

  @override
  String get updating => 'Aktualizowanie';

  @override
  String get updatingBalance => 'Aktualizuję saldo…';

  @override
  String get balanceUnavailable => 'Saldo niedostępne';

  @override
  String get checking => 'Kontrola';

  @override
  String get checkingBalance => 'Sprawdzam saldo…';

  @override
  String freeCount(int free) {
    return '$free bezpłatnie';
  }

  @override
  String usageBalance(int free, int credits) {
    return '$free bezpłatnie · $credits kredytów';
  }

  @override
  String get copyPreview => 'Skopiuj podgląd';

  @override
  String get copyResult => 'Skopiuj wynik';

  @override
  String get staticPreviewCaption => 'Podgląd statyczny';

  @override
  String get history => 'Historia';

  @override
  String get clearHistory => 'Wyczyść historię?';

  @override
  String get clearHistoryDescription =>
      'Spowoduje to usunięcie wszystkich ostatnich elementów na tym urządzeniu. Tego nie można cofnąć.';

  @override
  String get clearAll => 'Wyczyść wszystko';

  @override
  String get messageReceived => 'Wiadomość otrzymana';

  @override
  String get messageYouReceived => 'Wiadomość, którą otrzymałeś';

  @override
  String get pasteOriginalMessage => 'Wklej tutaj oryginalną wiadomość…';

  @override
  String get paste => 'Pasta';

  @override
  String get clear => 'Jasne';

  @override
  String get helpAiUnderstandIntent => 'Pomóż AI zrozumieć Twoje intencje';

  @override
  String get addReplyInstructions => 'Dodaj instrukcje dotyczące odpowiedzi…';

  @override
  String get generating => 'Generowanie…';

  @override
  String get generateReply => 'Wygeneruj odpowiedź';

  @override
  String get creatingNaturalOptions => 'Tworzenie kilku naturalnych opcji…';

  @override
  String get replyOptionsAppearHere => 'Tutaj pojawią się opcje odpowiedzi.';

  @override
  String get yourReplies => 'Twoje odpowiedzi';

  @override
  String get whyThisWorks => 'Dlaczego to działa';

  @override
  String get regenerateReplies => 'Regeneruj odpowiedzi';

  @override
  String get regenerateUsageNote =>
      'Regeneracja tworzy nowe odpowiedzi i wykorzystuje 1 generację.';

  @override
  String get couldNotExplain => 'Nie udało się wyjaśnić tej wiadomości';

  @override
  String get explainMessage => 'Wyjaśnij wiadomość';

  @override
  String get copyExplanation => 'Skopiuj wyjaśnienie';

  @override
  String get meaning => 'Oznaczający';

  @override
  String get tone => 'Ton';

  @override
  String get hiddenMeaning => 'Ukryte znaczenie';

  @override
  String get noHiddenMeaning => 'Nie wykryto żadnego ukrytego znaczenia.';

  @override
  String get suggestedReplies => 'Sugerowane odpowiedzi';

  @override
  String get moreOptions => 'Więcej opcji';

  @override
  String get audience => 'Publiczność';

  @override
  String get length => 'Długość';

  @override
  String get channel => 'Kanał';

  @override
  String get describeTone => 'Opisz ton';

  @override
  String get toneHint => 'np. ciepły, ale profesjonalny';

  @override
  String get describeRelationship => 'Opisz związek';

  @override
  String get relationshipHint => 'Na przykład: mój właściciel';

  @override
  String get customizeStyleToneFormat => 'Dostosuj styl, ton i format';

  @override
  String get bePolite => 'Bądź grzeczny';

  @override
  String get keepItShort => 'Pisz krótko';

  @override
  String get professional => 'Profesjonalny';

  @override
  String get friendly => 'Przyjazny';

  @override
  String get declinePolitely => 'Odmów grzecznie';

  @override
  String get sayThankYou => 'Powiedz dziękuję';

  @override
  String get auto => 'Automatyczny';

  @override
  String get natural => 'Naturalny';

  @override
  String get custom => 'Zwyczaj';

  @override
  String get friend => 'Przyjaciel';

  @override
  String get customer => 'Klient';

  @override
  String get coworker => 'Współpracownik';

  @override
  String get manager => 'Menedżer';

  @override
  String get short => 'Krótki';

  @override
  String get medium => 'Średni';

  @override
  String get detailed => 'Szczegółowy';

  @override
  String get textChannel => 'Tekst';

  @override
  String get email => 'E-mail';

  @override
  String get chat => 'Pogawędzić';

  @override
  String get textToPolish => 'Tekst do wypolerowania';

  @override
  String get pasteTextToImprove => 'Wklej tekst, który chcesz poprawić';

  @override
  String get pasteYourText => 'Wklej tutaj swój tekst…';

  @override
  String get improvingClarity =>
      'Poprawa przejrzystości przy jednoczesnym zachowaniu znaczenia…';

  @override
  String get polishedTextAppearsHere => 'Tutaj pojawi się poprawiony tekst.';

  @override
  String get polishedResult => 'Poprawiony tekst';

  @override
  String get whatChanged => 'Co się zmieniło?';

  @override
  String get polishAgain => 'Popraw ponownie';

  @override
  String get polishAgainUsageNote =>
      'Ponowne doskonalenie tworzy nowy wynik i wykorzystuje 1 generację.';

  @override
  String get messageToUnderstand => 'Wiadomość do zrozumienia';

  @override
  String get pasteMessageReceived => 'Wklej otrzymaną wiadomość';

  @override
  String get explainThisMessage => 'Wyjaśnij tę wiadomość';

  @override
  String get explaining => 'Wyjaśnianie…';

  @override
  String get readingBetweenLines => 'Czytanie między wierszami…';

  @override
  String get explanationAppearsHere => 'Twoje wyjaśnienie pojawi się tutaj.';

  @override
  String get noSuggestedReplies =>
      'Nie zwrócono żadnych sugerowanych odpowiedzi.';

  @override
  String get copy => 'Kopia';

  @override
  String get enterMessageFirst =>
      'Najpierw wpisz wiadomość, którą chcesz wyjaśnić.';

  @override
  String get explainRateLimited =>
      'Osiągnąłeś już limit wyjaśnień. Spróbuj ponownie później.';

  @override
  String get explainParseError =>
      'Nie mogliśmy wyraźnie odczytać wyjaśnienia. Spróbuj ponownie.';

  @override
  String get explainUnavailable =>
      'Funkcja Wyjaśnij jest chwilowo niedostępna. Spróbuj ponownie wkrótce.';

  @override
  String get unableToExplain => 'Nie można wyjaśnić tego komunikatu.';

  @override
  String get replyCtaTitle =>
      'Chcesz otrzymać odpowiedź, która lepiej odpowiada Twoim intencjom?';

  @override
  String get premiumTitle => 'RepWise Premium';

  @override
  String get back => 'Z powrotem';

  @override
  String get threeDaysFree => '3 dni za darmo';

  @override
  String get unlimitedReply => 'Nieograniczone pokolenia odpowiedzi';

  @override
  String get unlimitedPolish => 'Nieograniczone ulepszenia tekstu';

  @override
  String get balancesPreserved =>
      'Salda bezpłatne i kredytowe pozostają zachowane';

  @override
  String get loadingSubscriptionOptions => 'Ładowanie opcji subskrypcji…';

  @override
  String get startFreeTrial => 'Rozpocznij 3-dniowy bezpłatny okres próbny';

  @override
  String get startYearlyPlan => 'Rozpocznij plan roczny';

  @override
  String trialTerms(String price) {
    return 'Bezpłatnie przez 3 dni, następnie $price/rok. Anuluj w dowolnym momencie.';
  }

  @override
  String yearlyTerms(String price) {
    return '$price/rok. Anuluj w dowolnym momencie.';
  }

  @override
  String get displayedPrice => 'wyświetlaną cenę';

  @override
  String get topUpCredits => 'Doładowania kredytów';

  @override
  String get creditDescription =>
      'Każdy kredyt obejmuje jedną odpowiedź lub jedno ulepszenie tekstu. Kredyty nigdy nie wygasają.';

  @override
  String get loadingCreditPackages => 'Ładowanie pakietów środków…';

  @override
  String get creditPackagesUnavailable =>
      'Pakiety środków są obecnie niedostępne.';

  @override
  String get refreshPackages => 'Odśwież pakiety';

  @override
  String buyCreditPackage(int credits, String price) {
    return 'Kup $credits kredytów — $price';
  }

  @override
  String get restoring => 'Przywracam…';

  @override
  String get restorePremium => 'Przywróć subskrypcję Premium';

  @override
  String get purchaseVerification =>
      'Zakupy premium i kredytowe są weryfikowane przez ReplyWise. Zakupy kredytowe rozliczane są automatycznie.';

  @override
  String get newGuidanceTooltip => 'Nowe wytyczne';

  @override
  String get builtIn => 'Wbudowany';

  @override
  String get myGuidance => 'Moje wskazówki';

  @override
  String get useInReply => 'Użyj w odpowiedzi';

  @override
  String get useInPolish => 'Użyj do poprawy tekstu';

  @override
  String get deleteGuidance => 'Usunąć te wskazówki?';

  @override
  String get cannotBeUndone => 'Tego nie można cofnąć.';

  @override
  String get category => 'Kategoria';

  @override
  String get titleLabel => 'Tytuł';

  @override
  String get guidanceTitleHint => 'Krótka nazwa tego poradnika…';

  @override
  String get guidanceHint =>
      'Opisz, w jaki sposób sztuczna inteligencja powinna kształtować odpowiedź…';

  @override
  String get writeAnyLanguage => 'Napisz w dowolnym języku';

  @override
  String get saveChanges => 'Zapisz zmiany';

  @override
  String get saveGuidance => 'Zapisz wskazówki';

  @override
  String get couldNotSaveGuidance =>
      'Nie można zapisać tych wskazówek. Spróbuj ponownie.';

  @override
  String get concise => 'Zwięzły';

  @override
  String get moreNatural => 'Bardziej naturalny';

  @override
  String get improveGrammar => 'Popraw gramatykę';

  @override
  String get fixSpelling => 'Popraw pisownię';

  @override
  String get morePersuasive => 'Bardziej przekonujący';

  @override
  String get moreConfident => 'Bardziej pewny siebie';

  @override
  String get simplifyWording => 'Uprość sformułowanie';

  @override
  String get betterFlow => 'Lepszy przepływ';

  @override
  String get describePolish => 'Opisz, jak chcesz dopracować wersję roboczą';

  @override
  String get describeAudience => 'Opisz publiczność';

  @override
  String get audienceHint => 'np. mój menadżer';

  @override
  String get extraInstruction => 'Dodatkowa instrukcja';

  @override
  String get extraPolishHint =>
      'Dodaj inne preferencje dotyczące ulepszania tekstu';

  @override
  String get polishing => 'Poprawianie tekstu…';

  @override
  String get polishText => 'Popraw tekst';

  @override
  String get adjustToneLengthFormat => 'Dostosuj ton, długość i format';

  @override
  String get instructionProfessional =>
      'Spraw, aby tekst brzmiał profesjonalnie.';

  @override
  String get instructionFriendly =>
      'Spraw, aby pisanie było cieplejsze i bardziej przyjazne.';

  @override
  String get instructionConcise =>
      'Staraj się, aby tekst był zwięzły i bezpośredni.';

  @override
  String get instructionNatural =>
      'Spraw, aby sformułowanie brzmiało naturalnie i płynnie.';

  @override
  String get instructionGrammar => 'Popraw gramatykę, zachowując znaczenie.';

  @override
  String get instructionSpelling => 'Popraw wszystkie błędy ortograficzne.';

  @override
  String get instructionPersuasive =>
      'Spraw, aby tekst był bardziej przekonujący i przekonujący.';

  @override
  String get instructionConfident =>
      'Spraw, aby tekst brzmiał wyraźnie i pewnie.';

  @override
  String get instructionSimple =>
      'Używaj prostszych i łatwiejszych do odczytania sformułowań.';

  @override
  String get instructionFlow => 'Popraw przepływ zdań i przejścia.';

  @override
  String get shorter => 'Krótszy';

  @override
  String get sameLength => 'To samo';

  @override
  String get longer => 'Dłużej';

  @override
  String get favorites => 'Ulubione';

  @override
  String get createGuidanceEmpty =>
      'Stwórz własne wskazówki, aby móc je później wykorzystać.';

  @override
  String get removeFavorite => 'Usuń z ulubionych';

  @override
  String get addFavorite => 'Dodaj do ulubionych';

  @override
  String useTemplate(String title) {
    return 'Użyj „$title”';
  }

  @override
  String get chooseGuidance => 'Wybierz wskazówki';

  @override
  String get library => 'Biblioteka';

  @override
  String get general => 'Ogólny';

  @override
  String get decline => 'Spadek';

  @override
  String get thanks => 'Dzięki';

  @override
  String get followUp => 'Podejmować właściwe kroki';

  @override
  String get editGuidance => 'Edytuj wskazówki';

  @override
  String get makeProfessional => 'Zrób to profesjonalnie';

  @override
  String get makeFriendly => 'Zrób to przyjaźnie';

  @override
  String get askMoreTime => 'Poproś o więcej czasu';

  @override
  String get soundConfident => 'Brzmij pewnie';

  @override
  String get guidancePoliteContent =>
      'Odpowiedz w sposób kulturalny i pełen szacunku.';

  @override
  String get guidanceShortContent => 'Odpowiedź powinna być krótka i jasna.';

  @override
  String get guidanceProfessionalContent =>
      'Spraw, aby odpowiedź brzmiała profesjonalnie i adekwatnie do pracy.';

  @override
  String get guidanceFriendlyContent =>
      'Spraw, aby odpowiedź była ciepła i przyjazna.';

  @override
  String get guidanceDeclineContent =>
      'Grzecznie odrzuć prośbę, nie zabrzmiąc niegrzecznie.';

  @override
  String get guidanceThanksContent => 'Dodaj uznanie i uprzejme podziękowanie.';

  @override
  String get guidanceMoreTimeContent =>
      'Poproś o więcej czasu, jednocześnie brzmiąc odpowiedzialnie i uprzejmie.';

  @override
  String get guidanceConfidentContent =>
      'Spraw, aby odpowiedź brzmiała pewnie, ale nie agresywnie.';

  @override
  String todayAt(String time) {
    return 'Dzisiaj · $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Wczoraj · $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date · $time';
  }

  @override
  String get premiumActive => 'Subskrypcja premium aktywna';

  @override
  String creditsRemaining(String count) {
    return 'Pozostało $count kredytów';
  }

  @override
  String get adIsLoading => 'Reklama się ładuje. Spróbuj ponownie.';

  @override
  String get creditAdded => 'Dodano kredyt.';

  @override
  String get outOfCreditsTitle => 'Skończyły Ci się kredyty';

  @override
  String get outOfCreditsMessage =>
      'Obejrzyj krótką reklamę, aby otrzymać 1 darmowy kredyt lub uaktualnij, aby uzyskać większy dostęp.';

  @override
  String get buyCredits => 'Kup Kredyty';

  @override
  String get creditAddedTapGenerateAgain =>
      'Dodano kredyt. Kliknij ponownie opcję Generuj.';

  @override
  String get adDailyLimitReached =>
      'Osiągnięto dzienny limit nagród za reklamy.';

  @override
  String get adLoadFailed =>
      'Nie można załadować reklamy. Spróbuj ponownie później.';

  @override
  String get adRewardCooldown =>
      'Poczekaj chwilę przed obejrzeniem kolejnej reklamy.';

  @override
  String get adRewardFailed => 'Nie udało się dodać kredytu. Spróbuj ponownie.';

  @override
  String get recentDetail => 'Szczegóły';

  @override
  String get useAgain => 'Użyj ponownie';
}
