import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvider();
    test('Should not be initialized to begin with',
        () => {expect(provider.isInitialized, false)});
    test('cannot log out, if not initialized', () {
      expect(provider.logOut(),
          throwsA(const TypeMatcher<NotInitializedException>()));
    });
    test("should be able to be initialized", () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    });
    test('User should be null after initializing', () {
      expect(provider.currentUser, null);
    });
    test('should intialize in 2 seconds', () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    }, timeout: const Timeout(Duration(seconds: 3)));
    test('create user should delegate to login function', () async {
      final badEmailUser = provider.createUser(
        email: 'nobs@gmal.com', // Correct the email to match the one in logIn
        password: 'password',
      );
      expect(
        badEmailUser,
        throwsA(const TypeMatcher<UserNotFoundAuthException>()),
      );

      final badPassword = provider.createUser(
        email: 'nobsafrica@gmail.com',
        password: 'nobsafrica',
      );
      expect(
        badPassword,
        throwsA(const TypeMatcher<
            WrongPasswordAuthException>()), // Correct the exception type
      );

      final user = await provider.createUser(email: 'nobs', password: 'africa');
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });

    test('logged in users should be able to get verified', () {
      provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user?.isEmailVerified, true);
    });
    test('should be able to log out and login', () async {
      await provider.logOut();
      await provider.logIn(email: "email", password: "password");
      final user = provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser(
      {required String email, required String password}) async {
    if (!isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 2));
    return logIn(email: email, password: password);
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 2));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({required String email, required String password}) {
    if (!isInitialized) throw NotInitializedException();
    if (email == 'nobs@gmal.com') throw UserNotFoundAuthException();
    if (password == 'nobsafrica') throw WrongPasswordAuthException();
    const user =
        AuthUser(isEmailVerified: false, email: 'nobsafrica@gmail.com');
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 2));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedException();
    final user = _user;
    if (user == null) throw UserNotFoundAuthException();
    const newUser =
        AuthUser(isEmailVerified: true, email: 'nobsafrica@gmail.com');
    _user = newUser;
  }
}
