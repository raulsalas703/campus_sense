import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class SettingsScreen
    extends StatelessWidget {
  const SettingsScreen({
    super.key,
  });

  Future<void> _cambiarTema(
    BuildContext context,
    bool oscuro,
  ) async {
    try {
      await context
          .read<ThemeProvider>()
          .cambiarTema(oscuro);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar el tema: $e',
          ),
        ),
      );
    }
  }

  Future<void> _abrirUbicacion(
    BuildContext context,
  ) async {
    final abierto =
        await Geolocator
            .openLocationSettings();

    if (!abierto &&
        context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir la configuración de ubicación.',
          ),
        ),
      );
    }
  }

  Future<void> _abrirPermisos(
    BuildContext context,
  ) async {
    final abierto =
        await Geolocator.openAppSettings();

    if (!abierto &&
        context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir la configuración de la aplicación.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final themeProvider =
        context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 700,
          ),
          child: ListView(
            padding:
                const EdgeInsets.all(20),
            children: [
              const Text(
                'Apariencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Card(
                child: SwitchListTile(
                  secondary: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: const Text(
                    'Tema oscuro',
                  ),
                  subtitle: Text(
                    themeProvider.isDarkMode
                        ? 'El tema oscuro está activado.'
                        : 'El tema claro está activado.',
                  ),
                  value:
                      themeProvider.isDarkMode,
                  onChanged: (
                    value,
                  ) {
                    _cambiarTema(
                      context,
                      value,
                    );
                  },
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              const Text(
                'Ubicación',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          const Icon(
                        Icons
                            .location_on_outlined,
                      ),
                      title: const Text(
                        'Configuración de ubicación',
                      ),
                      subtitle:
                          const Text(
                        'Activar o desactivar el GPS del dispositivo.',
                      ),
                      trailing:
                          const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () {
                        _abrirUbicacion(
                          context,
                        );
                      },
                    ),

                    const Divider(
                      height: 1,
                    ),

                    ListTile(
                      leading:
                          const Icon(
                        Icons
                            .privacy_tip_outlined,
                      ),
                      title: const Text(
                        'Permisos de la aplicación',
                      ),
                      subtitle:
                          const Text(
                        'Administrar permisos de cámara y ubicación.',
                      ),
                      trailing:
                          const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () {
                        _abrirPermisos(
                          context,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              const Text(
                'Acerca de',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons
                        .info_outline,
                  ),
                  title: Text(
                    'Campus Sense',
                  ),
                  subtitle: Text(
                    'Versión 1.0.0',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}