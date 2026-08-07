import 'package:flutter/material.dart';
import 'sidebar_player.dart';
import 'mini_player.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth <= 800;

        return Scaffold(
          backgroundColor: AppTheme.bgDeep,
          body: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    child,
                    if (isMobile)
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SafeArea(child: MiniPlayer()),
                      ),
                  ],
                ),
              ),
              if (!isMobile)
                const SidebarPlayer(),
            ],
          ),
        );
      },
    );
  }
}
