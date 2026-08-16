import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../services/marker_service.dart';

class CreateMarkerScreen
    extends StatefulWidget {
  final LatLng position;

  const CreateMarkerScreen({
    super.key,
    required this.position,
  });

  @override
  State<CreateMarkerScreen> createState() =>
      _CreateMarkerScreenState();
}

class _CreateMarkerScreenState
    extends State<CreateMarkerScreen> {
  final TextEditingController
      _nombreController =
      TextEditingController();

  final TextEditingController
      _descripcionController =
      TextEditingController();

  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();

    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    final nombre =
        _nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Escribe un nombre para el marcador.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await MarkerService.crearMarcador(
        nombre: nombre,
        descripcion:
            _descripcionController.text,
        latitud:
            widget.position.latitude,
        longitud:
            widget.position.longitude,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Marcador guardado correctamente.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar el marcador: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuevo marcador',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 600,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(
                      22,
                    ),
                    decoration:
                        BoxDecoration(
                      color: colorScheme
                          .primaryContainer,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons
                              .add_location_alt_outlined,
                          size: 56,
                          color:
                              colorScheme.primary,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        const Text(
                          'Guardar este lugar',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          'Latitud: ${widget.position.latitude.toStringAsFixed(6)}',
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          'Longitud: ${widget.position.longitude.toStringAsFixed(6)}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  TextField(
                    controller:
                        _nombreController,
                    textCapitalization:
                        TextCapitalization.words,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Nombre del marcador',
                      hintText:
                          'Ej. Mi carro',
                      prefixIcon: Icon(
                        Icons.place_outlined,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  TextField(
                    controller:
                        _descripcionController,
                    textCapitalization:
                        TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 5,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Descripción (opcional)',
                      hintText:
                          'Ej. Estacionamiento junto a la entrada',
                      prefixIcon: Icon(
                        Icons.notes_outlined,
                      ),
                      border:
                          OutlineInputBorder(),
                      alignLabelWithHint:
                          true,
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  SizedBox(
                    height: 52,
                    child:
                        FilledButton.icon(
                      onPressed: _guardando
                          ? null
                          : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .bookmark_add_outlined,
                            ),
                      label: Text(
                        _guardando
                            ? 'Guardando...'
                            : 'Guardar marcador',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}