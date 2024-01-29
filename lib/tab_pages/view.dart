import 'dart:developer' as dev;
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
  // late Future<List<List<Note?>>> tempFuture;
  late Future<void> f;
  final midi = FlutterMidi();
  late Future<(List<List<Note>>, List<List<File>>)> music;

  @override
  void initState() {
    super.initState();
    f = rootBundle.load("sf2/piano.sf2").then((bytes) async {
      await midi.prepare(sf2: bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sheetMusic = ref.watch(sheetMusicProvider.notifier);
    final id = sheetMusic.getSheetMusicId();
    if (id != null) {
      ref.watch(databaseProvider.future).then((db) async {
        var model = Map<String, Object?>.from((await db
            .query("SheetMusic", where: "id = ?", whereArgs: [id]))[0]);
        model["dateViewed"] = DateTime.now().millisecondsSinceEpoch;
        await db.update("SheetMusic", model, where: "id = ?", whereArgs: [id]);
      });
    }

    music = sheetMusic.getMusic();

    //Render each part using the Part Widget
    return FutureBuilder(
      future: music,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final (notes, parts) = snapshot.data!;
          final player = Player(notes, midi, ref);
          dev.log(notes.map((e) => e.map((e) => e.pitch.name)).toString(),
              name: "NOTES");
          final nonEmptyParts =
              parts.where((element) => element.isNotEmpty).toList();
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemBuilder: (context, partNo) =>
                          Part(nonEmptyParts[partNo], partNo),
                      itemCount: nonEmptyParts.length,
                    ),
                  ),
                  Controls(player: player)
                ],
              ),
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
          "Part ${partNo + 1}",
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
