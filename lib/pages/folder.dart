import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:sdui/config.dart';
import 'package:sdui/pages/node_editor/nodes/index.dart';
import '/components/index.dart';
import '/models/index.dart';
import '/state.dart';
import 'package:swipe_image_gallery/swipe_image_gallery.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math';

Future<void> showPasswordDialog(BuildContext context, String folder) async {
  ThemeData theme = Theme.of(context);
  AppState provider = Inherited.of(context)!;
  String? password;

  var response = await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text("Enter password to unlock storage", style: theme.textTheme.titleSmall),
        content: SizedBox(
          width: 600,
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 10,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(label: Text("Password", style: theme.textTheme.bodyMedium)),
                onChanged: (value) => password = value,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 25,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(theme.colorScheme.secondary)),
                    onPressed: () => Navigator.pop(context, password),
                    child: Text("Submit", style: theme.textTheme.bodyMedium),
                  ),
                  ElevatedButton(
                    style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(theme.colorScheme.secondary)),
                    onPressed: () => Navigator.pop(context),
                    child: Text("Skip", style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  try {
    if (response != null && response.toString().isNotEmpty) {
      // User provided password
      provider.boxMap[folder] = await Hive.openLazyBox<PromptData>(
        folder,
        encryptionCipher: HiveAesCipher(generateEncryptionKey(response.toString())),
      );
    }
  } catch (err) {
    print(err.toString());
  }
}

void unlockFolder(BuildContext context, String folder) {
  AppState provider = Inherited.of(context)!;
  var folders = provider.folders.values.where((Folder item) => item.name == folder);

  // Folder is encrypted, ask user to unlock it and then cache it
  if (folders.isNotEmpty && folders.first.encrypted && provider.boxMap[folder] == null) {
    showPasswordDialog(context, folders.first.name);
  }

  if (folders.isNotEmpty && !folders.first.encrypted && provider.boxMap[folder] == null) {
    Hive.openLazyBox<PromptData>(folder).then((box) {
      provider.boxMap[folder] = box;
    });
  }
}

class FolderView extends StatefulWidget {
  final String path;
  const FolderView({super.key, required this.path});

  @override
  State<FolderView> createState() => _State();
}

