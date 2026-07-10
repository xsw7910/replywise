class EntitlementState {
  const EntitlementState({
    required this.isPremium,
    required this.freeUsesLimit,
    required this.freeUsesUsed,
    required this.freeUsesLeft,
    required this.paidCredits,
    required this.upgradeRequired,
  });

  const EntitlementState.initial()
    : isPremium = false,
      freeUsesLimit = 3,
      freeUsesUsed = 0,
      freeUsesLeft = null,
      paidCredits = 0,
      upgradeRequired = false;

  factory EntitlementState.fromJson(Map<String, dynamic> json) =>
      EntitlementState(
        isPremium: json['isPremium'] as bool? ?? false,
        freeUsesLimit: json['freeUsesLimit'] as int? ?? 3,
        freeUsesUsed: json['freeUsesUsed'] as int? ?? 0,
        freeUsesLeft: json['freeUsesLeft'] as int?,
        paidCredits: json['paidCredits'] as int? ?? 0,
        upgradeRequired: json['upgradeRequired'] as bool? ?? false,
      );

  final bool isPremium;
  final int freeUsesLimit;
  final int freeUsesUsed;
  final int? freeUsesLeft;
  final int paidCredits;
  final bool upgradeRequired;
}
