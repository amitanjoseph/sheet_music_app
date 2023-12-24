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
          final player = Player(snapshot.data!, midi, 120);
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
              const SafeArea(
                child:
                    Align(alignment: Alignment.topRight, child: SaveButton()),
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

class SaveButton extends ConsumerStatefulWidget {
  const SaveButton({super.key});

  @override
  ConsumerState<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends ConsumerState<SaveButton> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.save_outlined),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Save File?"),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final matches = RegExp("([^ A-Za-z0-9_-])")
                              .allMatches(value)
                              .fold(<String>[], (previousValue, element) {
                            final string =
                                value.substring(element.start, element.end);
                            dev.log(string, name: "REGEX MATCHES");
                            return previousValue.contains(string)
                                ? previousValue
                                : previousValue + [string];
                          });
                          return matches.isEmpty
                              ? null
                              : "Invalid Characters: ${matches.join(" ")}";
                        }
                        return "Name must be not empty.";
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Composer"),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      dev.log("SAVEVEVEVE");
                    }
                  },
                  child: const Text("Save"),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel")),
              ],
            );
          },
        );
      },
    );
  }
}

class Controls extends StatelessWidget {
  const Controls({
    super.key,
    required this.player,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.lightGreen[50],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DropdownMenu(
              initialSelection: KeySig.C,
              label: const Text("Key Signature"),
              onSelected: (value) {
                player.keysig = value!;
              },
              width: 120,
              dropdownMenuEntries: KeySig.values.map((e) {
                var name = e.name;
                name = name.replaceAll('Flat', '♭');
                name = name.replaceAll('Sharp', '♯');
                return DropdownMenuEntry(value: e, label: name);
              }).toList(),
            ),
            PlaybackButton(player: player),
            DropdownMenu(
              initialSelection: 120.0,
              label: const Text("Tempo"),
              width: 120,
              onSelected: (value) {
                player.tempo = value!.toInt();
              },
              dropdownMenuEntries: List.generate(25, (index) => 60 + index * 5)
                  .map((i) => DropdownMenuEntry(value: i, label: "♩ = $i"))
                  .toList(),
            ),
          ],
        ),
      ),
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

  int tempo;
  bool paused = false;
  KeySig keysig = KeySig.C;
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
    final pitch = transposedPitchToMidi(note.pitch, keysig);
    final length = lengthToBeats(note.length);
    midi.playMidiNote(midi: pitch);
    await Future.delayed(Duration(
        milliseconds: (bpmToSecondsPerBeat(tempo) * length * 1000).round()));
  }
}

enum KeySigType {
  sharp,
  flat;

  static const sharps = ["F", "C", "G", "D", "A", "E", "B"];
  static const flats = ["B", "E", "A", "D", "G", "C", "F"];
}

enum KeySig {
  C(KeySigType.sharp, 0),
  G(KeySigType.sharp, 1),
  D(KeySigType.sharp, 2),
  A(KeySigType.sharp, 3),
  E(KeySigType.sharp, 4),
  B(KeySigType.sharp, 5),
  FSharp(KeySigType.sharp, 6),
  CSharp(KeySigType.sharp, 7),
  F(KeySigType.flat, 1),
  BFlat(KeySigType.flat, 2),
  EFlat(KeySigType.flat, 3),
  AFlat(KeySigType.flat, 4),
  DFlat(KeySigType.flat, 5),
  GFlat(KeySigType.flat, 6);

  final KeySigType type;
  final int numberOfAccidentals;

  const KeySig(this.type, this.numberOfAccidentals);
}

int transposedPitchToMidi(Pitch pitch, KeySig scale) {
  final [note, number] = pitch.name.split('');
  final noteToMidi = {
    "A": 21,
    "B": 23,
    "C": 24,
    "D": 26,
    "E": 28,
    "F": 29,
    "G": 31,
  };

  final offset =
      note != 'A' && note != 'B' ? int.parse(number) - 1 : int.parse(number);

  final midi = noteToMidi[note]! + 12 * offset;
  switch (scale.type) {
    case KeySigType.sharp:
      final sharps = KeySigType.sharps.take(scale.numberOfAccidentals).toList();
      return midi + (sharps.contains(note) ? 1 : 0);
    case KeySigType.flat:
      final flats = KeySigType.flats.take(scale.numberOfAccidentals).toList();
      return midi + (flats.contains(note) ? -1 : 0);
  }
}
