import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final DemoOperator? operator;
  final bool isLoading;

  const AuthState({this.operator, this.isLoading = false});

  bool get isAuthenticated => operator != null;

  AuthState copyWith({DemoOperator? operator, bool? isLoading}) {
    return AuthState(
      operator: operator ?? this.operator,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState(operator: AuthRepository.availableDemoRoles.first);
  }

  Future<void> loginAs(DemoOperator role) async {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(authRepositoryProvider);
    final op = await repo.loginDemo(role);
    state = AuthState(operator: op, isLoading: false);
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AuthState(operator: null, isLoading: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
