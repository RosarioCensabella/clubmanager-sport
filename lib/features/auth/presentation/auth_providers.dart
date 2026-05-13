import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_result.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AppAuthUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return repository.authStateChanges();
});

final authControllerProvider = Provider<AuthController>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return AuthController(repository);
});

class AuthController {
  AuthController(this._repository);

  final AuthRepository _repository;

  AppAuthUser? get currentUser => _repository.currentUser;

  Future<AppResult<AppAuthUser>> signIn({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<AppResult<AppAuthUser?>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) {
    return _repository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }

  Future<AppResult<void>> sendPasswordResetEmail({required String email}) {
    return _repository.sendPasswordResetEmail(email: email);
  }

  Future<AppResult<void>> signOut() {
    return _repository.signOut();
  }
}
