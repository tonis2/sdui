import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
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
        title: Text(
          "Enter password to unlock storage",
          style: theme.textTheme.titleSmall,
        ),
        content: SizedBox(
          width: 600,
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 10,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  label: Text("Password", style: theme.textTheme.bodyMedium),
                ),
                onChanged: (value) => password = value,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 25,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        theme.colorScheme.secondary,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, password),
                    child: Text("Submit", style: theme.textTheme.bodyMedium),
                  ),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        theme.colorScheme.secondary,
                      ),
                    ),
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
      provider.boxMap[folder] = await provider.openProjectLazyBox<PromptData>(
        folder,
        cipher: HiveAesCipher(generateEncryptionKey(response.toString())),
      );
    }
  } catch (err) {
    print(err.toString());
  }
}

void unlockFolder(BuildContext context, String folder) {
  AppState provider = Inherited.of(context)!;
  var folders = provider.folders.values.where(
    (Folder item) => item.name == folder,
  );

  // Folder is encrypted, ask user to unlock it and then cache it
  if (folders.isNotEmpty &&
      folders.first.encrypted &&
      provider.boxMap[folder] == null) {
    showPasswordDialog(context, folders.first.name);
  }

  if (folders.isNotEmpty &&
      !folders.first.encrypted &&
      provider.boxMap[folder] == null) {
    provider.openProjectLazyBox<PromptData>(folder).then((box) {
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
  void dispose() {
    // Leaving the folder should hand the decoded images back to the GPU/OS.
    // Image.memory keeps every decoded frame in Flutter's app-global
    // ImageCache (keyed by the Uint8List), so unless we evict them here they
    // stay resident on the GPU until the process exits — which is exactly the
    // "images never released" leak. Children unmount before this parent State
    // is disposed, so their image-stream listeners are already gone; evicting
    // now drops the last reference and frees the texture.
    _logCacheStats('dispose: before');
    _evictImages(data);
    // Eviction only removes the keep-alive (LRU) entry. Any image still tracked
    // as "live" keeps an ImageStreamCompleterHandle pinning its ui.Image (and
    // its GPU texture). Since nothing under this route should be listening once
    // we're disposing, drop the live set so those textures become collectable.
    PaintingBinding.instance.imageCache.clearLiveImages();
    _logCacheStats('dispose: after');
    data = [];
    super.dispose();
  }

  /// Drop [items]' decoded textures from the global image cache. Safe to call
  /// while the widgets are still mounted: the eviction removes the cache's
  /// keep-alive handle, and the texture is freed once the widgets stop
  /// listening on the next rebuild.
  void _evictImages(List<PromptData> items) {
    for (final item in items) {
      // The resized grid thumbnail and any full-res copy the gallery decoded
      // are stored under separate cache keys, so drop both.
      _thumbProvider(item).evict();
      MemoryImage(item.data).evict();
    }
  }

  /// Debug-only snapshot of the global image cache so we can see, in the run
  /// log, whether leaving the folder actually shrinks it. Remove once the
  /// memory behaviour is confirmed.
  void _logCacheStats(String when) {
    if (kReleaseMode) return;
    final ImageCache c = PaintingBinding.instance.imageCache;
    debugPrint(
      '[FolderView] $when — cached: ${c.currentSize} imgs / '
      '${(c.currentSizeBytes / 1048576).toStringAsFixed(1)} MB, '
      'live: ${c.liveImageCount}, pending: ${c.pendingImageCount}',
    );
  }

  // Grid thumbnails only ever render a few hundred pixels wide, so decode them
  // at a reduced resolution instead of uploading each full-size image to the
  // GPU (a 1024px source then costs ~1/4 the texture memory). Full resolution
  // is used only in [openGallery]. Kept as a fixed target rather than a
  // devicePixelRatio-derived one so the ResizeImage cache key built here always
  // matches the one [_evictImages] reconstructs when releasing memory.
  // allowUpscaling: false leaves already-small images untouched. 400px keeps
  // grid tiles (~150-400px wide) crisp while downscaling the common 512/768/
  // 1024px sources — a 1024px image then costs ~6x less texture memory.
  static const int _thumbCacheWidth = 400;

  ImageProvider _thumbProvider(PromptData item) =>
      ResizeImage(MemoryImage(item.data), width: _thumbCacheWidth, allowUpscaling: false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if the box has new items since last load
    AppState provider = Inherited.of(context)!;
    LazyBox<PromptData>? box = provider.boxMap[widget.path];
    if (box != null &&
        box.length != _lastKnownBoxLength &&
        _lastKnownBoxLength > 0) {
      loadContent(activePage);
    }
  }

  void loadContent(int page) async {
    AppState provider = Inherited.of(context)!;
    activePage = page;
    // Release the current page's decoded images before loading the next one,
    // otherwise paging through a folder piles every page's textures onto the
    // GPU instead of just the page you're looking at.
    _evictImages(data);
    data = [];

    int startIndex = (page - 1) * itemsOnPage;

    LazyBox<PromptData>? box = provider.boxMap[widget.path];

    // Folder not loaded, load it to cache
    if (box == null &&
        await Hive.boxExists("folders", path: provider.projectPath)) {
      Folder folder = provider.folders.values.firstWhere(
        (item) => item.name == widget.path,
      );
      if (folder.encrypted) {
        await showPasswordDialog(context, widget.path);
      } else {
        provider.boxMap[widget.path] = await provider
            .openProjectLazyBox<PromptData>(widget.path);
      }
    }

    box = provider.boxMap[widget.path];
    var keys = box?.keys.toList().getRange(
      startIndex,
      min(startIndex + itemsOnPage, box.length),
    );

    // Load images from keys
    if (keys != null) {
      for (var key in keys) {
        var item = await box?.get(key);
        if (item != null) data.add(item);
      }
    }

    _lastKnownBoxLength = box?.length ?? 0;
    // This runs after awaits, so the page may have been left mid-load; don't
    // setState (and don't re-decode images) on a disposed State.
    if (!mounted) return;
    _logCacheStats('loaded page $page');
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
    TextStyle? textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: const Color.fromRGBO(255, 255, 255, 0.9),
    );

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
                            SelectableText(
                              item.prompt?.prompt ?? "-",
                              style: textStyle,
                            ),
                            Row(
                              mainAxisAlignment: .center,
                              spacing: 5,
                              children: [
                                Text(
                                  "Steps: ${item.prompt?.steps},",
                                  style: textStyle,
                                ),
                                Text(
                                  "Sampler: ${item.prompt?.sampler},",
                                  style: textStyle,
                                ),
                                Text(
                                  "Denoise: ${item.prompt?.noiseStrenght},",
                                  style: textStyle,
                                ),
                                Text(
                                  "Width: ${item.prompt?.width}, Height: ${item.prompt?.height}",
                                  style: textStyle,
                                ),
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
        Image(image: _thumbProvider(item)),
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
                    // Cascade each added image node below the previous one instead
                    // of dropping them all at the same spot. Stacked nodes share an
                    // identical offset, and the prompt's spatial ordering ties on
                    // equal coordinates and falls back to draw order — which is what
                    // scrambled init_images and forced a manual reconnect. Distinct,
                    // increasing dy gives every node a stable top-to-bottom slot.
                    final existing = provider.nodeController.nodes.values
                        .whereType<ImageNode>()
                        .length;
                    final position = Offset(100, 100 + existing * 120.0);
                    // Copy the bytes so the node owns its own buffer instead of
                    // sharing the gallery item's Uint8List. Otherwise the canvas
                    // node stays tied to a Hive record you can delete out from
                    // under it, which is what made deletes feel like they broke
                    // the graph.
                    provider.nodeController.addNode(
                      ImageNode(data: item.data.sublist(0), image: image),
                      position,
                    );
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
        Image(image: _thumbProvider(item)),
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
            child: image.$2.mimeType == "gif"
                ? gifView(image.$2)
                : imageView(image.$2),
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
          if (data.isEmpty)
            Text("Folder is empty", style: theme.textTheme.bodyLarge),
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
