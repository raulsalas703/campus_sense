import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
  });

  String _formatearFecha(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Guardando fecha...';
    }

    final fecha = timestamp.toDate().toLocal();

    final dia =
        fecha.day.toString().padLeft(2, '0');

    final mes =
        fecha.month.toString().padLeft(2, '0');

    final anio =
        fecha.year.toString();

    final hora =
        fecha.hour.toString().padLeft(2, '0');

    final minuto =
        fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio • $hora:$minuto';
  }

  String _coordenada(
    dynamic valor,
  ) {
    if (valor is num) {
      return valor.toDouble().toStringAsFixed(6);
    }

    return '0.000000';
  }

  String _precision(
    dynamic valor,
  ) {
    if (valor is num) {
      return '${valor.toDouble().toStringAsFixed(1)} m';
    }

    return 'No disponible';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No hay una sesión activa.',
          ),
        ),
      );
    }

    final historial = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('location_history')
        .orderBy(
          'fecha',
          descending: true,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: historial.snapshots(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 55,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    const Text(
                      'No se pudo cargar el historial.',
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

          final registros =
              snapshot.data?.docs ?? [];

          if (registros.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(
                  30,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                          .history_toggle_off_outlined,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      'Aún no hay ubicaciones guardadas',
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
                      'Regresa al inicio y selecciona "Mi ubicación" para crear tu primer registro.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                        fontSize: 15,
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
                      registros.length + 1,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    if (index == 0) {
                      return _ResumenHistorial(
                        cantidad:
                            registros.length,
                      );
                    }

                    final documento =
                        registros[index - 1];

                    final datos =
                        documento.data();

                    final latitud =
                        datos['latitud'];

                    final longitud =
                        datos['longitud'];

                    final precision =
                        datos['precision'];

                    final fecha =
                        datos['fecha'];

                    return _TarjetaHistorial(
                      numero: index,
                      fecha: _formatearFecha(
                        fecha is Timestamp
                            ? fecha
                            : null,
                      ),
                      latitud:
                          _coordenada(
                        latitud,
                      ),
                      longitud:
                          _coordenada(
                        longitud,
                      ),
                      precision:
                          _precision(
                        precision,
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

class _ResumenHistorial
    extends StatelessWidget {
  final int cantidad;

  const _ResumenHistorial({
    required this.cantidad,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      padding: const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),
            child: Icon(
              Icons.history,
              color:
                  colorScheme.onPrimary,
              size: 30,
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial de ubicaciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  '$cantidad ${cantidad == 1 ? 'registro guardado' : 'registros guardados'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaHistorial
    extends StatelessWidget {
  final int numero;
  final String fecha;
  final String latitud;
  final String longitud;
  final String precision;

  const _TarjetaHistorial({
    required this.numero,
    required this.fecha,
    required this.latitud,
    required this.longitud,
    required this.precision,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          18,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primary
                    .withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color:
                    colorScheme.primary,
                size: 28,
              ),
            ),

            const SizedBox(
              width: 15,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    fecha,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _dato(
                    icon:
                        Icons.north_outlined,
                    texto:
                        'Latitud: $latitud',
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  _dato(
                    icon:
                        Icons.east_outlined,
                    texto:
                        'Longitud: $longitud',
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  _dato(
                    icon:
                        Icons.gps_fixed,
                    texto:
                        'Precisión: $precision',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato({
    required IconData icon,
    required String texto,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
        ),
        const SizedBox(
          width: 7,
        ),
        Expanded(
          child: Text(
            texto,
          ),
        ),
      ],
    );
  }
}
