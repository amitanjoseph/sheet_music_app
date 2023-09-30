import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheet_music_app/main.dart';
import 'package:sheet_music_app/state.dart';

class HomeTab extends ConsumerWidget {
  //The function to be called when the page needs to be changed
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      alignment: Alignment.center,
      //Puts the buttons into a column
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            //This is the Saved Sheet Music Button which, when pressed switches,
            //to the Files Tab
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              //Set currentPage to the files tab
              onPressed: () {
                ref.read(currentPageProvider.notifier).state =
                    AppPages.filesTab;
              },
              child: const Text(
                'Saved Sheet Music',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            //This is the Scan Sheet Music Button which, when pressed switches,
            //to the Scan Tab
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                onPressed: () {
                  //Set currentPage to the scan tab
                  ref.read(currentPageProvider.notifier).state =
                      AppPages.scanTab;
                },
                child: const Text(
                  'Scan Sheet Music',
                )),
          ),
        ],
      ),
    );
  }
}
