import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
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

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  obtenerPuntosReportadosPendientes() {
    return _db
        .collection('puntos_reportados')
        .where('estado', isEqualTo: 'pendiente')
        .limit(80)
        .snapshots()
        .map((snapshot) => snapshot.docs);
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
      'aprobado': true,
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

  Future<void> aprobarPuntoReportado(
    QueryDocumentSnapshot<Map<String, dynamic>> reporte,
  ) async {
    final data = reporte.data();
    final puntoRef = _db.collection('puntos').doc(reporte.id);
    final reporteRef = _db.collection('puntos_reportados').doc(reporte.id);

    final batch = _db.batch();
    batch.set(puntoRef, {
      ...data,
      'estado': 'abierto',
      'confianza': 'comunidad',
      'aprobado': true,
      'rechazado': false,
      'oculto': false,
      'esBase': false,
      'aprobadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.update(reporteRef, {
      'estado': 'aprobado',
      'aprobado': true,
      'aprobadoEn': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> rechazarPuntoReportado(String id) async {
    await _db.collection('puntos_reportados').doc(id).set({
      'estado': 'rechazado',
      'rechazado': true,
      'oculto': true,
      'rechazadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> eliminarPuntoReportado(String id) async {
    await _db.collection('puntos_reportados').doc(id).delete();
  }

  Future<String> generarJsonPuntosAprobados() async {
    final snapshot = await _db
        .collection('puntos')
        .where('esBase', isEqualTo: false)
        .where('oculto', isEqualTo: false)
        .where('aprobado', isEqualTo: true)
        .get();

    final puntos = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'nombre': data['nombre'] ?? '',
        'tipo': data['tipo'] ?? 'hidratacion',
        'direccion': data['direccion'] ?? '',
        'telefono': data['telefono'] ?? '',
        'lat': data['lat'] ?? 0,
        'lng': data['lng'] ?? 0,
        'horario': data['horario'] ?? 'Por confirmar',
        'descripcion': data['descripcion'] ?? '',
        'estado': 'sin_confirmar',
        'confianza': 'pendiente',
        'ultimaConfirmacion': null,
        'confirmaciones': 0,
        'votosAbiertoHoy': 0,
        'votosCerradoHoy': 0,
        'diaVotacion': '',
        'fuente': 'manual',
        'direccionVerificada': data['direccionVerificada'] ?? false,
        'esBase': true,
      };
    }).toList();

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(puntos);
  }
}
