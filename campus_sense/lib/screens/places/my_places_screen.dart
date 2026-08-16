import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/location_service.dart';
import '../../services/marker_service.dart';
import '../map/location_map_screen.dart';

class MyPlacesScreen extends StatefulWidget {
  const MyPlacesScreen({super.key});

  @override
  State<MyPlacesScreen> createState() =>
      _MyPlacesScreenState();
}

class _MyPlacesScreenState
    extends State<MyPlacesScreen> {
  StreamSubscription<Position>?
      _positionSubscription;

  Position? _posicionActual;

  bool _cargandoUbicacion = true;

  String? _errorUbicacion;

  @override
  void initState() {
    super.initState();

    _iniciarUbicacion();
  }

  // =========================
  // UBICACIÓN
  // =========================

  Future<void> _iniciarUbicacion() async {
    try {
      final posicion =
          await LocationService
              .obtenerUbicacionActual();

      if (!mounted) {
        return;
      }

      setState(() {
        _posicionActual = posicion;
        _cargandoUbicacion = false;
        _errorUbicacion = null;
      });

      _positionSubscription =
          LocationService
              .escucharUbicacion()
              .listen(
        (nuevaPosicion) {
          if (!mounted) {
            return;
          }

          setState(() {
            _posicionActual =
                nuevaPosicion;

            _errorUbicacion = null;
          });
        },
        onError: (error) {
          if (!mounted) {
            return;
          }

          setState(() {
            _errorUbicacion =
                error.toString();
          });
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargandoUbicacion = false;
        _errorUbicacion = e.toString();
      });
    }
  }

  Future<void> _actualizarUbicacion()
      async {
    try {
      setState(() {
        _cargandoUbicacion = true;
      });

      final posicion =
          await LocationService
              .obtenerUbicacionActual();

      if (!mounted) {
        return;
      }

      setState(() {
        _posicionActual = posicion;
        _cargandoUbicacion = false;
        _errorUbicacion = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargandoUbicacion = false;
        _errorUbicacion = e.toString();
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo actualizar la ubicación: $e',
          ),
        ),
      );
    }
  }

  // =========================
  // DATOS DEL MARCADOR
  // =========================

  String _nombreLugar(
    Map<String, dynamic> datos,
  ) {
    final nombre =
        datos['nombre']
                ?.toString()
                .trim() ??
            '';

    if (nombre.isEmpty) {
      return 'Lugar guardado';
    }

    return nombre;
  }

  String _descripcionLugar(
    Map<String, dynamic> datos,
  ) {
    return datos['descripcion']
            ?.toString()
            .trim() ??
        '';
  }

  // =========================
  // DISTANCIA
  // =========================

  double? _calcularDistancia({
    required double? latitud,
    required double? longitud,
  }) {
    final posicion =
        _posicionActual;

    if (posicion == null ||
        latitud == null ||
        longitud == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      posicion.latitude,
      posicion.longitude,
      latitud,
      longitud,
    );
  }

  String _formatearDistancia(
    double distancia,
  ) {
    if (distancia < 1000) {
      return 'A ${distancia.round()} m de ti';
    }

    final kilometros =
        distancia / 1000;

    if (kilometros < 10) {
      return 'A ${kilometros.toStringAsFixed(1)} km de ti';
    }

    return 'A ${kilometros.round()} km de ti';
  }

  // =========================
  // ABRIR LUGAR EN MAPA
  // =========================

  Future<void> _abrirLugar({
    required BuildContext context,
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        documento,
  }) async {
    final datos =
        documento.data();

    final latitud =
        (datos['latitud'] as num?)
            ?.toDouble();

    final longitud =
        (datos['longitud'] as num?)
            ?.toDouble();

    if (latitud == null ||
        longitud == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Este lugar no tiene coordenadas válidas.',
          ),
        ),
      );

      return;
    }

    final nombre =
        _nombreLugar(datos);

    try {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Abriendo $nombre...',
          ),
        ),
      );

      Position posicionActual;

      // Si ya tenemos una ubicación
      // reciente, la reutilizamos.
      if (_posicionActual != null) {
        posicionActual =
            _posicionActual!;
      } else {
        posicionActual =
            await LocationService
                .obtenerUbicacionActual();
      }

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              LocationMapScreen(
            initialPosition:
                posicionActual,
            targetMarkerId:
                documento.id,
            targetPosition:
                LatLng(
              latitud,
              longitud,
            ),
            targetName:
                nombre,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir el lugar: $e',
          ),
        ),
      );
    }
  }

  // =========================
  // DISPOSE
  // =========================

  @override
  void dispose() {
    _positionSubscription
        ?.cancel();

    super.dispose();
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis lugares',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                'Actualizar ubicación',
            onPressed:
                _cargandoUbicacion
                    ? null
                    : _actualizarUbicacion,
            icon:
                _cargandoUbicacion
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .my_location,
                      ),
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream:
            MarkerService
                .escucharMarcadores(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot
                  .connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 55,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    const Text(
                      'No se pudieron cargar tus lugares.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      '${snapshot.error}',
                      textAlign:
                          TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final lugares =
              snapshot.data?.docs ??
                  [];

          if (lugares.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  30,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      Icons
                          .bookmark_border,
                      size: 80,
                      color:
                          colorScheme.primary,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      'Aún no tienes lugares guardados',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      'Abre Mi mapa y mantén presionado un punto para guardar tu primer lugar.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 850,
                ),
                child:
                    ListView.builder(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  itemCount:
                      lugares.length +
                          1,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    // =================
                    // CABECERA
                    // =================

                    if (index == 0) {
                      return Column(
                        children: [
                          Container(
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom:
                                  12,
                            ),
                            padding:
                                const EdgeInsets
                                    .all(
                              20,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  colorScheme
                                      .primaryContainer,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width:
                                      54,
                                  height:
                                      54,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        colorScheme
                                            .primary,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      15,
                                    ),
                                  ),
                                  child:
                                      Icon(
                                    Icons
                                        .bookmark_outlined,
                                    color:
                                        colorScheme
                                            .onPrimary,
                                    size:
                                        30,
                                  ),
                                ),

                                const SizedBox(
                                  width:
                                      16,
                                ),

                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Text(
                                        'Lugares guardados',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              18,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(
                                        height:
                                            4,
                                      ),

                                      Text(
                                        '${lugares.length} ${lugares.length == 1 ? 'lugar' : 'lugares'}',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Estado del GPS.
                          if (_cargandoUbicacion)
                            Container(
                              width:
                                  double.infinity,
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom:
                                    16,
                              ),
                              padding:
                                  const EdgeInsets
                                      .all(
                                12,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    colorScheme
                                        .surfaceContainerHighest,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),
                              child:
                                  const Row(
                                children: [
                                  SizedBox(
                                    width:
                                        18,
                                    height:
                                        18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  ),

                                  SizedBox(
                                    width:
                                        10,
                                  ),

                                  Expanded(
                                    child:
                                        Text(
                                      'Calculando tu ubicación...',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_errorUbicacion !=
                              null)
                            Container(
                              width:
                                  double.infinity,
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom:
                                    16,
                              ),
                              padding:
                                  const EdgeInsets
                                      .all(
                                12,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    colorScheme
                                        .errorContainer,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),
                              child:
                                  Row(
                                children: [
                                  Icon(
                                    Icons
                                        .location_off_outlined,
                                    color:
                                        colorScheme
                                            .onErrorContainer,
                                  ),

                                  const SizedBox(
                                    width:
                                        10,
                                  ),

                                  const Expanded(
                                    child:
                                        Text(
                                      'No se pudo calcular la distancia. Puedes actualizar tu ubicación.',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(
                            height: 4,
                          ),
                        ],
                      );
                    }

                    // =================
                    // LUGAR
                    // =================

                    final documento =
                        lugares[
                            index - 1];

                    final datos =
                        documento.data();

                    final nombre =
                        _nombreLugar(
                      datos,
                    );

                    final descripcion =
                        _descripcionLugar(
                      datos,
                    );

                    final latitud =
                        (datos['latitud']
                                    as num?)
                                ?.toDouble();

                    final longitud =
                        (datos['longitud']
                                    as num?)
                                ?.toDouble();

                    final distancia =
                        _calcularDistancia(
                      latitud:
                          latitud,
                      longitud:
                          longitud,
                    );

                    return Card(
                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 14,
                      ),
                      child: InkWell(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                        onTap: () {
                          _abrirLugar(
                            context:
                                context,
                            documento:
                                documento,
                          );
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(
                            18,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height:
                                    52,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      colorScheme
                                          .primary
                                          .withValues(
                                    alpha:
                                        0.12,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    14,
                                  ),
                                ),
                                child:
                                    Icon(
                                  Icons
                                      .place,
                                  color:
                                      colorScheme
                                          .primary,
                                  size: 28,
                                ),
                              ),

                              const SizedBox(
                                width: 15,
                              ),

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      nombre,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            17,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    if (descripcion
                                        .isNotEmpty) ...[
                                      const SizedBox(
                                        height:
                                            5,
                                      ),

                                      Text(
                                        descripcion,
                                        maxLines:
                                            2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style:
                                            TextStyle(
                                          color:
                                              colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(
                                      height:
                                          8,
                                    ),

                                    // DISTANCIA
                                    if (distancia !=
                                        null)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .near_me_outlined,
                                            size:
                                                16,
                                            color:
                                                colorScheme.primary,
                                          ),

                                          const SizedBox(
                                            width:
                                                5,
                                          ),

                                          Text(
                                            _formatearDistancia(
                                              distancia,
                                            ),
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  13,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color:
                                                  colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      )
                                    else if (_cargandoUbicacion)
                                      Text(
                                        'Calculando distancia...',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              13,
                                          color:
                                              colorScheme.onSurfaceVariant,
                                        ),
                                      ),

                                    if (latitud !=
                                            null &&
                                        longitud !=
                                            null) ...[
                                      const SizedBox(
                                        height:
                                            7,
                                      ),

                                      Text(
                                        '${latitud.toStringAsFixed(5)}, ${longitud.toStringAsFixed(5)}',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              11,
                                          color:
                                              colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              const Icon(
                                Icons
                                    .chevron_right,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}