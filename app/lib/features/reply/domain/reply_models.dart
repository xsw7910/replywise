class ReplyAudience {
  const ReplyAudience({
    required this.mode,
    this.preset,
    this.custom,
    required this.formality,
  });

  final String mode;
  final String? preset;
  final String? custom;
  final int formality;

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'preset': preset,
    'custom': custom,
    'formality': formality,
  };
}

class ReplyRequest {
  const ReplyRequest({
    required this.incoming,
    required this.guidance,
    required this.guidanceLang,
    this.tone,
    required this.audience,
  });

  final String incoming;
  final String guidance;
  final String guidanceLang;
  final String? tone;
  final ReplyAudience audience;

  Map<String, dynamic> toJson() => {
    'incoming': incoming,
    'guidance': guidance,
    'guidanceLang': guidanceLang,
    'outputLang': 'en',
    'tone': tone,
    'audience': audience.toJson(),
  };
}

class ReplyVersion {
  const ReplyVersion({required this.label, required this.text});

  final String label;
  final String text;

  factory ReplyVersion.fromJson(Map<String, dynamic> json) => ReplyVersion(
    label: json['label'] as String,
    text: json['text'] as String,
  );
}

class ReplyResult {
  const ReplyResult({required this.versions, required this.why});

  final List<ReplyVersion> versions;
  final String why;

  factory ReplyResult.fromJson(Map<String, dynamic> json) => ReplyResult(
    versions: (json['versions'] as List<dynamic>)
        .map((item) => ReplyVersion.fromJson(item as Map<String, dynamic>))
        .toList(),
    why: json['why'] as String,
  );
}

class ExplainResult {
  const ExplainResult({
    required this.meaning,
    required this.tone,
    required this.hiddenMeaning,
    required this.suggestedReplies,
  });

  final String meaning;
  final String tone;
  final String hiddenMeaning;
  final List<String> suggestedReplies;

  factory ExplainResult.fromJson(Map<String, dynamic> json) => ExplainResult(
    meaning: json['meaning'] as String,
    tone: json['tone'] as String,
    hiddenMeaning: json['hiddenMeaning'] as String,
    suggestedReplies: (json['suggestedReplies'] as List<dynamic>)
        .cast<String>(),
  );
}
