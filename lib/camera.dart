import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_camera_task/random_image_url.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import 'camera_view.dart';

class CameraScreen extends StatefulWidget {
  late List<CameraDescription> cameras;

  CameraScreen(this.cameras, {super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late CameraController controller;
  XFile? pictureFile;
  late Future<void> cameraValue;
  bool flash = false;
  late File capturedImages;
  bool iscamerafront = true;
  double transform = 0;
  int selectedCamera = 0;

  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeCamera(selectedCamera);
    _fetchAssets();
  }

  initializeCamera(int cameraIndex) async {
    controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.cameras[cameraIndex],
      // Define the resolution to use.
      ResolutionPreset.medium,
    );
    controller.setFlashMode(FlashMode.off);
    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = controller.initialize();
  }

  bool expanded = false;
  File? file;
  List<AssetEntity> assets = [];

  _fetchAssets() async {
    final albums = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
        filterOption: FilterOptionGroup(imageOption: FilterOption()));
    print(albums);
    final recentAlbum = albums.first;
    // List<AssetEntity> recentAssets = [];
    // await albums.forEach((element) async{recentAssets.addAll(await element.getAssetListRange(start: 0, end: 10000));});
    final recentAssets = await recentAlbum.getAssetListRange(
      start: 0, // start at index 0
      end: 500,
    );

    setState(() {
      assets = recentAssets;
      // image = assets[0].file;
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  double opacity = 0.0;
  double gallheight = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        FutureBuilder(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return AspectRatio(
                    aspectRatio: MediaQuery.of(context).size.aspectRatio,
                    child: CameraPreview(controller));
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            }),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.12,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (!expanded) if (details.delta.dy < 0) {
                setState(() {
                  expanded = true;
                  opacity = 1.0;
                  gallheight = MediaQuery.of(context).size.height * 0.96;
                });
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  CupertinoIcons.chevron_up,
                  color: Colors.white,
                  size: 22,
                ),
                Container(
                  color: Colors.transparent,
                  height: MediaQuery.of(context).size.height * 0.1,
                  width: MediaQuery.of(context).size.width,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, i) {
                      return FutureBuilder<Uint8List?>(
                        future: assets[i].thumbnailData,
                        builder: (_, snapshot) {
                          final bytes = snapshot.data;
                          if (bytes == null) return CircularProgressIndicator();
                          return InkWell(
                            onTap: () async {
                              file = await assets[i].file;
                              capturedImages = file!;
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (builder) => CameraViewPage(
                                            path: capturedImages.path,
                                          )));
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.height * 0.1,
                              padding: EdgeInsets.all(4),
                              child: Image.memory(bytes, fit: BoxFit.cover),
                            ),
                          );
                        },
                      );
                    },
                    itemCount: assets.length,
                  ),
                )
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.only(top: 5),
            width: MediaQuery.of(context).size.width,
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              // _buildGalleryBar(),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      flash ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        flash = !flash;
                      });
                      flash
                          ? controller.setFlashMode(FlashMode.torch)
                          : controller.setFlashMode(FlashMode.off);
                    },
                  ),
                  InkWell(
                    onTap: () async {
                      // takePhoto(context);
                      await _initializeControllerFuture;
                      var xFile = await controller.takePicture();
                      setState(() {
                        capturedImages = File(xFile.path);
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (builder) => CameraViewPage(
                                    path: capturedImages.path,
                                  )));
                    },
                    child: Icon(
                      Icons.panorama_fish_eye,
                      color: Colors.white,
                      size: 70,
                    ),
                  ),
                  IconButton(
                    icon: Transform.rotate(
                      angle: transform,
                      child: Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    onPressed: () async {
                      setState(() {
                        iscamerafront = !iscamerafront;
                      });
                      int cameraPos = iscamerafront ? 0 : 1;
                      controller = CameraController(
                          widget.cameras[cameraPos], ResolutionPreset.high);
                      cameraValue = controller.initialize();
                    },
                  )
                ],
              ),
              const SizedBox(
                height: 4,
              ),
              const Text(
                "Hold for video, tap for photo",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              )
            ]),
          ),
        ),
      ]),
    );
  }

  // void takePhoto(BuildContext context) async {
  //   final path =
  //       join((await getTemporaryDirectory()).path, "${DateTime.now()}.png");
  //   pictureFile = await controller.takePicture();
  //   // if (pictureFile != null) Image.file(File(pictureFile!.path));
  // }

  // Widget _buildGalleryBar() {
  //   final barHeight = 90.0;
  //   final vertPadding = 10.0;

  //   return Container(
  //       height: barHeight,
  //       child: ListView.builder(
  //         padding: EdgeInsets.symmetric(vertical: vertPadding),
  //         scrollDirection: Axis.horizontal,
  //         itemBuilder: ((context, index) {
  //           return Container(
  //             padding: EdgeInsets.only(right: 5.0),
  //             width: 70.0,
  //             height: barHeight - vertPadding * 2,
  //             child: Image(
  //               image: randomImageUrl(),
  //               fit: BoxFit.cover,
  //             ),
  //           );
  //         }),
  //       ));
  // }
}
