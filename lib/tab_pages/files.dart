import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state.dart';
import '../data_models/models.dart';

class FileTab extends ConsumerWidget {
  const FileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    db.when(
      data: (data) async {
        final maps = await data.query("SheetMusic");
        final models = maps.map((map) => SheetMusicModel.fromMap(map)).toList();
        return ListView.builder(
          itemCount: models.length,
          itemBuilder: (context, index) {
            final model = models[index];
            return File(title: model.name, composer: model.composer, dateCreated: dateCreated, dateLastViewed: dateLastViewed)
        },
        );
      },
    );
    //Placeholder Content
    return Container(
      alignment: Alignment.center,
      child: const Text('Page 2'),
    );
  }
}

class File extends StatelessWidget {
  final String title;
  final String? composer;
  final int dateCreated;
  final int dateLastViewed;
  const File(
      {super.key,
      required this.title,
      required this.composer,
      required this.dateCreated,
      required this.dateLastViewed});

  @override
  Widget build(BuildContext context) {
    final dateCreated = DateTime.fromMillisecondsSinceEpoch(this.dateCreated);
    final dateLastViewed =
        DateTime.fromMillisecondsSinceEpoch(this.dateLastViewed);
    return Card(
      child: Column(
        children: [
          Text(title),
          composer != null ? Row(children: [Text(composer)]) : const Row(),
          Row(children: [
            Text("$dateCreated"),
            Text("$dateLastViewed"),
          ])
        ],
      ),
    );
  }
}
