import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/location_service.dart';
import '../../services/marker_service.dart';
import 'create_marker_screen.dart';

class LocationMapScreen extends StatefulWidget {
  final Position initialPosition;

  // Si entramos desde "Mis lugares",
  // estos datos indican qué marcador mostrar.
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
  State<LocationMapScreen> createState() =>
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
  bool _guardandoHistorial = false;

  @override
  void initState() {
    super.initState();

    _position = widget.initialPosition;

    _iniciarSeguimiento();
  }

  // =========================
  // UBICACIÓN ACTUAL
  // =========================

  LatLng get _ubicacion {
    return LatLng(
      _position.latitude,
      _position.longitude,
    );
  }

  // Si venimos de Mis lugares,
  // el mapa abre centrado en ese lugar.
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
        _mapController.camera.zoom;

    final nuevoZoom =
        (zoomActual + 1)
            .clamp(
              3.0,
              19.0,
            )
            .toDouble();

    _mapController.move(
      _mapController.camera.center,
      nuevoZoom,
    );
  }

  void _alejar() {
    final zoomActual =
        _mapController.camera.zoom;

    final nuevoZoom =
        (zoomActual - 1)
            .clamp(
              3.0,
              19.0,
            )
            .toDouble();

    _mapController.move(
      _mapController.camera.center,
      nuevoZoom,
    );
  }

  // =========================
  // ACTUALIZAR UBICACIÓN
  // =========================

  Future<void> _actualizarUbicacion()
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
          _actualizando = false;
        });
      }
    }
  }

  // =========================
  // GUARDAR EN HISTORIAL
  // =========================

  Future<void>
      _guardarUbicacionHistorial()
      async {
    if (_guardandoHistorial) {
      return;
    }

    setState(() {
      _guardandoHistorial = true;
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
          _guardandoHistorial = false;
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
    await Navigator.of(context).push(
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

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              24,
              8,
              24,
              24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons
                          .location_on_outlined,
                      size: 30,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        nombre,
                        style:
                            const TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                if (descripcion
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 14,
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

                Text(
                  'Latitud: ${latitud.toStringAsFixed(6)}',
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Longitud: ${longitud.toStringAsFixed(6)}',
                ),

                const SizedBox(
                  height: 22,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  child:
                      OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(
                        sheetContext,
                      ).pop();

                      await _confirmarEliminar(
                        id: id,
                        nombre:
                            nombre,
                      );
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    label: const Text(
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
  // ELIMINAR MARCADOR
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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
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
                ).pop(false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
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
        _ultimaActualizacion.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minuto =
        _ultimaActualizacion.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final segundo =
        _ultimaActualizacion.second
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$hora:$minuto:$segundo';
  }

  // =========================
  // MARCADOR DEL USUARIO
  // =========================

  Marker _marcadorUsuario() {
    return Marker(
      point: _ubicacion,
      width: 110,
      height: 90,
      child: const Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.location_pin,
            size: 52,
            color: Colors.red,
          ),

          Text(
            'Tú estás aquí',
            style: TextStyle(
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

  Marker _marcadorTemporalDestino() {
    final punto =
        widget.targetPosition!;

    return Marker(
      point: punto,
      width: 120,
      height: 95,
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 55,
            color: Theme.of(context)
                .colorScheme
                .tertiary,
          ),

          Text(
            widget.targetName ??
                'Lugar guardado',
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
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
        (datos['latitud'] as num?)
                ?.toDouble() ??
            0;

    final longitud =
        (datos['longitud'] as num?)
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
          seleccionado ? 120 : 90,
      height:
          seleccionado ? 95 : 80,
      child: GestureDetector(
        behavior:
            HitTestBehavior.opaque,
        onTap: () {
          _mostrarMarcador(
            id: documento.id,
            nombre: nombre,
            descripcion:
                descripcion,
            latitud: latitud,
            longitud: longitud,
          );
        },
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              seleccionado
                  ? Icons.location_on
                  : Icons.place,
              size:
                  seleccionado ? 55 : 45,
              color: seleccionado
                  ? Theme.of(context)
                      .colorScheme
                      .tertiary
                  : Theme.of(context)
                      .colorScheme
                      .primary,
            ),

            Container(
              constraints:
                  BoxConstraints(
                maxWidth:
                    seleccionado
                        ? 120
                        : 90,
              ),
              child: Text(
                nombre,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize:
                      seleccionado
                          ? 12
                          : 11,
                  fontWeight:
                      seleccionado
                          ? FontWeight.bold
                          : FontWeight.w600,
                ),
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

    _mapController.dispose();

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
        widget.targetPosition != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          viendoLugar
              ? widget.targetName ??
                  'Lugar guardado'
              : 'Mi mapa',
          style: const TextStyle(
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
                  options: MapOptions(
                    initialCenter:
                        _centroInicial,
                    initialZoom:
                        viendoLugar
                            ? 18
                            : 17,
                    minZoom: 3,
                    maxZoom: 19,

                    // Mantén presionado
                    // para crear un lugar.
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
                          InteractiveFlag.drag |
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
                      stream: MarkerService
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

                        if (snapshot.hasData) {
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

                        // Si por alguna razón
                        // Firestore todavía no cargó,
                        // mostramos temporalmente
                        // el lugar seleccionado.
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
                      source: Text(
                        'OpenStreetMap contributors',
                      ),
                    ),
                  ],
                ),

                // =====================
                // MENSAJE SUPERIOR
                // =====================

                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 230,
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Theme.of(context)
                              .colorScheme
                              .surface,
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 5,
                          color:
                              Colors.black26,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          viendoLugar
                              ? Icons
                                  .bookmark_outlined
                              : Icons
                                  .touch_app_outlined,
                          size: 20,
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Flexible(
                          child: Text(
                            viendoLugar
                                ? 'Viendo: ${widget.targetName ?? 'Lugar guardado'}'
                                : 'Mantén presionado para guardar un lugar.',
                            style:
                                const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // =====================
                // ZOOM
                // =====================

                Positioned(
                  right: 16,
                  top: 16,
                  child: Card(
                    elevation: 4,
                    margin:
                        EdgeInsets.zero,
                    child: Column(
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
                          width: 32,
                          height: 1,
                          color: Colors
                              .grey
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

                // =====================
                // CENTRAR MAPA
                // =====================

                Positioned(
                  right: 16,
                  bottom: 18,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      // Si venimos de
                      // Mis lugares,
                      // aparece un botón
                      // para regresar al marcador.
                      if (viendoLugar) ...[
                        FloatingActionButton.small(
                          heroTag:
                              'centrarLugar',
                          onPressed:
                              _centrarEnLugar,
                          tooltip:
                              'Ver lugar guardado',
                          child:
                              const Icon(
                            Icons.place,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),
                      ],

                      FloatingActionButton.small(
                        heroTag:
                            'centrarMiUbicacion',
                        onPressed:
                            _centrarEnMi,
                        tooltip:
                            'Volver a mi ubicación',
                        child:
                            const Icon(
                          Icons.my_location,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // =========================
          // PANEL INFERIOR
          // =========================

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons
                          .location_on_outlined,
                    ),

                    SizedBox(
                      width: 8,
                    ),

                    Text(
                      'Tu ubicación',
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons.gps_fixed,
                      size: 17,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Expanded(
                      child: Text(
                        'Precisión aproximada: '
                        '${_position.accuracy.toStringAsFixed(1)} m',
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 17,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Text(
                      'Última actualización: '
                      '${_horaActualizacion()}',
                    ),
                  ],
                ),

                const SizedBox(
                  height: 16,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 48,
                  child:
                      FilledButton.icon(
                    onPressed:
                        _guardandoHistorial
                            ? null
                            : _guardarUbicacionHistorial,
                    icon:
                        _guardandoHistorial
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons.history,
                              ),
                    label: Text(
                      _guardandoHistorial
                          ? 'Guardando...'
                          : 'Guardar ubicación en historial',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 48,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _actualizando
                            ? null
                            : _actualizarUbicacion,
                    icon:
                        _actualizando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons.refresh,
                              ),
                    label: Text(
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