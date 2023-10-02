import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheet_music_app/pigeon/scanner.dart';
import 'package:sheet_music_app/state.dart';

class ViewTab extends ConsumerStatefulWidget {
  const ViewTab({super.key});

  @override
  ConsumerState<ViewTab> createState() => _ViewTabState();
}

class _ViewTabState extends ConsumerState<ViewTab> {
  late Future<String> imageFuture;
  @override
  void initState() {
    //Get first image in temporarySheetMusicImageProvider and send it
    imageFuture = ScannerAPI()
        .scan(ref.read(temporarySheetMusicImageProvider)[0][0].path);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //Show loading until scanning is done
    return FutureBuilder(
        future: imageFuture,
        builder: (context, snapshot) {
          //Check if kotlin has returned yet
          if (snapshot.connectionState == ConnectionState.done) {
            //Log returned path
            dev.log(snapshot.data!, name: "Kotlin Image");
            //Display image
            return Image.file(File(snapshot.data!));
          } else {
            //Show loading circle
            return const CircularProgressIndicator();
          }
        });
  }
}
