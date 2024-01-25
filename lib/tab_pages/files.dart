import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state.dart';
import '../data_models/models.dart';

class FileTab extends ConsumerWidget {
  const FileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return db.when(
      data: (data) {
        final models = data.query("SheetMusic").then(
            (maps) => maps.map((map) => SheetMusicModel.fromMap(map)).toList());
        return FutureBuilder(
          future: models,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                final models = snapshot.data!;
                return ListView.builder(
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    final model = models[index];
                    return File(
                        title: model.name,
                        composer: model.composer,
                        dateCreated: model.dateCreated,
                        dateLastViewed: model.dateViewed);
                  },
                );

              default:
                return const CircularProgressIndicator();
            }
          },
        );
      },
      error: (error, stackTrace) {
        dev.log("$error", name: "ERROR");
        dev.log("$stackTrace", name: "STACKTRACE");
        return const SnackBar(content: Text("Error loading files."));
      },
      loading: () {
        return const CircularProgressIndicator();
      },
    );
  }
}

class File extends StatelessWidget {
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
    final dateCreated = DateTime.fromMillisecondsSinceEpoch(this.dateCreated);
    final dateLastViewed =
        DateTime.fromMillisecondsSinceEpoch(this.dateLastViewed);
    return Card(
      child: Column(
        children: [
          Text(title),
          if (_composer != null) Row(children: [Text(_composer)]),
          Row(children: [
            Text("$dateCreated"),
            Text("$dateLastViewed"),
          ])
        ],
      ),
    );
  }
}
