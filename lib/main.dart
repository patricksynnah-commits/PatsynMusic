import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
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
  final OnAudioQuery audioQuery = OnAudioQuery();
  final AudioPlayer player = AudioPlayer();

  List<SongModel> songs = [];
  int currentIndex = -1;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  void requestPermission() async {
    await Permission.storage.request();
    await Permission.audio.request();

    songs = await audioQuery.querySongs();

    setState(() {});
  }

  Future<void> playSong(int index) async {
    await player.setFilePath(songs[index].data);
    player.play();

    setState(() {
      currentIndex = index;
      isPlaying = true;
    });
  }

  Future<void> pauseSong() async {
    await player.pause();

    setState(() {
      isPlaying = false;
    });
  }

  Future<void> resumeSong() async {
    await player.play();

    setState(() {
      isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patsynmusic"),
        centerTitle: true,
      ),
      body: songs.isEmpty
          ? const Center(
              child: Text(
                "No Music Found",
                style: TextStyle(fontSize: 20),
              ),
            )
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.music_note),
                    title: Text(
                      songs[index].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      songs[index].artist ?? "Unknown Artist",
                      maxLines: 1,
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        currentIndex == index && isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: () {
                        if (currentIndex == index && isPlaying) {
                          pauseSong();
                        } else if (currentIndex == index && !isPlaying) {
                          resumeSong();
                        } else {
                          playSong(index);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
