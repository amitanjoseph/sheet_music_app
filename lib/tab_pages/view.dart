import 'package:flutter/material.dart';
import 'dart:developer' as dev;

import 'package:sheet_music_app/pigeon/scanner.dart';

class ViewTab extends StatefulWidget {
  const ViewTab({super.key});

  @override
  State<ViewTab> createState() => _ViewTabState();
}

class _ViewTabState extends State<ViewTab> {
  @override
  void initState() {
    ScannerAPI().message().then(
      (msg) {
        dev.log(msg, name: "Kotlin Message");
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //Placeholder Content
    return Container(
      alignment: Alignment.center,
      child: const Text('Page 4'),
    );
  }
}
