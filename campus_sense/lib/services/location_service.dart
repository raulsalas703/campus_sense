import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<void> _verificarPermisos() async {
    final servicioActivo =
        await Geolocator.isLocationServiceEnabled();

    if (!servicioActivo) {
      throw Exception(
        'Los servicios de ubicación están desactivados.',
      );
    }

    LocationPermission permiso =
        await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied) {
      throw Exception(
        'No se concedió permiso para acceder a la ubicación.',
      );
    }

    if (permiso == LocationPermission.deniedForever) {
      throw Exception(
        'El permiso de ubicación fue bloqueado permanentemente.',
      );
    }
  }

  static Future<Position> obtenerUbicacionActual() async {
    await _verificarPermisos();

    const configuracion = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    return Geolocator.getCurrentPosition(
      locationSettings: configuracion,
    );
  }

  static Future<Position> guardarUbicacionActual() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No hay una sesión iniciada.');
    }

    final posicion = await obtenerUbicacionActual();

    await guardarPosicion(posicion);

    return posicion;
  }

  static Future<void> guardarPosicion(
    Position posicion,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No hay una sesión iniciada.');
    }

    await FirebaseFirestore.instance
        .collection('locations')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'latitud': posicion.latitude,
      'longitud': posicion.longitude,
      'precision': posicion.accuracy,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  static Stream<Position> escucharUbicacion() {
    const configuracion = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    return Geolocator.getPositionStream(
      locationSettings: configuracion,
    );
  }
}