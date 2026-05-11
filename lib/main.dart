import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const PatsynMusic());
}

class PatsynMusic extends StatelessWidget {
  const PatsynMusic({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const FileBrowserScreen(),
    );
  }
}

class FileBrowserScreen extends StatefulWidget {
  const FileBrowserScreen({super.key});

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  final AudioPlayer player = AudioPlayer();

  Directory currentDir = Directory('/storage/emulated/0/');
  List<FileSystemEntity> items = [];

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    await Permission.storage.request();
    await Permission.audio.request();
    loadFiles(currentDir);
  }

  void loadFiles(Directory dir) {
    try {
      List<FileSystemEntity> temp = dir.listSync();

      temp.sort((a, b) {
        return a.path.toLowerCase().compareTo(
              b.path.toLowerCase(),
            );
      });

      setState(() {
        currentDir = dir;
        items = temp;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> playSong(String path) async {
    await player.stop();
    await player.play(DeviceFileSource(path));
  }

  bool isMusicFile(String path) {
    return path.toLowerCase().endsWith('.mp3') ||
        path.toLowerCase().endsWith('.wav') ||
        path.toLowerCase().endsWith('.m4a');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PatsynMusic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              loadFiles(Directory('/storage/emulated/0/'));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.black26,
            child: Text(
              currentDir.path,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                FileSystemEntity item = items[index];
                String name = item.path.split('/').last;

                if (item is Directory) {
                  return ListTile(
                    leading: const Icon(
                      Icons.folder,
                      color: Colors.yellow,
                    ),
                    title: Text(name),
                    onTap: () {
                      loadFiles(item);
                    },
                  );
                } else if (item is File && isMusicFile(item.path)) {
                  return ListTile(
                    leading: const Icon(
                      Icons.music_note,
                      color: Colors.green,
                    ),
                    title: Text(name),
                    onTap: () {
                      playSong(item.path);
                    },
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.arrow_back),
        onPressed: () {
          if (currentDir.path != '/storage/emulated/0/') {
            loadFiles(currentDir.parent);
          }
        },
      ),
    );
  }
}