class _State extends State<FolderView> {
  List<PromptData> data = [];
  int activePage = 1;
  int _lastKnownBoxLength = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadContent(1));
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if the box has new items since last load
    AppState provider = Inherited.of(context)!;
    LazyBox<PromptData>? box = provider.boxMap[widget.path];
    if (box != null && box.length != _lastKnownBoxLength && _lastKnownBoxLength > 0) {
      loadContent(activePage);
    }
  }

  void loadContent(int page) async {
    AppState provider = Inherited.of(context)!;
    activePage = page;
    data = [];

    int startIndex = (page - 1) * itemsOnPage;

    LazyBox<PromptData>? box = provider.boxMap[widget.path];

    // Folder not loaded, load it to cache
    if (box == null && await Hive.boxExists("folders")) {
      Folder folder = provider.folders.values.firstWhere((item) => item.name == widget.path);
      if (folder.encrypted) {
        await showPasswordDialog(context, widget.path);
      } else {
        provider.boxMap[widget.path] = await Hive.openLazyBox<PromptData>(widget.path);
      }
    }

    box = provider.boxMap[widget.path];
    var keys = box?.keys.toList().getRange(startIndex, min(startIndex + itemsOnPage, box.length));

    // Load images from keys
    if (keys != null) {
      for (var key in keys) {
        var item = await box?.get(key);
        if (item != null) data.add(item);
      }
    }

    _lastKnownBoxLength = box?.length ?? 0;
    setState(() {});
  }

  // @override
  // void didUpdateWidget(covariant Folder oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   loadContent(activePage);
  // }

  void openGallery(PromptData image, int index) {
    ThemeData theme = Theme.of(context);
    Size size = MediaQuery.sizeOf(context);
    TextStyle? textStyle = theme.textTheme.bodyMedium?.copyWith(color: const Color.fromRGBO(255, 255, 255, 0.9));

    SwipeImageGallery(
      context: context,
      transitionDuration: 200,
      initialIndex: index,
      children: data
          .map(
            (item) => InkWell(
              onTap: () => context.pop(),
              child: SizedBox(
                height: size.height,
                child: Stack(
                  children: [
                    Align(alignment: .center, child: Image.memory(item.data)),
                    if (item.prompt != null)
                      Align(
                        alignment: .bottomCenter,
                        child: Column(
                          mainAxisAlignment: .end,
                          spacing: 5,
                          children: [
                            SelectableText(item.prompt?.prompt ?? "-", style: textStyle),
                            Row(
                              mainAxisAlignment: .center,
                              spacing: 5,
                              children: [
                                Text("Steps: ${item.prompt?.steps},", style: textStyle),
                                Text("Sampler: ${item.prompt?.sampler},", style: textStyle),
                                Text("Denoise: ${item.prompt?.noiseStrenght},", style: textStyle),
                                Text("Width: ${item.prompt?.width}, Height: ${item.prompt?.height}", style: textStyle),
                              ],
                            ),
                          ],
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

  Widget imageView(PromptData item) {
    return Stack(
      children: [
        Image.memory(item.data),
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
                    data.removeWhere((img) => img.key == item.key);
                    item.delete();
                    setState(() {});
                  },
                ),
                InkWell(
                  child: Tooltip(
                    message: "Save",
                    child: Icon(Icons.save, color: Colors.white),
                  ),
                  onTap: () async {
                    String? path = await FilePicker.platform.saveFile(
                      dialogTitle: 'Save image',
                      fileName: '${item.name ?? "default"}.png',
                    );
                    if (path != null) {
                      await File(path).writeAsBytes(item.data);
                    }
                  },
                ),
                InkWell(
                  child: Tooltip(
                    message: "Use for prompt",
                    child: Icon(Icons.image, color: Colors.white),
                  ),
                  onTap: () async {
                    AppState provider = Inherited.of(context)!;
                    var image = await decodeImageFromList(item.data);
                    provider.nodeController.addNode(ImageNode(data: item.data, image: image), Offset(100, 100));
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

  Widget gifView(PromptData item) {
    return Stack(
      children: [
        Image.memory(item.data),
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
                    data.removeWhere((img) => img.key == item.key);
                    item.delete();
                    setState(() {});
                  },
                ),
                InkWell(
                  child: Tooltip(
                    message: "Save",
                    child: Icon(Icons.save, color: Colors.white),
                  ),
                  onTap: () async {
                    String? path = await FilePicker.platform.saveFile(
                      dialogTitle: 'Save image',
                      fileName: '${item.name ?? "default"}.gif',
                    );
                    if (path != null) {
                      await File(path).writeAsBytes(item.data);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget galleryView() {
    return Expanded(
      child: ResponsiveGridList(
        horizontalGridSpacing: 16,
        verticalGridSpacing: 16,
        horizontalGridMargin: 50,
        verticalGridMargin: 50,
        minItemWidth: 150,
        minItemsPerRow: 2,
        maxItemsPerRow: 5,
        listViewBuilderOptions: ListViewBuilderOptions(),
        children: data.indexed.map((image) {
          return InkWell(
            onTap: () => openGallery(image.$2, image.$1),
            child: image.$2.mimeType == "gif" ? gifView(image.$2) : imageView(image.$2),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppState provider = Inherited.of(context)!;
    ThemeData theme = Theme.of(context);
    LazyBox<PromptData>? box = provider.boxMap[widget.path];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          if (data.isEmpty) Text("Folder is empty", style: theme.textTheme.bodyLarge),
          if (data.isNotEmpty) galleryView(),
          if (box != null && box.length > itemsOnPage)
            Container(
              width: 700,
              padding: EdgeInsetsGeometry.only(top: 10, bottom: 10),
              child: Pagination(
                activePage: activePage,
                totalPages: (box.length / itemsOnPage).ceil(),
                onSelect: (page) => loadContent(page),
              ),
            ),
        ],
      ),
    );
  }
}
