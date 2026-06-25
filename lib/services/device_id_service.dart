import 'package:firebase_auth/firebase_auth.dart';

class DeviceIdService {
  static Future<String> obtenerDeviceId() async {
    final auth = FirebaseAuth.instance;
    final usuarioActual = auth.currentUser;

    if (usuarioActual != null) {
      return usuarioActual.uid;
    }

    final credencial = await auth.signInAnonymously();
    return credencial.user!.uid;
  }
}
