import 'package:geolocator/geolocator.dart';

class UbicacionService {
  static Future<Position?> obtenerUbicacionActual() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      return null;
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return null;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  static String calcularDistanciaFormateada(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final metros = Geolocator.distanceBetween(lat1, lng1, lat2, lng2);

    if (metros < 1000) {
      return '${metros.round()} m';
    } else {
      final km = metros / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
}
