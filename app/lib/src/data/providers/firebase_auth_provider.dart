// lib/src/data/providers/firebase_auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseAuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _cachedPassword;

  // ── basic auth ─────────────────────────────────────────────────────────────

  Future<UserCredential> signUp(String email, String password) async {
    _cachedPassword = password;
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signIn(String email, String password) async {
    _cachedPassword = password;
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signInWithPassword(String email, String password) async {
    _cachedPassword = password;
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  String? get cachedPassword => _cachedPassword;

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> signOut() async {
    _cachedPassword = null;
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  User? get currentUser => _auth.currentUser;

  Future<void> reloadUser() async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.reload();
    }
  }

  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken(true);
  }

  // ── profile update helpers ─────────────────────────────────────────────────

  /// Reauthenticates the current user with their current password.
  /// Must be called before [updatePassword] to satisfy Firebase's
  /// recent-login requirement.
  ///
  /// Throws [FirebaseAuthException] on wrong password or network error.
  Future<void> reauthenticate(String currentPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user.');
    if (user.email == null) throw Exception('User has no email address.');

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Updates the current user's password in Firebase Auth.
  /// [reauthenticate] must be called first.
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user.');
    await user.updatePassword(newPassword);
    // Keep the cached password in sync so createStudent still works.
    _cachedPassword = newPassword;
  }

  // ── secondary-app helpers ──────────────────────────────────────────────────

  /// Returns the secondary FirebaseAuth instance, creating the secondary
  /// Firebase app if it does not exist yet.
  Future<FirebaseAuth> _getSecondaryAuth() async {
    final existingApp = Firebase.apps.cast<FirebaseApp?>().firstWhere(
      (app) => app?.name == '_parentVerifier',
      orElse: () => null,
    );

    if (existingApp != null) {
      return FirebaseAuth.instanceFor(app: existingApp);
    }

    final app = await Firebase.initializeApp(
      name: '_parentVerifier',
      options: Firebase.app().options,
    );
    return FirebaseAuth.instanceFor(app: app);
  }

  /// Verifies credentials using the secondary Firebase app so the current
  /// parent session is not disrupted.
  /// Returns the authenticated UID on success, null on failure.
  Future<String?> verifyCredentialsAndGetUid(
    String email,
    String password,
  ) async {
    try {
      final secondaryAuth = await _getSecondaryAuth();
      final credential = await secondaryAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      await secondaryAuth.signOut();
      return uid;
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Checks whether the Firebase account identified by [email] / [password]
  /// has verified their email address.
  ///
  /// Uses the secondary app so the parent's session is unaffected.
  /// Returns `null` if the credentials are wrong or any error occurs.
  Future<bool?> checkEmailVerifiedForCredentials(
    String email,
    String password,
  ) async {
    try {
      final secondaryAuth = await _getSecondaryAuth();
      final credential = await secondaryAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.reload();
      final verified = secondaryAuth.currentUser?.emailVerified;
      await secondaryAuth.signOut();
      return verified;
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
