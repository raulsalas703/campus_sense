import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
  });

  String _nombreRol(
    String rol,
  ) {
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

  IconData _iconoRol(
    String rol,
  ) {
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

  Future<void> _editarNombre(
    BuildContext context,
    String nombreActual,
  ) async {
    final controller = TextEditingController(
      text: nombreActual,
    );

    final nuevoNombre =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Editar nombre',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon:
                  Icon(Icons.person_outline),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                final nombre =
                    controller.text.trim();

                if (nombre.isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  nombre,
                );
              },
              child: const Text(
                'Guardar',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (nuevoNombre == null ||
        nuevoNombre.trim().isEmpty) {
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'nombre': nuevoNombre.trim(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(
        nuevoNombre.trim(),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Nombre actualizado correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo actualizar el nombre: $e',
          ),
        ),
      );
    }
  }

  Widget _datoPerfil({
    required BuildContext context,
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colorScheme.primary
                    .withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color:
                    colorScheme.primary,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    valor,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
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
            return const Center(
              child:
                  CircularProgressIndicator(),
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

          final rol =
              datos?['rol']
                      ?.toString()
                      .trim() ??
                  'student';

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

          final letra =
              nombre.isNotEmpty
                  ? nombre[0]
                      .toUpperCase()
                  : 'U';

          final colorScheme =
              Theme.of(context)
                  .colorScheme;

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 650,
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 12,
                    ),

                    CircleAvatar(
                      radius: 52,
                      backgroundColor:
                          colorScheme.primary,
                      child: Text(
                        letra,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Text(
                      nombre,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          _iconoRol(rol),
                          size: 18,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Text(
                          _nombreRol(rol),
                          style:
                              TextStyle(
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    _datoPerfil(
                      context: context,
                      icon:
                          Icons.person_outline,
                      titulo: 'Nombre',
                      valor: nombre,
                    ),

                    _datoPerfil(
                      context: context,
                      icon:
                          Icons.email_outlined,
                      titulo:
                          'Correo electrónico',
                      valor: correo,
                    ),

                    _datoPerfil(
                      context: context,
                      icon:
                          _iconoRol(rol),
                      titulo:
                          'Tipo de usuario',
                      valor:
                          _nombreRol(rol),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 50,
                      child:
                          FilledButton.icon(
                        onPressed: () {
                          _editarNombre(
                            context,
                            nombre,
                          );
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                        ),
                        label: const Text(
                          'Editar nombre',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}