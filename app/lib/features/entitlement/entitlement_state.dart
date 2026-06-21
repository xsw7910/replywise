// Stub — subscription / paywall logic is deferred.
// This file will hold the Riverpod entitlement state once implemented.

enum EntitlementTier { free, pro }

class EntitlementState {
  const EntitlementState({this.tier = EntitlementTier.free});

  final EntitlementTier tier;

  bool get isPro => tier == EntitlementTier.pro;
}
