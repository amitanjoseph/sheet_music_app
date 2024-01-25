import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sheet_music_app/data_models/models.dart' as models;
import 'package:sheet_music_app/pigeon/scanner.dart';
import 'package:sheet_music_app/state.dart';
import 'package:sheet_music_app/utils/music_utils.dart';
import 'package:sheet_music_app/utils/player.dart';

class SaveButton extends ConsumerStatefulWidget {
  final List<List<Note>> parts;
  final List<List<File>> partImages;
  const SaveButton({super.key, required this.parts, required this.partImages});

  @override
  ConsumerState<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends ConsumerState<SaveButton> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final composerController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
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
                      controller: nameController,
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
                      controller: composerController,
                      decoration: const InputDecoration(labelText: "Composer"),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final name = nameController.text;
                      final composer = composerController.text == ""
                          ? null
                          : composerController.text;
                      final dateViewed = DateTime.now().millisecondsSinceEpoch;
                      final dateCreated = DateTime.now().millisecondsSinceEpoch;
                      final (tempo, keySig) = ref.watch(controlsState);
                      final file = join(
                          (await getApplicationDocumentsDirectory()).path,
                          "$name.smn");
                      await File(file).writeAsBytes(makeSMN(widget.parts));
                      db.when(
                        data: (database) async {
                          final id = await models.SheetMusicModel(
                            name: name,
                            file: file,
                            composer: composer,
                            dateViewed: dateViewed,
                            dateCreated: dateCreated,
                            folder: null,
                            keySig: keySig.toString(),
                            tempo: tempo,
                          ).insert(database);
                          for (final (partNo, part)
                              in widget.partImages.indexed) {
                            for (final (seqNo, image) in part.indexed) {
                              await models.ImageModel(
                                      sheetMusicId: id,
                                      image: image.path,
                                      part: partNo,
                                      seqNo: seqNo)
                                  .insert(database);
                            }
                          }
                          dev.log("done");
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        error: (error, stackTrace) {
                          dev.log("$error", name: "ERROR");
                          dev.log("$stackTrace", name: "STACKTRACE");
                        },
                        loading: () {
                          dev.log("loading db");
                        },
                      );
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

class Controls extends ConsumerWidget {
  const Controls({
    super.key,
    required this.player,
  });

  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (tempo, keySig) = ref.watch(controlsState);
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
                ref.read(controlsState.notifier).state = (tempo, value!);
                // player.keysig = value!;
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
              initialSelection: 120,
              label: const Text("Tempo"),
              width: 120,
              onSelected: (value) {
                ref.read(controlsState.notifier).state = (value!, keySig);
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
