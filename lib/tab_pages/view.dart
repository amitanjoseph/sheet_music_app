import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sheet_music_app/pigeon/scanner.dart';
import 'package:sheet_music_app/state.dart';
import 'package:flutter_midi/flutter_midi.dart';

class ViewTab extends ConsumerStatefulWidget {
  const ViewTab({super.key});

  @override
  ConsumerState<ViewTab> createState() => _ViewTabState();
}

double bpmToSecondsPerBeat(int bpm) {
  return 60 / bpm;
}

int pitchToMidi(Pitch pitch) {
  switch (pitch) {
    case Pitch.A0:
      return 21;
    case Pitch.B0:
      return 23;
    case Pitch.C1:
      return 24;
    case Pitch.D1:
      return 26;
    case Pitch.E1:
      return 28;
    case Pitch.F1:
      return 29;
    case Pitch.G1:
      return 31;
    case Pitch.A1:
      return 33;
    case Pitch.B1:
      return 35;
    case Pitch.C2:
      return 36;
    case Pitch.D2:
      return 38;
    case Pitch.E2:
      return 40;
    case Pitch.F2:
      return 41;
    case Pitch.G2:
      return 43;
    case Pitch.A2:
      return 45;
    case Pitch.B2:
      return 47;
    case Pitch.C3:
      return 48;
    case Pitch.D3:
      return 50;
    case Pitch.E3:
      return 52;
    case Pitch.F3:
      return 53;
    case Pitch.G3:
      return 55;
    case Pitch.A3:
      return 57;
    case Pitch.B3:
      return 59;
    case Pitch.C4:
      return 60;
    case Pitch.D4:
      return 62;
    case Pitch.E4:
      return 64;
    case Pitch.F4:
      return 65;
    case Pitch.G4:
      return 67;
    case Pitch.A4:
      return 69;
    case Pitch.B4:
      return 71;
    case Pitch.C5:
      return 72;
    case Pitch.D5:
      return 74;
    case Pitch.E5:
      return 76;
    case Pitch.F5:
      return 77;
    case Pitch.G5:
      return 79;
    case Pitch.A5:
      return 81;
    case Pitch.B5:
      return 83;
    case Pitch.C6:
      return 84;
    case Pitch.D6:
      return 86;
    case Pitch.E6:
      return 88;
    case Pitch.F6:
      return 89;
    case Pitch.G6:
      return 91;
    case Pitch.A6:
      return 93;
    case Pitch.B6:
      return 95;
    case Pitch.C7:
      return 96;
    case Pitch.D7:
      return 98;
    case Pitch.E7:
      return 100;
    case Pitch.F7:
      return 101;
    case Pitch.G7:
      return 103;
    case Pitch.A7:
      return 105;
    case Pitch.B7:
      return 107;
    case Pitch.C8:
      return 108;
  }
}

class _ViewTabState extends ConsumerState<ViewTab> {
  // late Future<List<List<Note?>>> tempFuture;
  late Future<void> f;
  late Future<List<Note?>> notes;
  final midi = FlutterMidi();
  final tempo = bpmToSecondsPerBeat(100);

  @override
  void initState() {
    f = rootBundle.load("sf2/piano.sf2").then((bytes) async {
      await midi.prepare(sf2: bytes);
    });

    // midi.unmute().then(
    //   (value) async {
    //     final bytes = await rootBundle.load("sf2/piano.sf2");
    //     midi.prepare(sf2: bytes);
    //     return midi;
    //   },
    // );

    dev.log("HERE");

    //Get first image in temporarySheetMusicImageProvider and send it
    // tempFuture = Future.wait(
    //     ref.read(temporarySheetMusicImageProvider).map((part) async {
    //   final notes = <List<Note?>>[];
    //   for (final i in part.map((e) => ScannerAPI().scan(e.path))) {
    //     notes.add(await i);
    //   }
    //   return notes.expand((element) => element).toList();
    // }));

    // Create a temporary file to save the processed image
    notes = getTemporaryDirectory().then((value) async {
      final temp = await value.createTemp();
      final path = File("${temp.path}/sheet_music.jpg");
      return (await ScannerAPI().scan(path.path));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //The nested list of parts and images
    final parts = ref.read(temporarySheetMusicImageProvider);

    //Render each part using the Part Widget
    return FutureBuilder(
      future: notes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, partNo) =>
                      Part(parts[partNo], partNo + 1),
                  itemCount: parts.length,
                ),
              ),
              SizedBox(
                height: 120,
                child: IconButton(
                  onPressed: () async {
                    for (final i in snapshot.data!) {
                      if (i != null) {
                        dev.log(
                            "${i.pitch.name}: ${i.pitch.index}, ${i.length.name}",
                            name: "[NOTE]");
                        midi.playMidiNote(midi: pitchToMidi(i.pitch));
                        double beats = 1;
                        switch (i.length) {
                          case Length.breve:
                            beats = 8;
                            break;
                          case Length.semibreve:
                            beats = 4;
                            break;
                          case Length.minim:
                            beats = 2;
                            break;
                          case Length.crotchet:
                            beats = 1;
                            break;
                          case Length.quaver:
                            beats = 0.5;
                            break;
                          case Length.semiquaver:
                            beats = 0.25;
                            break;
                          case Length.demisemiquaver:
                            beats = 0.125;
                            break;
                          case Length.hemidemisemiquaver:
                            beats = 0.0625;
                            break;
                        }
                        await Future.delayed(Duration(
                            milliseconds: (tempo * beats * 1000).round()));
                      }
                    }
                    dev.log("play");
                  },
                  icon: Icon(
                    Icons.play_arrow_outlined,
                    size: 100,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
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
