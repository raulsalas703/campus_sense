import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return 'Buenos días';
    }

    if (hour >= 12 && hour < 19) {
      return 'Buenas tardes';
    }

    return 'Buenas noches';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 19) {
      return Icons.wb_sunny_rounded;
    }

    return Icons.nightlight_round;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.sensors_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CampusSense',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tu campus se adapta a ti',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Icon(
                    _getGreetingIcon(),
                    size: 30,
                    color: isDark ? Colors.amber : Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                'Aquí podrás consultar tu contexto y actividades.',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Contexto actual',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _ContextCard(
                    icon: Icons.location_on_rounded,
                    title: 'Ubicación',
                    value: 'Sin detectar',
                    iconColor: Colors.red,
                  ),
                  _ContextCard(
                    icon: Icons.access_time_rounded,
                    title: 'Hora',
                    value: _currentTime(),
                    iconColor: Colors.blue,
                  ),
                  const _ContextCard(
                    icon: Icons.light_mode_rounded,
                    title: 'Iluminación',
                    value: 'Pendiente',
                    iconColor: Colors.amber,
                  ),
                  const _ContextCard(
                    icon: Icons.directions_walk_rounded,
                    title: 'Movimiento',
                    value: 'Pendiente',
                    iconColor: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                '¿Qué necesitas?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              _MenuButton(
                icon: Icons.place_rounded,
                title: 'Lugares',
                subtitle: 'Consulta lugares de tu campus',
                onTap: () {},
              ),

              const SizedBox(height: 12),

              _MenuButton(
                icon: Icons.school_rounded,
                title: 'Actividades',
                subtitle: 'Consulta tus actividades académicas',
                onTap: () {},
              ),

              const SizedBox(height: 12),

              _MenuButton(
                icon: Icons.sensors_rounded,
                title: 'Contexto',
                subtitle: 'Consulta los sensores del dispositivo',
                onTap: () {},
              ),

              const SizedBox(height: 12),

              _MenuButton(
                icon: Icons.settings_rounded,
                title: 'Configuración',
                subtitle: 'Personaliza CampusSense',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _currentTime() {
    final now = DateTime.now();

    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _ContextCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const _ContextCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.60),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.60),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}