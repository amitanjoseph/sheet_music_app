import 'package:flutter_midi/flutter_midi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheet_music_app/pigeon/scanner.dart';
import 'package:sheet_music_app/state.dart';
import 'package:sheet_music_app/utils/music_utils.dart';

class Player {
  final List<List<Note>> parts;
  final FlutterMidi midi;

  WidgetRef ref;
  bool paused = false;
  List<int> currentNote;

  Player(this.parts, this.midi, this.ref)
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
    final (tempo, keysig) =
        ref.watch(sheetMusicProvider.notifier).getTempoAndKeySig();
    final pitch = transposedPitchToMidi(note.pitch, keysig);
    final length = lengthToBeats(note.length);
    midi.playMidiNote(midi: pitch);
    await Future.delayed(Duration(
        milliseconds: (bpmToSecondsPerBeat(tempo) * length * 1000).round()));
  }
}
