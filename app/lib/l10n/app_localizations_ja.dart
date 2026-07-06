// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '返信ワイズ';

  @override
  String get systemDefault => 'システムのデフォルト';

  @override
  String get chooseLanguage => 'アプリの言語を選択';

  @override
  String get settings => '設定';

  @override
  String get home => 'ホーム';

  @override
  String get reply => '返信';

  @override
  String get explain => '解説';

  @override
  String get polish => '推敲';

  @override
  String get yourAiReplyAssistant => 'AI 応答アシスタント';

  @override
  String get generateThoughtfulReplies => '思慮深い返信を即座に生成します。';

  @override
  String get makeWritingClear => '文章を明確かつ自然にしましょう。';

  @override
  String get understandTone => 'トーンと隠された意味を理解する。';

  @override
  String get templates => 'テンプレート';

  @override
  String get reuseInstructions => 'お気に入りの AI 命令を再利用します。';

  @override
  String get recent => '最近';

  @override
  String get viewAll => 'すべて表示';

  @override
  String get nothingHereYet => 'まだ何もありません';

  @override
  String get recentEmptyMessage => '最近の返信、洗練されたテキスト、説明がここに表示されます。';

  @override
  String get createFirstReply => '最初の返信を作成';

  @override
  String get tipOfTheDay => '今日のヒント';

  @override
  String get tipShortEmails => '返信率を高めるには、メールを 120 ワード以下に抑えます。';

  @override
  String get tipLeadWithAsk => '質問を先導します。最初の行に重要なリクエストを入れます。';

  @override
  String get tipMatchTone => '相手の口調に合わせて、信頼関係をより早く築きましょう。';

  @override
  String get tipClearSubject => '明確な件名は、気の利いた件名よりも多くの返信を受け取ります。';

  @override
  String get tipReadAloud => '返信を一度声に出して読んでください。ぎこちない表現が聞き取れます。';

  @override
  String get tipClearNextStep => '最後に明確な次のステップを 1 つ提示して、読者が何をすべきかを理解できるようにします。';

  @override
  String get yourPlan => '現在のプラン';

  @override
  String get plans => 'プラン';

  @override
  String get credits => 'クレジット';

  @override
  String get totalCredits => '総クレジット数';

  @override
  String get watchAd => '広告を見る';

  @override
  String get watchAdReward => '+1クレジット';

  @override
  String get currentPlan => '現在のプラン';

  @override
  String get freePlan => '無料プラン';

  @override
  String freeRepliesPerDay(int count) {
    return '1 日あたり $count 回の無料返信';
  }

  @override
  String get upgrade => 'アップグレード';

  @override
  String get support => 'サポート';

  @override
  String get supportDescription => 'ヘルプセンター / お問い合わせ';

  @override
  String get aboutDescription => 'バージョン、プライバシー、規約';

  @override
  String get guidance => 'ガイダンス';

  @override
  String get guidanceLibrary => 'ガイダンスライブラリ';

  @override
  String get languageAndInput => '言語と入力';

  @override
  String get appLanguage => 'アプリの言語';

  @override
  String get voiceGuidanceLanguage => '音声ガイド言語';

  @override
  String get autoDetect => '自動検出';

  @override
  String staticPreview(String label) {
    return '$label は静的プレビューです。';
  }

  @override
  String get about => 'アプリについて';

  @override
  String get version => 'バージョン';

  @override
  String get environment => '環境';

  @override
  String get developerTesting => '開発者テスト';

  @override
  String get resetFreeUsage => '無料使用量をリセットする';

  @override
  String addCredits(int count) {
    return '$count クレジットを追加';
  }

  @override
  String get simulatePremiumOn => 'プレミアムをシミュレートする';

  @override
  String get simulatePremiumOff => 'プレミアムオフをシミュレート';

  @override
  String get refreshAccountState => 'アカウントの状態を更新する';

  @override
  String get secureSession => '安全なセッション';

  @override
  String get anonymousSessionReady => '匿名セッションの準備ができました';

  @override
  String get connectingAnonymousSession => '匿名セッションを接続中…';

  @override
  String get refreshingSecureSession => '安全なセッションを更新しています…';

  @override
  String get restoringAnonymousSession => '匿名セッションを復元しています…';

  @override
  String get anonymousSessionUnavailable => '匿名セッションは使用できません';

  @override
  String get anonymousSessionNotStarted => '匿名セッションが開始されていません';

  @override
  String get retry => '再試行';

  @override
  String get developer => '開発者';

  @override
  String get localBackendConnection => 'ローカルバックエンド接続';

  @override
  String get refreshBackendStatus => 'バックエンドのステータスを更新する';

  @override
  String get checkingBackend => 'バックエンドをチェック中…';

  @override
  String get connected => '接続済み';

  @override
  String get connectionFailed => '接続に失敗しました';

  @override
  String get serviceUnreachable => 'サービスにアクセスできませんでした。接続を確認して、もう一度試してください。';

  @override
  String get copied => 'コピーされました';

  @override
  String get close => '近い';

  @override
  String get tryAgain => 'もう一度やり直してください';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get use => '使用';

  @override
  String get save => '保存';

  @override
  String get done => '完了';

  @override
  String get manageLibrary => 'ライブラリの管理';

  @override
  String get newGuidance => '新しいガイダンス';

  @override
  String get quickGuidance => 'クイックガイド';

  @override
  String get viewPlans => 'プランを見る';

  @override
  String get restore => '復元する';

  @override
  String get loading => '読み込み中…';

  @override
  String get premium => 'プレミアム';

  @override
  String get premiumUnlimited => 'プレミアム・無制限';

  @override
  String get updating => '更新中';

  @override
  String get updatingBalance => '残高を更新中…';

  @override
  String get balanceUnavailable => '残高が利用できません';

  @override
  String get checking => 'チェック中';

  @override
  String get checkingBalance => '残高を確認中…';

  @override
  String freeCount(int free) {
    return '$free 無料';
  }

  @override
  String usageBalance(int free, int credits) {
    return '$free無料 · $creditsクレジット';
  }

  @override
  String get copyPreview => 'コピープレビュー';

  @override
  String get copyResult => 'コピー結果';

  @override
  String get staticPreviewCaption => '静的プレビュー';

  @override
  String get history => '歴史';

  @override
  String get clearHistory => '履歴をクリアしますか？';

  @override
  String get clearHistoryDescription =>
      'これにより、このデバイス上の最近のアイテムがすべて削除されます。これを元に戻すことはできません。';

  @override
  String get clearAll => 'すべてクリア';

  @override
  String get messageReceived => 'メッセージを受信しました';

  @override
  String get messageYouReceived => '受け取ったメッセージ';

  @override
  String get pasteOriginalMessage => '元のメッセージをここに貼り付けます…';

  @override
  String get paste => 'ペースト';

  @override
  String get clear => 'クリア';

  @override
  String get helpAiUnderstandIntent => 'AI があなたの意図を理解できるようにする';

  @override
  String get addReplyInstructions => '返信手順を追加してください…';

  @override
  String get generating => '生成中…';

  @override
  String get generateReply => '返信の生成';

  @override
  String get creatingNaturalOptions => 'いくつかの自然なオプションを作成中…';

  @override
  String get replyOptionsAppearHere => '返信オプションがここに表示されます。';

  @override
  String get yourReplies => 'あなたの返信';

  @override
  String get whyThisWorks => 'なぜこれが機能するのか';

  @override
  String get regenerateReplies => '応答を再生成する';

  @override
  String get regenerateUsageNote => '再生成すると新しい応答が作成され、1 世代が使用されます。';

  @override
  String get couldNotExplain => 'このメッセージを説明できませんでした';

  @override
  String get explainMessage => 'メッセージの説明';

  @override
  String get copyExplanation => '説明をコピー';

  @override
  String get meaning => '意味';

  @override
  String get tone => 'トーン';

  @override
  String get hiddenMeaning => '隠された意味';

  @override
  String get noHiddenMeaning => '隠された意味は検出されませんでした。';

  @override
  String get suggestedReplies => '返信候補';

  @override
  String get moreOptions => 'その他のオプション';

  @override
  String get audience => '観客';

  @override
  String get length => '長さ';

  @override
  String get channel => 'チャネル';

  @override
  String get describeTone => 'トーンを説明する';

  @override
  String get toneHint => '例えば温かいけどプロフェッショナル';

  @override
  String get describeRelationship => '関係を説明する';

  @override
  String get relationshipHint => '例: 私の家主';

  @override
  String get customizeStyleToneFormat => 'スタイル、トーン、形式をカスタマイズする';

  @override
  String get bePolite => '礼儀正しくする';

  @override
  String get keepItShort => '短くしてください';

  @override
  String get professional => 'プロ';

  @override
  String get friendly => 'フレンドリー';

  @override
  String get declinePolitely => '丁重に断る';

  @override
  String get sayThankYou => 'ありがとうと言いましょう';

  @override
  String get auto => '自動';

  @override
  String get natural => '自然';

  @override
  String get custom => 'カスタム';

  @override
  String get friend => '友達';

  @override
  String get customer => 'お客様';

  @override
  String get coworker => '同僚';

  @override
  String get manager => 'マネージャー';

  @override
  String get short => '短い';

  @override
  String get medium => '中くらい';

  @override
  String get detailed => '詳細';

  @override
  String get textChannel => '文章';

  @override
  String get email => '電子メール';

  @override
  String get chat => 'チャット';

  @override
  String get textToPolish => '磨きをかけるテキスト';

  @override
  String get pasteTextToImprove => '改善したいテキストを貼り付けます';

  @override
  String get pasteYourText => 'ここにテキストを貼り付けてください…';

  @override
  String get improvingClarity => '意味を保ちながら明瞭さを向上させる…';

  @override
  String get polishedTextAppearsHere => '改善されたテキストがここに表示されます。';

  @override
  String get polishedResult => 'テキストの改善';

  @override
  String get whatChanged => '何が変わったのでしょうか？';

  @override
  String get polishAgain => '再度改善します';

  @override
  String get polishAgainUsageNote => '再度改善すると新しい結果が作成され、1 世代が使用されます。';

  @override
  String get messageToUnderstand => '理解するためのメッセージ';

  @override
  String get pasteMessageReceived => '受け取ったメッセージを貼り付けます';

  @override
  String get explainThisMessage => 'このメッセージを説明してください';

  @override
  String get explaining => '説明中…';

  @override
  String get readingBetweenLines => '行間を読んで…';

  @override
  String get explanationAppearsHere => 'あなたの説明がここに表示されます。';

  @override
  String get noSuggestedReplies => '提案された返信は返されませんでした。';

  @override
  String get copy => 'コピー';

  @override
  String get enterMessageFirst => '最初に説明するメッセージを入力します。';

  @override
  String get explainRateLimited => '現時点では説明の制限に達しました。後でもう一度試してください。';

  @override
  String get explainParseError => '説明をはっきりと読むことができませんでした。もう一度試してください。';

  @override
  String get explainUnavailable =>
      'Explain は一時的に利用できなくなります。しばらくしてからもう一度お試しください。';

  @override
  String get unableToExplain => 'このメッセージを説明できません。';

  @override
  String get replyCtaTitle => '自分の意図にもっと合致する返信が欲しいですか?';

  @override
  String get premiumTitle => 'リプライワイズ プレミアム';

  @override
  String get back => '戻る';

  @override
  String get threeDaysFree => '3日間無料';

  @override
  String get unlimitedReply => '無制限の応答世代';

  @override
  String get unlimitedPolish => '無制限のテキスト改善';

  @override
  String get balancesPreserved => '無料残高とクレジット残高は維持されます';

  @override
  String get loadingSubscriptionOptions => 'サブスクリプション オプションを読み込んでいます…';

  @override
  String get startFreeTrial => '3日間の無料トライアルを開始する';

  @override
  String get startYearlyPlan => '年間計画を開始する';

  @override
  String trialTerms(String price) {
    return '3 日間無料、その後は年間$price。いつでもキャンセルできます。';
  }

  @override
  String yearlyTerms(String price) {
    return '$price/年。いつでもキャンセルできます。';
  }

  @override
  String get displayedPrice => '表示価格';

  @override
  String get topUpCredits => 'トップアップクレジット';

  @override
  String get creditDescription =>
      '各クレジットには、1 つの返信または 1 つのテキストの改善が含まれます。クレジットに有効期限はありません。';

  @override
  String get loadingCreditPackages => 'クレジット パッケージを読み込んでいます…';

  @override
  String get creditPackagesUnavailable => '現在、クレジット パッケージはご利用いただけません。';

  @override
  String get refreshPackages => 'パッケージを更新する';

  @override
  String buyCreditPackage(int credits, String price) {
    return '$credits クレジットを購入 — $price';
  }

  @override
  String get restoring => '復元中…';

  @override
  String get restorePremium => 'プレミアムサブスクリプションを復元する';

  @override
  String get purchaseVerification =>
      'プレミアムおよびクレジットの購入は ReplyWise によって検証されます。クレジットの購入は自動的に調整されます。';

  @override
  String get newGuidanceTooltip => '新しいガイダンス';

  @override
  String get builtIn => '内蔵';

  @override
  String get myGuidance => '私の指導';

  @override
  String get useInReply => '返信で使用する';

  @override
  String get useInPolish => '文章の改善に使用します';

  @override
  String get deleteGuidance => 'このガイダンスを削除しますか?';

  @override
  String get cannotBeUndone => 'これを元に戻すことはできません。';

  @override
  String get category => 'カテゴリ';

  @override
  String get titleLabel => 'タイトル';

  @override
  String get guidanceTitleHint => 'このガイダンスの略称…';

  @override
  String get guidanceHint => 'AI が応答をどのように形成するかを説明します...';

  @override
  String get writeAnyLanguage => '任意の言語で書く';

  @override
  String get saveChanges => '変更を保存する';

  @override
  String get saveGuidance => '保存ガイダンス';

  @override
  String get couldNotSaveGuidance => 'このガイダンスを保存できませんでした。もう一度試してください。';

  @override
  String get concise => '簡潔';

  @override
  String get moreNatural => 'より自然に';

  @override
  String get improveGrammar => '文法を改善する';

  @override
  String get fixSpelling => 'スペルを修正';

  @override
  String get morePersuasive => 'より説得力のある';

  @override
  String get moreConfident => 'もっと自信を持って';

  @override
  String get simplifyWording => '文言を簡略化する';

  @override
  String get betterFlow => 'より良い流れ';

  @override
  String get describePolish => 'ドラフトをどのように仕上げたいかを説明してください';

  @override
  String get describeAudience => '聴衆について説明する';

  @override
  String get audienceHint => '例えば私のマネージャー';

  @override
  String get extraInstruction => '追加の指示';

  @override
  String get extraPolishHint => 'その他のテキスト改善設定を追加します';

  @override
  String get polishing => 'テキストを改善中…';

  @override
  String get polishText => 'テキストを改善する';

  @override
  String get adjustToneLengthFormat => 'トーン、長さ、形式を調整する';

  @override
  String get instructionProfessional => 'プロフェッショナルな文章にしましょう。';

  @override
  String get instructionFriendly => '文章をより温かくフレンドリーなものにしましょう。';

  @override
  String get instructionConcise => '文章は簡潔かつ直接的にしましょう。';

  @override
  String get instructionNatural => '言葉遣いが自然で流暢に聞こえるようにします。';

  @override
  String get instructionGrammar => '意味を保ったまま文法を修正します。';

  @override
  String get instructionSpelling => 'すべてのスペルミスを修正してください。';

  @override
  String get instructionPersuasive => '文章をより説得力があり説得力のあるものにします。';

  @override
  String get instructionConfident => '明瞭で自信に満ちた文章にしましょう。';

  @override
  String get instructionSimple => 'よりシンプルで読みやすい文言を使用します。';

  @override
  String get instructionFlow => '文章の流れとトランジションを改善します。';

  @override
  String get shorter => '短い';

  @override
  String get sameLength => '同じ';

  @override
  String get longer => 'より長い';

  @override
  String get favorites => 'お気に入り';

  @override
  String get createGuidanceEmpty => '独自のガイダンスを作成して、後で再利用します。';

  @override
  String get removeFavorite => 'お気に入りから削除';

  @override
  String get addFavorite => 'お気に入りに追加';

  @override
  String useTemplate(String title) {
    return '「$title」を使用してください';
  }

  @override
  String get chooseGuidance => 'ガイダンスを選択してください';

  @override
  String get library => '図書館';

  @override
  String get general => '一般的な';

  @override
  String get decline => '衰退';

  @override
  String get thanks => 'ありがとう';

  @override
  String get followUp => 'フォローアップ';

  @override
  String get editGuidance => '編集ガイダンス';

  @override
  String get makeProfessional => 'プロフェッショナルなものにする';

  @override
  String get makeFriendly => 'フレンドリーにしましょう';

  @override
  String get askMoreTime => 'もう少し時間を聞いてください';

  @override
  String get soundConfident => '自信があるように聞こえる';

  @override
  String get guidancePoliteContent => '返信は礼儀正しく敬意を持って行いましょう。';

  @override
  String get guidanceShortContent => '返信は短く明確にしてください。';

  @override
  String get guidanceProfessionalContent => '返信はプロフェッショナルで仕事に適したものにしましょう。';

  @override
  String get guidanceFriendlyContent => '温かくフレンドリーな返信をしましょう。';

  @override
  String get guidanceDeclineContent => '失礼にならないよう、丁寧に依頼を断りましょう。';

  @override
  String get guidanceThanksContent => '感謝の気持ちと丁寧な感謝の気持ちを添えてください。';

  @override
  String get guidanceMoreTimeContent => '責任感があり礼儀正しい印象を与えながら、もう少し時間をもらいましょう。';

  @override
  String get guidanceConfidentContent => '返事は自信に満ちているように聞こえますが、攻撃的ではありません。';

  @override
  String todayAt(String time) {
    return '今日 · $time';
  }

  @override
  String yesterdayAt(String time) {
    return '昨日 · $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date · $time';
  }

  @override
  String get premiumActive => 'プレミアムサブスクリプションがアクティブです';

  @override
  String creditsRemaining(String count) {
    return '$count クレジットが残っています';
  }

  @override
  String get adIsLoading => '広告を読み込んでいます。もう一度お試しください。';

  @override
  String get creditAdded => 'クレジットを追加しました。';

  @override
  String get outOfCreditsTitle => 'クレジットが不足しています';

  @override
  String get outOfCreditsMessage =>
      '短い広告を視聴して 1 つの無料クレジットを取得するか、アップグレードしてより多くのアクセスを獲得してください。';

  @override
  String get buyCredits => 'クレジットを購入する';

  @override
  String get creditAddedTapGenerateAgain => 'クレジットが追加されました。もう一度「生成」をタップします。';

  @override
  String get adDailyLimitReached => '広告リワードの1日の上限に達しました。';

  @override
  String get adLoadFailed => '広告を読み込めませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get adRewardCooldown => '次の広告を見るまで少しお待ちください。';

  @override
  String get adRewardFailed => 'クレジットを追加できませんでした。もう一度お試しください。';

  @override
  String get recentDetail => '詳細';

  @override
  String get useAgain => 'もう一度使う';
}
