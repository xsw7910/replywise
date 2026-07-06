class PolishRequest {
  const PolishRequest({
    required this.draft,
    required this.direction,
    this.custom,
    this.guidance,
    this.tone,
    this.audience,
    this.length,
    this.extraInstruction,
    required this.guidanceLang,
    this.appLocale,
  });

  final String draft;
  final String direction;
  final String? custom;
  final String? guidance;
  final String? tone;
  final String? audience;
  final String? length;
  final String? extraInstruction;
  final String guidanceLang;
  final String? appLocale;

  Map<String, dynamic> toJson() => {
    'draft': draft,
    'direction': direction,
    'custom': custom,
    'guidance': guidance,
    'tone': tone,
    'audience': audience,
    'length': length,
    'extraInstruction': extraInstruction,
    'guidanceLang': guidanceLang,
    if (appLocale != null) 'appLocale': appLocale,
  };
}

class PolishResult {
  const PolishResult({required this.polished, required this.changes});

  final String polished;
  final String changes;

  factory PolishResult.fromJson(Map<String, dynamic> json) => PolishResult(
    polished: json['polished'] as String,
    changes: json['changes'] as String,
  );
}
