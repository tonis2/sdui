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

class Gallery extends StatefulWidget {
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _State();
}

class _State extends State<Gallery> {
  int activePage = 1;

  @override
  void initState() {
    super.initState();
  }

  void openGallery(BackgroundImage image, int index) {
    AppState provider = Inherited.of(context)!;

    ThemeData theme = Theme.of(context);
    Size size = MediaQuery.sizeOf(context);

    int startIndex = (activePage - 1) * provider.imagesOnPage;

    var images = provider.images.values.toList().getRange(
      startIndex,
      min(startIndex + provider.imagesOnPage, provider.images.length),
    );

    SwipeImageGallery(
      context: context,
      transitionDuration: 200,
      initialIndex: index,
      children: images
          .map(
            (img) => InkWell(
              onTap: () {
                context.pop();
              },
              child: SizedBox(
                height: size.height,
                child: Stack(
                  children: [
                    Align(alignment: .center, child: Image.memory(img.data)),
                    if (img.prompt != null)
                      Align(
                        alignment: .bottomCenter,
                        child: SelectableText(
                          img.prompt!,
                          style: theme.textTheme.bodyMedium?.copyWith(color: const Color.fromRGBO(255, 255, 255, 0.9)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    ).show();
  }

  Widget galleryView() {
    AppState provider = Inherited.of(context)!;

    int startIndex = (activePage - 1) * provider.imagesOnPage;

    var images = provider.images.values.toList().getRange(
      startIndex,
      min(startIndex + provider.imagesOnPage, provider.images.length),
    );

    Widget imageView(BackgroundImage image) {
      return Stack(
        children: [
          Image.memory(image.data),
          Positioned(
            right: 5,
            top: 5,
            child: Container(
              padding: EdgeInsets.all(5),
              color: Colors.blueGrey,
              child: Column(
                spacing: 10,
                children: [
                  InkWell(
                    child: Tooltip(
                      message: "Delete",
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    onTap: () {
                      image.delete();
                      setState(() {});
                    },
                  ),
                  InkWell(
                    child: Tooltip(
                      message: "Save",
                      child: Icon(Icons.save, color: Colors.white),
                    ),
                    onTap: () async {
                      await FileSaver.instance.saveFile(
                        name: image.name ?? "default",
                        mimeType: MimeType.png,
                        bytes: image.data,
                      );
                    },
                  ),
                  InkWell(
                    child: Tooltip(
                      message: "Use for prompt",
                      child: Icon(Icons.edit, color: Colors.white),
                    ),
                    onTap: () async {
                      provider.clearImages();
                      provider.painterController.setBackground(
                        BackgroundImage(width: image.width, height: image.height, data: image.data, name: image.name),
                      );
                      provider.imagePrompt.addExtraImage(image.data);
                      provider.imagePrompt.width = image.width;
                      provider.imagePrompt.height = image.height;
                      context.go(AppRoutes.home);
                    },
                  ),
                ],
              ),
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
        children: images.indexed
            .map((image) => InkWell(onTap: () => openGallery(image.$2, image.$1), child: imageView(image.$2)))
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

          if (provider.images.length > provider.imagesOnPage)
            Container(
              width: 545,
              padding: EdgeInsetsGeometry.only(top: 10, bottom: 10),
              child: Pagination(
                activePage: activePage,
                totalPages: (provider.images.length / provider.imagesOnPage).ceil(),
                onSelect: (page) {
                  setState(() {
                    activePage = page;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
