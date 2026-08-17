import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/location_service.dart';
import '../../services/marker_service.dart';
import 'create_marker_screen.dart';

class LocationMapScreen
    extends StatefulWidget {
  final Position initialPosition;

  final String? targetMarkerId;
  final LatLng? targetPosition;
  final String? targetName;

  const LocationMapScreen({
    super.key,
    required this.initialPosition,
    this.targetMarkerId,
    this.targetPosition,
    this.targetName,
  });

  @override
  State<LocationMapScreen>
      createState() =>
          _LocationMapScreenState();
}

class _LocationMapScreenState
    extends State<LocationMapScreen> {
  final MapController _mapController =
      MapController();

  StreamSubscription<Position>?
      _positionSubscription;

  late Position _position;

  DateTime _ultimaActualizacion =
      DateTime.now();

  bool _actualizando = false;
  bool _guardandoHistorial =
      false;

  @override
  void initState() {
    super.initState();

    _position =
        widget.initialPosition;

    _iniciarSeguimiento();
  }

  // =========================
  // UBICACIÓN
  // =========================

  LatLng get _ubicacion {
    return LatLng(
      _position.latitude,
      _position.longitude,
    );
  }

  LatLng get _centroInicial {
    return widget.targetPosition ??
        _ubicacion;
  }

  void _iniciarSeguimiento() {
    _positionSubscription =
        LocationService
            .escucharUbicacion()
            .listen(
      (position) {
        if (!mounted) {
          return;
        }

        setState(() {
          _position = position;

          _ultimaActualizacion =
              DateTime.now();
        });
      },
      onError: (error) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Error actualizando ubicación: $error',
            ),
          ),
        );
      },
    );
  }

  // =========================
  // DISTANCIA
  // =========================

  double _distanciaA({
    required double latitud,
    required double longitud,
  }) {
    return Geolocator.distanceBetween(
      _position.latitude,
      _position.longitude,
      latitud,
      longitud,
    );
  }

  String _formatearDistancia(
    double distancia,
  ) {
    if (distancia < 1000) {
      return '${distancia.round()} m';
    }

    final km =
        distancia / 1000;

    if (km < 10) {
      return '${km.toStringAsFixed(1)} km';
    }

    return '${km.round()} km';
  }

  String? get _distanciaDestino {
    final destino =
        widget.targetPosition;

    if (destino == null) {
      return null;
    }

    return _formatearDistancia(
      _distanciaA(
        latitud:
            destino.latitude,
        longitud:
            destino.longitude,
      ),
    );
  }

  // =========================
  // NAVEGACIÓN EXTERNA
  // =========================

  Future<void> _comoLlegar({
    required double latitud,
    required double longitud,
  }) async {
    final origen =
        '${_position.latitude},${_position.longitude}';

    final destino =
        '$latitud,$longitud';

    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'origin': origen,
        'destination':
            destino,
        'dir_action':
            'navigate',
      },
    );

    try {
      final abierto =
          await launchUrl(
        uri,
        mode:
            LaunchMode
                .externalApplication,
      );

      if (!abierto &&
          mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir la navegación.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir la navegación: $e',
          ),
        ),
      );
    }
  }

  Future<void>
      _navegarAlDestino()
      async {
    final destino =
        widget.targetPosition;

    if (destino == null) {
      return;
    }

    await _comoLlegar(
      latitud:
          destino.latitude,
      longitud:
          destino.longitude,
    );
  }

  // =========================
  // CONTROLES DEL MAPA
  // =========================

  void _centrarEnMi() {
    _mapController.move(
      _ubicacion,
      17,
    );
  }

  void _centrarEnLugar() {
    final lugar =
        widget.targetPosition;

    if (lugar == null) {
      return;
    }

    _mapController.move(
      lugar,
      18,
    );
  }

  void _acercar() {
    final zoomActual =
        _mapController
            .camera.zoom;

    final nuevoZoom =
        (zoomActual + 1)
            .clamp(
              3.0,
              19.0,
            )
            .toDouble();

    _mapController.move(
      _mapController
          .camera.center,
      nuevoZoom,
    );
  }

  void _alejar() {
    final zoomActual =
        _mapController
            .camera.zoom;

    final nuevoZoom =
        (zoomActual - 1)
            .clamp(
              3.0,
              19.0,
            )
            .toDouble();

    _mapController.move(
      _mapController
          .camera.center,
      nuevoZoom,
    );
  }

  // =========================
  // ACTUALIZAR UBICACIÓN
  // =========================

  Future<void>
      _actualizarUbicacion()
      async {
    if (_actualizando) {
      return;
    }

    setState(() {
      _actualizando = true;
    });

    try {
      final nuevaPosicion =
          await LocationService
              .guardarUbicacionActual();

      if (!mounted) {
        return;
      }

      setState(() {
        _position =
            nuevaPosicion;

        _ultimaActualizacion =
            DateTime.now();
      });

      _centrarEnMi();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Ubicación actualizada.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo actualizar la ubicación: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actualizando =
              false;
        });
      }
    }
  }

  // =========================
  // HISTORIAL
  // =========================

  Future<void>
      _guardarUbicacionHistorial()
      async {
    if (_guardandoHistorial) {
      return;
    }

    setState(() {
      _guardandoHistorial =
          true;
    });

    try {
      await LocationService
          .guardarPosicion(
        _position,
      );

      await LocationService
          .guardarEnHistorial(
        _position,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Ubicación guardada en el historial.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la ubicación: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardandoHistorial =
              false;
        });
      }
    }
  }

  // =========================
  // CREAR MARCADOR
  // =========================

  Future<void> _crearMarcador(
    LatLng punto,
  ) async {
    await Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) =>
            CreateMarkerScreen(
          position: punto,
        ),
      ),
    );
  }

  // =========================
  // VER MARCADOR
  // =========================

  Future<void> _mostrarMarcador({
    required String id,
    required String nombre,
    required String descripcion,
    required double latitud,
    required double longitud,
  }) async {
    if (!mounted) {
      return;
    }

    final distancia =
        _distanciaA(
      latitud: latitud,
      longitud:
          longitud,
    );

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (sheetContext) {
        final colorScheme =
            Theme.of(
          sheetContext,
        ).colorScheme;

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              24,
              8,
              24,
              24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize
                      .min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration:
                          BoxDecoration(
                        color:
                            colorScheme
                                .primaryContainer,
                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                      ),
                      child: Icon(
                        Icons
                            .location_on,
                        color:
                            colorScheme
                                .primary,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            nombre,
                            style:
                                const TextStyle(
                              fontSize:
                                  20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Row(
                            children: [
                              Icon(
                                Icons
                                    .near_me_outlined,
                                size: 16,
                                color:
                                    colorScheme
                                        .primary,
                              ),

                              const SizedBox(
                                width: 5,
                              ),

                              Text(
                                '${_formatearDistancia(distancia)} de ti',
                                style:
                                    TextStyle(
                                  color:
                                      colorScheme
                                          .primary,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (descripcion
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 18,
                  ),

                  Text(
                    descripcion,
                    style:
                        const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 18,
                ),

                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets
                          .all(
                    14,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        colorScheme
                            .surfaceContainerHighest,
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Latitud: ${latitud.toStringAsFixed(6)}',
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        'Longitud: ${longitud.toStringAsFixed(6)}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 50,
                  child:
                      FilledButton.icon(
                    onPressed: () {
                      Navigator.of(
                        sheetContext,
                      ).pop();

                      _comoLlegar(
                        latitud:
                            latitud,
                        longitud:
                            longitud,
                      );
                    },
                    icon:
                        const Icon(
                      Icons
                          .directions_outlined,
                    ),
                    label:
                        const Text(
                      'Cómo llegar',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        () async {
                      Navigator.of(
                        sheetContext,
                      ).pop();

                      await _confirmarEliminar(
                        id: id,
                        nombre:
                            nombre,
                      );
                    },
                    icon:
                        const Icon(
                      Icons
                          .delete_outline,
                    ),
                    label:
                        const Text(
                      'Eliminar marcador',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================
  // ELIMINAR
  // =========================

  Future<void> _confirmarEliminar({
    required String id,
    required String nombre,
  }) async {
    if (!mounted) {
      return;
    }

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'Eliminar marcador',
          ),
          content: Text(
            '¿Quieres eliminar "$nombre"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  false,
                );
              },
              child:
                  const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  true,
                );
              },
              child:
                  const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await MarkerService
          .eliminarMarcador(
        id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Marcador eliminado.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar el marcador: $e',
          ),
        ),
      );
    }
  }

  // =========================
  // HORA
  // =========================

  String _horaActualizacion() {
    final hora =
        _ultimaActualizacion
            .hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minuto =
        _ultimaActualizacion
            .minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final segundo =
        _ultimaActualizacion
            .second
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$hora:$minuto:$segundo';
  }

  // =========================
  // MARCADOR USUARIO
  // =========================

  Marker _marcadorUsuario() {
    return Marker(
      point:
          _ubicacion,
      width: 110,
      height: 90,
      child:
          const Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons
                .location_pin,
            size: 52,
            color:
                Colors.red,
          ),
          Text(
            'Tú estás aquí',
            style:
                TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // MARCADOR TEMPORAL
  // =========================

  Marker
      _marcadorTemporalDestino() {
    final punto =
        widget.targetPosition!;

    return Marker(
      point: punto,
      width: 125,
      height: 95,
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons
                .location_on,
            size: 55,
            color:
                Theme.of(context)
                    .colorScheme
                    .tertiary,
          ),
          Text(
            widget.targetName ??
                'Lugar guardado',
            maxLines: 1,
            overflow:
                TextOverflow
                    .ellipsis,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // MARCADOR FIRESTORE
  // =========================

  Marker _crearMarcadorGuardado(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        documento,
  ) {
    final datos =
        documento.data();

    final nombre =
        datos['nombre']
                ?.toString()
                .trim() ??
            'Marcador';

    final descripcion =
        datos['descripcion']
                ?.toString()
                .trim() ??
            '';

    final latitud =
        (datos['latitud']
                    as num?)
                ?.toDouble() ??
            0;

    final longitud =
        (datos['longitud']
                    as num?)
                ?.toDouble() ??
            0;

    final seleccionado =
        documento.id ==
            widget.targetMarkerId;

    return Marker(
      point: LatLng(
        latitud,
        longitud,
      ),
      width:
          seleccionado
              ? 125
              : 95,
      height:
          seleccionado
              ? 95
              : 82,
      child:
          GestureDetector(
        behavior:
            HitTestBehavior
                .opaque,
        onTap: () {
          _mostrarMarcador(
            id:
                documento.id,
            nombre:
                nombre,
            descripcion:
                descripcion,
            latitud:
                latitud,
            longitud:
                longitud,
          );
        },
        child: Column(
          mainAxisSize:
              MainAxisSize
                  .min,
          children: [
            Icon(
              seleccionado
                  ? Icons
                      .location_on
                  : Icons.place,
              size:
                  seleccionado
                      ? 55
                      : 45,
              color: seleccionado
                  ? Theme.of(
                      context,
                    )
                      .colorScheme
                      .tertiary
                  : Theme.of(
                      context,
                    )
                      .colorScheme
                      .primary,
            ),
            Text(
              nombre,
              maxLines:
                  1,
              overflow:
                  TextOverflow
                      .ellipsis,
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize:
                    seleccionado
                        ? 12
                        : 11,
                fontWeight:
                    seleccionado
                        ? FontWeight
                            .bold
                        : FontWeight
                            .w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription
        ?.cancel();

    _mapController
        .dispose();

    super.dispose();
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(
    BuildContext context,
  ) {
    final viendoLugar =
        widget.targetPosition !=
            null;

    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          viendoLugar
              ? widget.targetName ??
                  'Lugar guardado'
              : 'Mi mapa',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController:
                      _mapController,
                  options:
                      MapOptions(
                    initialCenter:
                        _centroInicial,
                    initialZoom:
                        viendoLugar
                            ? 18
                            : 17,
                    minZoom:
                        3,
                    maxZoom:
                        19,
                    onLongPress: (
                      _,
                      punto,
                    ) {
                      _crearMarcador(
                        punto,
                      );
                    },
                    interactionOptions:
                        const InteractionOptions(
                      flags:
                          InteractiveFlag
                                  .drag |
                              InteractiveFlag
                                  .flingAnimation |
                              InteractiveFlag
                                  .pinchMove |
                              InteractiveFlag
                                  .pinchZoom |
                              InteractiveFlag
                                  .doubleTapZoom |
                              InteractiveFlag
                                  .doubleTapDragZoom |
                              InteractiveFlag
                                  .scrollWheelZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.campus_sense',
                    ),

                    StreamBuilder<
                        QuerySnapshot<
                            Map<String,
                                dynamic>>>(
                      stream:
                          MarkerService
                              .escucharMarcadores(),
                      builder: (
                        context,
                        snapshot,
                      ) {
                        final marcadores =
                            <Marker>[
                          _marcadorUsuario(),
                        ];

                        bool encontroDestino =
                            false;

                        if (snapshot
                            .hasData) {
                          for (final documento
                              in snapshot
                                  .data!
                                  .docs) {
                            if (documento.id ==
                                widget
                                    .targetMarkerId) {
                              encontroDestino =
                                  true;
                            }

                            marcadores.add(
                              _crearMarcadorGuardado(
                                documento,
                              ),
                            );
                          }
                        }

                        if (viendoLugar &&
                            !encontroDestino) {
                          marcadores.add(
                            _marcadorTemporalDestino(),
                          );
                        }

                        return MarkerLayer(
                          markers:
                              marcadores,
                        );
                      },
                    ),

                    const SimpleAttributionWidget(
                      source:
                          Text(
                        'OpenStreetMap contributors',
                      ),
                    ),
                  ],
                ),

                // TEXTO SUPERIOR
                Positioned(
                  left: 16,
                  top: 16,
                  child:
                      Container(
                    constraints:
                        const BoxConstraints(
                      maxWidth:
                          235,
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal:
                          12,
                      vertical:
                          9,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          colorScheme
                              .surface,
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                      boxShadow:
                          const [
                        BoxShadow(
                          blurRadius:
                              5,
                          color:
                              Colors.black26,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize
                              .min,
                      children: [
                        Icon(
                          viendoLugar
                              ? Icons
                                  .directions_outlined
                              : Icons
                                  .touch_app_outlined,
                          size:
                              20,
                        ),
                        const SizedBox(
                          width:
                              8,
                        ),
                        Flexible(
                          child:
                              Text(
                            viendoLugar
                                ? '${widget.targetName ?? 'Lugar'} • ${_distanciaDestino ?? ''}'
                                : 'Mantén presionado para guardar un lugar.',
                            style:
                                const TextStyle(
                              fontSize:
                                  12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ZOOM
                Positioned(
                  right: 16,
                  top: 16,
                  child:
                      Card(
                    elevation:
                        4,
                    margin:
                        EdgeInsets.zero,
                    child:
                        Column(
                      children: [
                        IconButton(
                          tooltip:
                              'Acercar',
                          onPressed:
                              _acercar,
                          icon:
                              const Icon(
                            Icons.add,
                          ),
                        ),
                        Container(
                          width:
                              32,
                          height:
                              1,
                          color:
                              Colors.grey
                                  .shade300,
                        ),
                        IconButton(
                          tooltip:
                              'Alejar',
                          onPressed:
                              _alejar,
                          icon:
                              const Icon(
                            Icons.remove,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // CENTRAR
                Positioned(
                  right: 16,
                  bottom: 18,
                  child:
                      Column(
                    mainAxisSize:
                        MainAxisSize
                            .min,
                    children: [
                      if (viendoLugar) ...[
                        FloatingActionButton
                            .small(
                          heroTag:
                              'centrarLugar',
                          onPressed:
                              _centrarEnLugar,
                          tooltip:
                              'Ver lugar',
                          child:
                              const Icon(
                            Icons.place,
                          ),
                        ),

                        const SizedBox(
                          height:
                              10,
                        ),
                      ],

                      FloatingActionButton
                          .small(
                        heroTag:
                            'centrarUsuario',
                        onPressed:
                            _centrarEnMi,
                        tooltip:
                            'Mi ubicación',
                        child:
                            const Icon(
                          Icons
                              .my_location,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // PANEL INFERIOR
          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets
                    .fromLTRB(
              20,
              16,
              20,
              20,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                if (viendoLugar) ...[
                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .all(
                      15,
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
                        Icon(
                          Icons
                              .directions_outlined,
                          color:
                              colorScheme
                                  .primary,
                          size:
                              28,
                        ),

                        const SizedBox(
                          width:
                              12,
                        ),

                        Expanded(
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                widget.targetName ??
                                    'Lugar guardado',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height:
                                    3,
                              ),

                              Text(
                                '${_distanciaDestino ?? '--'} de tu ubicación',
                              ),
                            ],
                          ),
                        ),

                        FilledButton(
                          onPressed:
                              _navegarAlDestino,
                          child:
                              const Text(
                            'Ir',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height:
                        14,
                  ),
                ],

                const Row(
                  children: [
                    Icon(
                      Icons
                          .location_on_outlined,
                    ),
                    SizedBox(
                      width:
                          8,
                    ),
                    Text(
                      'Tu ubicación',
                      style:
                          TextStyle(
                        fontSize:
                            18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      10,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .gps_fixed,
                      size:
                          17,
                    ),
                    const SizedBox(
                      width:
                          7,
                    ),
                    Expanded(
                      child:
                          Text(
                        'Precisión aproximada: ${_position.accuracy.toStringAsFixed(1)} m',
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      7,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .access_time,
                      size:
                          17,
                    ),
                    const SizedBox(
                      width:
                          7,
                    ),
                    Text(
                      'Actualizado: ${_horaActualizacion()}',
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      15,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height:
                      48,
                  child:
                      FilledButton.icon(
                    onPressed:
                        _guardandoHistorial
                            ? null
                            : _guardarUbicacionHistorial,
                    icon:
                        _guardandoHistorial
                            ? const SizedBox(
                                width:
                                    18,
                                height:
                                    18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons.history,
                              ),
                    label:
                        Text(
                      _guardandoHistorial
                          ? 'Guardando...'
                          : 'Guardar ubicación en historial',
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                      10,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height:
                      48,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _actualizando
                            ? null
                            : _actualizarUbicacion,
                    icon:
                        _actualizando
                            ? const SizedBox(
                                width:
                                    18,
                                height:
                                    18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons.refresh,
                              ),
                    label:
                        Text(
                      _actualizando
                          ? 'Actualizando...'
                          : 'Actualizar ubicación',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}