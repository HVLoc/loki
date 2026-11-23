import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<Result<AuthUser, Failure>> ensureSignedInAnonymously();
  Future<Result<AuthUser, Failure>> linkWithGoogle();
  Future<Result<AuthUser, Failure>> linkWithEmailPassword(
    String email,
    String password,
  );
  Future<Result<AuthUser, Failure>> signInWithEmailPassword(
    String email,
    String password,
  );
  Future<Result<void, Failure>> signOut();
  AuthUser? getCurrentUser();
  Stream<AuthUser?> watchAuthState();
}
