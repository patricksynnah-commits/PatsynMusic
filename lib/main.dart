import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PatsynMusic());
}

class PatsynMusic extends StatelessWidget {
  const PatsynMusic({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MusicHome(),
    );
  }
}

class MusicHome extends StatefulWidget {
  const MusicHome({super.key});

  @override
  State<MusicHome> createState() => _MusicHomeState();
}

class _MusicHomeState extends State<MusicHome> {
  final AudioPlayer player = AudioPlayer();

  List<FileSystemEntity> songs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    initApp();
  }

  Future<void> initApp() async {
    await Permission.storage.request();
    await Permission.audio.request();
    loadSongs();
  }

  void loadSongs() {
    try {
      Directory dir = Directory('/storage/emulated/0/');

      List<FileSystemEntity> files = dir
          .listSync(recursive: true)
          .where((file) => file.path.endsWith('.mp3'))
          .toList();

      setState(() {
        songs = files;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> playSong(String path) async {
    await player.play(DeviceFileSource(path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PatsynMusic'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : songs.isEmpty
              ? const Center(
                  child: Text('No MP3 files found'),
                )
              : ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    String path = songs[index].path;
                    String name = path.split('/').last;

                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(name),
                      onTap: () {
                        playSong(path);
                      },
                    );
                  },
                ),
    );
  }
}
