import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sheet_music_app/main.dart';
import '../state.dart';
import '../data_models/models.dart';

enum FileOrdering {
  viewDate,
  alphabetical,
  composer,
  creationDate,
}

class FileTab extends ConsumerWidget {
  const FileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordering = ref.watch(fileOrderingProvider);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: MenuBar(
                children: [
                  SubmenuButton(
                    menuChildren: [
                      SubmenuButton(
                        menuChildren: [
                          MenuItemButton(
                            onPressed: () {
                              ref.read(fileOrderingProvider.notifier).state =
                                  FileOrdering.viewDate;
                            },
                            trailingIcon: ordering == FileOrdering.viewDate
                                ? const Icon(
                                    Icons.circle,
                                    size: 15,
                                  )
                                : null,
                            child: const Text("By View Date"),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              ref.read(fileOrderingProvider.notifier).state =
                                  FileOrdering.alphabetical;
                            },
                            trailingIcon: ordering == FileOrdering.alphabetical
                                ? const Icon(
                                    Icons.circle,
                                    size: 15,
                                  )
                                : null,
                            child: const Text("A-Z"),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              ref.read(fileOrderingProvider.notifier).state =
                                  FileOrdering.composer;
                            },
                            trailingIcon: ordering == FileOrdering.composer
                                ? const Icon(
                                    Icons.circle,
                                    size: 15,
                                  )
                                : null,
                            child: const Text("By Composer"),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              ref.read(fileOrderingProvider.notifier).state =
                                  FileOrdering.creationDate;
                            },
                            trailingIcon: ordering == FileOrdering.creationDate
                                ? const Icon(
                                    Icons.circle,
                                    size: 15,
                                  )
                                : null,
                            child: const Text("By Creation Date"),
                          ),
                        ],
                        child: const MenuAcceleratorLabel("&Sort"),
                      ),
                    ],
                    child: const Icon(Icons.filter_alt_outlined),
                  )
                ],
              ),
            ),
          ],
        ),
        const Expanded(child: Files()),
      ],
    );
  }
}

class Files extends ConsumerWidget {
  const Files({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Database handler
    final db = ref.watch(databaseProvider);
    final ordering = ref.watch(fileOrderingProvider);
    //Switch on db to show different things depending on asynchronous state
    switch (db) {
      //If database is available, query it
      case AsyncData(:final value):
        //Query sheet music table and generate models for each
        final models = value.query("SheetMusic").then((maps) => maps
            .map((map) => (map["id"] as int, SheetMusicModel.fromMap(map)))
            .toList());
        //Show loading if query has not fulfilled
        return Consumer(
          builder: (context, ref, child) {
            return FutureBuilder(
              future: models,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  //If query finished
                  case ConnectionState.done:
                    var models = snapshot.data!;
                    models.sort((a, b) {
                      switch (ordering) {
                        case FileOrdering.viewDate:
                          return (-a.$2.dateViewed).compareTo(-b.$2.dateViewed);
                        case FileOrdering.alphabetical:
                          return a.$2.name.compareTo(b.$2.name);
                        case FileOrdering.composer:
                          return (a.$2.composer ?? "")
                              .compareTo(b.$2.composer ?? "");
                        case FileOrdering.creationDate:
                          return (-a.$2.dateCreated)
                              .compareTo(-b.$2.dateCreated);
                      }
                    });
                    //Return a list of all the sheet music files using the File widget
                    return ListView.builder(
                      itemCount: models.length,
                      itemBuilder: (context, index) {
                        //Destructure model to get information about it
                        final (
                          id,
                          SheetMusicModel(
                            :name,
                            :composer,
                            :dateCreated,
                            :dateViewed
                          )
                        ) = models[index];
                        return File(
                            id: id,
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
class File extends ConsumerWidget {
  //Info being displayed
  final String title;
  final String? _composer;
  final int dateCreated;
  final int dateLastViewed;
  final int id;
  const File(
      {super.key,
      required this.id,
      required this.title,
      required String? composer,
      required this.dateCreated,
      required this.dateLastViewed})
      : _composer = composer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Convert from ints to dates
    final dateCreated = DateTime.fromMillisecondsSinceEpoch(this.dateCreated);
    final dateLastViewed =
        DateTime.fromMillisecondsSinceEpoch(this.dateLastViewed);
    //The actual card widget
    return Card(
      color: Theme.of(context).primaryColor,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          ref.watch(sheetMusicProvider.notifier).setSaved(id);
          ref.watch(currentPageProvider.notifier).state = AppPages.viewTab;
        },
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
      ),
    );
  }
}
