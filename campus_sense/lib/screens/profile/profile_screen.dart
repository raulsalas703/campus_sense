import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
  });

  Widget _datoPerfil({
    required BuildContext context,
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color: colorScheme
            .surfaceContainerHighest
            .withValues(
          alpha: 0.55,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration:
                BoxDecoration(
              color: colorScheme
                  .primary
                  .withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
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
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
                ),

                const SizedBox(
                  height: 4,
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
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          DocumentSnapshot<
              Map<String, dynamic>>>(
        stream: FirebaseFirestore
            .instance
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

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Text(
                  'No se pudo cargar el perfil:\n${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
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

          final letra =
              nombre.isNotEmpty
                  ? nombre[0]
                      .toUpperCase()
                  : 'U';

          final colorScheme =
              Theme.of(context)
                  .colorScheme;

          return SafeArea(
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                24,
              ),
              child: Center(
                child:
                    ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 650,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(
                          26,
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
                          children: [
                            CircleAvatar(
                              radius:
                                  48,
                              backgroundColor:
                                  Colors.white
                                      .withValues(
                                alpha:
                                    0.20,
                              ),
                              child:
                                  Text(
                                letra,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize:
                                      36,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height:
                                  16,
                            ),

                            Text(
                              nombre,
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    24,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  5,
                            ),

                            Text(
                              correo,
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white70,
                                fontSize:
                                    13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      Align(
                        alignment:
                            Alignment
                                .centerLeft,
                        child: Text(
                          'Información de la cuenta',
                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                colorScheme
                                    .onSurface,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      _datoPerfil(
                        context:
                            context,
                        icon: Icons
                            .person_outline,
                        titulo:
                            'Nombre',
                        valor:
                            nombre,
                      ),

                      _datoPerfil(
                        context:
                            context,
                        icon: Icons
                            .email_outlined,
                        titulo:
                            'Correo electrónico',
                        valor:
                            correo,
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        height:
                            50,
                        child:
                            FilledButton.icon(
                          onPressed:
                              () async {
                            await Navigator.of(
                              context,
                            ).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditNameScreen(
                                  nombreActual:
                                      nombre,
                                ),
                              ),
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .edit_outlined,
                          ),
                          label:
                              const Text(
                            'Editar nombre',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EditNameScreen
    extends StatefulWidget {
  final String nombreActual;

  const EditNameScreen({
    super.key,
    required this.nombreActual,
  });

  @override
  State<EditNameScreen> createState() =>
      _EditNameScreenState();
}

class _EditNameScreenState
    extends State<EditNameScreen> {
  late final TextEditingController
      _nombreController;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _nombreController =
        TextEditingController(
      text:
          widget.nombreActual,
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();

    super.dispose();
  }

  Future<void> _guardarNombre()
      async {
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
            'Escribe un nombre.',
          ),
        ),
      );

      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'nombre': nombre,
        },
        SetOptions(
          merge: true,
        ),
      );

      await user.updateDisplayName(
        nombre,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Nombre actualizado correctamente.',
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
            'No se pudo actualizar el nombre: $e',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar nombre',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 600,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                children: [
                  const Icon(
                    Icons
                        .account_circle_outlined,
                    size: 75,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  const Text(
                    'Nombre de perfil',
                    style:
                        TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    'Este nombre se mostrará en tu cuenta de GeoSense.',
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  TextField(
                    controller:
                        _nombreController,
                    textCapitalization:
                        TextCapitalization
                            .words,
                    textInputAction:
                        TextInputAction
                            .done,
                    onSubmitted:
                        (_) {
                      _guardarNombre();
                    },
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Nombre',
                      prefixIcon:
                          Icon(
                        Icons
                            .person_outline,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  SizedBox(
                    height: 50,
                    child:
                        FilledButton.icon(
                      onPressed:
                          _guardando
                              ? null
                              : _guardarNombre,
                      icon:
                          _guardando
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
                                      .save_outlined,
                                ),
                      label:
                          Text(
                        _guardando
                            ? 'Guardando...'
                            : 'Guardar cambios',
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