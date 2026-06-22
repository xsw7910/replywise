class PolishRequest {
  const PolishRequest({
    required this.draft,
    required this.direction,
    this.custom,
    required this.guidanceLang,
  });

  final String draft;
  final String direction;
  final String? custom;
  final String guidanceLang;

  Map<String, dynamic> toJson() => {
    'draft': draft,
    'direction': direction,
    'custom': custom,
    'guidanceLang': guidanceLang,
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
