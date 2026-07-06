// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'ОтветитьМудрый';

  @override
  String get systemDefault => 'Как в системе';

  @override
  String get chooseLanguage => 'Выберите язык приложения';

  @override
  String get settings => 'Настройки';

  @override
  String get settingsSubtitle =>
      'Управляйте аккаунтом и настройками приложения';

  @override
  String get home => 'Главная';

  @override
  String get reply => 'Ответить';

  @override
  String get explain => 'Объяснить';

  @override
  String get polish => 'Улучшить';

  @override
  String get yourAiReplyAssistant => 'Ваш ИИ-помощник по ответам';

  @override
  String get generateThoughtfulReplies =>
      'Мгновенно создавайте продуманные ответы.';

  @override
  String get makeWritingClear => 'Сделайте свой текст ясным и естественным.';

  @override
  String get understandTone => 'Понять тон и скрытый смысл.';

  @override
  String get templates => 'Шаблоны';

  @override
  String get reuseInstructions =>
      'Повторно используйте свои любимые инструкции ИИ.';

  @override
  String get recent => 'Недавние';

  @override
  String get viewAll => 'Показать все';

  @override
  String get nothingHereYet => 'Здесь пока ничего нет';

  @override
  String get recentEmptyMessage =>
      'Здесь появятся ваши недавние ответы, доработанный текст и пояснения.';

  @override
  String get createFirstReply => 'Создать первый ответ';

  @override
  String get tipOfTheDay => 'Совет дня';

  @override
  String get tipShortEmails =>
      'Держите электронные письма объемом менее 120 слов, чтобы повысить скорость отклика.';

  @override
  String get tipLeadWithAsk =>
      'Задайте свой вопрос — поместите ключевой запрос в первую строку.';

  @override
  String get tipMatchTone =>
      'Подбирайте тон собеседника, чтобы быстрее установить взаимопонимание.';

  @override
  String get tipClearSubject =>
      'Четкая тема получает больше ответов, чем умная.';

  @override
  String get tipReadAloud =>
      'Прочтите свой ответ вслух один раз — он бросается в глаза неловкой формулировкой.';

  @override
  String get tipClearNextStep =>
      'Закончите одним четким следующим шагом, чтобы читатель знал, что делать.';

  @override
  String get yourPlan => 'Ваш план';

  @override
  String get plans => 'Планы';

  @override
  String get credits => 'Кредиты';

  @override
  String get totalCredits => 'Всего кредитов';

  @override
  String get watchAd => 'Посмотреть рекламу';

  @override
  String get watchAdReward => '+2 кредита';

  @override
  String get currentPlan => 'Текущий план';

  @override
  String get freePlan => 'Бесплатный план';

  @override
  String freeRepliesPerDay(int count) {
    return '$count бесплатных ответов в день';
  }

  @override
  String get upgrade => 'Улучшить';

  @override
  String get support => 'Поддержка';

  @override
  String get supportDescription => 'Справочный центр / Свяжитесь с нами';

  @override
  String get aboutDescription => 'Версия, Конфиденциальность, Условия';

  @override
  String get guidance => 'Инструкции';

  @override
  String get guidanceLibrary => 'Библиотека инструкций';

  @override
  String get languageAndInput => 'Язык и ввод';

  @override
  String get appLanguage => 'Язык приложения';

  @override
  String get voiceGuidanceLanguage => 'Язык голосовых подсказок';

  @override
  String get autoDetect => 'Автоопределение';

  @override
  String staticPreview(String label) {
    return '$label — статический предварительный просмотр.';
  }

  @override
  String get about => 'О приложении';

  @override
  String get version => 'Версия';

  @override
  String get environment => 'Среда';

  @override
  String get developerTesting => 'Тестирование разработчиков';

  @override
  String get resetFreeUsage => 'Сбросить бесплатное использование';

  @override
  String addCredits(int count) {
    return 'Добавьте $count кредитов';
  }

  @override
  String get simulatePremiumOn => 'Имитировать Премиум Вкл.';

  @override
  String get simulatePremiumOff => 'Имитировать Премиум Выкл.';

  @override
  String get refreshAccountState => 'Обновить состояние аккаунта';

  @override
  String get secureSession => 'Безопасный сеанс';

  @override
  String get anonymousSessionReady => 'Анонимный сеанс готов';

  @override
  String get connectingAnonymousSession => 'Подключение анонимного сеанса…';

  @override
  String get refreshingSecureSession => 'Обновление безопасного сеанса…';

  @override
  String get restoringAnonymousSession => 'Восстановление анонимного сеанса…';

  @override
  String get anonymousSessionUnavailable => 'Анонимный сеанс недоступен';

  @override
  String get anonymousSessionNotStarted => 'Анонимный сеанс не начался';

  @override
  String get retry => 'Повторить';

  @override
  String get developer => 'Разработчик';

  @override
  String get localBackendConnection => 'Локальное подключение к серверу';

  @override
  String get refreshBackendStatus => 'Обновить статус серверной части';

  @override
  String get checkingBackend => 'Проверка серверной части…';

  @override
  String get connected => 'Подключено';

  @override
  String get connectionFailed => 'Соединение не удалось';

  @override
  String get serviceUnreachable =>
      'Мы не смогли дозвониться до сервиса. Проверьте подключение и повторите попытку.';

  @override
  String get copied => 'Скопировано';

  @override
  String get close => 'Закрывать';

  @override
  String get tryAgain => 'Попробуйте еще раз';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Изменить';

  @override
  String get use => 'Использовать';

  @override
  String get save => 'Сохранить';

  @override
  String get done => 'Готово';

  @override
  String get manageLibrary => 'Управление библиотекой';

  @override
  String get newGuidance => 'Новое руководство';

  @override
  String get quickGuidance => 'Быстрое руководство';

  @override
  String get viewPlans => 'Посмотреть планы';

  @override
  String get restore => 'Восстановить';

  @override
  String get loading => 'Загрузка…';

  @override
  String get premium => 'Премиум';

  @override
  String get premiumUnlimited => 'Премиум · Без ограничений';

  @override
  String get updating => 'Обновление';

  @override
  String get updatingBalance => 'Обновление баланса…';

  @override
  String get balanceUnavailable => 'Баланс недоступен';

  @override
  String get checking => 'Проверка';

  @override
  String get checkingBalance => 'Проверка баланса…';

  @override
  String freeCount(int free) {
    return '$free бесплатно';
  }

  @override
  String usageBalance(int free, int credits) {
    return '$free бесплатно · $credits кредитов';
  }

  @override
  String get copyPreview => 'Копировать предварительный просмотр';

  @override
  String get copyResult => 'Копировать результат';

  @override
  String get staticPreviewCaption => 'Статический предварительный просмотр';

  @override
  String get history => 'История';

  @override
  String get clearHistory => 'Очистить историю?';

  @override
  String get clearHistoryDescription =>
      'При этом будут удалены все последние объекты на этом устройстве. Это невозможно отменить.';

  @override
  String get clearAll => 'Очистить все';

  @override
  String get messageReceived => 'Сообщение получено';

  @override
  String get messageYouReceived => 'Сообщение, которое вы получили';

  @override
  String get pasteOriginalMessage => 'Вставьте сюда исходное сообщение…';

  @override
  String get paste => 'Вставить';

  @override
  String get clear => 'Прозрачный';

  @override
  String get helpAiUnderstandIntent => 'Помогите ИИ понять ваши намерения';

  @override
  String get addReplyInstructions => 'Добавьте инструкции по ответу…';

  @override
  String get generating => 'Создание…';

  @override
  String get generateReply => 'Создать ответ';

  @override
  String get creatingNaturalOptions =>
      'Создание нескольких естественных вариантов…';

  @override
  String get replyOptionsAppearHere => 'Здесь появятся варианты ответа.';

  @override
  String get yourReplies => 'Ваши ответы';

  @override
  String get whyThisWorks => 'Почему это работает';

  @override
  String get regenerateReplies => 'Восстановить ответы';

  @override
  String get regenerateUsageNote =>
      'Регенерация создает новые ответы и использует 1 поколение.';

  @override
  String get couldNotExplain => 'Не удалось объяснить это сообщение';

  @override
  String get explainMessage => 'Объяснить сообщение';

  @override
  String get copyExplanation => 'Скопировать объяснение';

  @override
  String get meaning => 'Значение';

  @override
  String get tone => 'Тон';

  @override
  String get hiddenMeaning => 'Скрытый смысл';

  @override
  String get noHiddenMeaning => 'Скрытый смысл не обнаружен.';

  @override
  String get suggestedReplies => 'Предлагаемые ответы';

  @override
  String get moreOptions => 'Больше возможностей';

  @override
  String get audience => 'Аудитория';

  @override
  String get length => 'Длина';

  @override
  String get channel => 'Канал';

  @override
  String get describeTone => 'Опишите тон';

  @override
  String get toneHint => 'например тепло, но профессионально';

  @override
  String get describeRelationship => 'Опишите отношения';

  @override
  String get relationshipHint => 'Например: мой домовладелец';

  @override
  String get customizeStyleToneFormat => 'Настройте стиль, тон и формат';

  @override
  String get bePolite => 'Будьте вежливы';

  @override
  String get keepItShort => 'Держите это коротким';

  @override
  String get professional => 'Профессиональный';

  @override
  String get friendly => 'Дружелюбно';

  @override
  String get declinePolitely => 'Отклонить вежливо';

  @override
  String get sayThankYou => 'Скажи спасибо';

  @override
  String get auto => 'Авто';

  @override
  String get natural => 'Естественный';

  @override
  String get custom => 'Обычай';

  @override
  String get friend => 'Друг';

  @override
  String get customer => 'Клиент';

  @override
  String get coworker => 'Коллега';

  @override
  String get manager => 'Менеджер';

  @override
  String get short => 'Короткий';

  @override
  String get medium => 'Середина';

  @override
  String get detailed => 'Подробный';

  @override
  String get textChannel => 'Текст';

  @override
  String get email => 'Электронная почта';

  @override
  String get chat => 'Чат';

  @override
  String get textToPolish => 'Текст для доработки';

  @override
  String get pasteTextToImprove => 'Вставьте текст, который вы хотите улучшить';

  @override
  String get pasteYourText => 'Вставьте сюда свой текст…';

  @override
  String get improvingClarity => 'Улучшение ясности, сохраняя при этом смысл…';

  @override
  String get polishedTextAppearsHere => 'Улучшенный текст появится здесь.';

  @override
  String get polishedResult => 'Улучшенный текст';

  @override
  String get whatChanged => 'Что изменилось?';

  @override
  String get polishAgain => 'Улучшить снова';

  @override
  String get polishAgainUsageNote =>
      'Повторное улучшение создает новый результат и использует 1 поколение.';

  @override
  String get messageToUnderstand => 'Сообщение для понимания';

  @override
  String get pasteMessageReceived => 'Вставьте полученное сообщение';

  @override
  String get explainThisMessage => 'Объясните это сообщение';

  @override
  String get explaining => 'Объяснение…';

  @override
  String get readingBetweenLines => 'Читая между строк…';

  @override
  String get explanationAppearsHere => 'Ваше объяснение появится здесь.';

  @override
  String get noSuggestedReplies =>
      'Ни одного предложенного ответа не получено.';

  @override
  String get copy => 'Копировать';

  @override
  String get enterMessageFirst => 'Сначала введите сообщение, чтобы объяснить.';

  @override
  String get explainRateLimited =>
      'На данный момент вы достигли предела объяснений. Пожалуйста, повторите попытку позже.';

  @override
  String get explainParseError =>
      'Мы не могли ясно прочитать объяснение. Пожалуйста, попробуйте еще раз.';

  @override
  String get explainUnavailable =>
      'Объяснение временно недоступно. Пожалуйста, повторите попытку в ближайшее время.';

  @override
  String get unableToExplain => 'Невозможно объяснить это сообщение.';

  @override
  String get replyCtaTitle =>
      'Хотите ответ, который лучше соответствует вашим намерениям?';

  @override
  String get premiumTitle => 'ReplyWise Премиум';

  @override
  String get back => 'Назад';

  @override
  String get threeDaysFree => '3 дня бесплатно';

  @override
  String get unlimitedReply => 'Неограниченное количество поколений ответов';

  @override
  String get unlimitedPolish => 'Неограниченные улучшения текста';

  @override
  String get balancesPreserved =>
      'Свободные и кредитные остатки остаются сохраненными';

  @override
  String get loadingSubscriptionOptions => 'Загрузка вариантов подписки…';

  @override
  String get startFreeTrial => 'Начать 3-дневную бесплатную пробную версию';

  @override
  String get startYearlyPlan => 'Начать годовой план';

  @override
  String trialTerms(String price) {
    return 'Бесплатно в течение 3 дней, затем $price в год. Отменить в любое время.';
  }

  @override
  String yearlyTerms(String price) {
    return '$price/год. Отменить в любое время.';
  }

  @override
  String get displayedPrice => 'отображаемая цена';

  @override
  String get topUpCredits => 'Пополнения кредитов';

  @override
  String pricePerCredit(String price) {
    return '$price за кредит';
  }

  @override
  String get creditDescription =>
      'Каждый балл покрывает один ответ или одно улучшение текста. Кредиты никогда не истекают.';

  @override
  String get loadingCreditPackages => 'Загрузка кредитных пакетов…';

  @override
  String get creditPackagesUnavailable => 'Кредитные пакеты сейчас недоступны.';

  @override
  String get refreshPackages => 'Обновить пакеты';

  @override
  String buyCreditPackage(int credits, String price) {
    return 'Купить кредиты $credits — $price';
  }

  @override
  String get restoring => 'Восстановление…';

  @override
  String get restorePremium => 'Восстановить Премиум подписку';

  @override
  String get purchaseVerification =>
      'Покупки премиум-класса и кредитов проверяются ReplyWise. Покупки в кредит сверяются автоматически.';

  @override
  String get newGuidanceTooltip => 'Новое руководство';

  @override
  String get builtIn => 'Встроенный';

  @override
  String get myGuidance => 'Мое руководство';

  @override
  String get useInReply => 'Использовать в ответе';

  @override
  String get useInPolish => 'Используйте для улучшения текста';

  @override
  String get deleteGuidance => 'Удалить это руководство?';

  @override
  String get cannotBeUndone => 'Это невозможно отменить.';

  @override
  String get category => 'Категория';

  @override
  String get titleLabel => 'Заголовок';

  @override
  String get guidanceTitleHint => 'Краткое название этого руководства…';

  @override
  String get guidanceHint => 'Опишите, как ИИ должен формировать ответ…';

  @override
  String get writeAnyLanguage => 'Пишите на любом языке';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get saveGuidance => 'Сохранить руководство';

  @override
  String get couldNotSaveGuidance =>
      'Не удалось сохранить это руководство. Пожалуйста, попробуйте еще раз.';

  @override
  String get concise => 'Краткий';

  @override
  String get moreNatural => 'Более естественный';

  @override
  String get improveGrammar => 'Улучшить грамматику';

  @override
  String get fixSpelling => 'Исправить орфографию';

  @override
  String get morePersuasive => 'Более убедительно';

  @override
  String get moreConfident => 'Более уверенно';

  @override
  String get simplifyWording => 'Упростить формулировку';

  @override
  String get betterFlow => 'Улучшенный поток';

  @override
  String get describePolish =>
      'Опишите, как вы хотите доработать черновой вариант';

  @override
  String get describeAudience => 'Опишите аудиторию';

  @override
  String get audienceHint => 'например мой менеджер';

  @override
  String get extraInstruction => 'Дополнительная инструкция';

  @override
  String get extraPolishHint =>
      'Добавьте любые другие настройки улучшения текста.';

  @override
  String get polishing => 'Улучшение текста…';

  @override
  String get polishText => 'Улучшить текст';

  @override
  String get adjustToneLengthFormat => 'Отрегулируйте тон, длину и формат';

  @override
  String get instructionProfessional =>
      'Сделайте так, чтобы текст звучал профессионально.';

  @override
  String get instructionFriendly =>
      'Сделайте письмо более теплым и дружелюбным.';

  @override
  String get instructionConcise => 'Сделайте письмо кратким и прямым.';

  @override
  String get instructionNatural =>
      'Сделайте так, чтобы формулировка звучала естественно и свободно.';

  @override
  String get instructionGrammar => 'Исправьте грамматику, сохранив смысл.';

  @override
  String get instructionSpelling => 'Исправьте все орфографические ошибки.';

  @override
  String get instructionPersuasive =>
      'Сделайте письмо более убедительным и убедительным.';

  @override
  String get instructionConfident =>
      'Сделайте так, чтобы письмо звучало четко и уверенно.';

  @override
  String get instructionSimple =>
      'Используйте более простые и понятные формулировки.';

  @override
  String get instructionFlow =>
      'Улучшите последовательность предложений и переходы.';

  @override
  String get shorter => 'короче';

  @override
  String get sameLength => 'Такой же';

  @override
  String get longer => 'дольше';

  @override
  String get favorites => 'Избранное';

  @override
  String get createGuidanceEmpty =>
      'Создайте собственное руководство, чтобы использовать его позже.';

  @override
  String get removeFavorite => 'Удалить из избранного';

  @override
  String get addFavorite => 'Добавить в избранное';

  @override
  String useTemplate(String title) {
    return 'Используйте «$title»';
  }

  @override
  String get chooseGuidance => 'Выберите руководство';

  @override
  String get library => 'Библиотека';

  @override
  String get general => 'Общий';

  @override
  String get decline => 'Отклонить';

  @override
  String get thanks => 'Спасибо';

  @override
  String get followUp => 'Следовать за';

  @override
  String get editGuidance => 'Изменить руководство';

  @override
  String get makeProfessional => 'Сделайте это профессионально';

  @override
  String get makeFriendly => 'Сделайте это дружелюбным';

  @override
  String get askMoreTime => 'Попросите больше времени';

  @override
  String get soundConfident => 'Звучит уверенно';

  @override
  String get guidancePoliteContent => 'Ответьте вежливо и уважительно.';

  @override
  String get guidanceShortContent => 'Держите ответ кратким и ясным.';

  @override
  String get guidanceProfessionalContent =>
      'Сделайте так, чтобы ответ звучал профессионально и уместно для работы.';

  @override
  String get guidanceFriendlyContent => 'Сделайте ответ теплым и дружелюбным.';

  @override
  String get guidanceDeclineContent =>
      'Вежливо отклоните просьбу, но не грубо.';

  @override
  String get guidanceThanksContent =>
      'Добавьте признательность и вежливое спасибо.';

  @override
  String get guidanceMoreTimeContent =>
      'Попросите больше времени, стараясь звучать ответственно и вежливо.';

  @override
  String get guidanceConfidentContent =>
      'Пусть ответ звучит уверенно, но не агрессивно.';

  @override
  String todayAt(String time) {
    return 'Сегодня · $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Вчера · $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date · $time';
  }

  @override
  String get premiumActive => 'Премиум-подписка активна';

  @override
  String creditsRemaining(String count) {
    return 'Осталось $count кредитов';
  }

  @override
  String get adIsLoading =>
      'Реклама загружается. Пожалуйста, попробуйте снова.';

  @override
  String get creditAdded => 'Кредит добавлен.';

  @override
  String get outOfCreditsTitle => 'У тебя закончились кредиты';

  @override
  String get outOfCreditsMessage =>
      'Посмотрите короткую рекламу, чтобы получить 2 бесплатных кредита, или обновите версию, чтобы получить больше доступа.';

  @override
  String get buyCredits => 'Купить кредиты';

  @override
  String get creditAddedTapGenerateAgain =>
      'Кредит добавлен. Нажмите «Создать» еще раз.';

  @override
  String get adDailyLimitReached =>
      'Достигнут дневной лимит наград за рекламу.';

  @override
  String get adLoadFailed => 'Не удалось загрузить рекламу. Попробуйте позже.';

  @override
  String get adRewardCooldown =>
      'Подождите немного, прежде чем смотреть другую рекламу.';

  @override
  String get adRewardFailed => 'Не удалось добавить кредит. Попробуйте снова.';

  @override
  String get recentDetail => 'Подробности';

  @override
  String get useAgain => 'Использовать снова';
}
