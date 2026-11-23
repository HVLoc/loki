import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/core/utils/app_logger.dart';
import 'package:loki/features/auth/domain/entities/auth_user.dart';
import 'package:loki/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  FirebaseAuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Future<Result<AuthUser, Failure>> ensureSignedInAnonymously() async {
    try {
      final existing = _firebaseAuth.currentUser;
      if (existing != null) {
        return Success(_mapUser(existing));
      }
      final credential = await _firebaseAuth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        return const FailureResult(
          AuthFailure('Failed to create anonymous user session'),
        );
      }
      return Success(_mapUser(user));
    } on FirebaseAuthException catch (e, st) {
      if (e.code == 'admin-restricted-operation') {
        AppLogger.warn(
          'AuthRepo',
          'Anonymous auth disabled on Firebase Console; waiting for Google/Email sign-in',
        );
      } else {
        AppLogger.error('AuthRepo', 'Anonymous sign-in failed', e, st);
      }
      return FailureResult(AuthFailure(e.message ?? e.code, code: e.code));
    } catch (e, st) {
      AppLogger.error('AuthRepo', 'Unexpected anonymous sign-in error', e, st);
      return FailureResult(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthUser, Failure>> linkWithGoogle() async {
    try {
      final current = _firebaseAuth.currentUser;
      if (current == null) {
        return const FailureResult(AuthFailure('No active user session'));
      }
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        return const FailureResult(
          AuthFailure('Google sign-in was cancelled', code: 'cancelled'),
        );
      }
      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final linked = await current.linkWithCredential(credential);
      return Success(_mapUser(linked.user ?? current));
    } on FirebaseAuthException catch (e, st) {
      AppLogger.error('AuthRepo', 'Google link failed', e, st);
      return FailureResult(AuthFailure(e.message ?? e.code, code: e.code));
    } catch (e, st) {
      AppLogger.error('AuthRepo', 'Unexpected Google link error', e, st);
      return FailureResult(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthUser, Failure>> linkWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final current = _firebaseAuth.currentUser;
      if (current == null) {
        return const FailureResult(AuthFailure('No active user session'));
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final linked = await current.linkWithCredential(credential);
      return Success(_mapUser(linked.user ?? current));
    } on FirebaseAuthException catch (e, st) {
      AppLogger.error('AuthRepo', 'Email link failed', e, st);
      return FailureResult(AuthFailure(e.message ?? e.code, code: e.code));
    } catch (e, st) {
      AppLogger.error('AuthRepo', 'Unexpected email link error', e, st);
      return FailureResult(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthUser, Failure>> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const FailureResult(AuthFailure('Sign-in returned null user'));
      }
      return Success(_mapUser(user));
    } on FirebaseAuthException catch (e, st) {
      AppLogger.error('AuthRepo', 'Email sign-in failed', e, st);
      return FailureResult(AuthFailure(e.message ?? e.code, code: e.code));
    } catch (e, st) {
      AppLogger.error('AuthRepo', 'Unexpected email sign-in error', e, st);
      return FailureResult(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('AuthRepo', 'Sign-out failed', e, st);
      return FailureResult(AuthFailure(e.toString()));
    }
  }

  @override
  AuthUser? getCurrentUser() {
    final user = _firebaseAuth.currentUser;
    return user == null ? null : _mapUser(user);
  }

  @override
  Stream<AuthUser?> watchAuthState() => _firebaseAuth.authStateChanges().map(
    (u) => u == null ? null : _mapUser(u),
  );

  AuthUser _mapUser(User user) => AuthUser(
    uid: user.uid,
    isAnonymous: user.isAnonymous,
    email: user.email,
    displayName: user.displayName,
  );
}
