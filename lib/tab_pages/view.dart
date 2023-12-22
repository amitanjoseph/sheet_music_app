import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

double lengthToBeats(Length length) {
  switch (length) {
    case Length.breve:
      return 8;
    case Length.semibreve:
      return 4;
    case Length.minim:
      return 2;
    case Length.crotchet:
      return 1;
    case Length.quaver:
      return 0.5;
    case Length.semiquaver:
      return 0.25;
    case Length.demisemiquaver:
      return 0.125;
    case Length.hemidemisemiquaver:
      return 0.0625;
  }
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
  final midi = FlutterMidi();
  final tempo = bpmToSecondsPerBeat(100);
  late List<List<File>> parts;
  late Future<List<List<Note>>> music;

  @override
  void initState() {
    f = rootBundle.load("sf2/piano.sf2").then((bytes) async {
      await midi.prepare(sf2: bytes);
    });

    parts = ref.read(temporarySheetMusicImageProvider);

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
    music = Future.wait(parts.map((part) async {
      return (await Future.wait(part.map((line) async {
        return (await ScannerAPI().scan(line.path));
      })))
          .expand((element) => element.map((e) => e!))
          .toList();
    }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //The nested list of parts and images

    //Render each part using the Part Widget
    return FutureBuilder(
      future: music,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final player = Player(snapshot.data!, midi, tempo);
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
                child: PlaybackButton(player: player),
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

class PlaybackButton extends StatefulWidget {
  const PlaybackButton({
    super.key,
    required this.player,
  });

  final Player player;

  @override
  State<PlaybackButton> createState() => _PlaybackButtonState();
}

class _PlaybackButtonState extends State<PlaybackButton> {
  var paused = true;

  void _toggle() {
    setState(() {
      paused = !paused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return paused
        ? IconButton(
            onPressed: () async {
              dev.log("play");
              _toggle();
              await widget.player.play();
            },
            icon: Icon(
              Icons.play_arrow_outlined,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
          )
        : IconButton(
            onPressed: () {
              dev.log("pause");
              _toggle();
              widget.player.pause();
            },
            icon: Icon(
              Icons.pause_outlined,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
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

extension ListGet<T> on List<T> {
  T? get(int index) => index < 0 || index >= length ? null : this[index];
}

class Player {
  final List<List<Note>> parts;
  final FlutterMidi midi;
  final double tempo;

  bool paused = false;
  List<int> currentNote;
  Player(this.parts, this.midi, this.tempo)
      : currentNote = List.generate(parts.length, (index) => 0);

  Future<void> play() async {
    paused = false;
    await Future.wait(parts.indexed.map((arg) async {
      final index = arg.$1;
      final part = arg.$2;
      for (var i = currentNote[index]; i < part.length; i++) {
        currentNote[index] = i;
        if (paused) break;
        await _playNote(part[i]);
      }
    }));
  }

  void pause() {
    paused = true;
  }

  Future<void> _playNote(Note note) async {
    final pitch = pitchToMidi(note.pitch);
    final length = lengthToBeats(note.length);
    midi.playMidiNote(midi: pitch);
    await Future.delayed(
        Duration(milliseconds: (tempo * length * 1000).round()));
  }
}
