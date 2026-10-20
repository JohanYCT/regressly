import 'package:flutter_test/flutter_test.dart';
import 'package:regressly/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Tests', () {
    test('Inicialmente no hay sesión activa', () async {
      final hasSession = await AuthService.instance.hasSession();
      expect(hasSession, isFalse);
    });

    test('Establecer modo invitado activa la sesión como invitado', () async {
      await AuthService.instance.setGuestMode();

      final hasSession = await AuthService.instance.hasSession();
      final isGuest = await AuthService.instance.isGuest();
      final profile = await AuthService.instance.getUserProfile();

      expect(hasSession, isTrue);
      expect(isGuest, isTrue);
      expect(profile, isNull);
    });

    test('Cerrar sesión limpia el estado de la sesión', () async {
      await AuthService.instance.setGuestMode();
      expect(await AuthService.instance.hasSession(), isTrue);

      await AuthService.instance.signOut();

      expect(await AuthService.instance.hasSession(), isFalse);
      expect(await AuthService.instance.isGuest(), isFalse);
      expect(await AuthService.instance.getUserProfile(), isNull);
    });
  });
}
