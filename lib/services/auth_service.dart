import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo sencillo para representar la información del usuario autenticado.
class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });
}

/// Servicio encargado de la autenticación con Google y la gestión del estado de sesión.
class AuthService {
  /// Instancia del cliente de Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Claves para SharedPreferences
  static const String _keyIsLoggedIn = 'auth_is_logged_in';
  static const String _keyIsGuest = 'auth_is_guest';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserName = 'auth_user_name';
  static const String _keyUserEmail = 'auth_user_email';
  static const String _keyUserPhoto = 'auth_user_photo';

  /// Instancia Singleton de AuthService
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  /// Inicia sesión utilizando la cuenta de Google del usuario.
  ///
  /// Guarda la información del usuario en SharedPreferences para uso offline.
  Future<UserProfile?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setBool(_keyIsGuest, false);
      await prefs.setString(_keyUserId, googleUser.id);
      await prefs.setString(_keyUserName, googleUser.displayName ?? '');
      await prefs.setString(_keyUserEmail, googleUser.email);
      if (googleUser.photoUrl != null) {
        await prefs.setString(_keyUserPhoto, googleUser.photoUrl!);
      } else {
        await prefs.remove(_keyUserPhoto);
      }

      return UserProfile(
        id: googleUser.id,
        displayName: googleUser.displayName ?? '',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl,
      );
    } catch (e) {
      // Error al iniciar sesión
      return null;
    }
  }

  /// Establece el modo de uso como 'Invitado' (sin cuenta vinculada).
  Future<void> setGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setBool(_keyIsGuest, true);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPhoto);
  }

  /// Cierra la sesión activa de Google y limpia las preferencias locales.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.setBool(_keyIsGuest, false);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPhoto);
  }

  /// Verifica si hay una sesión activa (ya sea como usuario registrado o como invitado).
  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Indica si el usuario actual está navegando en modo invitado.
  Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsGuest) ?? false;
  }

  /// Obtiene el perfil del usuario guardado localmente si está autenticado.
  Future<UserProfile?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuestMode = prefs.getBool(_keyIsGuest) ?? false;
    if (isGuestMode) return null;

    final id = prefs.getString(_keyUserId);
    final email = prefs.getString(_keyUserEmail);
    if (id == null || email == null) return null;

    return UserProfile(
      id: id,
      displayName: prefs.getString(_keyUserName) ?? '',
      email: email,
      photoUrl: prefs.getString(_keyUserPhoto),
    );
  }
}
