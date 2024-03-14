import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sheet_music_app/main.dart';
import '../state.dart';
import '../data_models/models.dart';

class FileTab extends ConsumerWidget {
  const FileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: scaffoldKey,
      body: const Column(
        children: [
          //Menu Bar with Filter Button
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
          //Show each of the files
          Expanded(child: Files()),
        ],
      ),
    );
  }
}

//Unique identifier
final scaffoldKey = GlobalKey();

//File Sorting Order
enum FileOrdering {
  viewDate,
  alphabetical,
  composer,
  creationDate,
}

//ADT representing each filter and the necessary data for each
sealed class Filters {}

//Composer filter, with name
class Composer implements Filters {
  final String? composer;
  const Composer(this.composer);
}

//Creation Date filter, with date
class CreationDate implements Filters {
  final DateTime date;
  const CreationDate(this.date);
}

//No filter
class None implements Filters {}

//Button for filtering (and sorting)
class FilterButton extends ConsumerWidget {
  const FilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Set ordering
    final ordering = ref.watch(fileOrderingProvider);
    //Unique lists of all the dates and composers in the database
    final composersAndDateSet =
        ref.watch(databaseProvider.future).then((db) async {
      //The composer and dateCreated for each piece of music
      final records =
          await db.query("SheetMusic", columns: ["composer", "dateCreated"]);
      //Unique set of composers
      final composerSet = Set<String?>.from(records.map((i) => i["composer"]));
      //Unique list of createion dates
      final creationDateSet = records
          //Convert creation dates to dates
          .map((i) => i["dateCreated"])
          .map((e) => DateTime.fromMillisecondsSinceEpoch(e as int))
          .fold(<DateTime>[], (accum, date) {
        //If date is not in accum, add it
        //Otherwise leave accum
        if (accum
            .where((otherDate) => DateUtils.isSameDay(date, otherDate))
            .isEmpty) {
          return accum + [date];
        } else {
          return accum;
        }
      });
      return (composerSet.toList(), creationDateSet.toList());
    });
    //Current filter chosen
    final filter = ref.watch(filterProvider);
    return SubmenuButton(
      menuChildren: [
        SubmenuButton(
          menuChildren: [
            //Sort By View Date
            MenuItemButton(
              onPressed: () {
                ref.read(fileOrderingProvider.notifier).state =
                    FileOrdering.viewDate;
              },
              //Show icon to indicate selection
              trailingIcon: ordering == FileOrdering.viewDate
                  ? const Icon(
                      Icons.circle,
                      size: 15,
                    )
                  : null,
              child: const Text("By View Date"),
            ),
            //Sort in alphabetical order
            MenuItemButton(
              onPressed: () {
                ref.read(fileOrderingProvider.notifier).state =
                    FileOrdering.alphabetical;
              },
              //Show icon to indicate selection
              trailingIcon: ordering == FileOrdering.alphabetical
                  ? const Icon(
                      Icons.circle,
                      size: 15,
                    )
                  : null,
              child: const Text("A-Z"),
            ),
            //Sort by Composer
            MenuItemButton(
              onPressed: () {
                ref.read(fileOrderingProvider.notifier).state =
                    FileOrdering.composer;
              },
              //Show icon to indicate selection
              trailingIcon: ordering == FileOrdering.composer
                  ? const Icon(
                      Icons.circle,
                      size: 15,
                    )
                  : null,
              child: const Text("By Composer"),
            ),
            //Sort by Creation Date
            MenuItemButton(
              onPressed: () {
                ref.read(fileOrderingProvider.notifier).state =
                    FileOrdering.creationDate;
              },
              //Show icon to indicate selection
              trailingIcon: ordering == FileOrdering.creationDate
                  ? const Icon(
                      Icons.circle,
                      size: 15,
                    )
                  : null,
              child: const Text("By Creation Date"),
            ),
          ],
          //Submenu Label Sort
          child: const MenuAcceleratorLabel("&Sort"),
        ),
        //Await composersAndDateSet
        FutureBuilder(
          future: composersAndDateSet,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              //If ready do process
              case ConnectionState.done:
                //Get composers and creation dates
                final (composers, creationDates) = snapshot.data!;
                return SubmenuButton(menuChildren: [
                  SubmenuButton(
                      //Display each composer
                      menuChildren: composers.map((item) {
                        return MenuItemButton(
                            //Show icon if it is currently filtered
                            trailingIcon: switch (filter) {
                              Composer(composer: final composer) =>
                                composer == item
                                    ? const Icon(Icons.circle, size: 15)
                                    : null,
                              _ => null
                            },
                            onPressed: () {
                              //If filtering this composer, deselect filter
                              //Otherwise set filter to this composer
                              switch (filter) {
                                case Composer(composer: final composer):
                                  if (composer == item) {
                                    ref.watch(filterProvider.notifier).state =
                                        None();
                                  } else {
                                    ref.watch(filterProvider.notifier).state =
                                        Composer(item);
                                  }
                                  break;
                                //Set filter to this composer
                                default:
                                  ref.watch(filterProvider.notifier).state =
                                      Composer(item);
                              }
                            },
                            //Show composer name (or Unknown if composer was null)
                            child: Text(item ?? "Unknown"));
                      }).toList(),
                      //Submenu label
                      child: const MenuAcceleratorLabel("&By Composer")),
                  //Creation Date filter menu option
                  MenuItemButton(
                    child: const Text("By Creation Date"),
                    onPressed: () async {
                      //Valid days to choose from
                      var validDays = creationDates;
                      validDays.sort();

                      //Show date picker dialog
                      final date = await showDatePicker(
                        context: scaffoldKey.currentContext!,
                        firstDate: validDays.first,
                        lastDate: validDays.last,
                        //Date is valid if in valid days
                        selectableDayPredicate: (day) => validDays
                            .where(
                                (element) => DateUtils.isSameDay(day, element))
                            .isNotEmpty,
                      );
                      //Set filter to selected date
                      ref.watch(filterProvider.notifier).state =
                          CreationDate(date!);
                    },
                  )
                  //Filter submenu label
                ], child: const MenuAcceleratorLabel("&Filter"));

              default:
                //Loading Screen
                return const CircularProgressIndicator();
            }
          },
        )
      ],
      child: const Icon(Icons.filter_alt_outlined),
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
                    //Sort by selected ordering
                    models.sort((a, b) {
                      switch (ordering) {
                        case FileOrdering.viewDate:
                          return (-a.$2.dateViewed).compareTo(-b.$2.dateViewed);
                        case FileOrdering.alphabetical:
                          return a.$2.name.compareTo(b.$2.name);
                        case FileOrdering.composer:
                          //If composer was not provided, compare with ""
                          return (a.$2.composer ?? "")
                              .compareTo(b.$2.composer ?? "");
                        case FileOrdering.creationDate:
                          return (-a.$2.dateCreated)
                              .compareTo(-b.$2.dateCreated);
                      }
                    });
                    //Gets models matching filtering
                    models = models.where((element) {
                      switch (ref.watch(filterProvider)) {
                        case Composer(composer: final composer):
                          return element.$2.composer == composer;
                        case CreationDate(date: final date):
                          //If creation day is the same, return
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
      default:
        //Otherwise show loading spinner
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
      //Show animation on tap
      child: InkWell(
        onTap: () async {
          //Set sheetmusic to saved
          await ref.watch(sheetMusicProvider.notifier).setSaved(id);
          //Switch tab
          ref.watch(currentPageProvider.notifier).state = AppPages.viewTab;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Display music title
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
            //Show info about Creation Date and Last Viewed Date
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
