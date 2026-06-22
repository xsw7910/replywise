enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  refreshing,
  tokenExpired,
  failure,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.userId,
    this.appUserId,
    this.errorMessage,
  });

  final AuthStatus status;
  final int? userId;
  final String? appUserId;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading =>
      status == AuthStatus.authenticating || status == AuthStatus.refreshing;

  AuthState copyWith({
    AuthStatus? status,
    int? userId,
    String? appUserId,
    String? errorMessage,
    bool clearError = false,
  }) => AuthState(
    status: status ?? this.status,
    userId: userId ?? this.userId,
    appUserId: appUserId ?? this.appUserId,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
