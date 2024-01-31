import 'dart:developer' as dev;
import 'dart:io';
import 'package:archive/archive.dart';
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
  //Key for form so it is uniquely identified
  final _formKey = GlobalKey<FormState>();
  //Controllers for input fields
  final nameController = TextEditingController();
  final composerController = TextEditingController();

  //Disposal on widget closure
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
        //Show dialog to allow saving file and specifying name & composer
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Save File?"),
              //Form to allow validation of input fields
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //Name input field
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (value) {
                        //Validate name string
                        if (value != null && value.isNotEmpty) {
                          //Disallowed characters
                          final matches = RegExp("([^ A-Za-z0-9_-])")
                              .allMatches(value)
                              //Get unique list of all illegal characters in string
                              .fold(<String>[], (accum, element) {
                            //Get the illegal character
                            final string =
                                value.substring(element.start, element.end);
                            dev.log(string, name: "REGEX MATCHES");
                            //If illegal character not identified yet, add it to accum
                            return accum.contains(string)
                                ? accum
                                : accum + [string];
                          });
                          //Valid if no illegal matches were made
                          return matches.isEmpty
                              ? null
                              : "Invalid Characters: ${matches.join(" ")}";
                        }
                        return "Name must be not empty.";
                      },
                    ),
                    //Composer input field
                    TextFormField(
                      controller: composerController,
                      decoration: const InputDecoration(labelText: "Composer"),
                    )
                  ],
                ),
              ),
              actions: [
                //Save Button
                TextButton(
                  onPressed: () async {
                    //If valid
                    if (_formKey.currentState!.validate()) {
                      final name = nameController.text;
                      final composer = composerController.text == ""
                          ? null
                          : composerController.text;
                      final dateViewed = DateTime.now().millisecondsSinceEpoch;
                      final dateCreated = DateTime.now().millisecondsSinceEpoch;
                      final (tempo, keySig) = ref.watch(controlsState);
                      //Write data to SMN file and compress with bzip2
                      final file = join(
                          (await getApplicationDocumentsDirectory()).path,
                          "$name.smn");
                      final smnBytes = makeSMN(widget.parts);
                      final bzip2Bytes = BZip2Encoder().encode(smnBytes);

                      await File(file).writeAsBytes(bzip2Bytes);
                      //Add to database
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
                          //Close dialog
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        //Performs logs
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
                //Cancel Button
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

//Defines the pause/play functionality
class Controls extends ConsumerWidget {
  const Controls({
    super.key,
    required this.player,
  });

  //Object representing the music, providing handles to control playback
  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Get tempo and key signature from global state
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
            //Key Signature selector
            DropdownMenu(
              initialSelection: KeySig.C,
              label: const Text("Key Signature"),
              onSelected: (value) async {
                //Set key signature
                ref.read(controlsState.notifier).state = (tempo, value!);
              },
              width: 120,
              //Render each entry correctly
              dropdownMenuEntries: KeySig.values.map((e) {
                var name = e.name;
                name = name.replaceAll('Flat', '♭');
                name = name.replaceAll('Sharp', '♯');
                return DropdownMenuEntry(value: e, label: name);
              }).toList(),
            ),
            //Pause/Play button widget
            PlaybackButton(player: player),
            //Tempo drop down selector
            DropdownMenu(
              initialSelection: 120,
              label: const Text("Tempo"),
              width: 120,
              onSelected: (value) {
                //Set tempo state
                ref.read(controlsState.notifier).state = (value!, keySig);
              },
              //Generate 25 tempos to choose from - starting from 60 and with increments of 5
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

//Pause/Play Button widget
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
  //Whether the button is paused or not
  var paused = true;
  void _toggle() {
    setState(() {
      paused = !paused;
    });
  }

  @override
  Widget build(BuildContext context) {
    //Enable toggling, switching icons when the button is pressed
    return paused
        ? IconButton(
            //Show paused button and start playing music
            onPressed: () async {
              dev.log("play");
              _toggle();
              await widget.player.play();
            },

            //Play button arrow
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
