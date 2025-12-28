import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '/components/index.dart';
import '/models/index.dart';
import '/state.dart';
import 'package:swipe_image_gallery/swipe_image_gallery.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '/models/index.dart';

class Gallery extends StatefulWidget {
  @override
  State<Gallery> createState() => _State();
}

class _State extends State<Gallery> {
  @override
  void initState() {
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   AppState provider = Inherited.of(context)!;
    //   setState(() {});
    // });
    super.initState();
  }

  void openGallery(BackgroundImage image) {
    AppState provider = Inherited.of(context)!;

    SwipeImageGallery(
      context: context,
      transitionDuration: 200,
      initialIndex: image.key,
      children: provider.images.values
          .map(
            (img) => InkWell(
              onTap: () {
                context.pop();
              },
              child: Image.memory(img.data),
            ),
          )
          .toList(),
    ).show();
  }

  Widget galleryView() {
    AppState provider = Inherited.of(context)!;
    ThemeData theme = Theme.of(context);

    Widget imageView(BackgroundImage image) {
      return Stack(
        children: [
          Image.memory(image.data),
          Positioned(
            bottom: 0,
            left: 0,
            child: Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Delete", style: theme.textTheme.bodyMedium),
                  onPressed: () {
                    print(image.key);
                    provider.images.deleteAt(image.key);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

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
        children: provider.images.values
            .toList()
            .map((image) => InkWell(onTap: () => openGallery(image), child: imageView(image)))
            .toList(),
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
          if (provider.images.values.isEmpty) Text("Gallery is empty", style: theme.textTheme.bodyLarge),
          if (provider.images.isNotEmpty) galleryView(),
        ],
      ),
    );
  }
}
