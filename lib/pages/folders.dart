import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sdui/config.dart';
import '/components/index.dart';
import '/models/index.dart';
import '/state.dart';
import 'dart:math';
import 'package:hive_ce/hive_ce.dart';
// import 'package:image/image.dart' as imageLib;

class Folders extends StatefulWidget {
  const Folders({super.key});

  @override
  State<Folders> createState() => _State();
}

class _State extends State<Folders> {
  int activePage = 1;
  List<Folder> folders = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadFolders(1));
    super.initState();
  }

  void loadFolders(int page) async {
    if (await Hive.boxExists("folders") == false) return;
    folders = [];
    AppState provider = Inherited.of(context)!;
    activePage = page;
    int startIndex = (page - 1) * itemsOnPage;
    for (Folder folder in provider.folders.values.toList().getRange(
      startIndex,
      min(startIndex + itemsOnPage, provider.folders.length),
    )) {
      folder.size = provider.folders.length;
      folders.add(folder);
    }

    setState(() {});
  }

  Widget foldersList() {
    ThemeData theme = Theme.of(context);
    AppState provider = Inherited.of(context)!;

    return DefaultTextStyle(
      style: theme.textTheme.bodyMedium!,
      child: CustomTable(
        columnWidths: {0: FixedSize(width: 200), 1: FixedSize(width: 80), 2: FixedSize(width: 60)},
        maxHeight: 600,
        headerRow: CustomRow(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(color: theme.colorScheme.secondary),
          children: [
            Text("Name", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: .bold)),
            Text("Size", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: .bold)),
            Text("Encrypted", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: .bold)),
            Text("Delete", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: .bold)),
            SizedBox(),
          ],
        ),
        children: folders.map((item) {
          // Get folder size
          LazyBox<PromptData>? box = provider.boxMap[item.name];

          return CustomRow(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            itemDecoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: theme.colorScheme.shadow),
                horizontal: BorderSide(color: theme.colorScheme.shadow),
              ),
            ),
            children: [
              Text(item.name),
              Text(box?.length.toString() ?? "0"),
              Text(item.encrypted.toString()),
              IconButton(
                onPressed: () async {
                  item.delete();
                  provider.boxMap.remove(item.name);
                  loadFolders(activePage);
                },
                icon: Icon(Icons.delete, color: theme.colorScheme.tertiary),
              ),
              IconButton(
                onPressed: () => context.go("/folder/${item.name}"),
                icon: Icon(Icons.arrow_forward, color: theme.colorScheme.tertiary),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppState provider = Inherited.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 60),
      child: Column(
        children: [
          if (folders.isEmpty) Text("No folders created", style: theme.textTheme.bodyLarge),
          if (folders.isNotEmpty) foldersList(),
          if (provider.folders.length > itemsOnPage)
            Container(
              width: 700,
              padding: EdgeInsetsGeometry.only(top: 10, bottom: 10),
              child: Pagination(
                activePage: activePage,
                totalPages: (provider.folders.length / itemsOnPage).ceil(),
                onSelect: (page) => loadFolders(page),
              ),
            ),
        ],
      ),
    );
  }
}
