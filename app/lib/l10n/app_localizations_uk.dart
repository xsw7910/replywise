// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'ReplyWise';

  @override
  String get systemDefault => 'Як у системі';

  @override
  String get chooseLanguage => 'Виберіть мову застосунку';

  @override
  String get settings => 'Налаштування';

  @override
  String get home => 'Головна';

  @override
  String get reply => 'Відповісти';

  @override
  String get explain => 'Пояснити';

  @override
  String get polish => 'Покращити';

  @override
  String get yourAiReplyAssistant => 'Ваш AI помічник відповіді';

  @override
  String get generateThoughtfulReplies =>
      'Миттєво створюйте вдумливі відповіді.';

  @override
  String get makeWritingClear => 'Пишіть чітко й природно.';

  @override
  String get understandTone => 'Зрозумійте тон і прихований зміст.';

  @override
  String get templates => 'Шаблони';

  @override
  String get reuseInstructions =>
      'Повторно використовуйте свої улюблені інструкції ШІ.';

  @override
  String get recent => 'Нещодавні';

  @override
  String get viewAll => 'Переглянути всі';

  @override
  String get nothingHereYet => 'Тут поки нічого немає';

  @override
  String get recentEmptyMessage =>
      'Тут з’являться ваші останні відповіді, відшліфований текст і пояснення.';

  @override
  String get createFirstReply => 'Створити першу відповідь';

  @override
  String get tipOfTheDay => 'Порада дня';

  @override
  String get tipShortEmails =>
      'Тримайте електронні листи менше 120 слів, щоб отримати більше відповідей.';

  @override
  String get tipLeadWithAsk =>
      'Lead with your ask — помістіть ключовий запит у першому рядку.';

  @override
  String get tipMatchTone =>
      'Збігайтеся з тоном іншої людини, щоб швидше налагодити взаєморозуміння.';

  @override
  String get tipClearSubject =>
      'Чіткий рядок теми отримує більше відповідей, ніж розумний.';

  @override
  String get tipReadAloud =>
      'Прочитайте свою відповідь вголос один раз — вона вловить незграбні фрази.';

  @override
  String get tipClearNextStep =>
      'Завершіть одним чітким наступним кроком, щоб читач знав, що робити.';

  @override
  String get yourPlan => 'Ваш план';

  @override
  String get plans => 'Плани';

  @override
  String get credits => 'Кредити';

  @override
  String get totalCredits => 'Всього кредитів';

  @override
  String get watchAd => 'Дивитися рекламу';

  @override
  String get watchAdReward => '+1 кредит';

  @override
  String get currentPlan => 'Поточний план';

  @override
  String get freePlan => 'Безкоштовний план';

  @override
  String freeRepliesPerDay(int count) {
    return '$count безкоштовних відповідей на день';
  }

  @override
  String get upgrade => 'Покращити';

  @override
  String get support => 'Підтримка';

  @override
  String get supportDescription => 'Довідковий центр / Зв\'язатися з нами';

  @override
  String get aboutDescription => 'Версія, конфіденційність, умови';

  @override
  String get guidance => 'Інструкції';

  @override
  String get guidanceLibrary => 'Бібліотека інструкцій';

  @override
  String get languageAndInput => 'Мова та введення';

  @override
  String get appLanguage => 'Мова застосунку';

  @override
  String get voiceGuidanceLanguage => 'Мова голосових підказок';

  @override
  String get autoDetect => 'Автоматичне визначення';

  @override
  String staticPreview(String label) {
    return '$label є статичним попереднім переглядом.';
  }

  @override
  String get about => 'Про застосунок';

  @override
  String get version => 'Версія';

  @override
  String get environment => 'Навколишнє середовище';

  @override
  String get developerTesting => 'Тестування розробником';

  @override
  String get resetFreeUsage => 'Скинути безкоштовне використання';

  @override
  String addCredits(int count) {
    return 'Додайте $count кредитів';
  }

  @override
  String get simulatePremiumOn => 'Simulate Premium On';

  @override
  String get simulatePremiumOff => 'Simulate Premium Off';

  @override
  String get refreshAccountState => 'Оновити стан облікового запису';

  @override
  String get secureSession => 'Безпечний сеанс';

  @override
  String get anonymousSessionReady => 'Анонімна сесія готова';

  @override
  String get connectingAnonymousSession => 'Підключення анонімного сеансу…';

  @override
  String get refreshingSecureSession => 'Оновлення безпечного сеансу…';

  @override
  String get restoringAnonymousSession => 'Відновлення анонімного сеансу…';

  @override
  String get anonymousSessionUnavailable => 'Анонімний сеанс недоступний';

  @override
  String get anonymousSessionNotStarted => 'Анонімний сеанс не почався';

  @override
  String get retry => 'Повторити';

  @override
  String get developer => 'Розробник';

  @override
  String get localBackendConnection => 'Локальний серверний підключення';

  @override
  String get refreshBackendStatus => 'Оновити статус серверної частини';

  @override
  String get checkingBackend => 'Перевірка серверної частини…';

  @override
  String get connected => 'Підключено';

  @override
  String get connectionFailed => 'Помилка підключення';

  @override
  String get serviceUnreachable =>
      'Ми не змогли додзвонитися до служби. Перевірте підключення та повторіть спробу.';

  @override
  String get copied => 'Скопійовано';

  @override
  String get close => 'Закрити';

  @override
  String get tryAgain => 'Спробуйте знову';

  @override
  String get cancel => 'Скасувати';

  @override
  String get delete => 'Видалити';

  @override
  String get edit => 'Редагувати';

  @override
  String get use => 'Використати';

  @override
  String get save => 'Зберегти';

  @override
  String get done => 'Готово';

  @override
  String get manageLibrary => 'Керувати бібліотекою';

  @override
  String get newGuidance => 'Нове керівництво';

  @override
  String get quickGuidance => 'Швидке керівництво';

  @override
  String get viewPlans => 'Переглянути плани';

  @override
  String get restore => 'Відновити';

  @override
  String get loading => 'Завантаження…';

  @override
  String get premium => 'Преміум';

  @override
  String get premiumUnlimited => 'Преміум · Необмежений';

  @override
  String get updating => 'Оновлення';

  @override
  String get updatingBalance => 'Оновлення балансу…';

  @override
  String get balanceUnavailable => 'Баланс недоступний';

  @override
  String get checking => 'Перевірка';

  @override
  String get checkingBalance => 'Перевірка балансу…';

  @override
  String freeCount(int free) {
    return '$free безкоштовно';
  }

  @override
  String usageBalance(int free, int credits) {
    return '$free безкоштовно · $credits кредитів';
  }

  @override
  String get copyPreview => 'Копіювати попередній перегляд';

  @override
  String get copyResult => 'Копіювати результат';

  @override
  String get staticPreviewCaption => 'Статичний попередній перегляд';

  @override
  String get history => 'історія';

  @override
  String get clearHistory => 'Очистити історію?';

  @override
  String get clearHistoryDescription =>
      'Буде видалено всі останні елементи на цьому пристрої. Це неможливо скасувати.';

  @override
  String get clearAll => 'Очистити все';

  @override
  String get messageReceived => 'Повідомлення отримано';

  @override
  String get messageYouReceived => 'Повідомлення, яке ви отримали';

  @override
  String get pasteOriginalMessage => 'Вставте оригінальне повідомлення сюди…';

  @override
  String get paste => 'Вставити';

  @override
  String get clear => 'ясно';

  @override
  String get helpAiUnderstandIntent => 'Допоможіть ШІ зрозуміти ваші наміри';

  @override
  String get addReplyInstructions => 'Додайте інструкції для відповіді…';

  @override
  String get generating => 'Створення…';

  @override
  String get generateReply => 'Створити відповідь';

  @override
  String get creatingNaturalOptions => 'Створення кількох природних варіантів…';

  @override
  String get replyOptionsAppearHere =>
      'Тут з’являться ваші варіанти відповіді.';

  @override
  String get yourReplies => 'Ваші відповіді';

  @override
  String get whyThisWorks => 'Чому це працює';

  @override
  String get regenerateReplies => 'Відновити відповіді';

  @override
  String get regenerateUsageNote =>
      'Повторне створення створює нові відповіді та використовує 1 покоління.';

  @override
  String get couldNotExplain => 'Не вдалося пояснити це повідомлення';

  @override
  String get explainMessage => 'Поясніть повідомлення';

  @override
  String get copyExplanation => 'Скопіюйте пояснення';

  @override
  String get meaning => 'Сенс';

  @override
  String get tone => 'Тон';

  @override
  String get hiddenMeaning => 'Прихований сенс';

  @override
  String get noHiddenMeaning => 'Прихованого сенсу не виявлено.';

  @override
  String get suggestedReplies => 'Запропоновані відповіді';

  @override
  String get moreOptions => 'Більше варіантів';

  @override
  String get audience => 'Аудиторія';

  @override
  String get length => 'Довжина';

  @override
  String get channel => 'Канал';

  @override
  String get describeTone => 'Опишіть тон';

  @override
  String get toneHint => 'напр. тепло, але професійно';

  @override
  String get describeRelationship => 'Опишіть відносини';

  @override
  String get relationshipHint => 'Наприклад: мій орендодавець';

  @override
  String get customizeStyleToneFormat => 'Налаштуйте стиль, тон і формат';

  @override
  String get bePolite => 'Будь ввічливим';

  @override
  String get keepItShort => 'Будьте короткими';

  @override
  String get professional => 'професійний';

  @override
  String get friendly => 'дружній';

  @override
  String get declinePolitely => 'Ввічливо відмовитися';

  @override
  String get sayThankYou => 'Скажи спасибі';

  @override
  String get auto => 'Авто';

  @override
  String get natural => 'Природні';

  @override
  String get custom => 'Custom';

  @override
  String get friend => 'Друг';

  @override
  String get customer => 'Замовник';

  @override
  String get coworker => 'Колега по роботі';

  @override
  String get manager => 'Менеджер';

  @override
  String get short => 'Короткий';

  @override
  String get medium => 'Середній';

  @override
  String get detailed => 'Детальний';

  @override
  String get textChannel => 'текст';

  @override
  String get email => 'Електронна пошта';

  @override
  String get chat => 'Чат';

  @override
  String get textToPolish => 'Текст для полірування';

  @override
  String get pasteTextToImprove => 'Вставте текст, який ви хочете покращити';

  @override
  String get pasteYourText => 'Вставте свій текст тут…';

  @override
  String get improvingClarity => 'Покращуючи ясність, зберігаючи значення…';

  @override
  String get polishedTextAppearsHere => 'Ваш покращений текст з’явиться тут.';

  @override
  String get polishedResult => 'Покращений текст';

  @override
  String get whatChanged => 'Що змінилося?';

  @override
  String get polishAgain => 'Знову покращити';

  @override
  String get polishAgainUsageNote =>
      'Повторне покращення створює новий результат і використовує 1 покоління.';

  @override
  String get messageToUnderstand => 'Повідомлення для розуміння';

  @override
  String get pasteMessageReceived => 'Вставте отримане повідомлення';

  @override
  String get explainThisMessage => 'Поясніть це повідомлення';

  @override
  String get explaining => 'Пояснення…';

  @override
  String get readingBetweenLines => 'Читаючи між рядків…';

  @override
  String get explanationAppearsHere => 'Ваше пояснення з’явиться тут.';

  @override
  String get noSuggestedReplies => 'Немає запропонованих відповідей.';

  @override
  String get copy => 'Копіювати';

  @override
  String get enterMessageFirst =>
      'Спочатку введіть повідомлення, щоб пояснити.';

  @override
  String get explainRateLimited =>
      'Наразі ви досягли ліміту пояснень. Спробуйте пізніше.';

  @override
  String get explainParseError =>
      'Ми не змогли чітко прочитати пояснення. Спробуйте ще раз.';

  @override
  String get explainUnavailable =>
      'Пояснення тимчасово недоступне. Спробуйте ще раз незабаром.';

  @override
  String get unableToExplain => 'Неможливо пояснити це повідомлення.';

  @override
  String get replyCtaTitle =>
      'Хочете отримати відповідь, яка краще відповідає вашим намірам?';

  @override
  String get premiumTitle => 'ReplyWise Premium';

  @override
  String get back => 'Назад';

  @override
  String get threeDaysFree => '3 дні безкоштовно';

  @override
  String get unlimitedReply => 'Необмежена кількість поколінь відповідей';

  @override
  String get unlimitedPolish => 'Необмежені покращення тексту';

  @override
  String get balancesPreserved =>
      'Вільні та кредитні залишки залишаються збереженими';

  @override
  String get loadingSubscriptionOptions => 'Завантаження варіантів підписки…';

  @override
  String get startFreeTrial => 'Почніть 3-денну безкоштовну пробну версію';

  @override
  String get startYearlyPlan => 'Розпочати річний план';

  @override
  String trialTerms(String price) {
    return 'Безкоштовно протягом 3 днів, потім $price/рік. Скасувати будь-коли.';
  }

  @override
  String yearlyTerms(String price) {
    return '$price/рік. Скасувати будь-коли.';
  }

  @override
  String get displayedPrice => 'відображена ціна';

  @override
  String get topUpCredits => 'Поповнення кредитів';

  @override
  String get creditDescription =>
      'Кожен кредит покриває одну відповідь або одне покращення тексту. Термін дії кредитів не закінчується.';

  @override
  String get loadingCreditPackages => 'Завантаження кредитних пакетів…';

  @override
  String get creditPackagesUnavailable => 'Кредитні пакети зараз недоступні.';

  @override
  String get refreshPackages => 'Оновити пакети';

  @override
  String buyCreditPackage(int credits, String price) {
    return 'Придбайте $credits кредитів — $price';
  }

  @override
  String get restoring => 'Відновлення…';

  @override
  String get restorePremium => 'Відновити підписку Premium';

  @override
  String get purchaseVerification =>
      'Покупки преміум-класу та кредиту перевіряються ReplyWise. Покупки в кредит звіряються автоматично.';

  @override
  String get newGuidanceTooltip => 'Нове керівництво';

  @override
  String get builtIn => 'Вбудований';

  @override
  String get myGuidance => 'Моє керівництво';

  @override
  String get useInReply => 'Використовуйте у відповіді';

  @override
  String get useInPolish => 'Використовуйте для покращення тексту';

  @override
  String get deleteGuidance => 'Видалити цю інструкцію?';

  @override
  String get cannotBeUndone => 'Це неможливо скасувати.';

  @override
  String get category => 'Категорія';

  @override
  String get titleLabel => 'Назва';

  @override
  String get guidanceTitleHint => 'Коротка назва цього посібника…';

  @override
  String get guidanceHint =>
      'Опишіть, як штучний інтелект має формувати відповідь…';

  @override
  String get writeAnyLanguage => 'Пишіть будь-якою мовою';

  @override
  String get saveChanges => 'Зберегти зміни';

  @override
  String get saveGuidance => 'Зберегти керівництво';

  @override
  String get couldNotSaveGuidance =>
      'Не вдалося зберегти цю інструкцію. Спробуйте ще раз.';

  @override
  String get concise => 'Лаконічний';

  @override
  String get moreNatural => 'Більш натуральний';

  @override
  String get improveGrammar => 'Удосконалювати граматику';

  @override
  String get fixSpelling => 'Виправити правопис';

  @override
  String get morePersuasive => 'Більш переконливий';

  @override
  String get moreConfident => 'Більш впевнений';

  @override
  String get simplifyWording => 'Спростіть формулювання';

  @override
  String get betterFlow => 'Кращий потік';

  @override
  String get describePolish => 'Опишіть, як ви хочете відшліфувати чернетку';

  @override
  String get describeAudience => 'Охарактеризуйте аудиторію';

  @override
  String get audienceHint => 'напр. мій менеджер';

  @override
  String get extraInstruction => 'Додаткова інструкція';

  @override
  String get extraPolishHint =>
      'Додайте будь-які інші параметри покращення тексту';

  @override
  String get polishing => 'Покращення тексту…';

  @override
  String get polishText => 'Покращте текст';

  @override
  String get adjustToneLengthFormat => 'Налаштуйте тон, довжину та формат';

  @override
  String get instructionProfessional => 'Нехай текст звучить професійно.';

  @override
  String get instructionFriendly => 'Зробіть письмо теплішим і дружнішим.';

  @override
  String get instructionConcise => 'Зробіть письмо лаконічним і прямим.';

  @override
  String get instructionNatural =>
      'Нехай формулювання звучить природно і плавно.';

  @override
  String get instructionGrammar => 'Виправте граматику, зберігши значення.';

  @override
  String get instructionSpelling => 'Виправте всі орфографічні помилки.';

  @override
  String get instructionPersuasive =>
      'Зробіть текст більш переконливим і переконливим.';

  @override
  String get instructionConfident =>
      'Нехай написане звучить чітко та впевнено.';

  @override
  String get instructionSimple =>
      'Використовуйте простіші формулювання, які легше читати.';

  @override
  String get instructionFlow => 'Покращте потік речень і переходи.';

  @override
  String get shorter => 'Коротше';

  @override
  String get sameLength => 'Те саме';

  @override
  String get longer => 'Довше';

  @override
  String get favorites => 'Вибране';

  @override
  String get createGuidanceEmpty =>
      'Створіть власну інструкцію, щоб використовувати її пізніше.';

  @override
  String get removeFavorite => 'Видалити з вибраного';

  @override
  String get addFavorite => 'Додати в обране';

  @override
  String useTemplate(String title) {
    return 'Використовуйте «$title»';
  }

  @override
  String get chooseGuidance => 'Виберіть керівництво';

  @override
  String get library => 'Бібліотека';

  @override
  String get general => 'Загальний';

  @override
  String get decline => 'відхилити';

  @override
  String get thanks => 'дякую';

  @override
  String get followUp => 'Подальші дії';

  @override
  String get editGuidance => 'Редагувати вказівки';

  @override
  String get makeProfessional => 'Зробіть це професійно';

  @override
  String get makeFriendly => 'Зробіть це дружнім';

  @override
  String get askMoreTime => 'Попросіть більше часу';

  @override
  String get soundConfident => 'Звучить впевнено';

  @override
  String get guidancePoliteContent => 'Відповідайте ввічливо й шанобливо.';

  @override
  String get guidanceShortContent => 'Нехай відповідь буде короткою та чіткою.';

  @override
  String get guidanceProfessionalContent =>
      'Нехай відповідь звучить професійно та підходить для роботи.';

  @override
  String get guidanceFriendlyContent =>
      'Зробіть відповідь теплою і доброзичливою.';

  @override
  String get guidanceDeclineContent =>
      'Ввічливо відхиліть запит, не видаючись грубим.';

  @override
  String get guidanceThanksContent => 'Додайте вдячність і ввічливу подяку.';

  @override
  String get guidanceMoreTimeContent =>
      'Попросіть більше часу, звучачи відповідально та ввічливо.';

  @override
  String get guidanceConfidentContent =>
      'Нехай відповідь звучить впевнено, але не агресивно.';

  @override
  String todayAt(String time) {
    return 'Сьогодні · $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Учора · $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date · $time';
  }

  @override
  String get premiumActive => 'Преміум підписка активна';

  @override
  String creditsRemaining(String count) {
    return 'Залишилося $count кредитів';
  }

  @override
  String get adIsLoading =>
      'Реклама завантажується. Будь ласка, спробуйте ще раз.';

  @override
  String get creditAdded => 'Кредит додано.';

  @override
  String get outOfCreditsTitle => 'У вас закінчилися кредити';

  @override
  String get outOfCreditsMessage =>
      'Перегляньте коротку рекламу, щоб отримати 1 безкоштовний кредит, або перейдіть, щоб отримати більше доступу.';

  @override
  String get buyCredits => 'Купити кредити';

  @override
  String get creditAddedTapGenerateAgain =>
      'Кредит додано. Знову торкніться «Створити».';

  @override
  String get adDailyLimitReached =>
      'Досягнуто денний ліміт винагород за рекламу.';

  @override
  String get adLoadFailed =>
      'Не вдалося завантажити рекламу. Спробуйте пізніше.';

  @override
  String get adRewardCooldown =>
      'Зачекайте трохи, перш ніж переглядати іншу рекламу.';

  @override
  String get adRewardFailed => 'Не вдалося додати кредит. Спробуйте ще раз.';
}
