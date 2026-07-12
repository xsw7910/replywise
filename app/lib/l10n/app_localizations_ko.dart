// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'ReplyWise';

  @override
  String get systemDefault => '시스템 기본값';

  @override
  String get chooseLanguage => '앱 언어 선택';

  @override
  String get settings => '설정';

  @override
  String get settingsSubtitle => '계정 및 앱 환경설정 관리';

  @override
  String get home => '홈';

  @override
  String get reply => '답장';

  @override
  String get explain => '설명';

  @override
  String get polish => '다듬기';

  @override
  String get yourAiReplyAssistant => '당신의 AI 답장 도우미';

  @override
  String get generateThoughtfulReplies => '사려 깊은 답변을 즉시 생성하세요.';

  @override
  String get makeWritingClear => '글을 명확하고 자연스럽게 작성하세요.';

  @override
  String get understandTone => '어조와 숨겨진 의미를 이해합니다.';

  @override
  String get templates => '템플릿';

  @override
  String get reuseInstructions => '좋아하는 AI 지침을 재사용하세요.';

  @override
  String get recent => '최근';

  @override
  String get viewAll => '모두 보기';

  @override
  String get nothingHereYet => '아직 내용이 없습니다';

  @override
  String get recentEmptyMessage => '최근 답변, 세련된 텍스트, 설명이 여기에 표시됩니다.';

  @override
  String get createFirstReply => '첫 답장 만들기';

  @override
  String get tipOfTheDay => '오늘의 팁';

  @override
  String get tipShortEmails => '응답률을 높이려면 이메일을 120단어 미만으로 유지하세요.';

  @override
  String get tipLeadWithAsk => '질문부터 시작하세요. 첫 번째 줄에 핵심 요청을 입력하세요.';

  @override
  String get tipMatchTone => '상대방의 말투를 맞춰서 더 빠르게 관계를 형성하세요.';

  @override
  String get tipClearSubject => '명확한 제목은 기발한 제목보다 더 많은 답변을 얻습니다.';

  @override
  String get tipReadAloud => '답장을 큰 소리로 한 번 읽으십시오. 어색한 문구가 발견됩니다.';

  @override
  String get tipClearNextStep => '독자가 무엇을 해야 할지 알 수 있도록 명확한 다음 단계로 마무리하세요.';

  @override
  String get yourPlan => '내 요금제';

  @override
  String get plans => '요금제';

  @override
  String get credits => '크레딧';

  @override
  String get totalCredits => '총 크레딧';

  @override
  String get watchAd => '광고 보기';

  @override
  String get watchAdReward => '+2 크레딧';

  @override
  String get currentPlan => '현재 요금제';

  @override
  String get freePlan => '무료 플랜';

  @override
  String freeRepliesPerDay(int count) {
    return '$count 하루 무료 답장';
  }

  @override
  String get upgrade => '업그레이드';

  @override
  String get support => '고객 지원';

  @override
  String get supportDescription => '도움말 센터 / 문의하기';

  @override
  String get aboutDescription => '버전, 개인정보 보호, 약관';

  @override
  String get guidance => '가이드';

  @override
  String get guidanceLibrary => '템플릿';

  @override
  String get languageAndInput => '언어 및 입력';

  @override
  String get appLanguage => '앱 언어';

  @override
  String get voiceGuidanceLanguage => '음성 안내 언어';

  @override
  String get autoDetect => '자동 감지';

  @override
  String staticPreview(String label) {
    return '$label은 정적 미리보기입니다.';
  }

  @override
  String get about => '정보';

  @override
  String get version => '버전';

  @override
  String get environment => '환경';

  @override
  String get developerTesting => '개발자 테스트';

  @override
  String get resetFreeUsage => '무료 사용량 재설정';

  @override
  String addCredits(int count) {
    return '$count 크레딧 추가';
  }

  @override
  String get simulatePremiumOn => '프리미엄 시뮬레이션';

  @override
  String get simulatePremiumOff => '시뮬레이션 프리미엄 끄기';

  @override
  String get refreshAccountState => '계정 상태 새로 고침';

  @override
  String get secureSession => '보안 세션';

  @override
  String get anonymousSessionReady => '익명 세션이 준비되었습니다.';

  @override
  String get connectingAnonymousSession => '익명 세션 연결 중…';

  @override
  String get refreshingSecureSession => '보안 세션을 새로 고치는 중…';

  @override
  String get restoringAnonymousSession => '익명 세션 복원 중…';

  @override
  String get anonymousSessionUnavailable => '익명 세션을 사용할 수 없습니다.';

  @override
  String get anonymousSessionNotStarted => '익명 세션이 시작되지 않았습니다.';

  @override
  String get retry => '다시 시도';

  @override
  String get developer => '개발자';

  @override
  String get localBackendConnection => '로컬 백엔드 연결';

  @override
  String get refreshBackendStatus => '백엔드 상태 새로 고침';

  @override
  String get checkingBackend => '백엔드 확인 중…';

  @override
  String get connected => '연결됨';

  @override
  String get connectionFailed => '연결 실패';

  @override
  String get serviceUnreachable => '서비스에 연결할 수 없습니다. 연결을 확인하고 다시 시도하세요.';

  @override
  String get copied => '복사됨';

  @override
  String get close => '닫다';

  @override
  String get tryAgain => '다시 시도하세요';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get edit => '편집';

  @override
  String get use => '사용';

  @override
  String get save => '저장';

  @override
  String get done => '완료';

  @override
  String get manageLibrary => '템플릿 관리';

  @override
  String get newGuidance => '새로운 지침';

  @override
  String get quickGuidance => '빠른 안내';

  @override
  String get viewPlans => '계획 보기';

  @override
  String get restore => '복원하다';

  @override
  String get loading => '로드 중…';

  @override
  String get premium => '프리미엄';

  @override
  String get premiumUnlimited => '프리미엄 · 무제한';

  @override
  String get updating => '업데이트 중';

  @override
  String get updatingBalance => '잔액 업데이트 중…';

  @override
  String get balanceUnavailable => '잔액을 사용할 수 없음';

  @override
  String get checking => '확인 중';

  @override
  String get checkingBalance => '잔액 확인 중…';

  @override
  String freeCount(int free) {
    return '$free 무료';
  }

  @override
  String usageBalance(int free, int credits) {
    return '$free 무료 · $credits 크레딧';
  }

  @override
  String get copyPreview => '미리보기 복사';

  @override
  String get copyResult => '결과 복사';

  @override
  String get staticPreviewCaption => '정적 미리보기';

  @override
  String get history => '역사';

  @override
  String get clearHistory => '기록을 삭제하시겠습니까?';

  @override
  String get clearHistoryDescription =>
      '이렇게 하면 이 기기의 최근 항목이 모두 삭제됩니다. 이 작업은 취소할 수 없습니다.';

  @override
  String get clearAll => '모두 지우기';

  @override
  String get messageReceived => '메시지 수신됨';

  @override
  String get messageYouReceived => '받은 메시지';

  @override
  String get pasteOriginalMessage => '여기에 원본 메시지를 붙여넣으세요…';

  @override
  String get paste => '반죽';

  @override
  String get clear => '분명한';

  @override
  String get helpAiUnderstandIntent => 'AI가 사용자의 의도를 이해하도록 돕기';

  @override
  String get addReplyInstructions => '답장 지침을 추가하세요...';

  @override
  String get generating => '생성 중…';

  @override
  String get generateReply => '답장 생성';

  @override
  String get creatingNaturalOptions => '몇 가지 자연스러운 옵션 만들기…';

  @override
  String get replyOptionsAppearHere => '답장 옵션이 여기에 표시됩니다.';

  @override
  String get yourReplies => '귀하의 답변';

  @override
  String get whyThisWorks => '이것이 작동하는 이유';

  @override
  String get regenerateReplies => '답글 재생성';

  @override
  String get regenerateUsageNote => '재생성은 새로운 응답을 생성하고 1세대를 사용합니다.';

  @override
  String get couldNotExplain => '이 메시지를 설명할 수 없습니다.';

  @override
  String get explainMessage => '메시지 설명';

  @override
  String get copyExplanation => '설명 복사';

  @override
  String get meaning => '의미';

  @override
  String get tone => '음정';

  @override
  String get hiddenMeaning => '숨겨진 의미';

  @override
  String get noHiddenMeaning => '숨겨진 의미가 감지되지 않았습니다.';

  @override
  String get suggestedReplies => '제안된 답변';

  @override
  String get moreOptions => '추가 옵션';

  @override
  String get audience => '청중';

  @override
  String get length => '길이';

  @override
  String get channel => '채널';

  @override
  String get describeTone => '톤을 설명하세요.';

  @override
  String get toneHint => '예를 들어 따뜻하지만 전문적인';

  @override
  String get describeRelationship => '관계를 설명하세요.';

  @override
  String get relationshipHint => '예: 내 집주인';

  @override
  String get customizeStyleToneFormat => '스타일, 톤, 형식을 맞춤설정하세요.';

  @override
  String get bePolite => '예의바르게 행동하세요';

  @override
  String get keepItShort => '짧게 유지하세요';

  @override
  String get professional => '전문적인';

  @override
  String get friendly => '친숙한';

  @override
  String get declinePolitely => '정중하게 거절하다';

  @override
  String get sayThankYou => '감사하다고 말하세요';

  @override
  String get auto => '자동';

  @override
  String get natural => '자연스러운';

  @override
  String get custom => '관습';

  @override
  String get friend => '친구';

  @override
  String get customer => '고객';

  @override
  String get coworker => '동료';

  @override
  String get manager => '관리자';

  @override
  String get short => '짧은';

  @override
  String get medium => '중간';

  @override
  String get detailed => '상세한';

  @override
  String get textChannel => '텍스트';

  @override
  String get email => '이메일';

  @override
  String get chat => '채팅';

  @override
  String get textToPolish => '다듬을 텍스트';

  @override
  String get pasteTextToImprove => '개선하고 싶은 텍스트를 붙여넣으세요.';

  @override
  String get pasteYourText => '여기에 텍스트를 붙여넣으세요…';

  @override
  String get improvingClarity => '의미를 유지하면서 명확성을 향상시키세요…';

  @override
  String get polishedTextAppearsHere => '개선된 텍스트가 여기에 표시됩니다.';

  @override
  String get polishedResult => '향상된 텍스트';

  @override
  String get whatChanged => '무엇이 바뀌었나요?';

  @override
  String get polishAgain => '다시 개선하세요';

  @override
  String get polishAgainUsageNote => '다시 개선하면 새로운 결과가 생성되고 1세대가 사용됩니다.';

  @override
  String get messageToUnderstand => '이해하라는 메시지';

  @override
  String get pasteMessageReceived => '받은 메시지를 붙여넣으세요.';

  @override
  String get explainThisMessage => '이 메시지를 설명하세요';

  @override
  String get explaining => '설명 중…';

  @override
  String get readingBetweenLines => '줄 사이를 읽는 중…';

  @override
  String get explanationAppearsHere => '귀하의 설명이 여기에 표시됩니다.';

  @override
  String get noSuggestedReplies => '추천 답변이 반환되지 않았습니다.';

  @override
  String get copy => '복사';

  @override
  String get enterMessageFirst => '먼저 설명할 메시지를 입력하세요.';

  @override
  String get explainRateLimited => '현재 설명 한도에 도달했습니다. 나중에 다시 시도해 주세요.';

  @override
  String get explainParseError => '설명을 명확하게 읽을 수 없었습니다. 다시 시도해 주세요.';

  @override
  String get explainUnavailable => '일시적으로 설명을 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get unableToExplain => '이 메시지를 설명할 수 없습니다.';

  @override
  String get replyCtaTitle => '귀하의 의도에 더 잘 맞는 답변을 원하시나요?';

  @override
  String get premiumTitle => 'ReplyWise 프리미엄';

  @override
  String get back => '뒤쪽에';

  @override
  String get threeDaysFree => '3일 무료';

  @override
  String get unlimitedReply => '무제한 응답 세대';

  @override
  String get unlimitedPolish => '무제한 텍스트 개선';

  @override
  String get balancesPreserved => '무료 및 크레딧 잔액이 유지됩니다.';

  @override
  String get loadingSubscriptionOptions => '구독 옵션 로드 중…';

  @override
  String get startFreeTrial => '3일 무료 평가판 시작';

  @override
  String get startYearlyPlan => '연간 요금제 시작';

  @override
  String trialTerms(String price) {
    return '3일 동안 무료이며 그 이후에는 $price/년입니다. 언제든지 취소하세요.';
  }

  @override
  String yearlyTerms(String price) {
    return '$price/년. 언제든지 취소하세요.';
  }

  @override
  String get displayedPrice => '표시된 가격';

  @override
  String get topUpCredits => '충전 크레딧';

  @override
  String pricePerCredit(String price) {
    return '크레딧당 $price';
  }

  @override
  String get creditDescription =>
      '각 크레딧에는 하나의 답변 또는 하나의 텍스트 개선이 포함됩니다. 크레딧은 만료되지 않습니다.';

  @override
  String get loadingCreditPackages => '크레딧 패키지 로드 중…';

  @override
  String get creditPackagesUnavailable => '지금은 크레딧 패키지를 사용할 수 없습니다.';

  @override
  String get refreshPackages => '패키지 새로 고침';

  @override
  String buyCreditPackage(int credits, String price) {
    return '$credits 크레딧 구매 — $price';
  }

  @override
  String get restoring => '복원 중…';

  @override
  String get restorePremium => '프리미엄 구독 복원';

  @override
  String get purchaseVerification =>
      '프리미엄 및 크레딧 구매는 ReplyWise를 통해 확인됩니다. 크레딧 구매는 자동으로 조정됩니다.';

  @override
  String get newGuidanceTooltip => '새로운 지침';

  @override
  String get builtIn => '내장';

  @override
  String get myGuidance => '나의 지침';

  @override
  String get useInReply => '답장에 사용';

  @override
  String get useInPolish => '텍스트 개선에 사용';

  @override
  String get deleteGuidance => '이 지침을 삭제하시겠습니까?';

  @override
  String get cannotBeUndone => '이 작업은 취소할 수 없습니다.';

  @override
  String get category => '범주';

  @override
  String get titleLabel => '제목';

  @override
  String get guidanceTitleHint => '이 지침의 약칭…';

  @override
  String get guidanceHint => 'AI가 응답을 어떻게 형성해야 하는지 설명하세요…';

  @override
  String get writeAnyLanguage => '어떤 언어로든 쓰세요';

  @override
  String get saveChanges => '변경사항 저장';

  @override
  String get saveGuidance => '안내 저장';

  @override
  String get couldNotSaveGuidance => '이 안내를 저장할 수 없습니다. 다시 시도해 주세요.';

  @override
  String get concise => '간결한';

  @override
  String get moreNatural => '더 자연스러워요';

  @override
  String get improveGrammar => '문법 향상';

  @override
  String get fixSpelling => '철자 수정';

  @override
  String get morePersuasive => '더 설득력 있음';

  @override
  String get moreConfident => '더 자신감있게';

  @override
  String get simplifyWording => '표현 단순화';

  @override
  String get betterFlow => '더 나은 흐름';

  @override
  String get describePolish => '초안을 어떻게 다듬기를 원하는지 설명하세요.';

  @override
  String get describeAudience => '청중을 설명하라';

  @override
  String get audienceHint => '예를 들어 내 매니저';

  @override
  String get extraInstruction => '추가 지시 사항';

  @override
  String get extraPolishHint => '기타 텍스트 개선 기본 설정 추가';

  @override
  String get polishing => '텍스트 개선 중…';

  @override
  String get polishText => '텍스트 개선';

  @override
  String get adjustToneLengthFormat => '톤, 길이, 형식 조정';

  @override
  String get instructionProfessional => '글쓰기를 전문적으로 들리게 만드세요.';

  @override
  String get instructionFriendly => '글을 더욱 따뜻하고 친근하게 만들어 보세요.';

  @override
  String get instructionConcise => '글을 간결하고 직접적으로 작성하세요.';

  @override
  String get instructionNatural => '자연스럽고 유창하게 표현되도록 하세요.';

  @override
  String get instructionGrammar => '의미를 유지하면서 문법을 수정하세요.';

  @override
  String get instructionSpelling => '모든 철자 오류를 수정하세요.';

  @override
  String get instructionPersuasive => '글을 더욱 설득력 있고 매력적으로 만드세요.';

  @override
  String get instructionConfident => '글을 명확하고 자신감 있게 작성하세요.';

  @override
  String get instructionSimple => '더 간단하고 읽기 쉬운 문구를 사용하세요.';

  @override
  String get instructionFlow => '문장 흐름과 전환을 개선합니다.';

  @override
  String get shorter => '더 짧게';

  @override
  String get sameLength => '같은';

  @override
  String get longer => '더 길게';

  @override
  String get favorites => '즐겨찾기';

  @override
  String get createGuidanceEmpty => '나중에 재사용할 수 있도록 자신만의 지침을 만드세요.';

  @override
  String get removeFavorite => '즐겨찾기에서 제거';

  @override
  String get addFavorite => '즐겨찾기에 추가';

  @override
  String useTemplate(String title) {
    return '\'$title\'을 사용하세요.';
  }

  @override
  String get chooseGuidance => '안내를 선택하세요';

  @override
  String get library => '도서관';

  @override
  String get general => '일반적인';

  @override
  String get decline => '감소';

  @override
  String get thanks => '감사해요';

  @override
  String get followUp => '후속 조치';

  @override
  String get editGuidance => '지침 편집';

  @override
  String get makeProfessional => '전문적으로 만드세요';

  @override
  String get makeFriendly => '친근하게 만드세요';

  @override
  String get askMoreTime => '시간을 더 달라고 요청하세요';

  @override
  String get soundConfident => '자신감 있는 소리';

  @override
  String get guidancePoliteContent => '대답은 정중하고 정중하게 하세요.';

  @override
  String get guidanceShortContent => '답변은 짧고 명확하게 유지하세요.';

  @override
  String get guidanceProfessionalContent => '전문적이고 업무에 적합한 답변을 만드십시오.';

  @override
  String get guidanceFriendlyContent => '따뜻하고 친근한 답변을 해주세요.';

  @override
  String get guidanceDeclineContent => '무례하게 들리지 않고 정중하게 요청을 거절하세요.';

  @override
  String get guidanceThanksContent => '감사와 정중한 감사를 더해보세요.';

  @override
  String get guidanceMoreTimeContent => '책임감 있고 정중하게 말하면서 더 많은 시간을 요청하십시오.';

  @override
  String get guidanceConfidentContent => '대답은 자신감 있게 들리되 공격적이지는 않게 하십시오.';

  @override
  String todayAt(String time) {
    return '오늘 · $time';
  }

  @override
  String yesterdayAt(String time) {
    return '어제 · $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date · $time';
  }

  @override
  String get premiumActive => '프리미엄 구독 활성';

  @override
  String creditsRemaining(String count) {
    return '$count 크레딧 남음';
  }

  @override
  String get adIsLoading => '광고를 불러오는 중입니다. 다시 시도해 주세요.';

  @override
  String get creditAdded => '크레딧이 추가되었습니다.';

  @override
  String get outOfCreditsTitle => '크레딧이 부족합니다.';

  @override
  String get outOfCreditsMessage =>
      '짧은 광고를 시청하여 2개의 무료 크레딧을 받거나 업그레이드하여 더 많은 액세스 권한을 얻으세요.';

  @override
  String get buyCredits => '크레딧 구매';

  @override
  String get creditAddedTapGenerateAgain => '크레딧이 추가되었습니다. 생성을 다시 탭하세요.';

  @override
  String get adDailyLimitReached => '일일 광고 보상 한도에 도달했습니다.';

  @override
  String get adLoadFailed => '광고를 불러올 수 없습니다. 나중에 다시 시도해 주세요.';

  @override
  String get adRewardCooldown => '다른 광고를 보기 전에 잠시 기다려 주세요.';

  @override
  String get adRewardFailed => '크레딧을 추가하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get recentDetail => '세부정보';

  @override
  String get useAgain => '다시 사용';

  @override
  String get useATemplate => '템플릿 사용';

  @override
  String get acceptPolitely => '정중히 수락';

  @override
  String get askForClarification => '설명 요청';

  @override
  String get explainTheReason => '이유 설명';

  @override
  String get offerAnAlternative => '대안 제시';

  @override
  String get suggestACompromise => '절충안 제안';

  @override
  String get showAppreciation => '감사 표현';

  @override
  String get apologizeBriefly => '간단히 사과';

  @override
  String get beFirmButKind => '단호하지만 친절하게';

  @override
  String get appStatusMaintenanceTitle => '점검 중';

  @override
  String get appStatusServerUnavailableMessage =>
      '서버에 연결하는 데 문제가 있습니다. 나중에 다시 시도해 주세요.';

  @override
  String get appStatusUpdateRequiredTitle => '업데이트 필요';

  @override
  String get appStatusUpdateNow => '지금 업데이트';

  @override
  String get appStatusUpdateAvailableTitle => '업데이트 사용 가능';

  @override
  String get appStatusUpdate => '업데이트';

  @override
  String get appStatusLater => '나중에';

  @override
  String get appStatusFeatureUnavailableTitle => '일시적으로 사용할 수 없음';

  @override
  String get appStatusFeatureUnavailableMessage =>
      '이 기능은 일시적으로 사용할 수 없습니다. 나중에 다시 시도해 주세요.';

  @override
  String get gotIt => '확인';

  @override
  String get getCredits => '크레딧 받기';

  @override
  String get errorEmptyInputTitle => '먼저 메시지를 추가하세요';

  @override
  String get errorEmptyInputMessage => '도움이 필요한 메시지를 입력해 주세요.';

  @override
  String get errorConnectionTitle => '연결 문제';

  @override
  String get errorConnectionMessage =>
      '서버에 연결하는 데 문제가 있습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get errorServiceUnavailableTitle => '서비스를 이용할 수 없음';

  @override
  String get errorServiceUnavailableMessage =>
      'ReplyWise를 일시적으로 이용할 수 없습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorCreditsTitle => '크레딧이 없습니다';

  @override
  String get errorCreditsMessage => '계속하려면 크레딧이 필요합니다.';

  @override
  String get errorRateLimitedTitle => '잠시 기다려 주세요';

  @override
  String get errorRateLimitedMessage => '요청을 너무 빠르게 보내고 있습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorAiBusyTitle => 'AI가 바쁩니다';

  @override
  String get errorAiBusyMessage => 'AI 서비스를 일시적으로 이용할 수 없습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorUnexpectedTitle => '문제가 발생했습니다';

  @override
  String get errorUnexpectedMessage => '다시 시도해 주세요.';

  @override
  String get shareReply => '답장 공유';

  @override
  String get shareExplanation => '설명 공유';

  @override
  String get sharePolishedText => '다듬은 텍스트 공유';
}
