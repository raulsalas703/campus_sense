import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/location_service.dart';

class LocationMapScreen extends StatefulWidget {
  final Position initialPosition;

  const LocationMapScreen({
    super.key,
    required this.initialPosition,
  });

  @override
  State<LocationMapScreen> createState() =>
      _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSubscription;

  late Position _position;

  DateTime _ultimaActualizacion = DateTime.now();

  bool _actualizando = false;

  @override
  void initState() {
    super.initState();

    _position = widget.initialPosition;

    _iniciarSeguimiento();
  }

  void _iniciarSeguimiento() {
    _positionSubscription =
        LocationService.escucharUbicacion().listen(
      (position) {
        if (!mounted) return;

        setState(() {
          _position = position;
          _ultimaActualizacion = DateTime.now();
        });
      },
      onError: (error) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error actualizando ubicación: $error',
            ),
          ),
        );
      },
    );
  }

  LatLng get _ubicacion {
    return LatLng(
      _position.latitude,
      _position.longitude,
    );
  }

  void _centrarMapa() {
    _mapController.move(
      _ubicacion,
      17,
    );
  }

  void _acercar() {
    final zoomActual = _mapController.camera.zoom;

    final nuevoZoom =
        (zoomActual + 1).clamp(3.0, 19.0).toDouble();

    _mapController.move(
      _mapController.camera.center,
      nuevoZoom,
    );
  }

  void _alejar() {
    final zoomActual = _mapController.camera.zoom;

    final nuevoZoom =
        (zoomActual - 1).clamp(3.0, 19.0).toDouble();

    _mapController.move(
      _mapController.camera.center,
      nuevoZoom,
    );
  }

  Future<void> _actualizarUbicacion() async {
    if (_actualizando) return;

    setState(() {
      _actualizando = true;
    });

    try {
      final nuevaPosicion =
          await LocationService.guardarUbicacionActual();

      if (!mounted) return;

      setState(() {
        _position = nuevaPosicion;
        _ultimaActualizacion = DateTime.now();
      });

      _centrarMapa();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ubicación actualizada.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
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

  String _horaActualizacion() {
    final hora = _ultimaActualizacion.hour
        .toString()
        .padLeft(2, '0');

    final minuto = _ultimaActualizacion.minute
        .toString()
        .padLeft(2, '0');

    final segundo = _ultimaActualizacion.second
        .toString()
        .padLeft(2, '0');

    return '$hora:$minuto:$segundo';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi ubicación',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _ubicacion,
                    initialZoom: 17,

                    // Límites de zoom.
                    minZoom: 3,
                    maxZoom: 19,

                    // Interacción tipo Google Maps.
                    interactionOptions:
                        const InteractionOptions(
                      flags: InteractiveFlag.drag |
                          InteractiveFlag.flingAnimation |
                          InteractiveFlag.pinchMove |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.doubleTapDragZoom |
                          InteractiveFlag.scrollWheelZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.campus_sense',
                    ),

                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _ubicacion,
                          width: 110,
                          height: 90,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SimpleAttributionWidget(
                      source: Text(
                        'OpenStreetMap contributors',
                      ),
                    ),
                  ],
                ),

                // CONTROLES DE ZOOM
                Positioned(
                  right: 16,
                  top: 16,
                  child: Card(
                    elevation: 4,
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        IconButton(
                          tooltip: 'Acercar',
                          onPressed: _acercar,
                          icon: const Icon(
                            Icons.add,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                        IconButton(
                          tooltip: 'Alejar',
                          onPressed: _alejar,
                          icon: const Icon(
                            Icons.remove,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // VOLVER A MI UBICACIÓN
                Positioned(
                  right: 16,
                  bottom: 18,
                  child: FloatingActionButton.small(
                    heroTag: 'centrarMapa',
                    onPressed: _centrarMapa,
                    tooltip: 'Volver a mi ubicación',
                    child: const Icon(
                      Icons.my_location,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
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
                      Icons.location_on_outlined,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      'Ubicación actual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                    Text(
                      'Precisión aproximada: '
                      '${_position.accuracy.toStringAsFixed(1)} m',
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
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _actualizando
                        ? null
                        : _actualizarUbicacion,
                    icon: _actualizando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
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