import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final nombre = _nameController.text.trim();
        final user = credential.user;

        if (user != null) {
          if (nombre.isNotEmpty) {
            await user.updateDisplayName(nombre);
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'nombre': nombre,
            'correo': email,
            'fechaCreacion': FieldValue.serverTimestamp(),
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      String mensaje = 'Ocurrió un error. Intenta nuevamente.';

      switch (e.code) {
        case 'invalid-email':
          mensaje = 'El correo electrónico no es válido.';
          break;

        case 'user-disabled':
          mensaje = 'Esta cuenta está deshabilitada.';
          break;

        case 'user-not-found':
          mensaje = 'No existe una cuenta con este correo.';
          break;

        case 'wrong-password':
          mensaje = 'La contraseña es incorrecta.';
          break;

        case 'invalid-credential':
          mensaje = 'Correo o contraseña incorrectos.';
          break;

        case 'email-already-in-use':
          mensaje = 'Ya existe una cuenta con este correo.';
          break;

        case 'weak-password':
          mensaje = 'La contraseña debe tener al menos 6 caracteres.';
          break;

        case 'too-many-requests':
          mensaje = 'Demasiados intentos. Intenta nuevamente más tarde.';
          break;

        default:
          mensaje = e.message ?? 'Ocurrió un error inesperado.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ocurrió un error inesperado.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeMode() {
    setState(() {
      _isLogin = !_isLogin;
    });

    _formKey.currentState?.reset();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(
                alpha: 0.16,
              ),
              colorScheme.surface,
              colorScheme.tertiary.withValues(
                alpha: 0.10,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 440,
                ),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ==========================
                          // LOGO DE CAMPUS SENSE
                          // ==========================
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/icons/campus_sense_icon.png',
                              width: 95,
                              height: 95,
                              fit: BoxFit.cover,

                              // Si Flutter no encuentra la imagen,
                              // mostrará este icono en lugar de romper.
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return Container(
                                  width: 95,
                                  height: 95,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.tertiary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          // ==========================
                          // NOMBRE DE LA APP
                          // ==========================
                          const Text(
                            'GeoSense',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          Text(
                            _isLogin
                                ? 'Bienvenido de nuevo'
                                : 'Crea tu cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            'Tu campus, siempre contigo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(
                            height: 30,
                          ),

                          // ==========================
                          // CAMPO NOMBRE
                          // SOLO DURANTE REGISTRO
                          // ==========================
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Ingresa tu nombre';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                          ],

                          // ==========================
                          // CORREO
                          // ==========================
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Ingresa tu correo';
                              }

                              if (!value.contains('@')) {
                                return 'Ingresa un correo válido';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          // ==========================
                          // CONTRASEÑA
                          // ==========================
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onFieldSubmitted: (_) {
                              _submit();
                            },
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                              ),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu contraseña';
                              }

                              if (!_isLogin && value.length < 6) {
                                return 'Usa al menos 6 caracteres';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 24,
                          ),

                          // ==========================
                          // BOTÓN
                          // ==========================
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed:
                                  _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isLogin
                                          ? 'Iniciar sesión'
                                          : 'Crear cuenta',
                                    ),
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          // ==========================
                          // CAMBIAR LOGIN / REGISTRO
                          // ==========================
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _isLogin
                                      ? '¿No tienes cuenta?'
                                      : '¿Ya tienes cuenta?',
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    _isLoading ? null : _changeMode,
                                child: Text(
                                  _isLogin
                                      ? 'Regístrate'
                                      : 'Inicia sesión',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}