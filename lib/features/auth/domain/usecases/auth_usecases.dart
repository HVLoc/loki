import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/features/auth/domain/entities/auth_user.dart';
import 'package:loki/features/auth/domain/repositories/auth_repository.dart';

class EnsureAnonymousSessionUseCase {
  const EnsureAnonymousSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser, Failure>> call() =>
      _repository.ensureSignedInAnonymously();
}

class LinkAccountUseCase {
  const LinkAccountUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser, Failure>> withGoogle() =>
      _repository.linkWithGoogle();

  Future<Result<AuthUser, Failure>> withEmailPassword(
    String email,
    String password,
  ) {
    if (email.trim().isEmpty || !email.contains('@')) {
      return Future.value(
        const FailureResult(ValidationFailure('Invalid email address')),
      );
    }
    if (password.length < 6) {
      return Future.value(
        const FailureResult(
          ValidationFailure('Password must be at least 6 characters'),
        ),
      );
    }
    return _repository.linkWithEmailPassword(email.trim(), password);
  }
}
