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
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// google_sign_in 7.x requires exactly one `initialize()` call. On Android
  /// the server (web) client ID is read from the `default_web_client_id`
  /// resource generated from google-services.json.
  Future<void>? _googleInit;
  Future<void> _ensureGoogleInitialized() =>
      _googleInit ??= _googleSignIn.initialize();

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

  /// Shows the native account chooser (Android Credential Manager bottom
  /// sheet) listing Google accounts already signed in on the device, so the
  /// user picks one with a single tap instead of typing email/password.
  ///
  /// - If an (anonymous) session exists, the Google account is linked to it
  ///   so existing data is kept.
  /// - If there is no session (e.g. Anonymous auth is disabled on Firebase),
  ///   the user is signed in directly with Google.
  /// - If the Google account already belongs to another Firebase user, the
  ///   app switches to that account.
  @override
  Future<Result<AuthUser, Failure>> linkWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final googleAccount = await _googleSignIn.authenticate();
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null) {
        return const FailureResult(
          AuthFailure('Không lấy được mã xác thực từ Google'),
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final current = _firebaseAuth.currentUser;
      if (current == null) {
        return _signInWithCredential(credential);
      }
      try {
        final linked = await current.linkWithCredential(credential);
        return Success(_mapUser(linked.user ?? current));
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          return _signInWithCredential(e.credential ?? credential);
        }
        rethrow;
      }
    } on GoogleSignInException catch (e, st) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const FailureResult(
          AuthFailure('Đã huỷ liên kết Google', code: 'cancelled'),
        );
      }
      AppLogger.error('AuthRepo', 'Google sign-in failed', e, st);
      final message =
          e.code == GoogleSignInExceptionCode.clientConfigurationError
          ? 'Cấu hình Google Sign-In chưa đúng (kiểm tra SHA-1 trên Firebase).'
          : (e.description ?? 'Không thể đăng nhập Google');
      return FailureResult(AuthFailure(message, code: e.code.name));
    } on FirebaseAuthException catch (e, st) {
      AppLogger.error('AuthRepo', 'Google link failed', e, st);
      final message = switch (e.code) {
        'provider-already-linked' => 'Tài khoản đã được liên kết Google.',
        _ => e.message ?? e.code,
      };
      return FailureResult(AuthFailure(message, code: e.code));
    } catch (e, st) {
      AppLogger.error('AuthRepo', 'Unexpected Google link error', e, st);
      return FailureResult(AuthFailure(e.toString()));
    }
  }

  Future<Result<AuthUser, Failure>> _signInWithCredential(
    AuthCredential credential,
  ) async {
    final result = await _firebaseAuth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      return const FailureResult(AuthFailure('Đăng nhập Google thất bại'));
    }
    return Success(_mapUser(user));
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
