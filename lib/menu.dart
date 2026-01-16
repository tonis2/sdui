import 'package:flutter/material.dart';
import 'package:sdui/services/pwa/pwa_install.dart';
import '/state.dart';
import '/config.dart';
import 'package:go_router/go_router.dart';

class MenuItem {
  String link;
  String name;
  IconData icon;
  MenuItem({required this.link, required this.name, required this.icon});
}

var menuItems = [
  MenuItem(link: AppRoutes.home, name: "Home", icon: Icons.home),
  MenuItem(link: AppRoutes.gallery, name: "Gallery", icon: Icons.photo_library),
];

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _State();
}

class _State extends State<Menu> {
  final _pwaService = PwaInstallService();
  bool _showInstall = false;

  @override
  void initState() {
    super.initState();
    _showInstall = _pwaService.isInstallAvailable;
    _pwaService.onInstallAvailable.listen((available) {
      setState(() => _showInstall = available);
    });
  }

  void open(MenuItem item) {
    context.go(item.link);
  }

  @override
  Widget build(BuildContext context) {
    AppState provider = Inherited.of(context)!;
    ThemeData theme = Theme.of(context);

    return Expanded(
      child: Padding(
        padding: EdgeInsetsGeometry.only(top: 40),
        child: Column(
          spacing: 20,
          children: [
            ...menuItems.map((item) {
              final isActive = GoRouterState.of(context).uri.toString() == item.link;
              return Tooltip(
                message: item.name,
                child: InkWell(
                  child: Icon(item.icon, color: isActive ? Colors.lightGreen : theme.colorScheme.tertiary, size: 25),
                  onTap: () => context.go(item.link),
                ),
              );
            }),
            const Spacer(),
            // Install button at bottom
            if (_showInstall)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _InstallTile(
                  onTap: () async {
                    await _pwaService.promptInstall();
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InstallTile extends StatelessWidget {
  final VoidCallback onTap;

  const _InstallTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromRGBO(250, 172, 39, 1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color.fromRGBO(250, 172, 39, 0.8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.download, size: 20, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                'Install App',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
