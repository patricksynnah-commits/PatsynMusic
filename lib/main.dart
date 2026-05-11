import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() {
  runApp(const PatsynMusic());
}

class PatsynMusic extends StatelessWidget {
  const PatsynMusic({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MusicHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MusicHome extends StatefulWidget {
  @override
  State<MusicHome> createState() => _MusicHomeState();
}

class _MusicHomeState extends State<MusicHome> {
  List<FileSystemEntity> songs = [];
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  void requestPermission() async {
    await Permission.storage.request();
    loadSongs();
  }

  void loadSongs() {
    final dir = Directory('/storage/emulated/0/');
    setState(() {
      songs = dir
          .listSync(recursive: true)
          .where((file) => file.path.endsWith('.mp3'))
          .toList();
    });
  }

  void playSong(String path) async {
    await player.play(DeviceFileSource(path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PatsynMusic")),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          String path = songs[index].path;
          String name = path.split('/').last;

          return ListTile(
            title: Text(name),
            onTap: () => playSong(path),
          );
        },
      ),
    );
  }
}
