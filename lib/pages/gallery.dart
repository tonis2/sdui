import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '/components/index.dart';
import '/models/index.dart';
import '/state.dart';
import 'package:swipe_image_gallery/swipe_image_gallery.dart';

class Gallery extends StatefulWidget {
  @override
  State<Gallery> createState() => _State();
}

class _State extends State<Gallery> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppState provider = Inherited.of(context)!;
      await provider.loadImageCache();
      setState(() {});
    });
    super.initState();
  }

  void openGallery(BackgroundImage image) {
    AppState provider = Inherited.of(context)!;
    var index = provider.images.indexOf(image);

    SwipeImageGallery(
      context: context,
      initialIndex: index,
      children: provider.images
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
    Size size = MediaQuery.sizeOf(context);
    return Expanded(
      child: GridView(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisExtent: size.width / 3,
          crossAxisSpacing: size.width / 3,
        ),
        children: provider.images
            .map(
              (image) => InkWell(
                onTap: () {
                  openGallery(image);
                },
                child: Image.memory(image.data),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppState provider = Inherited.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          if (provider.images.isEmpty) Text("Gallery is empty"),
          if (provider.images.isNotEmpty) galleryView(),
        ],
      ),
    );
  }
}
