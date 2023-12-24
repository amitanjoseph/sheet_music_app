import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheet_music_app/pigeon/scanner.dart';
import 'package:sheet_music_app/state.dart';
import 'package:flutter_midi/flutter_midi.dart';
import 'package:sheet_music_app/utils/player.dart';

import 'view_controls.dart';

class ViewTab extends ConsumerStatefulWidget {
  const ViewTab({super.key});

  @override
  ConsumerState<ViewTab> createState() => _ViewTabState();
}

class _ViewTabState extends ConsumerState<ViewTab> {
  // late Future<List<List<Note?>>> tempFuture;
  late Future<void> f;
  final midi = FlutterMidi();
  late List<List<File>> parts;
  late Future<List<List<Note>>> music;

  @override
  void initState() {
    super.initState();
    f = rootBundle.load("sf2/piano.sf2").then((bytes) async {
      await midi.prepare(sf2: bytes);
    });

    parts = ref.read(temporarySheetMusicImageProvider);

    // Create a temporary file to save the processed image
    music = Future.wait(parts.map((part) async {
      return (await Future.wait(part.map((line) async {
        return (await ScannerAPI().scan(line.path));
      })))
          .expand((element) => element.map((e) => e!))
          .toList();
    }));
  }

  @override
  Widget build(BuildContext context) {
    //The nested list of parts and images

    //Render each part using the Part Widget
    return FutureBuilder(
      future: music,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final player = Player(snapshot.data!, midi, ref);
          dev.log(
              snapshot.data!.map((e) => e.map((e) => e.pitch.name)).toString(),
              name: "NOTES");
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemBuilder: (context, partNo) =>
                          Part(parts[partNo], partNo + 1),
                      itemCount: parts.length,
                    ),
                  ),
                  Controls(player: player)
                ],
              ),
              SafeArea(
                child: Align(
                    alignment: Alignment.topRight,
                    child: SaveButton(
                      parts: snapshot.data!,
                      partImages: parts,
                    )),
              )
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

//Renders each part as a list of images with a title as the Part No.
class Part extends StatelessWidget {
  final List<File> images;
  final int partNo;
  const Part(this.images, this.partNo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        //Part Title
        Text(
          "Part $partNo",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        //List of Images
        ListView.builder(
          itemBuilder: (context, index) {
            return Image.file(images[index]);
          },
          itemCount: images.length,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
        )
      ],
    );
  }
}
