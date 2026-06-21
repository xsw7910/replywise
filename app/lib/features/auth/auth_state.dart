// Stub — auth logic is deferred.
// This file will hold the Riverpod auth state once implemented.

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unauthenticated, this.userId});

  final AuthStatus status;
  final String? userId;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}
