import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/location_service.dart';
import '../camera/location_camera_screen.dart';
import '../history/history_screen.dart';
import '../map/location_map_screen.dart';
import '../places/my_places_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  Future<void> _confirmarSalir(
    BuildContext context,
  ) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Cerrar sesión',
          ),
          content: const Text(
            '¿Seguro que quieres cerrar sesión?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Cerrar sesión',
              ),
            ),
          ],
        );
      },
    );

    if (salir == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _abrirMiMapa(
    BuildContext context,
  ) async {
    try {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Obteniendo tu ubicación...',
          ),
        ),
      );

      final posicion =
          await LocationService
              .obtenerUbicacionActual();

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
                posicion,
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
            'No se pudo abrir el mapa: $e',
          ),
        ),
      );
    }
  }

  Widget _actionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: onPressed,
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color:
                colorScheme.surfaceContainerHighest,
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    colorScheme.primary,
                size: 25,
              ),

              const SizedBox(
                height: 7,
              ),

              Text(
                label,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(22),
        side: BorderSide(
          color: colorScheme.outlineVariant
              .withValues(
            alpha: 0.55,
          ),
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration:
                    BoxDecoration(
                  color: colorScheme.primary
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 29,
                  color:
                      colorScheme.primary,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      description,
                      style: TextStyle(
                        height: 1.35,
                        fontSize: 13.5,
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Container(
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(
                  color: colorScheme
                      .surfaceContainerHighest,
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        final datos =
            snapshot.data?.data();

        final nombreFirestore =
            datos?['nombre']
                    ?.toString()
                    .trim() ??
                '';

        final correoFirestore =
            datos?['correo']
                    ?.toString()
                    .trim() ??
                '';

        final nombre =
            nombreFirestore.isNotEmpty
                ? nombreFirestore
                : (user.displayName
                            ?.trim()
                            .isNotEmpty ==
                        true
                    ? user.displayName!
                        .trim()
                    : 'Usuario');

        final correo =
            correoFirestore.isNotEmpty
                ? correoFirestore
                : (user.email ??
                    'Sin correo');

        final inicial =
            nombre.isNotEmpty
                ? nombre[0].toUpperCase()
                : 'U';

        final colorScheme =
            Theme.of(context)
                .colorScheme;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration:
                      BoxDecoration(
                    color: colorScheme
                        .primary,
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    Icons
                        .explore_rounded,
                    color:
                        colorScheme
                            .onPrimary,
                    size: 23,
                  ),
                ),

                const SizedBox(
                  width: 11,
                ),

                const Text(
                  'GeoSense',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Cuenta',
                offset:
                    const Offset(
                  0,
                  50,
                ),
                onSelected: (value) {
                  WidgetsBinding
                      .instance
                      .addPostFrameCallback(
                    (_) async {
                      if (!context
                          .mounted) {
                        return;
                      }

                      if (value ==
                          'profile') {
                        await Navigator.of(
                          context,
                        ).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ProfileScreen(),
                          ),
                        );
                      }

                      if (value ==
                          'settings') {
                        await Navigator.of(
                          context,
                        ).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const SettingsScreen(),
                          ),
                        );
                      }

                      if (value ==
                          'logout') {
                        await _confirmarSalir(
                          context,
                        );
                      }
                    },
                  );
                },
                itemBuilder:
                    (context) {
                  return [
                    PopupMenuItem<
                        String>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            nombre,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            correo,
                            style:
                                const TextStyle(
                              fontSize:
                                  12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const PopupMenuDivider(),

                    const PopupMenuItem<
                        String>(
                      value:
                          'profile',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .person_outline,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Mi perfil',
                          ),
                        ],
                      ),
                    ),

                    const PopupMenuItem<
                        String>(
                      value:
                          'settings',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .settings_outlined,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Ajustes',
                          ),
                        ],
                      ),
                    ),

                    const PopupMenuDivider(),

                    const PopupMenuItem<
                        String>(
                      value:
                          'logout',
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Cerrar sesión',
                          ),
                        ],
                      ),
                    ),
                  ];
                },
                child: Padding(
                  padding:
                      const EdgeInsets.only(
                    right: 16,
                  ),
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor:
                        colorScheme
                            .primaryContainer,
                    child: Text(
                      inicial,
                      style: TextStyle(
                        color: colorScheme
                            .onPrimaryContainer,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 850,
                ),
                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      // =================
                      // CABECERA
                      // =================
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(
                          24,
                        ),
                        decoration:
                            BoxDecoration(
                          gradient:
                              LinearGradient(
                            begin:
                                Alignment
                                    .topLeft,
                            end:
                                Alignment
                                    .bottomRight,
                            colors: [
                              colorScheme
                                  .primary,
                              colorScheme
                                  .tertiary,
                            ],
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            26,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius:
                                      25,
                                  backgroundColor:
                                      Colors
                                          .white
                                          .withValues(
                                    alpha:
                                        0.18,
                                  ),
                                  child:
                                      Text(
                                    inicial,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize:
                                          20,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width:
                                      14,
                                ),

                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Text(
                                        'Hola 👋',
                                        style:
                                            TextStyle(
                                          color:
                                              Colors.white70,
                                          fontSize:
                                              14,
                                        ),
                                      ),

                                      Text(
                                        nombre,
                                        maxLines:
                                            1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.white,
                                          fontSize:
                                              22,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 24,
                            ),

                            const Text(
                              'Tus lugares, siempre contigo.',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    24,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            const Text(
                              'Explora tu ubicación, guarda lugares importantes y consulta tu historial.',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white70,
                                fontSize:
                                    14,
                                height:
                                    1.45,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      Row(
                        children: [
                          _actionButton(
                            context:
                                context,
                            icon: Icons
                                .person_outline,
                            label:
                                'Perfil',
                            onPressed:
                                () {
                              Navigator.of(
                                context,
                              ).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ProfileScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          _actionButton(
                            context:
                                context,
                            icon: Icons
                                .settings_outlined,
                            label:
                                'Ajustes',
                            onPressed:
                                () {
                              Navigator.of(
                                context,
                              ).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      const Text(
                        'Explora',
                        style:
                            TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        'Todo lo que necesitas en un solo lugar.',
                        style: TextStyle(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      _featureCard(
                        context:
                            context,
                        icon: Icons
                            .explore_outlined,
                        title:
                            'Mi mapa',
                        description:
                            'Consulta tu ubicación en tiempo real, explora el mapa y guarda nuevos lugares.',
                        onTap: () {
                          _abrirMiMapa(
                            context,
                          );
                        },
                      ),

                      _featureCard(
                        context:
                            context,
                        icon: Icons
                            .bookmark_border_rounded,
                        title:
                            'Mis lugares',
                        description:
                            'Encuentra rápidamente tus lugares guardados y ábrelos directamente en el mapa.',
                        onTap: () {
                          Navigator.of(
                            context,
                          ).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MyPlacesScreen(),
                            ),
                          );
                        },
                      ),

                      _featureCard(
                        context:
                            context,
                        icon: Icons
                            .history_rounded,
                        title:
                            'Historial',
                        description:
                            'Consulta las ubicaciones que decidiste guardar anteriormente.',
                        onTap: () {
                          Navigator.of(
                            context,
                          ).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const HistoryScreen(),
                            ),
                          );
                        },
                      ),

                      _featureCard(
                        context:
                            context,
                        icon: Icons
                            .camera_alt_outlined,
                        title:
                            'Cámara con ubicación',
                        description:
                            'Utiliza la cámara mientras consultas tu ubicación actual en tiempo real.',
                        onTap: () {
                          Navigator.of(
                            context,
                          ).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const LocationCameraScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}