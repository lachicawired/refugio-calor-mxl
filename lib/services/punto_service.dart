import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../models/punto.dart';
import '../models/reporte.dart';
import 'device_id_service.dart';

class PuntoService {
  static const int _votosMinimosParaCambiarEstado = 2;
  static const int _maxReportesPunto = 2;
  static const Duration _ventanaReportesPunto = Duration(days: 3);

  final _db = FirebaseFirestore.instance;

  Future<List<Punto>> obtenerPuntosMapa() async {
    final puntosBase = await _cargarPuntosBase();
    final idsBase = puntosBase.map((punto) => punto.id).toList();

    final estadosBase = await _obtenerDocsPorIds('puntos_estado', idsBase);
    final ocultosBase = await _obtenerDocsPorIds('puntos_ocultos', idsBase);

    final puntosBaseCombinados = puntosBase
        .where((punto) => ocultosBase[punto.id]?['oculto'] != true)
        .map((punto) => _combinarPunto(punto, estadosBase[punto.id]))
        .toList();

    final puntosFirestore = await _db
        .collection('puntos')
        .where('esBase', isEqualTo: false)
        .where('oculto', isEqualTo: false)
        .where('aprobado', isEqualTo: true)
        .get();

    final puntosDinamicos = puntosFirestore.docs
        .map((doc) => Punto.fromFirestore(doc))
        .where((punto) => !punto.oculto)
        .toList();

    final idsDinamicos = puntosDinamicos.map((punto) => punto.id).toList();
    final estadosDinamicos = await _obtenerDocsPorIds(
      'puntos_estado',
      idsDinamicos,
    );

    return [
      ...puntosBaseCombinados,
      ...puntosDinamicos.map(
        (punto) => _combinarPunto(punto, estadosDinamicos[punto.id]),
      ),
    ];
  }

  Future<Punto> obtenerPuntoCombinado(Punto punto) async {
    if (punto.esBase) {
      final oculto = await _db.collection('puntos_ocultos').doc(punto.id).get();
      if (oculto.data()?['oculto'] == true) {
        return punto.copyWith(oculto: true);
      }
    }

    final estado = await _db.collection('puntos_estado').doc(punto.id).get();
    return _combinarPunto(punto, estado.data());
  }

  Future<void> crearPunto(Punto punto) async {
    await _db.collection('puntos').add(punto.toFirestore());
  }

