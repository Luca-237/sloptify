import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'sidebar_player.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Layout responsive: en móviles muy angostos se podría ocultar o mostrar como bottom sheet.
    // Para simplificar, mostraremos la sidebar siempre que haya ancho, o la apilaremos.
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Row(
        children: [
          Expanded(
            child: child,
          ),
          // Sidebar
          const SidebarPlayer(),
        ],
      ),
    );
  }
}
