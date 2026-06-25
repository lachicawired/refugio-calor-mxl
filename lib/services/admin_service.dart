import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/punto.dart';
import 'punto_service.dart';

class AdminService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _puntoService = PuntoService();

  User? get usuarioActual => _auth.currentUser;

  Future<UserCredential> iniciarSesion({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> cerrarSesion() => _auth.signOut();

  Future<bool> esAdminActual() async {
    final usuario = _auth.currentUser;
    if (usuario == null) return false;

    final doc = await _db.collection('admins').doc(usuario.uid).get();
    return doc.exists;
  }

  Stream<bool> observarAdminActual() {
    final usuario = _auth.currentUser;
    if (usuario == null) return Stream.value(false);

    return _db
        .collection('admins')
        .doc(usuario.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<Punto>> obtenerPuntosPendientes() {
    return Stream.fromFuture(_puntoService.obtenerPuntosMapa()).map((puntos) {
      return puntos
          .where(
            (punto) =>
                punto.estado == 'pendiente' ||
                punto.confianza == 'reciente' ||
                punto.confianza == 'pendiente',
          )
          .toList();
    });
  }

  Stream<List<Punto>> obtenerTodosLosPuntos() {
    return Stream.fromFuture(_puntoService.obtenerPuntosMapa());
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> obtenerReportes() {
    return _db
        .collection('reportes')
        .orderBy('creadoEn', descending: true)
        .limit(80)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> crearPuntoOficial(Map<String, dynamic> data) async {
    await _db.collection('puntos').add({
      ...data,
      'fuente': 'manual',
      'confianza': 'oficial',
      'estado': data['estado'] ?? 'abierto',
      'direccionVerificada': true,
      'oculto': false,
      'esBase': false,
      'ultimaConfirmacion': FieldValue.serverTimestamp(),
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> actualizarPunto(Punto punto, Map<String, dynamic> data) async {
    final collection = punto.esBase ? 'puntos_estado' : 'puntos';
    await _db.collection(collection).doc(punto.id).set({
      ...data,
      'actualizadoPorAdminEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> aceptarPunto(Punto punto) async {
    await actualizarPunto(punto, {
      'estado': 'abierto',
      'confianza': 'oficial',
      'fuente': 'manual',
      'direccionVerificada': true,
      'ultimaConfirmacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> marcarCerrado(Punto punto) async {
    await actualizarPunto(punto, {'estado': 'cerrado', 'confianza': 'cerrado'});
  }

  Future<void> eliminarPunto(Punto punto) async {
    if (punto.esBase) {
      await _db.collection('puntos_ocultos').doc(punto.id).set({
        'oculto': true,
        'ocultoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    await _db.collection('puntos').doc(punto.id).set({
      'oculto': true,
      'ocultoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
