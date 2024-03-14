import 'package:flutter_midi/flutter_midi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheet_music_app/pigeon/scanner.dart';
import 'package:sheet_music_app/state.dart';
import 'package:sheet_music_app/utils/music_utils.dart';

//Class managing the audio playback
class Player {
  //The music to play
  final List<List<Note>> parts;
  //The handler to allow for playing actual notes
  final FlutterMidi midi;
  //Ref to access tempo and key signatures from global providers
  WidgetRef ref;
  //State recording whether the music is currently paused
  bool paused = false;
  //Stores the index representing the note each part is at for playing
  List<int> currentNote;

  Player(this.parts, this.midi, this.ref)
      //Set current note for each part to the zeroth index
      : currentNote = List.generate(parts.length, (index) => 0);

  //Method to start playing
  Future<void> play() async {
    //Set paused to false
    paused = false;
    //Asynchronously play each part
    await Future.wait(parts.indexed.map((arg) async {
      //Index representing the part number
      final index = arg.$1;
      //All the notes in this part
      final part = arg.$2;
      //Start from the last saved note and end at the final note in this part
      for (var i = currentNote[index]; i < part.length; i++) {
        //Update currentNote for this part to the new current note
        currentNote[index] = i;
        //Don't play if paused is true
        //This is here so that every part stops playing the current note
        //and can resume correctly
        if (paused) break;
        //Play the provided note
        await _playNote(part[i]);
      }
    }));
  }

  //Pause playback
  void pause() {
    paused = true;
  }

  //Play the provided note
  Future<void> _playNote(Note note) async {
    //Get tempo and key signature
    final (tempo, keysig) =
        ref.watch(sheetMusicProvider.notifier).getTempoAndKeySig();
    //Transpose the note to be played
    final pitch = transposedPitchToMidi(note.pitch, keysig);
    //Get the number of beats to play the note for
    final length = lengthToBeats(note.length);
    //Play the note
    midi.playMidiNote(midi: pitch);
    //Wait the correct amount of time before continuing playing
    await Future.delayed(Duration(
        milliseconds: (bpmToSecondsPerBeat(tempo) * length * 1000).round()));
  }
}
