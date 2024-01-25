import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../state.dart';
import '../data_models/models.dart';

class FileTab extends ConsumerWidget {
  const FileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Database handler
    final db = ref.watch(databaseProvider);
    //Switch on db to show different things depending on asynchronous state
    switch (db) {
      //If database is available, query it
      case AsyncData(:final value):
        //Query sheet music table and generate models for each
        final models = value.query("SheetMusic").then(
            (maps) => maps.map((map) => SheetMusicModel.fromMap(map)).toList());
        //Show loading if query has not fulfilled
        return FutureBuilder(
          future: models,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              //If query finished
              case ConnectionState.done:
                final models = snapshot.data!;
                //Return a list of all the sheet music files using the File widget
                return ListView.builder(
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    //Destructure model to get information about it
                    final SheetMusicModel(
                      :name,
                      :composer,
                      :dateCreated,
                      :dateViewed
                    ) = models[index];
                    return File(
                        title: name,
                        composer: composer,
                        dateCreated: dateCreated,
                        dateLastViewed: dateViewed);
                  },
                );

              //Loading spinner otherwise
              default:
                return const CircularProgressIndicator();
            }
          },
        );
      //If the database errors out, perform logging and popup warning
      case AsyncError(:final error, :final stackTrace):
        dev.log("$error", name: "ERROR");
        dev.log("$stackTrace", name: "STACKTRACE");
        return const SnackBar(content: Text("Error loading files."));
      //Otherwise show loading spinner
      default:
        return const CircularProgressIndicator();
    }
  }
}

//The card that displays the information about the sheet music to allow selection
class File extends StatelessWidget {
  //Info being displayed
  final String title;
  final String? _composer;
  final int dateCreated;
  final int dateLastViewed;
  const File(
      {super.key,
      required this.title,
      required String? composer,
      required this.dateCreated,
      required this.dateLastViewed})
      : _composer = composer;

  @override
  Widget build(BuildContext context) {
    //Convert from ints to dates
    final dateCreated = DateTime.fromMillisecondsSinceEpoch(this.dateCreated);
    final dateLastViewed =
        DateTime.fromMillisecondsSinceEpoch(this.dateLastViewed);
    //The actual card widget
    return Card(
      color: Theme.of(context).primaryColor,
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .apply(
                    displayColor: Colors.white,
                  )
                  .headlineMedium,
            ),
          ),
          //If composer has been specfied, show it
          if (_composer != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Row(children: [
                Text(
                  "Composer - $_composer",
                  style: Theme.of(context)
                      .textTheme
                      .apply(displayColor: Colors.white)
                      .bodySmall,
                )
              ]),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Date Created - ${DateFormat("d/M/y").format(dateCreated)}",
                    style: Theme.of(context)
                        .textTheme
                        .apply(displayColor: Colors.white)
                        .bodySmall,
                  ),
                  Text(
                    "Last Viewed - ${DateFormat("d/M/y").format(dateLastViewed)}",
                    style: Theme.of(context)
                        .textTheme
                        .apply(displayColor: Colors.white)
                        .bodySmall,
                  ),
                ]),
          )
        ],
      ),
    );
  }
}
