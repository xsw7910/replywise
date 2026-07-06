// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'YanıtlaWise';

  @override
  String get systemDefault => 'Sistem varsayılanı';

  @override
  String get chooseLanguage => 'Uygulama dilini seç';

  @override
  String get settings => 'Ayarlar';

  @override
  String get settingsSubtitle =>
      'Hesabınızı ve uygulama tercihlerinizi yönetin';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get reply => 'Yanıtla';

  @override
  String get explain => 'Açıkla';

  @override
  String get polish => 'İyileştir';

  @override
  String get yourAiReplyAssistant => 'Yapay zeka yanıt asistanınız';

  @override
  String get generateThoughtfulReplies =>
      'Anında düşünceli yanıtlar oluşturun.';

  @override
  String get makeWritingClear => 'Yazınızı net ve doğal yapın.';

  @override
  String get understandTone => 'Tonu ve gizli anlamı anlayın.';

  @override
  String get templates => 'Şablonlar';

  @override
  String get reuseInstructions => 'Favori AI talimatlarınızı yeniden kullanın.';

  @override
  String get recent => 'Son kullanılanlar';

  @override
  String get viewAll => 'Tümünü gör';

  @override
  String get nothingHereYet => 'Henüz burada bir şey yok';

  @override
  String get recentEmptyMessage =>
      'Son yanıtlarınız, gösterişli metniniz ve açıklamalarınız burada görünecek.';

  @override
  String get createFirstReply => 'İlk yanıtını oluştur';

  @override
  String get tipOfTheDay => 'Günün ipucu';

  @override
  String get tipShortEmails =>
      'Daha yüksek yanıt oranları için e-postaları 120 kelimenin altında tutun.';

  @override
  String get tipLeadWithAsk =>
      'İsteğinizle liderlik edin; anahtar isteği ilk satıra koyun.';

  @override
  String get tipMatchTone =>
      'Daha hızlı uyum sağlamak için diğer kişinin ses tonunu eşleştirin.';

  @override
  String get tipClearSubject =>
      'Açık bir konu satırı, akıllı bir konu satırından daha fazla yanıt alır.';

  @override
  String get tipReadAloud =>
      'Yanıtınızı bir kez yüksek sesle okuyun; garip ifadeler yakalar.';

  @override
  String get tipClearNextStep =>
      'Okuyucunun ne yapacağını bilmesi için bir sonraki adımı açık bir şekilde bitirin.';

  @override
  String get yourPlan => 'Planın';

  @override
  String get plans => 'Planlar';

  @override
  String get credits => 'Kredi';

  @override
  String get totalCredits => 'Toplam kredi';

  @override
  String get watchAd => 'Reklamı izle';

  @override
  String get watchAdReward => '+1 kredi';

  @override
  String get currentPlan => 'Mevcut plan';

  @override
  String get freePlan => 'Ücretsiz plan';

  @override
  String freeRepliesPerDay(int count) {
    return 'Günlük $count ücretsiz yanıt';
  }

  @override
  String get upgrade => 'Yükselt';

  @override
  String get support => 'Destek';

  @override
  String get supportDescription => 'Yardım merkezi / Bize ulaşın';

  @override
  String get aboutDescription => 'Sürüm, Gizlilik, Şartlar';

  @override
  String get guidance => 'Yönergeler';

  @override
  String get guidanceLibrary => 'Yönerge Kitaplığı';

  @override
  String get languageAndInput => 'Dil ve giriş';

  @override
  String get appLanguage => 'Uygulama dili';

  @override
  String get voiceGuidanceLanguage => 'Sesli yönlendirme dili';

  @override
  String get autoDetect => 'Otomatik Algılama';

  @override
  String staticPreview(String label) {
    return '$label statik bir önizlemedir.';
  }

  @override
  String get about => 'Hakkında';

  @override
  String get version => 'Sürüm';

  @override
  String get environment => 'Çevre';

  @override
  String get developerTesting => 'Geliştirici Testi';

  @override
  String get resetFreeUsage => 'Ücretsiz kullanımı sıfırla';

  @override
  String addCredits(int count) {
    return '$count kredi ekle';
  }

  @override
  String get simulatePremiumOn => 'Premium Simülasyonu Açık';

  @override
  String get simulatePremiumOff => 'Premium Kapalı Simülasyonu';

  @override
  String get refreshAccountState => 'Hesap durumunu yenile';

  @override
  String get secureSession => 'Güvenli oturum';

  @override
  String get anonymousSessionReady => 'Anonim oturum hazır';

  @override
  String get connectingAnonymousSession => 'Anonim oturuma bağlanılıyor…';

  @override
  String get refreshingSecureSession => 'Güvenli oturum yenileniyor…';

  @override
  String get restoringAnonymousSession => 'Anonim oturum geri yükleniyor…';

  @override
  String get anonymousSessionUnavailable => 'Anonim oturum kullanılamıyor';

  @override
  String get anonymousSessionNotStarted => 'Anonim oturum başlatılmadı';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get developer => 'Geliştirici';

  @override
  String get localBackendConnection => 'Yerel arka uç bağlantısı';

  @override
  String get refreshBackendStatus => 'Arka uç durumunu yenile';

  @override
  String get checkingBackend => 'Arka uç kontrol ediliyor…';

  @override
  String get connected => 'Bağlı';

  @override
  String get connectionFailed => 'Bağlantı başarısız oldu';

  @override
  String get serviceUnreachable =>
      'Servise ulaşamadık. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get close => 'Kapalı';

  @override
  String get tryAgain => 'Tekrar deneyin';

  @override
  String get cancel => 'İptal';

  @override
  String get delete => 'Sil';

  @override
  String get edit => 'Düzenle';

  @override
  String get use => 'Kullan';

  @override
  String get save => 'Kaydet';

  @override
  String get done => 'Bitti';

  @override
  String get manageLibrary => 'Kitaplığı Yönet';

  @override
  String get newGuidance => 'Yeni Rehber';

  @override
  String get quickGuidance => 'Hızlı rehberlik';

  @override
  String get viewPlans => 'Planları görüntüle';

  @override
  String get restore => 'Eski haline getirmek';

  @override
  String get loading => 'Yükleniyor…';

  @override
  String get premium => 'Premium';

  @override
  String get premiumUnlimited => 'Prim · Sınırsız';

  @override
  String get updating => 'Güncelleniyor';

  @override
  String get updatingBalance => 'Bakiye güncelleniyor…';

  @override
  String get balanceUnavailable => 'Bakiye kullanılamıyor';

  @override
  String get checking => 'Kontrol ediliyor';

  @override
  String get checkingBalance => 'Bakiye kontrol ediliyor…';

  @override
  String freeCount(int free) {
    return '$free ücretsiz';
  }

  @override
  String usageBalance(int free, int credits) {
    return '$free ücretsiz · $credits kredi';
  }

  @override
  String get copyPreview => 'Önizlemeyi kopyala';

  @override
  String get copyResult => 'Sonucu kopyala';

  @override
  String get staticPreviewCaption => 'Statik önizleme';

  @override
  String get history => 'Tarih';

  @override
  String get clearHistory => 'Geçmiş temizlensin mi?';

  @override
  String get clearHistoryDescription =>
      'Bu işlem, bu cihazdaki tüm son öğeleri kaldırır. Bu geri alınamaz.';

  @override
  String get clearAll => 'Tümünü temizle';

  @override
  String get messageReceived => 'Mesaj alındı';

  @override
  String get messageYouReceived => 'Aldığınız mesaj';

  @override
  String get pasteOriginalMessage => 'Orijinal mesajı buraya yapıştırın…';

  @override
  String get paste => 'Yapıştır';

  @override
  String get clear => 'Temizlemek';

  @override
  String get helpAiUnderstandIntent =>
      'Yapay zekanın amacınızı anlamasına yardımcı olun';

  @override
  String get addReplyInstructions => 'Yanıt talimatlarınızı ekleyin…';

  @override
  String get generating => 'Oluşturuluyor…';

  @override
  String get generateReply => 'Yanıt Oluştur';

  @override
  String get creatingNaturalOptions => 'Birkaç doğal seçenek yaratmak…';

  @override
  String get replyOptionsAppearHere => 'Yanıt seçenekleriniz burada görünecek.';

  @override
  String get yourReplies => 'Yanıtlarınız';

  @override
  String get whyThisWorks => 'Bu neden işe yarıyor?';

  @override
  String get regenerateReplies => 'Yanıtları yeniden oluştur';

  @override
  String get regenerateUsageNote =>
      'Yeniden oluşturma, yeni yanıtlar oluşturur ve 1 nesil kullanır.';

  @override
  String get couldNotExplain => 'Bu mesajı açıklayamadım';

  @override
  String get explainMessage => 'Mesajı açıkla';

  @override
  String get copyExplanation => 'Açıklamayı kopyala';

  @override
  String get meaning => 'Anlam';

  @override
  String get tone => 'Ton';

  @override
  String get hiddenMeaning => 'Gizli Anlam';

  @override
  String get noHiddenMeaning => 'Gizli bir anlam tespit edilmedi.';

  @override
  String get suggestedReplies => 'Önerilen Yanıtlar';

  @override
  String get moreOptions => 'Daha fazla seçenek';

  @override
  String get audience => 'Kitle';

  @override
  String get length => 'Uzunluk';

  @override
  String get channel => 'Kanal';

  @override
  String get describeTone => 'Tonu açıklayın';

  @override
  String get toneHint => 'örneğin sıcak ama profesyonel';

  @override
  String get describeRelationship => 'İlişkiyi açıklayın';

  @override
  String get relationshipHint => 'Örneğin: ev sahibim';

  @override
  String get customizeStyleToneFormat => 'Stili, tonu ve formatı özelleştirin';

  @override
  String get bePolite => 'Kibar ol';

  @override
  String get keepItShort => 'Kısa tutun';

  @override
  String get professional => 'Profesyonel';

  @override
  String get friendly => 'Arkadaşça';

  @override
  String get declinePolitely => 'Kibarca reddet';

  @override
  String get sayThankYou => 'Teşekkür ederim deyin';

  @override
  String get auto => 'Otomatik';

  @override
  String get natural => 'Doğal';

  @override
  String get custom => 'Gelenek';

  @override
  String get friend => 'Arkadaş';

  @override
  String get customer => 'Müşteri';

  @override
  String get coworker => 'İş arkadaşı';

  @override
  String get manager => 'Müdür';

  @override
  String get short => 'Kısa';

  @override
  String get medium => 'Orta';

  @override
  String get detailed => 'Ayrıntılı';

  @override
  String get textChannel => 'Metin';

  @override
  String get email => 'E-posta';

  @override
  String get chat => 'Sohbet';

  @override
  String get textToPolish => 'Parlatılacak metin';

  @override
  String get pasteTextToImprove => 'Geliştirmek istediğiniz metni yapıştırın';

  @override
  String get pasteYourText => 'Metninizi buraya yapıştırın…';

  @override
  String get improvingClarity => 'Anlamınızı korurken netliği artırmak…';

  @override
  String get polishedTextAppearsHere =>
      'Geliştirilmiş metniniz burada görünecek.';

  @override
  String get polishedResult => 'Geliştirilmiş metin';

  @override
  String get whatChanged => 'Ne değişti?';

  @override
  String get polishAgain => 'Tekrar geliştirin';

  @override
  String get polishAgainUsageNote =>
      'Tekrar iyileştirme yeni bir sonuç yaratır ve 1 nesil kullanır.';

  @override
  String get messageToUnderstand => 'Anlamak için mesaj';

  @override
  String get pasteMessageReceived => 'Aldığınız mesajı yapıştırın';

  @override
  String get explainThisMessage => 'Bu mesajı açıklayın';

  @override
  String get explaining => 'Açıklanıyor…';

  @override
  String get readingBetweenLines => 'Satır aralarını okumak…';

  @override
  String get explanationAppearsHere => 'Açıklamanız burada görünecektir.';

  @override
  String get noSuggestedReplies => 'Önerilen yanıtlardan hiçbiri geri dönmedi.';

  @override
  String get copy => 'Kopyala';

  @override
  String get enterMessageFirst => 'Önce açıklayacak bir mesaj girin.';

  @override
  String get explainRateLimited =>
      'Şimdilik açıklama sınırına ulaştınız. Lütfen daha sonra tekrar deneyin.';

  @override
  String get explainParseError =>
      'Açıklamayı net okuyamadık. Lütfen tekrar deneyin.';

  @override
  String get explainUnavailable =>
      'Açıklama geçici olarak kullanılamıyor. Lütfen kısa süre sonra tekrar deneyin.';

  @override
  String get unableToExplain => 'Bu mesajı açıklayamıyorum.';

  @override
  String get replyCtaTitle =>
      'Niyetinize daha iyi uyan bir yanıt mı istiyorsunuz?';

  @override
  String get premiumTitle => 'ReplyWise Premium';

  @override
  String get back => 'Geri';

  @override
  String get threeDaysFree => '3 gün ücretsiz';

  @override
  String get unlimitedReply => 'Sınırsız Yanıt nesilleri';

  @override
  String get unlimitedPolish => 'Sınırsız metin iyileştirmeleri';

  @override
  String get balancesPreserved => 'Ücretsiz ve kredi bakiyeleri korunur';

  @override
  String get loadingSubscriptionOptions => 'Abonelik seçenekleri yükleniyor…';

  @override
  String get startFreeTrial => '3 Günlük Ücretsiz Denemeyi Başlatın';

  @override
  String get startYearlyPlan => 'Yıllık Planı Başlat';

  @override
  String trialTerms(String price) {
    return '3 gün boyunca ücretsiz, ardından yılda $price. İstediğiniz zaman iptal edin.';
  }

  @override
  String yearlyTerms(String price) {
    return '$price/yıl. İstediğiniz zaman iptal edin.';
  }

  @override
  String get displayedPrice => 'görüntülenen fiyat';

  @override
  String get topUpCredits => 'Yükleme Kredileri';

  @override
  String pricePerCredit(String price) {
    return 'Kredi başına $price';
  }

  @override
  String get creditDescription =>
      'Her kredi bir yanıtı veya bir metin iyileştirmesini kapsar. Kredilerin süresi asla dolmaz.';

  @override
  String get loadingCreditPackages => 'Kredi paketleri yükleniyor…';

  @override
  String get creditPackagesUnavailable =>
      'Kredi paketleri şu anda kullanılamıyor.';

  @override
  String get refreshPackages => 'Paketleri yenile';

  @override
  String buyCreditPackage(int credits, String price) {
    return '$credits Kredi Satın Alın — $price';
  }

  @override
  String get restoring => 'Geri yükleniyor…';

  @override
  String get restorePremium => 'Premium aboneliğini geri yükle';

  @override
  String get purchaseVerification =>
      'Premium ve kredi satın alımları ReplyWise tarafından doğrulanır. Kredi alımlarının mutabakatı otomatik olarak yapılır.';

  @override
  String get newGuidanceTooltip => 'Yeni rehberlik';

  @override
  String get builtIn => 'Yerleşik';

  @override
  String get myGuidance => 'Rehberim';

  @override
  String get useInReply => 'Yanıtta kullan';

  @override
  String get useInPolish => 'Metin iyileştirme için kullanın';

  @override
  String get deleteGuidance => 'Bu kılavuz silinsin mi?';

  @override
  String get cannotBeUndone => 'Bu geri alınamaz.';

  @override
  String get category => 'Kategori';

  @override
  String get titleLabel => 'Başlık';

  @override
  String get guidanceTitleHint => 'Bu rehberin kısa adı…';

  @override
  String get guidanceHint =>
      'Yapay zekanın yanıtı nasıl şekillendirmesi gerektiğini açıklayın…';

  @override
  String get writeAnyLanguage => 'Herhangi bir dilde yazın';

  @override
  String get saveChanges => 'Değişiklikleri kaydet';

  @override
  String get saveGuidance => 'Kılavuzu kaydet';

  @override
  String get couldNotSaveGuidance =>
      'Bu kılavuz kaydedilemedi. Lütfen tekrar deneyin.';

  @override
  String get concise => 'Kısa';

  @override
  String get moreNatural => 'Daha doğal';

  @override
  String get improveGrammar => 'Dilbilgisini geliştirin';

  @override
  String get fixSpelling => 'Yazımı düzelt';

  @override
  String get morePersuasive => 'Daha ikna edici';

  @override
  String get moreConfident => 'Daha güvenli';

  @override
  String get simplifyWording => 'İfadeleri basitleştirin';

  @override
  String get betterFlow => 'Daha iyi akış';

  @override
  String get describePolish =>
      'Taslağın nasıl cilalanmasını istediğinizi açıklayın';

  @override
  String get describeAudience => 'İzleyiciyi tanımlayın';

  @override
  String get audienceHint => 'örneğin menajerim';

  @override
  String get extraInstruction => 'Ekstra talimat';

  @override
  String get extraPolishHint => 'Başka metin iyileştirme tercihleri ​​ekleyin';

  @override
  String get polishing => 'Metin iyileştiriliyor…';

  @override
  String get polishText => 'Metni iyileştirin';

  @override
  String get adjustToneLengthFormat => 'Tonu, uzunluğu ve formatı ayarlayın';

  @override
  String get instructionProfessional =>
      'Yazının profesyonel görünmesini sağlayın.';

  @override
  String get instructionFriendly => 'Yazıyı daha sıcak ve samimi hale getirin.';

  @override
  String get instructionConcise => 'Yazıyı kısa ve net yapın.';

  @override
  String get instructionNatural =>
      'İfadelerin doğal ve akıcı olmasını sağlayın.';

  @override
  String get instructionGrammar => 'Anlamı korurken dilbilgisini düzeltin.';

  @override
  String get instructionSpelling => 'Tüm yazım hatalarını düzeltin.';

  @override
  String get instructionPersuasive =>
      'Yazıyı daha ikna edici ve ilgi çekici hale getirin.';

  @override
  String get instructionConfident =>
      'Yazının net ve kendinden emin olmasını sağlayın.';

  @override
  String get instructionSimple =>
      'Daha basit, okunması kolay ifadeler kullanın.';

  @override
  String get instructionFlow => 'Cümle akışını ve geçişleri iyileştirin.';

  @override
  String get shorter => 'Daha kısa';

  @override
  String get sameLength => 'Aynı';

  @override
  String get longer => 'Daha uzun';

  @override
  String get favorites => 'Favoriler';

  @override
  String get createGuidanceEmpty =>
      'Daha sonra yeniden kullanmak için kendi rehberinizi oluşturun.';

  @override
  String get removeFavorite => 'Favorilerden kaldır';

  @override
  String get addFavorite => 'Favorilere ekle';

  @override
  String useTemplate(String title) {
    return '“$title” kullanın';
  }

  @override
  String get chooseGuidance => 'Rehberliği seçin';

  @override
  String get library => 'Kütüphane';

  @override
  String get general => 'Genel';

  @override
  String get decline => 'Reddetmek';

  @override
  String get thanks => 'Teşekkürler';

  @override
  String get followUp => 'Takip etmek';

  @override
  String get editGuidance => 'Kılavuzu Düzenle';

  @override
  String get makeProfessional => 'Profesyonel hale getirin';

  @override
  String get makeFriendly => 'Dostça yap';

  @override
  String get askMoreTime => 'Daha fazla zaman isteyin';

  @override
  String get soundConfident => 'Kendine güvenen bir ses';

  @override
  String get guidancePoliteContent => 'Cevabınızı kibar ve saygılı yapın.';

  @override
  String get guidanceShortContent => 'Cevabınızı kısa ve net tutun.';

  @override
  String get guidanceProfessionalContent =>
      'Yanıtınızın profesyonel ve iş için uygun olmasını sağlayın.';

  @override
  String get guidanceFriendlyContent => 'Cevabınızı sıcak ve samimi yapın.';

  @override
  String get guidanceDeclineContent =>
      'Talebi kaba görünmeden kibarca reddedin.';

  @override
  String get guidanceThanksContent =>
      'Takdirinizi ve kibar bir teşekkürünüzü ekleyin.';

  @override
  String get guidanceMoreTimeContent =>
      'Sorumlu ve kibar görünerek daha fazla zaman isteyin.';

  @override
  String get guidanceConfidentContent =>
      'Yanıtınızın kendinden emin görünmesini sağlayın ancak agresif olmayın.';

  @override
  String todayAt(String time) {
    return 'Bugün · $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Dün · $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date · $time';
  }

  @override
  String get premiumActive => 'Premium abonelik aktif';

  @override
  String creditsRemaining(String count) {
    return '$count kredi kaldı';
  }

  @override
  String get adIsLoading => 'Reklam yükleniyor. Lütfen tekrar deneyin.';

  @override
  String get creditAdded => 'Kredi eklendi.';

  @override
  String get outOfCreditsTitle => 'Krediniz bitti';

  @override
  String get outOfCreditsMessage =>
      '1 ücretsiz kredi kazanmak için kısa bir reklam izleyin veya daha fazla erişim için yükseltme yapın.';

  @override
  String get buyCredits => 'Kredi Satın Al';

  @override
  String get creditAddedTapGenerateAgain =>
      'Kredi eklendi. Tekrar Oluştur\'a dokunun.';

  @override
  String get adDailyLimitReached => 'Günlük reklam ödülü sınırına ulaşıldı.';

  @override
  String get adLoadFailed =>
      'Reklam yüklenemedi. Lütfen daha sonra tekrar deneyin.';

  @override
  String get adRewardCooldown =>
      'Başka bir reklam izlemeden önce lütfen biraz bekleyin.';

  @override
  String get adRewardFailed => 'Krediniz eklenemedi. Lütfen tekrar deneyin.';

  @override
  String get recentDetail => 'Ayrıntılar';

  @override
  String get useAgain => 'Tekrar kullan';
}
