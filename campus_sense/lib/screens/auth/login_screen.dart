import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
      final password = _passwordController.text.trim();

      if (_isLogin) {
        // INICIAR SESIÓN
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // CREAR CUENTA
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
              'rol': 'student',
              'fechaCreacion': FieldValue.serverTimestamp(),
            });
          }
      }

      // No necesitamos Navigator.
      // AuthGate detecta automáticamente la sesión.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

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
          mensaje = 'La contraseña es demasiado débil.';
          break;

        case 'operation-not-allowed':
          mensaje =
              'El inicio de sesión con correo y contraseña no está habilitado.';
          break;

        case 'too-many-requests':
          mensaje =
              'Demasiados intentos. Intenta nuevamente más tarde.';
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
      if (!mounted) return;

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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 42,
                            color: Color(0xFF2563EB),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Campus Sense',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _isLogin
                              ? 'Inicia sesión para continuar'
                              : 'Crea tu cuenta',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 30),

                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(
                                Icons.person_outline,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (!_isLogin &&
                                  (value == null ||
                                      value.trim().isEmpty)) {
                                return 'Ingresa tu nombre';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

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

                        const SizedBox(height: 16),

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
                            if (value == null ||
                                value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }

                            if (!_isLogin &&
                                value.length < 6) {
                              return 'Usa al menos 6 caracteres';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
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

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? '¿No tienes cuenta?'
                                  : '¿Ya tienes cuenta?',
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
    );
  }
}