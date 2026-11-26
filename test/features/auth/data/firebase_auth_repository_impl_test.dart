import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loki/core/error/failures.dart';
import 'package:loki/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleAccount extends Mock implements GoogleSignInAccount {}

void main() {
  late MockFirebaseAuth mockAuth;
  late _MockGoogleSignIn mockGoogleSignIn;
  late FirebaseAuthRepositoryImpl repository;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = _MockGoogleSignIn();
    repository = FirebaseAuthRepositoryImpl(
      firebaseAuth: mockAuth,
      googleSignIn: mockGoogleSignIn,
    );
  });

  test(
    'ensureSignedInAnonymously creates anonymous session when signed out',
    () async {
      final result = await repository.ensureSignedInAnonymously();

      expect(result.isSuccess, isTrue);
      final user = result.dataOrNull!;
      expect(user.uid, isNotEmpty);
      expect(user.isAnonymous, isTrue);
    },
  );

  test('getCurrentUser returns existing signed-in user', () async {
    final signedInAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'user-123',
        isAnonymous: false,
        email: 'loc@example.com',
        displayName: 'Loc',
      ),
    );
    final repo = FirebaseAuthRepositoryImpl(
      firebaseAuth: signedInAuth,
      googleSignIn: mockGoogleSignIn,
    );

    final user = repo.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.uid, 'user-123');
    expect(user.isAnonymous, isFalse);
    expect(user.email, 'loc@example.com');
  });

  test('signOut clears current user session', () async {
    await repository.ensureSignedInAnonymously();
    expect(repository.getCurrentUser(), isNotNull);

    final outResult = await repository.signOut();
    expect(outResult.isSuccess, isTrue);
    expect(repository.getCurrentUser(), isNull);
  });

  test(
    'linkWithEmailPassword returns AuthFailure when no user is signed in',
    () async {
      final result = await repository.linkWithEmailPassword(
        'loc@example.com',
        'StrongPass123!',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
    },
  );

  test(
    'linkWithGoogle uses native account chooser and maps cancel to cancelled',
    () async {
      final anonAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'anon-1', isAnonymous: true),
      );
      when(() => mockGoogleSignIn.initialize()).thenAnswer((_) async {});
      when(() => mockGoogleSignIn.authenticate()).thenThrow(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      );
      final repo = FirebaseAuthRepositoryImpl(
        firebaseAuth: anonAuth,
        googleSignIn: mockGoogleSignIn,
      );

      final result = await repo.linkWithGoogle();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'cancelled');
      verify(() => mockGoogleSignIn.initialize()).called(1);
      verify(() => mockGoogleSignIn.authenticate()).called(1);

      // initialize() must only run once across repeated attempts.
      await repo.linkWithGoogle();
      verifyNever(() => mockGoogleSignIn.initialize());
    },
  );

  test(
    'linkWithGoogle signs in directly with Google when no session exists',
    () async {
      final signedOutAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'google-1', email: 'loc@gmail.com'),
      );
      final account = _MockGoogleAccount();
      when(
        () => account.authentication,
      ).thenReturn(const GoogleSignInAuthentication(idToken: 'id-token'));
      when(() => mockGoogleSignIn.initialize()).thenAnswer((_) async {});
      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => account);
      final repo = FirebaseAuthRepositoryImpl(
        firebaseAuth: signedOutAuth,
        googleSignIn: mockGoogleSignIn,
      );

      final result = await repo.linkWithGoogle();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.uid, 'google-1');
      expect(signedOutAuth.currentUser, isNotNull);
    },
  );
}
