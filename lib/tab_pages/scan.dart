import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheet_music_app/main.dart';
import 'package:sheet_music_app/state.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  ScanTabState createState() => ScanTabState();
}

class ScanTabState extends State<ScanTab> {
  //Object for controlling the Camera
  late CameraController _controller;
  //Future for initialising the camera and the camera controller
  late Future<Future<void>> _cameraInitialiser;

  @override
  void initState() {
    super.initState();
    //Get the camera and initialise the camera controller with it
    _cameraInitialiser = availableCameras().then((cameras) {
      _controller = CameraController(cameras.first, ResolutionPreset.max,
          enableAudio: false);
      return _controller.initialize();
    });
  }

  //Destroy the camera resource when the widget is closed
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Show a loading screen until the available cameras are found
    return FutureBuilder(
      future: _cameraInitialiser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          //Show a loading screen until the camera is initialised
          return FutureBuilder(
            future: snapshot.data,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Camera(controller: _controller);
              } else {
                //Loading screen
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        } else {
          //Loading Screen
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class Camera extends ConsumerStatefulWidget {
  const Camera({
    super.key,
    required this.controller,
  });

  final CameraController controller;

  @override
  ConsumerState<Camera> createState() => _CameraState();
}

class _CameraState extends ConsumerState<Camera> {
  //Whether the flash is on or not
  var flash = false;
  final takingPicture = ValueNotifier(false);
  //Index into the temporarySheetMusicImages array, representing
  //which parts/no. of parts that are being captured
  var partNumber = 0;

  void toggleFlash() {
    setState(() {
      flash = !flash;
    });
    if (flash) {
      widget.controller.setFlashMode(FlashMode.always);
    } else {
      widget.controller.setFlashMode(FlashMode.off);
    }
  }

  Future<String> takePicture() async {
    //Lock taking picture
    takingPicture.value = true;
    //Take picture and store reference in image
    final image = await widget.controller.takePicture();
    // //Get path to application documents directory
    // final dir = await getApplicationDocumentsDirectory();
    // //Save image to the path
    // final imagePath = path.join(dir.path, 'img.png');
    // await image.saveTo(imagePath);
    //Unlock taking picture
    takingPicture.value = false;
    //Return path for testing
    return image.path;
  }

  void incrementPartNumber() {
    setState(() {
      partNumber += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    //Choose the biggest scale between the phone height and camera
    //height or the phone width and camera width - the biggest one
    //will always ensure all white gaps are filled
    final scale = max(
        (MediaQuery.sizeOf(context).height + 2) /
            widget.controller.value.previewSize!.height,
        MediaQuery.sizeOf(context).width /
            widget.controller.value.previewSize!.width);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        //Make CameraPreview fullscreen
        Transform.scale(
          scale: scale,
          child: CameraPreview(widget.controller),
        ),

        //Detect currently takingPicture or not
        ValueListenableBuilder(
          valueListenable: takingPicture,
          //The button for taking pictures
          builder: (context, pictureBeingTaken, _) => CameraCaptureButton(
              pictureBeingTaken: pictureBeingTaken,
              takePicture: takePicture,
              incrementPartNumber: incrementPartNumber,
              partNumber: partNumber),
        ),

        //Make sure flash button is underneath notification bar
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            //Display correct flash icon depending on whether it is on or off
            child: flash
                ? IconButton(
                    onPressed: toggleFlash,
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                  )
                : IconButton(
                    onPressed: toggleFlash,
                    icon: const Icon(Icons.flash_off, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}

class CameraCaptureButton extends ConsumerWidget {
  final bool pictureBeingTaken;
  final Future<String> Function() takePicture;
  final void Function() incrementPartNumber;
  final int partNumber;
  const CameraCaptureButton(
      {super.key,
      required this.pictureBeingTaken,
      required this.takePicture,
      required this.incrementPartNumber,
      required this.partNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      //Disable button if a picture is being taken
      onPressed: !pictureBeingTaken
          ? () {
              //Take picture
              takePicture().then((path) {
                //Add image to temporarySheetMusicImages
                ref
                    .read(temporarySheetMusicImages.notifier)
                    .state[partNumber]
                    .add(Image.file(File(path)));
                //Log the entire list for testing purposes
                dev.log(
                  "${ref.read(temporarySheetMusicImages).map((e) {
                    return e.map((e) => e.toStringShort());
                  })}",
                  name: "Sheet Music Images",
                );
                //Show dialog for next required actions
                showDialog(
                  //Prevent the dialog from being dismissed by pressing
                  //outside it
                  barrierDismissible: false,
                  context: context,
                  builder: (builder) {
                    return AlertDialog(
                      title: const Text("Photo Taken"),
                      content: const Text(
                          "Do you want to continue adding to the current part, add to a new on or have you finished?"),
                      actions: [
                        //Button to continue scanning pictures for the
                        //current part
                        TextButton(
                          onPressed: () {
                            //Exit dialog to show camera
                            Navigator.of(context).pop();
                          },
                          child: const Text("Continue"),
                        ),
                        //Button to make a new part
                        TextButton(
                          onPressed: () {
                            //Increment the current part number being added to
                            incrementPartNumber();
                            //Add new part list
                            ref
                                .read(temporarySheetMusicImages.notifier)
                                .state
                                .add([]);
                            //Exit dialog to show camera
                            Navigator.of(context).pop();
                          },
                          child: const Text("New Part"),
                        ),
                        //Button to complete capturing and start scanning
                        TextButton(
                          onPressed: () {
                            //Exit dialog
                            Navigator.of(context).pop();
                            //Show view tab
                            ref.read(currentPageProvider.notifier).state =
                                AppPages.viewTab;
                          },
                          child: const Text("Done"),
                        ),
                      ],
                    );
                  },
                );
              });
            }
          : () {},
      icon: const Icon(
        Icons.circle_outlined,
        size: 120,
        color: Colors.white,
      ),
    );
  }
}