  Future<void> reportarPuntoComunitario(Punto punto) async {
    final uid = await DeviceIdService.obtenerDeviceId();
    final limite = await _usuarioSuperoLimiteReportes(uid);
    if (limite) {
      throw LimiteReportesException();
    }

    final reporteRef = _db.collection('puntos_reportados').doc();
    final logRef = _db
        .collection('usuarios_reportes')
        .doc(uid)
        .collection('puntos_reportados')
        .doc(reporteRef.id);

    final data = {
      ...punto.toFirestore(),
      'estado': 'pendiente',
      'confianza': 'reciente',
      'fuente': 'comunidad',
      'direccionVerificada': false,
      'creadorUid': uid,
      'oculto': false,
      'esBase': false,
      'aprobado': false,
      'rechazado': false,
      'creadoEn': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.set(reporteRef, data);
    batch.set(logRef, {
      'puntoReportadoId': reporteRef.id,
      'creadoEn': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> registrarReporte(Reporte reporte) async {
    if (_esVotoDisponibilidad(reporte.tipoReporte)) {
      await _registrarVotoDisponibilidad(reporte);
      return;
    }

    final estadoRef = _db.collection('puntos_estado').doc(reporte.puntoId);
    final reporteRef = _db.collection('reportes').doc();

    await _db.runTransaction((transaction) async {
      transaction.set(reporteRef, reporte.toFirestore());

      if (reporte.tipoReporte == 'reportar_cambio') {
        transaction.set(estadoRef, {
          'confianza': 'pendiente',
          'requiereRevision': true,
          'ultimaRevisionSolicitada': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<List<Punto>> _cargarPuntosBase() async {
    final jsonString = await rootBundle.loadString(
      'assets/puntos_mexicali.json',
    );
    final data = jsonDecode(jsonString) as List<dynamic>;

    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return Punto.fromMap(map, id: map['id'] as String).copyWith(esBase: true);
    }).toList();
  }

  Future<Map<String, Map<String, dynamic>>> _obtenerDocsPorIds(
    String collection,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return {};

    final resultado = <String, Map<String, dynamic>>{};
    for (var i = 0; i < ids.length; i += 30) {
      final fin = i + 30 > ids.length ? ids.length : i + 30;
      final chunk = ids.sublist(i, fin);
      final snapshot = await _db
          .collection(collection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        resultado[doc.id] = doc.data();
      }
    }

    return resultado;
  }

  Punto _combinarPunto(Punto punto, Map<String, dynamic>? estado) {
    if (estado == null) {
      return punto.copyWith(
        estado: punto.estado == 'abierto' || punto.estado == 'cerrado'
            ? punto.estado
            : 'pendiente',
        confianza: punto.confianza == 'oficial' ? 'oficial' : 'pendiente',
      );
    }

    return punto.copyWith(
      nombre: estado['nombre'] ?? punto.nombre,
      tipo: estado['tipo'] ?? punto.tipo,
      direccion: estado['direccion'] ?? punto.direccion,
      telefono: estado['telefono'] ?? punto.telefono,
      lat: (estado['lat'] ?? punto.lat).toDouble(),
      lng: (estado['lng'] ?? punto.lng).toDouble(),
      horario: estado['horario'] ?? punto.horario,
      descripcion: estado['descripcion'] ?? punto.descripcion,
      estado: estado['estado'] ?? punto.estado,
      confianza: estado['confianza'] ?? punto.confianza,
      ultimaConfirmacion: estado['ultimaConfirmacion'] != null
          ? (estado['ultimaConfirmacion'] as Timestamp).toDate()
          : punto.ultimaConfirmacion,
      confirmaciones: estado['confirmaciones'] ?? punto.confirmaciones,
      votosAbiertoHoy: estado['votosAbiertoHoy'] ?? punto.votosAbiertoHoy,
      votosCerradoHoy: estado['votosCerradoHoy'] ?? punto.votosCerradoHoy,
      diaVotacion: estado['diaVotacion'] ?? punto.diaVotacion,
      fuente: estado['fuente'] ?? punto.fuente,
      direccionVerificada:
          estado['direccionVerificada'] ?? punto.direccionVerificada,
      oculto: estado['oculto'] ?? punto.oculto,
    );
  }

  Future<void> _registrarVotoDisponibilidad(Reporte reporte) async {
    final dia = _diaActual();
    final votoId = '${dia}_${reporte.deviceId}';
    final estadoRef = _db.collection('puntos_estado').doc(reporte.puntoId);
    final reporteRef = _db.collection('reportes').doc();
    final votoRef = estadoRef.collection('votos_diarios').doc(votoId);
    final resumenRef = estadoRef.collection('resumen_diario').doc(dia);

    await _db.runTransaction((transaction) async {
      final votoAnterior = await transaction.get(votoRef);
      final resumenActual = await transaction.get(resumenRef);

      final tipoAnterior = votoAnterior.data()?['tipoReporte'] as String?;
      final resumen = resumenActual.data() ?? <String, dynamic>{};
      var abiertos = resumen['abiertos'] ?? 0;
      var cerrados = resumen['cerrados'] ?? 0;

      if (tipoAnterior == 'confirmado_abierto') abiertos--;
      if (tipoAnterior == 'reportado_cerrado') cerrados--;

      if (reporte.tipoReporte == 'confirmado_abierto') abiertos++;
      if (reporte.tipoReporte == 'reportado_cerrado') cerrados++;

      abiertos = abiertos < 0 ? 0 : abiertos;
      cerrados = cerrados < 0 ? 0 : cerrados;

      final total = abiertos + cerrados;
      final estado = _estadoPorMayoria(abiertos, cerrados, total);
      final confianza = _confianzaPorMayoria(estado, total);

      transaction.set(reporteRef, reporte.toFirestore());
      transaction.set(votoRef, {
        'puntoId': reporte.puntoId,
        'deviceId': reporte.deviceId,
        'tipoReporte': reporte.tipoReporte,
        'dia': dia,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      transaction.set(resumenRef, {
        'dia': dia,
        'abiertos': abiertos,
        'cerrados': cerrados,
        'total': total,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      final cambiosEstado = <String, dynamic>{
        'estado': estado,
        'confianza': confianza,
        'confirmaciones': abiertos,
        'votosAbiertoHoy': abiertos,
        'votosCerradoHoy': cerrados,
        'diaVotacion': dia,
        'actualizadoEn': FieldValue.serverTimestamp(),
      };

      if (reporte.tipoReporte == 'confirmado_abierto') {
        cambiosEstado['ultimaConfirmacion'] = FieldValue.serverTimestamp();
      }

      transaction.set(estadoRef, cambiosEstado, SetOptions(merge: true));
    });
  }

  bool _esVotoDisponibilidad(String tipoReporte) {
    return tipoReporte == 'confirmado_abierto' ||
        tipoReporte == 'reportado_cerrado';
  }

  String _estadoPorMayoria(int abiertos, int cerrados, int total) {
    if (total < _votosMinimosParaCambiarEstado) return 'pendiente';
    if (abiertos > cerrados) return 'abierto';
    if (cerrados > abiertos) return 'cerrado';
    return 'pendiente';
  }

  String _confianzaPorMayoria(String estado, int total) {
    if (total < _votosMinimosParaCambiarEstado) return 'reciente';
    if (estado == 'abierto') return 'comunidad';
    if (estado == 'cerrado') return 'cerrado';
    return 'pendiente';
  }

  String _diaActual() {
    final ahora = DateTime.now();
    final year = ahora.year.toString().padLeft(4, '0');
    final month = ahora.month.toString().padLeft(2, '0');
    final day = ahora.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  Future<bool> _usuarioSuperoLimiteReportes(String uid) async {
    final desde = Timestamp.fromDate(
      DateTime.now().subtract(_ventanaReportesPunto),
    );
    final snapshot = await _db
        .collection('usuarios_reportes')
        .doc(uid)
        .collection('puntos_reportados')
        .where('creadoEn', isGreaterThanOrEqualTo: desde)
        .limit(_maxReportesPunto)
        .get();

    return snapshot.docs.length >= _maxReportesPunto;
  }
}

class LimiteReportesException implements Exception {
  @override
  String toString() {
    return 'Ya reportaste 2 puntos recientemente. Intenta de nuevo más tarde.';
  }
}
