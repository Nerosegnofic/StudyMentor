import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseAuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _cachedPassword;

  Future<UserCredential> signUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

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

  /// Verifies credentials using a secondary FirebaseAuth instance
  /// to avoid disrupting the current user session.
  /// Returns the authenticated UID if successful, null otherwise.
  Future<String?> verifyCredentialsAndGetUid(
    String email,
    String password,
  ) async {
    try {
      final existingApp = Firebase.apps.cast<FirebaseApp?>().firstWhere(
        (app) => app?.name == '_parentVerifier',
        orElse: () => null,
      );

      FirebaseAuth secondaryAuth;
      if (existingApp != null) {
        secondaryAuth = FirebaseAuth.instanceFor(app: existingApp);
      } else {
        final app = await Firebase.initializeApp(
          name: '_parentVerifier',
          options: Firebase.app().options,
        );
        secondaryAuth = FirebaseAuth.instanceFor(app: app);
      }

      final credential = await secondaryAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;

      // Sign out the secondary instance immediately — no session leakage
      await secondaryAuth.signOut();

      return uid;
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
    }
  }
}