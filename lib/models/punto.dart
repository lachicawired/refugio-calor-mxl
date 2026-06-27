import 'package:cloud_firestore/cloud_firestore.dart';

class Punto {
  final String id;
  final String nombre;
  final String tipo;
  final String direccion;
  final String telefono;
  final double lat;
  final double lng;
  final String horario;
  final String descripcion;
  final String estado;
  final String confianza;
  final DateTime? ultimaConfirmacion;
  final int confirmaciones;
  final int votosAbiertoHoy;
  final int votosCerradoHoy;
  final String diaVotacion;
  final String fuente;
  final bool direccionVerificada;
  final bool oculto;
  final bool esBase;
  final bool aprobado;
  final bool verificadoOficialmente;

  Punto({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.direccion,
    required this.telefono,
    required this.lat,
    required this.lng,
    required this.horario,
    required this.descripcion,
    required this.estado,
    required this.confianza,
    required this.ultimaConfirmacion,
    required this.confirmaciones,
    required this.votosAbiertoHoy,
    required this.votosCerradoHoy,
    required this.diaVotacion,
    required this.fuente,
    required this.direccionVerificada,
    this.oculto = false,
    this.esBase = false,
    this.aprobado = false,
    this.verificadoOficialmente = false,
  });

  factory Punto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Punto.fromMap(data, id: doc.id);
  }

  factory Punto.fromMap(Map<String, dynamic> data, {required String id}) {
    return Punto(
      id: id,
      nombre: data['nombre'] ?? '',
      tipo: data['tipo'] ?? 'hidratacion',
      direccion: data['direccion'] ?? '',
      telefono: data['telefono'] ?? '',
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      horario: data['horario'] ?? '',
      descripcion: data['descripcion'] ?? '',
      estado: data['estado'] ?? 'sin_confirmar',
      confianza: data['confianza'] ?? _confianzaDesdeEstado(data['estado']),
      ultimaConfirmacion: data['ultimaConfirmacion'] != null
          ? (data['ultimaConfirmacion'] as Timestamp).toDate()
          : null,
      confirmaciones: data['confirmaciones'] ?? 0,
      votosAbiertoHoy: data['votosAbiertoHoy'] ?? 0,
      votosCerradoHoy: data['votosCerradoHoy'] ?? 0,
      diaVotacion: data['diaVotacion'] ?? '',
      fuente: data['fuente'] ?? 'manual',
      direccionVerificada: data['direccionVerificada'] ?? false,
      oculto: data['oculto'] ?? false,
      esBase: data['esBase'] ?? false,
      aprobado: data['aprobado'] ?? false,
      verificadoOficialmente:
          data['verificadoOficialmente'] == true ||
          data['confianza'] == 'verificado_oficialmente' ||
          data['confianza'] == 'oficial',
    );
  }

  static String _confianzaDesdeEstado(dynamic estado) {
    if (estado == 'abierto') return 'comunidad';
    if (estado == 'cerrado') return 'cerrado';
    return 'pendiente';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'tipo': tipo,
      'direccion': direccion,
      'telefono': telefono,
      'lat': lat,
      'lng': lng,
      'horario': horario,
      'descripcion': descripcion,
      'estado': estado,
      'confianza': confianza,
      'ultimaConfirmacion': ultimaConfirmacion,
      'confirmaciones': confirmaciones,
      'votosAbiertoHoy': votosAbiertoHoy,
      'votosCerradoHoy': votosCerradoHoy,
      'diaVotacion': diaVotacion,
      'fuente': fuente,
      'direccionVerificada': direccionVerificada,
      'oculto': oculto,
      'esBase': esBase,
      'aprobado': aprobado,
      'verificadoOficialmente': verificadoOficialmente,
    };
  }

  Punto copyWith({
    String? id,
    String? nombre,
    String? tipo,
    String? direccion,
    String? telefono,
    double? lat,
    double? lng,
    String? horario,
    String? descripcion,
    String? estado,
    String? confianza,
    DateTime? ultimaConfirmacion,
    int? confirmaciones,
    int? votosAbiertoHoy,
    int? votosCerradoHoy,
    String? diaVotacion,
    String? fuente,
    bool? direccionVerificada,
    bool? oculto,
    bool? esBase,
    bool? aprobado,
    bool? verificadoOficialmente,
  }) {
    return Punto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      horario: horario ?? this.horario,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      confianza: confianza ?? this.confianza,
      ultimaConfirmacion: ultimaConfirmacion ?? this.ultimaConfirmacion,
      confirmaciones: confirmaciones ?? this.confirmaciones,
      votosAbiertoHoy: votosAbiertoHoy ?? this.votosAbiertoHoy,
      votosCerradoHoy: votosCerradoHoy ?? this.votosCerradoHoy,
      diaVotacion: diaVotacion ?? this.diaVotacion,
      fuente: fuente ?? this.fuente,
      direccionVerificada: direccionVerificada ?? this.direccionVerificada,
      oculto: oculto ?? this.oculto,
      esBase: esBase ?? this.esBase,
      aprobado: aprobado ?? this.aprobado,
      verificadoOficialmente:
          verificadoOficialmente ?? this.verificadoOficialmente,
    );
  }
}
