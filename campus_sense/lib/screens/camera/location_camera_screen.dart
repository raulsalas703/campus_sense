import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/location_service.dart';

class LocationCameraScreen extends StatefulWidget {
  const LocationCameraScreen({super.key});

  @override
  State<LocationCameraScreen> createState() =>
      _LocationCameraScreenState();
}

class _LocationCameraScreenState
    extends State<LocationCameraScreen> {
  CameraController? _cameraController;
  StreamSubscription<Position>? _positionSubscription;

  Position? _position;

  bool _loadingCamera = true;
  bool _actualizandoUbicacion = false;

  String? _errorCamera;

  DateTime _ultimaActualizacion = DateTime.now();

  @override
  void initState() {
    super.initState();

    _inicializar();
  }

  Future<void> _inicializar() async {
    await Future.wait([
      _inicializarCamara(),
      _inicializarUbicacion(),
    ]);
  }

  Future<void> _inicializarCamara() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) return;

        setState(() {
          _errorCamera = 'No se encontró ninguna cámara.';
          _loadingCamera = false;
        });

        return;
      }

      CameraController? controllerFuncionando;
      String? ultimoError;

      for (final camera in cameras) {
        final controller = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        try {
          await controller.initialize();

          if (controller.value.isInitialized) {
            controllerFuncionando = controller;
            break;
          }
        } on CameraException catch (e) {
          ultimoError =
              '${e.code}: ${e.description ?? 'Error desconocido'}';

          await controller.dispose();
        } catch (e) {
          ultimoError = e.toString();

          await controller.dispose();
        }
      }

      if (!mounted) {
        await controllerFuncionando?.dispose();
        return;
      }

      if (controllerFuncionando == null) {
        setState(() {
          _errorCamera =
              'No se pudo abrir ninguna cámara.\n\n'
              '${ultimoError ?? 'Revisa los permisos de cámara.'}\n\n'
              'Asegúrate de que ninguna otra aplicación esté usando la cámara.';

          _loadingCamera = false;
        });

        return;
      }

      setState(() {
        _cameraController = controllerFuncionando;
        _errorCamera = null;
        _loadingCamera = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorCamera =
            'No se pudo abrir la cámara.\n\n'
            '${e.description ?? e.code}';

        _loadingCamera = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorCamera =
            'No se pudo acceder a la cámara.\n\n$e';

        _loadingCamera = false;
      });
    }
  }

  Future<void> _inicializarUbicacion() async {
    try {
      final position =
          await LocationService.obtenerUbicacionActual();

      if (!mounted) return;

      setState(() {
        _position = position;
        _ultimaActualizacion = DateTime.now();
      });

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
                'Error de ubicación: $error',
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo obtener la ubicación: $e',
          ),
        ),
      );
    }
  }

  Future<void> _actualizarUbicacion() async {
    if (_actualizandoUbicacion) return;

    setState(() {
      _actualizandoUbicacion = true;
    });

    try {
      final position =
          await LocationService.guardarUbicacionActual();

      // Guardamos también este registro en el historial.
      await LocationService.guardarEnHistorial(
        position,
      );

      if (!mounted) return;

      setState(() {
        _position = position;
        _ultimaActualizacion = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ubicación actualizada y guardada.',
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
          _actualizandoUbicacion = false;
        });
      }
    }
  }

  Future<void> _reintentarCamara() async {
    setState(() {
      _loadingCamera = true;
      _errorCamera = null;
    });

    await _cameraController?.dispose();
    _cameraController = null;

    await _inicializarCamara();
  }

  String _hora() {
    final hora =
        _ultimaActualizacion.hour.toString().padLeft(2, '0');

    final minuto =
        _ultimaActualizacion.minute.toString().padLeft(2, '0');

    final segundo =
        _ultimaActualizacion.second.toString().padLeft(2, '0');

    return '$hora:$minuto:$segundo';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _cameraController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Cámara con ubicación',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingCamera) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 18),
            Text(
              'Abriendo cámara...',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorCamera != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                color: Colors.white,
                size: 65,
              ),

              const SizedBox(height: 20),

              Text(
                _errorCamera!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 26),

              FilledButton.icon(
                onPressed: _reintentarCamara,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Reintentar cámara',
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Revisa que la aplicación tenga permiso para usar '
                'la cámara y que ninguna otra aplicación la esté utilizando.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized) {
      return const Center(
        child: Text(
          'La cámara no está disponible.',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraPreview(controller),

        Positioned(
          top: 18,
          left: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.55,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'Ubicación activa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              70,
              20,
              24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(
                    alpha: 0.9,
                  ),
                ],
              ),
            ),
            child: _buildLocationInfo(),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview(
    CameraController controller,
  ) {
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(
          controller,
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    final position = _position;

    if (position == null) {
      return const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 14),
          Text(
            'Obteniendo ubicación...',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          children: [
            Icon(
              Icons.my_location,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              'Tu ubicación actual',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          'Latitud: '
          '${position.latitude.toStringAsFixed(6)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          'Longitud: '
          '${position.longitude.toStringAsFixed(6)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          'Precisión aproximada: '
          '${position.accuracy.toStringAsFixed(1)} m',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          'Última actualización: ${_hora()}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _actualizandoUbicacion
                ? null
                : _actualizarUbicacion,
            icon: _actualizandoUbicacion
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.refresh,
                  ),
            label: Text(
              _actualizandoUbicacion
                  ? 'Actualizando...'
                  : 'Actualizar ubicación',
            ),
          ),
        ),
      ],
    );
  }
}