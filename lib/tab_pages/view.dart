import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sheet_music_app/pigeon/scanner.dart';
import 'package:sheet_music_app/state.dart';

class ViewTab extends ConsumerStatefulWidget {
  const ViewTab({super.key});

  @override
  ConsumerState<ViewTab> createState() => _ViewTabState();
}

class _ViewTabState extends ConsumerState<ViewTab> {
  late Future<String> imageFuture;
  late Future<String> tempFuture;
  @override
  void initState() {
    //Get first image in temporarySheetMusicImageProvider and send it
    tempFuture = ScannerAPI()
        .scan(ref.read(temporarySheetMusicImageProvider).last.last.path)
        .then((value) => value.path);

    //Create a temporary file to save the processed image
    // tempFuture = getTemporaryDirectory().then((value) async {
    //   final temp = await value.createTemp();
    //   final path = File("${temp.path}/sheet_music.jpg");
    //   return (await ScannerAPI().scan(path.path)).path;
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //Show loading until scanning is done
    return FutureBuilder(
        //imageFuture resolves when Kotlin returns the image path
        future: tempFuture,
        builder: (context, snapshot) {
          //Check if kotlin has returned yet
          if (snapshot.connectionState == ConnectionState.done) {
            //Display image
            return Column(
              children: [
                Image.file(File(snapshot.data!)),
                Image.asset("images/template1.png")
              ],
            );
          } else {
            //Show loading circle
            return const Center(child: CircularProgressIndicator());
          }
        });
  }
}
