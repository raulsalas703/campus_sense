import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarkerService {
  static CollectionReference<Map<String, dynamic>>
      _coleccionMarcadores() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'No hay una sesión iniciada.',
      );
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('markers');
  }

  static Stream<
      QuerySnapshot<Map<String, dynamic>>>
      escucharMarcadores() {
    return _coleccionMarcadores()
        .orderBy(
          'creadoEn',
          descending: true,
        )
        .snapshots();
  }

  static Future<void> crearMarcador({
    required String nombre,
    required String descripcion,
    required double latitud,
    required double longitud,
  }) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'No hay una sesión iniciada.',
      );
    }

    final nombreLimpio = nombre.trim();
    final descripcionLimpia =
        descripcion.trim();

    if (nombreLimpio.isEmpty) {
      throw Exception(
        'El marcador necesita un nombre.',
      );
    }

    await _coleccionMarcadores().add({
      'uid': user.uid,
      'nombre': nombreLimpio,
      'descripcion': descripcionLimpia,
      'latitud': latitud,
      'longitud': longitud,
      'creadoEn':
          FieldValue.serverTimestamp(),
    });
  }

  static Future<void> eliminarMarcador(
    String marcadorId,
  ) async {
    await _coleccionMarcadores()
        .doc(marcadorId)
        .delete();
  }
}