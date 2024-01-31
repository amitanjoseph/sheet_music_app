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

sealed class Filters {}

class Composer implements Filters {
  final String? composer;
  const Composer(this.composer);
}

class CreationDate implements Filters {
  final DateTime date;
  const CreationDate(this.date);
}

class None implements Filters {}

class FilterButton extends ConsumerWidget {
  const FilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordering = ref.watch(fileOrderingProvider);
    final composersAndDateSet =
        ref.watch(databaseProvider.future).then((db) async {
      final records =
          await db.query("SheetMusic", columns: ["composer", "dateCreated"]);
      final composerSet = Set<String?>.from(records.map((i) => i["composer"]));
      final creationDateSet =
          Set<int>.from(records.map((i) => i["dateCreated"]));
      dev.log(composerSet.toString(), name: "COMPOSERS");
      dev.log(creationDateSet.toString(), name: "CREATION DATES");
      return (composerSet.toList(), creationDateSet.toList());
    });

    final filter = ref.watch(filterProvider);
    return SubmenuButton(
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
        FutureBuilder(
          future: composersAndDateSet,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                final (composers, creationDates) = snapshot.data!;
                return SubmenuButton(menuChildren: [
                  SubmenuButton(
                      menuChildren: composers.map((item) {
                        return MenuItemButton(
                            trailingIcon: switch (filter) {
                              Composer(composer: final composer) =>
                                composer == item
                                    ? const Icon(Icons.circle, size: 15)
                                    : null,
                              _ => null
                            },
                            onPressed: () {
                              switch (filter) {
                                case Composer(composer: final composer):
                                  dev.log(composer.toString());
                                  if (composer == item) {
                                    ref.watch(filterProvider.notifier).state =
                                        None();
                                  } else {
                                    ref.watch(filterProvider.notifier).state =
                                        Composer(item);
                                  }
                                  break;
                                default:
                                  ref.watch(filterProvider.notifier).state =
                                      Composer(item);
                              }
                            },
                            child: Text(item ?? "Unknown"));
                      }).toList(),
                      child: const MenuAcceleratorLabel("&By Composer")),
                  MenuItemButton(
                    child: const Text("By Creation Date"),
                    onPressed: () async {
                      var validDays = creationDates
                          .map((date) =>
                              DateTime.fromMillisecondsSinceEpoch(date))
                          .toList();
                      validDays.sort();
                      dev.log(validDays.map((e) => e.toString()).toString(),
                          name: "VALID DAYS");
                      final date = await showDatePicker(
                        context: context,
                        firstDate: validDays.first,
                        lastDate: validDays.last,
                        selectableDayPredicate: (day) =>
                            validDays.contains(day),
                      );
                      ref.watch(filterProvider.notifier).state =
                          CreationDate(date!);
                    },
                  )
                ], child: const MenuAcceleratorLabel("&Filter"));

              default:
                return const CircularProgressIndicator();
            }
          },
        )
      ],
      child: const Icon(Icons.filter_alt_outlined),
    );
  }
}

class FileTab extends ConsumerWidget {
  const FileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: MenuBar(
                children: [
                  SafeArea(
                    child: FilterButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
        Expanded(child: Files()),
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
                    models = models.where((element) {
                      switch (ref.watch(filterProvider)) {
                        case Composer(composer: final composer):
                          return element.$2.composer == composer;
                        case CreationDate(date: final date):
                          return DateUtils.isSameDay(
                              date,
                              DateTime.fromMillisecondsSinceEpoch(
                                  element.$2.dateCreated));
                        case None():
                          return true;
                      }
                    }).toList();
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
