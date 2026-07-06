// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'ตอบกลับWise';

  @override
  String get systemDefault => 'ค่าเริ่มต้นของระบบ';

  @override
  String get chooseLanguage => 'เลือกภาษาของแอป';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get home => 'หน้าหลัก';

  @override
  String get reply => 'ตอบกลับ';

  @override
  String get explain => 'อธิบาย';

  @override
  String get polish => 'ปรับปรุง';

  @override
  String get yourAiReplyAssistant => 'ผู้ช่วยตอบกลับ AI ของคุณ';

  @override
  String get generateThoughtfulReplies => 'สร้างคำตอบที่รอบคอบทันที';

  @override
  String get makeWritingClear => 'ทำให้การเขียนของคุณชัดเจนและเป็นธรรมชาติ';

  @override
  String get understandTone => 'เข้าใจน้ำเสียงและความหมายที่ซ่อนอยู่';

  @override
  String get templates => 'เทมเพลต';

  @override
  String get reuseInstructions => 'ใช้คำสั่ง AI ที่คุณชื่นชอบซ้ำ';

  @override
  String get recent => 'ล่าสุด';

  @override
  String get viewAll => 'ดูทั้งหมด';

  @override
  String get nothingHereYet => 'ยังไม่มีข้อมูล';

  @override
  String get recentEmptyMessage =>
      'การตอบกลับ ข้อความที่ปรับปรุง และคำอธิบายล่าสุดของคุณจะปรากฏที่นี่';

  @override
  String get createFirstReply => 'สร้างคำตอบแรก';

  @override
  String get tipOfTheDay => 'เคล็ดลับประจำวัน';

  @override
  String get tipShortEmails =>
      'เก็บอีเมลไว้ไม่เกิน 120 คำเพื่อให้อัตราการตอบกลับสูงขึ้น';

  @override
  String get tipLeadWithAsk =>
      'เริ่มต้นด้วยคำถามของคุณ — ใส่คำขอหลักในบรรทัดแรก';

  @override
  String get tipMatchTone =>
      'จับคู่น้ำเสียงของอีกฝ่ายเพื่อสร้างสายสัมพันธ์ที่รวดเร็วยิ่งขึ้น';

  @override
  String get tipClearSubject =>
      'หัวเรื่องที่ชัดเจนจะได้รับการตอบกลับมากกว่าหัวเรื่องที่ฉลาด';

  @override
  String get tipReadAloud =>
      'อ่านออกเสียงคำตอบของคุณหนึ่งครั้ง — มันอาจใช้ถ้อยคำที่น่าอึดอัดใจได้';

  @override
  String get tipClearNextStep =>
      'จบด้วยขั้นตอนต่อไปที่ชัดเจนเพื่อให้ผู้อ่านรู้ว่าต้องทำอย่างไร';

  @override
  String get yourPlan => 'แพ็กเกจของคุณ';

  @override
  String get plans => 'แพ็กเกจ';

  @override
  String get credits => 'เครดิต';

  @override
  String get totalCredits => 'เครดิตทั้งหมด';

  @override
  String get watchAd => 'ดูโฆษณา';

  @override
  String get watchAdReward => '+1 เครดิต';

  @override
  String get currentPlan => 'แผนปัจจุบัน';

  @override
  String get freePlan => 'แผนฟรี';

  @override
  String freeRepliesPerDay(int count) {
    return '$count ตอบกลับฟรีต่อวัน';
  }

  @override
  String get upgrade => 'อัพเกรด';

  @override
  String get support => 'ความช่วยเหลือ';

  @override
  String get supportDescription => 'ศูนย์ช่วยเหลือ / ติดต่อเรา';

  @override
  String get aboutDescription => 'เวอร์ชัน ความเป็นส่วนตัว เงื่อนไข';

  @override
  String get guidance => 'คำแนะนำ';

  @override
  String get guidanceLibrary => 'คลังคำแนะนำ';

  @override
  String get languageAndInput => 'ภาษาและการป้อนข้อมูล';

  @override
  String get appLanguage => 'ภาษาของแอป';

  @override
  String get voiceGuidanceLanguage => 'ภาษาแนะนำด้วยเสียง';

  @override
  String get autoDetect => 'ตรวจจับอัตโนมัติ';

  @override
  String staticPreview(String label) {
    return '$label เป็นตัวอย่างแบบคงที่';
  }

  @override
  String get about => 'เกี่ยวกับ';

  @override
  String get version => 'เวอร์ชัน';

  @override
  String get environment => 'สิ่งแวดล้อม';

  @override
  String get developerTesting => 'การทดสอบนักพัฒนา';

  @override
  String get resetFreeUsage => 'รีเซ็ตการใช้งานฟรี';

  @override
  String addCredits(int count) {
    return 'เพิ่มเครดิต $count';
  }

  @override
  String get simulatePremiumOn => 'จำลองการเปิดแบบพรีเมียม';

  @override
  String get simulatePremiumOff => 'จำลองการปิดพรีเมียม';

  @override
  String get refreshAccountState => 'รีเฟรชสถานะบัญชี';

  @override
  String get secureSession => 'เซสชันที่ปลอดภัย';

  @override
  String get anonymousSessionReady => 'เซสชันที่ไม่ระบุชื่อพร้อมแล้ว';

  @override
  String get connectingAnonymousSession =>
      'กำลังเชื่อมต่อเซสชันที่ไม่ระบุชื่อ...';

  @override
  String get refreshingSecureSession => 'กำลังรีเฟรชเซสชันที่ปลอดภัย...';

  @override
  String get restoringAnonymousSession => 'กำลังกู้คืนเซสชันที่ไม่ระบุชื่อ...';

  @override
  String get anonymousSessionUnavailable =>
      'เซสชันที่ไม่ระบุชื่อไม่พร้อมใช้งาน';

  @override
  String get anonymousSessionNotStarted =>
      'เซสชั่นที่ไม่ระบุชื่อไม่ได้เริ่มต้น';

  @override
  String get retry => 'ลองอีกครั้ง';

  @override
  String get developer => 'นักพัฒนา';

  @override
  String get localBackendConnection => 'การเชื่อมต่อแบ็กเอนด์ในเครื่อง';

  @override
  String get refreshBackendStatus => 'รีเฟรชสถานะแบ็กเอนด์';

  @override
  String get checkingBackend => 'กำลังตรวจสอบแบ็กเอนด์...';

  @override
  String get connected => 'เชื่อมต่อแล้ว';

  @override
  String get connectionFailed => 'การเชื่อมต่อล้มเหลว';

  @override
  String get serviceUnreachable =>
      'เราไม่สามารถเข้าถึงบริการได้ ตรวจสอบการเชื่อมต่อของคุณแล้วลองอีกครั้ง';

  @override
  String get copied => 'คัดลอกแล้ว';

  @override
  String get close => 'ปิด';

  @override
  String get tryAgain => 'ลองอีกครั้ง';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get delete => 'ลบ';

  @override
  String get edit => 'แก้ไข';

  @override
  String get use => 'ใช้';

  @override
  String get save => 'บันทึก';

  @override
  String get done => 'เสร็จสิ้น';

  @override
  String get manageLibrary => 'จัดการห้องสมุด';

  @override
  String get newGuidance => 'คำแนะนำใหม่';

  @override
  String get quickGuidance => 'คำแนะนำอย่างรวดเร็ว';

  @override
  String get viewPlans => 'ดูแผน';

  @override
  String get restore => 'คืนค่า';

  @override
  String get loading => 'กำลังโหลด...';

  @override
  String get premium => 'พรีเมี่ยม';

  @override
  String get premiumUnlimited => 'พรีเมียม · ไม่จำกัด';

  @override
  String get updating => 'กำลังอัปเดต';

  @override
  String get updatingBalance => 'กำลังอัปเดตยอดคงเหลือ...';

  @override
  String get balanceUnavailable => 'ยอดคงเหลือไม่พร้อมใช้งาน';

  @override
  String get checking => 'กำลังตรวจสอบ';

  @override
  String get checkingBalance => 'กำลังตรวจสอบยอดเงิน…';

  @override
  String freeCount(int free) {
    return '$free ฟรี';
  }

  @override
  String usageBalance(int free, int credits) {
    return '$free ฟรี · $credits เครดิต';
  }

  @override
  String get copyPreview => 'คัดลอกตัวอย่าง';

  @override
  String get copyResult => 'คัดลอกผลลัพธ์';

  @override
  String get staticPreviewCaption => 'การแสดงตัวอย่างแบบคงที่';

  @override
  String get history => 'ประวัติศาสตร์';

  @override
  String get clearHistory => 'ล้างประวัติ?';

  @override
  String get clearHistoryDescription =>
      'การดำเนินการนี้จะลบรายการล่าสุดทั้งหมดบนอุปกรณ์นี้ สิ่งนี้ไม่สามารถยกเลิกได้';

  @override
  String get clearAll => 'เคลียร์ทั้งหมด';

  @override
  String get messageReceived => 'ได้รับข้อความแล้ว';

  @override
  String get messageYouReceived => 'ข้อความที่คุณได้รับ';

  @override
  String get pasteOriginalMessage => 'วางข้อความต้นฉบับที่นี่...';

  @override
  String get paste => 'แปะ';

  @override
  String get clear => 'ชัดเจน';

  @override
  String get helpAiUnderstandIntent => 'ช่วยให้ AI เข้าใจเจตนาของคุณ';

  @override
  String get addReplyInstructions => 'เพิ่มคำแนะนำในการตอบกลับของคุณ...';

  @override
  String get generating => 'กำลังสร้าง...';

  @override
  String get generateReply => 'สร้างการตอบกลับ';

  @override
  String get creatingNaturalOptions =>
      'การสร้างทางเลือกที่เป็นธรรมชาติบางอย่าง...';

  @override
  String get replyOptionsAppearHere => 'ตัวเลือกการตอบกลับของคุณจะปรากฏที่นี่';

  @override
  String get yourReplies => 'คำตอบของคุณ';

  @override
  String get whyThisWorks => 'ทำไมสิ่งนี้ถึงได้ผล';

  @override
  String get regenerateReplies => 'สร้างการตอบกลับใหม่';

  @override
  String get regenerateUsageNote =>
      'การสร้างใหม่จะสร้างการตอบกลับใหม่และใช้ 1 รุ่น';

  @override
  String get couldNotExplain => 'ไม่สามารถอธิบายข้อความนี้ได้';

  @override
  String get explainMessage => 'อธิบายข้อความ';

  @override
  String get copyExplanation => 'คัดลอกคำอธิบาย';

  @override
  String get meaning => 'ความหมาย';

  @override
  String get tone => 'โทน';

  @override
  String get hiddenMeaning => 'ความหมายที่ซ่อนอยู่';

  @override
  String get noHiddenMeaning => 'ไม่พบความหมายที่ซ่อนอยู่';

  @override
  String get suggestedReplies => 'คำตอบที่แนะนำ';

  @override
  String get moreOptions => 'ตัวเลือกเพิ่มเติม';

  @override
  String get audience => 'ผู้ชม';

  @override
  String get length => 'ความยาว';

  @override
  String get channel => 'ช่อง';

  @override
  String get describeTone => 'อธิบายโทนเสียง';

  @override
  String get toneHint => 'เช่น อบอุ่นแต่เป็นมืออาชีพ';

  @override
  String get describeRelationship => 'อธิบายความสัมพันธ์';

  @override
  String get relationshipHint => 'ตัวอย่างเช่น: เจ้าของบ้านของฉัน';

  @override
  String get customizeStyleToneFormat => 'ปรับแต่งสไตล์ โทน และรูปแบบ';

  @override
  String get bePolite => 'สุภาพ';

  @override
  String get keepItShort => 'ให้มันสั้น';

  @override
  String get professional => 'มืออาชีพ';

  @override
  String get friendly => 'เป็นกันเอง';

  @override
  String get declinePolitely => 'ปฏิเสธอย่างสุภาพ';

  @override
  String get sayThankYou => 'พูดขอบคุณ';

  @override
  String get auto => 'อัตโนมัติ';

  @override
  String get natural => 'เป็นธรรมชาติ';

  @override
  String get custom => 'กำหนดเอง';

  @override
  String get friend => 'เพื่อน';

  @override
  String get customer => 'ลูกค้า';

  @override
  String get coworker => 'เพื่อนร่วมงาน';

  @override
  String get manager => 'ผู้จัดการ';

  @override
  String get short => 'สั้น';

  @override
  String get medium => 'ปานกลาง';

  @override
  String get detailed => 'รายละเอียด';

  @override
  String get textChannel => 'ข้อความ';

  @override
  String get email => 'อีเมล';

  @override
  String get chat => 'แชท';

  @override
  String get textToPolish => 'ข้อความที่จะขัด';

  @override
  String get pasteTextToImprove => 'วางข้อความที่คุณต้องการปรับปรุง';

  @override
  String get pasteYourText => 'วางข้อความของคุณที่นี่...';

  @override
  String get improvingClarity =>
      'ปรับปรุงความชัดเจนในขณะที่ยังคงความหมายของคุณ...';

  @override
  String get polishedTextAppearsHere =>
      'ข้อความที่ได้รับการปรับปรุงของคุณจะปรากฏที่นี่';

  @override
  String get polishedResult => 'ปรับปรุงข้อความ';

  @override
  String get whatChanged => 'มีอะไรเปลี่ยนแปลง?';

  @override
  String get polishAgain => 'ปรับปรุงอีกครั้ง';

  @override
  String get polishAgainUsageNote =>
      'การปรับปรุงอีกครั้งสร้างผลลัพธ์ใหม่และใช้ 1 รุ่น';

  @override
  String get messageToUnderstand => 'ข้อความเพื่อความเข้าใจ';

  @override
  String get pasteMessageReceived => 'วางข้อความที่คุณได้รับ';

  @override
  String get explainThisMessage => 'อธิบายข้อความนี้';

  @override
  String get explaining => 'กำลังอธิบาย...';

  @override
  String get readingBetweenLines => 'กำลังอ่านระหว่างบรรทัด...';

  @override
  String get explanationAppearsHere => 'คำอธิบายของคุณจะปรากฏที่นี่';

  @override
  String get noSuggestedReplies => 'ไม่มีการตอบกลับที่แนะนำ';

  @override
  String get copy => 'สำเนา';

  @override
  String get enterMessageFirst => 'กรอกข้อความเพื่ออธิบายก่อน';

  @override
  String get explainRateLimited =>
      'คุณใช้คำอธิบายถึงขีดจำกัดแล้วในตอนนี้ โปรดลองอีกครั้งในภายหลัง';

  @override
  String get explainParseError => 'เราอ่านคำอธิบายได้ไม่ชัดเจน โปรดลองอีกครั้ง';

  @override
  String get explainUnavailable =>
      'Explain ไม่สามารถใช้งานได้ชั่วคราว โปรดลองอีกครั้งในอีกสักครู่';

  @override
  String get unableToExplain => 'ไม่สามารถอธิบายข้อความนี้ได้';

  @override
  String get replyCtaTitle => 'ต้องการคำตอบที่ตรงกับความตั้งใจของคุณหรือไม่?';

  @override
  String get premiumTitle => 'รีพลายไวส์ พรีเมียม';

  @override
  String get back => 'กลับ';

  @override
  String get threeDaysFree => 'ฟรี 3 วัน';

  @override
  String get unlimitedReply => 'รุ่นตอบกลับไม่ จำกัด';

  @override
  String get unlimitedPolish => 'ปรับปรุงข้อความได้ไม่จำกัด';

  @override
  String get balancesPreserved => 'ยอดคงเหลือฟรีและเครดิตจะยังคงอยู่';

  @override
  String get loadingSubscriptionOptions =>
      'กำลังโหลดตัวเลือกการสมัครรับข้อมูล...';

  @override
  String get startFreeTrial => 'เริ่มทดลองใช้ฟรี 3 วัน';

  @override
  String get startYearlyPlan => 'เริ่มแผนรายปี';

  @override
  String trialTerms(String price) {
    return 'ฟรี 3 วัน จากนั้น $price/ปี ยกเลิกได้ตลอดเวลา';
  }

  @override
  String yearlyTerms(String price) {
    return '$price/ปี ยกเลิกได้ตลอดเวลา';
  }

  @override
  String get displayedPrice => 'ราคาที่แสดง';

  @override
  String get topUpCredits => 'เครดิตเติมเงิน';

  @override
  String get creditDescription =>
      'เครดิตแต่ละรายการครอบคลุมหนึ่งคำตอบหรือการปรับปรุงข้อความหนึ่งรายการ เครดิตไม่มีวันหมดอายุ';

  @override
  String get loadingCreditPackages => 'กำลังโหลดแพ็คเกจเครดิต...';

  @override
  String get creditPackagesUnavailable =>
      'แพ็คเกจเครดิตไม่สามารถใช้งานได้ในขณะนี้';

  @override
  String get refreshPackages => 'รีเฟรชแพ็คเกจ';

  @override
  String buyCreditPackage(int credits, String price) {
    return 'ซื้อเครดิต $credits — $price';
  }

  @override
  String get restoring => 'กำลังคืนค่า...';

  @override
  String get restorePremium => 'คืนค่าการสมัครสมาชิกระดับพรีเมียม';

  @override
  String get purchaseVerification =>
      'การซื้อพรีเมี่ยมและเครดิตได้รับการตรวจสอบโดย ReplyWise การซื้อเครดิตจะได้รับการกระทบยอดโดยอัตโนมัติ';

  @override
  String get newGuidanceTooltip => 'คำแนะนำใหม่';

  @override
  String get builtIn => 'บิวท์อิน';

  @override
  String get myGuidance => 'คำแนะนำของฉัน';

  @override
  String get useInReply => 'ใช้ในการตอบกลับ';

  @override
  String get useInPolish => 'ใช้สำหรับการปรับปรุงข้อความ';

  @override
  String get deleteGuidance => 'ลบคำแนะนำนี้ใช่ไหม';

  @override
  String get cannotBeUndone => 'สิ่งนี้ไม่สามารถยกเลิกได้';

  @override
  String get category => 'หมวดหมู่';

  @override
  String get titleLabel => 'ชื่อ';

  @override
  String get guidanceTitleHint => 'ชื่อย่อของคำแนะนำนี้...';

  @override
  String get guidanceHint => 'อธิบายว่า AI ควรกำหนดรูปแบบการตอบกลับอย่างไร...';

  @override
  String get writeAnyLanguage => 'เขียนเป็นภาษาใดก็ได้';

  @override
  String get saveChanges => 'บันทึกการเปลี่ยนแปลง';

  @override
  String get saveGuidance => 'บันทึกคำแนะนำ';

  @override
  String get couldNotSaveGuidance =>
      'ไม่สามารถบันทึกคำแนะนำนี้ได้ โปรดลองอีกครั้ง';

  @override
  String get concise => 'กระชับ';

  @override
  String get moreNatural => 'เป็นธรรมชาติมากขึ้น';

  @override
  String get improveGrammar => 'ปรับปรุงไวยากรณ์';

  @override
  String get fixSpelling => 'แก้ไขการสะกดคำ';

  @override
  String get morePersuasive => 'โน้มน้าวใจมากขึ้น';

  @override
  String get moreConfident => 'มีความมั่นใจมากขึ้น';

  @override
  String get simplifyWording => 'ลดความซับซ้อนของถ้อยคำ';

  @override
  String get betterFlow => 'ไหลเวียนได้ดีขึ้น';

  @override
  String get describePolish => 'อธิบายว่าคุณต้องการให้ร่างขัดเกลาอย่างไร';

  @override
  String get describeAudience => 'บรรยายถึงผู้ฟัง';

  @override
  String get audienceHint => 'เช่น ผู้จัดการของฉัน';

  @override
  String get extraInstruction => 'คำแนะนำเพิ่มเติม';

  @override
  String get extraPolishHint => 'เพิ่มการตั้งค่าการปรับปรุงข้อความอื่นๆ';

  @override
  String get polishing => 'กำลังปรับปรุงข้อความ...';

  @override
  String get polishText => 'ปรับปรุงข้อความ';

  @override
  String get adjustToneLengthFormat => 'ปรับโทน ความยาว และรูปแบบ';

  @override
  String get instructionProfessional => 'ทำให้การเขียนฟังดูเป็นมืออาชีพ';

  @override
  String get instructionFriendly => 'ทำให้การเขียนอบอุ่นและเป็นมิตรมากขึ้น';

  @override
  String get instructionConcise => 'เขียนให้กระชับและตรงประเด็น';

  @override
  String get instructionNatural => 'ทำให้ถ้อยคำฟังดูเป็นธรรมชาติและคล่องแคล่ว';

  @override
  String get instructionGrammar => 'แก้ไขไวยากรณ์ในขณะที่รักษาความหมาย';

  @override
  String get instructionSpelling => 'แก้ไขข้อผิดพลาดการสะกดทั้งหมด';

  @override
  String get instructionPersuasive =>
      'ทำให้การเขียนโน้มน้าวใจและน่าสนใจยิ่งขึ้น';

  @override
  String get instructionConfident => 'ทำให้เสียงการเขียนชัดเจนและมั่นใจ';

  @override
  String get instructionSimple => 'ใช้คำที่เรียบง่ายและอ่านง่ายขึ้น';

  @override
  String get instructionFlow => 'ปรับปรุงการลื่นไหลและการเปลี่ยนประโยค';

  @override
  String get shorter => 'สั้นลง';

  @override
  String get sameLength => 'เดียวกัน';

  @override
  String get longer => 'อีกต่อไป';

  @override
  String get favorites => 'รายการโปรด';

  @override
  String get createGuidanceEmpty => 'สร้างคำแนะนำของคุณเองเพื่อใช้ซ้ำในภายหลัง';

  @override
  String get removeFavorite => 'ลบออกจากรายการโปรด';

  @override
  String get addFavorite => 'เพิ่มในรายการโปรด';

  @override
  String useTemplate(String title) {
    return 'ใช้ “$title”';
  }

  @override
  String get chooseGuidance => 'เลือกคำแนะนำ';

  @override
  String get library => 'ห้องสมุด';

  @override
  String get general => 'ทั่วไป';

  @override
  String get decline => 'ปฏิเสธ';

  @override
  String get thanks => 'ขอบคุณ';

  @override
  String get followUp => 'การติดตามผล';

  @override
  String get editGuidance => 'แก้ไขคำแนะนำ';

  @override
  String get makeProfessional => 'ทำให้เป็นมืออาชีพ';

  @override
  String get makeFriendly => 'ทำให้มันเป็นมิตร';

  @override
  String get askMoreTime => 'ขอเวลาเพิ่ม';

  @override
  String get soundConfident => 'เสียงมั่นใจ';

  @override
  String get guidancePoliteContent => 'ตอบกลับอย่างสุภาพและให้เกียรติ';

  @override
  String get guidanceShortContent => 'ตอบกลับให้สั้นและชัดเจน';

  @override
  String get guidanceProfessionalContent =>
      'ทำให้การตอบกลับฟังดูเป็นมืออาชีพและเหมาะสมกับการทำงาน';

  @override
  String get guidanceFriendlyContent => 'ทำให้การตอบกลับอบอุ่นและเป็นกันเอง';

  @override
  String get guidanceDeclineContent => 'ปฏิเสธคำขออย่างสุภาพโดยไม่ดูหยาบคาย';

  @override
  String get guidanceThanksContent => 'เติมคำขอบคุณและคำขอบคุณอย่างสุภาพ';

  @override
  String get guidanceMoreTimeContent =>
      'ขอเวลาเพิ่มในขณะที่ฟังดูมีความรับผิดชอบและสุภาพ';

  @override
  String get guidanceConfidentContent => 'ทำให้คำตอบฟังดูมั่นใจแต่ไม่ก้าวร้าว';

  @override
  String todayAt(String time) {
    return 'วันนี้ · $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'เมื่อวาน · $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date · $time';
  }

  @override
  String get premiumActive => 'การสมัครสมาชิกแบบพรีเมียมเปิดใช้งานอยู่';

  @override
  String creditsRemaining(String count) {
    return '$count เครดิตที่เหลืออยู่';
  }

  @override
  String get adIsLoading => 'กำลังโหลดโฆษณา โปรดลองอีกครั้ง';

  @override
  String get creditAdded => 'เพิ่มเครดิตแล้ว';

  @override
  String get outOfCreditsTitle => 'คุณไม่มีเครดิตแล้ว';

  @override
  String get outOfCreditsMessage =>
      'ดูโฆษณาสั้นๆ เพื่อรับ 1 เครดิตฟรี หรืออัปเกรดเพื่อการเข้าถึงที่มากขึ้น';

  @override
  String get buyCredits => 'ซื้อเครดิต';

  @override
  String get creditAddedTapGenerateAgain => 'เพิ่มเครดิตแล้ว แตะสร้างอีกครั้ง';

  @override
  String get adDailyLimitReached => 'ถึงขีดจำกัดรางวัลโฆษณารายวันแล้ว';

  @override
  String get adLoadFailed => 'ไม่สามารถโหลดโฆษณาได้ โปรดลองอีกครั้งในภายหลัง';

  @override
  String get adRewardCooldown => 'โปรดรอสักครู่ก่อนดูโฆษณาอื่น';

  @override
  String get adRewardFailed => 'ไม่สามารถเพิ่มเครดิตของคุณได้ โปรดลองอีกครั้ง';
}
