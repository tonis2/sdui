import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sdui/config.dart';
import '/components/index.dart';
import '/models/index.dart';
import '/state.dart';
import 'package:swipe_image_gallery/swipe_image_gallery.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:file_saver/file_saver.dart';
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
  Box<Folder>? folders;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      folders = await Hive.openBox('folders');
    });
    super.initState();
  }

  Widget foldersList() {
    AppState provider = Inherited.of(context)!;

    return Expanded(
      child: ResponsiveGridList(
        horizontalGridSpacing: 16, // Horizontal space between grid items
        verticalGridSpacing: 16, // Vertical space between grid items
        horizontalGridMargin: 50, // Horizontal space around the grid
        verticalGridMargin: 50, // Vertical space around the grid
        minItemWidth: 150, // The minimum item width (can be smaller, if the layout constraints are smaller)
        minItemsPerRow: 2, // The minimum items to show in a single row. Takes precedence over minItemWidth
        maxItemsPerRow: 5, // The maximum items to show in a single row. Can be useful on large screens
        listViewBuilderOptions:
            ListViewBuilderOptions(), // Options that are getting passed to the ListView.builder() function
        children: [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppState provider = Inherited.of(context)!;
    ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          if (folders == null || folders!.isEmpty) Text("No folders created", style: theme.textTheme.bodyLarge),
          if (folders == null || folders!.isNotEmpty) foldersList(),

          if (folders != null && folders!.keys.length > imagesOnPage)
            Container(
              width: 545,
              padding: EdgeInsetsGeometry.only(top: 10, bottom: 10),
              child: Pagination(
                activePage: activePage,
                totalPages: (provider.images!.length / imagesOnPage).ceil(),
                onSelect: (page) => {},
              ),
            ),
        ],
      ),
    );
  }
}
