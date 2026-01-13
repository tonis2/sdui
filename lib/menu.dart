import 'package:flutter/material.dart';
import '/state.dart';
import '/config.dart';
import 'package:go_router/go_router.dart';

class MenuItem {
  String link;
  String name;
  MenuItem({required this.link, required this.name});
}

var menuItems = [MenuItem(link: AppRoutes.home, name: "home"), MenuItem(link: AppRoutes.gallery, name: "gallery")];

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _State();
}

class _State extends State<Menu> {
  void open(MenuItem item) {
    context.go(item.link);
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    AppState provider = Inherited.of(context)!;

    ThemeData theme = Theme.of(context);

    return Container(
      width: size.width,
      height: size.height,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        spacing: 10,
        children: menuItems
            .map<Widget>(
              ((item) => Padding(
                padding: EdgeInsets.all(5),
                child: InkWell(
                  onTap: () => open(item),
                  child: Text(item.name, style: theme.textTheme.bodyMedium),
                ),
              )),
            )
            .toList(),
      ),
    );
  }
}
