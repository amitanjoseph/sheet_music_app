import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheet_music_app/pigeon/scanner.dart';
import 'package:flutter_midi/flutter_midi.dart';
import 'package:sheet_music_app/state.dart';
import 'package:sheet_music_app/utils/player.dart';

import 'view_controls.dart';

class ViewTab extends ConsumerStatefulWidget {
  const ViewTab({super.key});

  @override
  ConsumerState<ViewTab> createState() => _ViewTabState();
}

class _ViewTabState extends ConsumerState<ViewTab> {
  //Object to handle actually playing notes from midi numbers
  final midi = FlutterMidi();
  //Future to store music and images
  late Future<(List<List<Note>>, List<List<File>>)> music;

  @override
  void initState() {
    super.initState();
    //Load soundfont piano sound for midi object to play
    rootBundle.load("sf2/piano.sf2").then((bytes) async {
      await midi.prepare(sf2: bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    //Provider storing sheet music state
    final sheetMusic = ref.watch(sheetMusicProvider.notifier);
    //If sheet music was previously saved
    final id = sheetMusic.getSheetMusicId();
    if (id != null) {
      //Update dateViewed to today
      ref.watch(databaseProvider.future).then((db) async {
        var model = Map<String, Object?>.from((await db
            .query("SheetMusic", where: "id = ?", whereArgs: [id]))[0]);
        model["dateViewed"] = DateTime.now().millisecondsSinceEpoch;
        await db.update("SheetMusic", model, where: "id = ?", whereArgs: [id]);
      });
    }

    //Get music (either saved or unsaved)
    music = sheetMusic.getMusic();

    //Render each part using the Part Widget when music has loaded
    return FutureBuilder(
      future: music,
      builder: (context, snapshot) {
        //If music has loaded
        if (snapshot.connectionState == ConnectionState.done) {
          //Get notes and image parts
          final (notes, parts) = snapshot.data!;
          //Initialise player
          final player = Player(notes, midi, ref);
          //Get all image parts that are non-empty
          final nonEmptyParts =
              parts.where((element) => element.isNotEmpty).toList();
          //Render widgets (Stack used to allow save button to show on top)
          return Stack(
            children: [
              //Place for parts
              Column(
                children: [
                  //Show each of the parts
                  Expanded(
                    child: ListView.builder(
                      itemBuilder: (context, partNo) =>
                          Part(nonEmptyParts[partNo], partNo),
                      itemCount: nonEmptyParts.length,
                    ),
                  ),
                  //Render the controls for playback
                  Controls(player: player)
                ],
              ),
              //If sheet music is unsaved, show save button
              if (sheetMusic.stateIsUnsaved())
                SafeArea(
                  child: Align(
                      alignment: Alignment.topRight,
                      child: SaveButton(
                        parts: notes,
                        partImages: nonEmptyParts,
                      )),
                )
            ],
          );
        } else {
          //Loading screen
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

//Renders each part as a list of images with a title as the Part No.
class Part extends StatelessWidget {
  //Images for this part
  final List<File> images;
  //Which part it is
  final int partNo;
  const Part(this.images, this.partNo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        //Part Title
        Text(
          "Part ${partNo + 1}",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        //List of Images
        ListView.builder(
          itemBuilder: (context, index) {
            return Image.file(images[index]);
          },
          itemCount: images.length,
          //Prevents needing to scroll through each separate part
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
        )
      ],
    );
  }
}
