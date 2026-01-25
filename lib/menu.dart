import 'package:flutter/material.dart';
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
  MenuItem(link: AppRoutes.folders, name: "Folders", icon: Icons.folder),
];

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _State();
}

class _State extends State<Menu> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppState provider = Inherited.of(context)!;
    ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.secondary.withAlpha(150)),
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
        ],
      ),
    );
  }
}
