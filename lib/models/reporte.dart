import 'package:cloud_firestore/cloud_firestore.dart';

class Reporte {
  final String id;
  final String puntoId;
  final String tipoReporte; // "confirmado_abierto" | "reportado_cerrado" | "reportar_cambio"
  final DateTime creadoEn;
  final String deviceId;
  final String comentario;

  Reporte({
    required this.id,
    required this.puntoId,
    required this.tipoReporte,
    required this.creadoEn,
    required this.deviceId,
    this.comentario = '',
  });

  factory Reporte.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Reporte(
      id: doc.id,
      puntoId: data['puntoId'] ?? '',
      tipoReporte: data['tipoReporte'] ?? '',
      creadoEn: data['creadoEn'] != null
          ? (data['creadoEn'] as Timestamp).toDate()
          : DateTime.now(),
      deviceId: data['deviceId'] ?? '',
      comentario: data['comentario'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'puntoId': puntoId,
      'tipoReporte': tipoReporte,
      'creadoEn': FieldValue.serverTimestamp(),
      'deviceId': deviceId,
      'comentario': comentario,
    };
  }
}
