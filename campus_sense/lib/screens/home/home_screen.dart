import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/location_service.dart';
import '../camera/location_camera_screen.dart';
import '../map/location_map_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmarSalir(BuildContext context) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Seguro que quieres salir?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    if (salir == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  String _nombreRol(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador';

      case 'teacher':
        return 'Docente';

      case 'student':
      default:
        return 'Estudiante';
    }
  }

  IconData _iconoRol(String rol) {
    switch (rol) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;

      case 'teacher':
        return Icons.school_outlined;

      case 'student':
      default:
        return Icons.person_outline;
    }
  }

  Widget _topButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  Widget _mainButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirMiUbicacion(BuildContext context) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Obteniendo ubicación...')));

      final posicion = await LocationService.guardarUbicacionActual();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationMapScreen(initialPosition: posicion),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener la ubicación: $e')),
      );
    }
  }

  Future<void> _abrirMapa(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cargando mapa...')));

      final posicion = await LocationService.obtenerUbicacionActual();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationMapScreen(initialPosition: posicion),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo abrir el mapa: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay una sesión activa.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final datos = snapshot.data?.data();

        final nombreFirestore = datos?['nombre']?.toString().trim() ?? '';

        final correoFirestore = datos?['correo']?.toString().trim() ?? '';

        final rolFirestore = datos?['rol']?.toString().trim() ?? 'student';

        final nombreMostrar = nombreFirestore.isNotEmpty
            ? nombreFirestore
            : (user.displayName?.trim().isNotEmpty == true
                  ? user.displayName!.trim()
                  : 'Estudiante');

        final correoMostrar = correoFirestore.isNotEmpty
            ? correoFirestore
            : (user.email ?? 'Sin correo');

        final rolMostrar = _nombreRol(rolFirestore);

        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Campus Sense',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Cuenta',
                icon: const Icon(Icons.account_circle_outlined),
                onSelected: (value) {
                  if (value == 'logout') {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!context.mounted) return;

                      await _confirmarSalir(context);
                    });

                    return;
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;

                    if (value == 'profile') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    }

                    if (value == 'settings') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    }
                  });
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreMostrar,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            correoMostrar,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(_iconoRol(rolFirestore), size: 17),
                              const SizedBox(width: 6),
                              Text(
                                rolMostrar,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const PopupMenuDivider(),

                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline),
                          SizedBox(width: 10),
                          Text('Mi perfil'),
                        ],
                      ),
                    ),

                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined),
                          SizedBox(width: 10),
                          Text('Ajustes'),
                        ],
                      ),
                    ),

                    const PopupMenuDivider(),

                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 10),
                          Text('Cerrar sesión'),
                        ],
                      ),
                    ),
                  ];
                },
              ),

              const SizedBox(width: 8),
            ],
          ),

          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $nombreMostrar 👋',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Bienvenido a Campus Sense',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Icon(
                            _iconoRol(rolFirestore),
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            rolMostrar,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          _topButton(
                            icon: Icons.settings_outlined,
                            label: 'Ajustes',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 12),

                          _topButton(
                            icon: Icons.person_outline,
                            label: 'Perfil',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        '¿Qué quieres hacer?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _mainButton(
                        context: context,
                        icon: Icons.my_location_outlined,
                        title: 'Mi ubicación',
                        subtitle: 'Ver y guardar dónde estoy actualmente.',
                        onTap: () {
                          _abrirMiUbicacion(context);
                        },
                      ),

                      _mainButton(
                        context: context,
                        icon: Icons.map_outlined,
                        title: 'Mapa del campus',
                        subtitle: 'Explorar el mapa y ver mi posición.',
                        onTap: () {
                          _abrirMapa(context);
                        },
                      ),

                      _mainButton(
                        context: context,
                        icon: Icons.camera_alt_outlined,
                        title: 'Cámara con ubicación',
                        subtitle:
                            'Usar la cámara y ver mi ubicación en tiempo real.',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LocationCameraScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            _confirmarSalir(context);
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión'),
                        ),
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
