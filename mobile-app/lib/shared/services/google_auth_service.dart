import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

class GoogleAuthService {
  static const String _sheetsScope =
      'https://www.googleapis.com/auth/spreadsheets';

  static final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: const [
      'email',
      _sheetsScope,
    ],
  );

  static Future<GoogleSignInAccount?> signInInteractive() async {
    return googleSignIn.signIn();
  }

  static Future<GoogleSignInAccount?> signInSilently() async {
    return googleSignIn.signInSilently();
  }

  static Future<AuthClient?> authClient({bool trySilentSignIn = true}) async {
    var client = await googleSignIn.authenticatedClient();
    if (client != null) return client;

    if (googleSignIn.currentUser == null && trySilentSignIn) {
      await signInSilently();
      client = await googleSignIn.authenticatedClient();
      if (client != null) return client;
    }

    // No separate "verify" step: if silent auth is unavailable, request access directly.
    final account = await signInInteractive();
    if (account == null) return null;
    return googleSignIn.authenticatedClient();
  }

  static Future<void> signOut() async {
    await googleSignIn.signOut();
  }
}
