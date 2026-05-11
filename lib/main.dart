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
      title: 'PatsynMusic',
      theme: ThemeData.dark(),
      home: const MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() =>
      _MusicPlayerScreenState();
}

class _MusicPlayerScreenState
    extends State<MusicPlayerScreen> {
  final AudioPlayer player = AudioPlayer();

  List<File> songs = [];

  int currentIndex = -1;

  bool isPlaying = false;

  bool loading = true;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();

    initializePlayer();
    requestPermissionsAndScan();
  }

  void initializePlayer() {
    player.onDurationChanged.listen((d) {
      setState(() {
        duration = d;
      });
    });

    player.onPositionChanged.listen((p) {
      setState(() {
        position = p;
      });
    });

    player.onPlayerComplete.listen((event) {
      playNext();
    });
  }

  Future<void> requestPermissionsAndScan() async {
    await Permission.storage.request();
    await Permission.audio.request();

    await scanSongs();
  }

  Future<void> scanSongs() async {
    List<File> foundSongs = [];

    Directory root = Directory('/storage/emulated/0/');

    void scanDirectory(Directory dir) {
      try {
        List<FileSystemEntity> files =
            dir.listSync();

        for (var file in files) {
          if (file is Directory) {
            scanDirectory(file);
          } else if (file is File) {
            String path =
                file.path.toLowerCase();

            if (path.endsWith('.mp3') ||
                path.endsWith('.wav') ||
                path.endsWith('.m4a')) {
              foundSongs.add(file);
            }
          }
        }
      } catch (_) {}
    }

    scanDirectory(root);

    foundSongs.sort(
      (a, b) =>
          a.path
              .toLowerCase()
              .compareTo(
                b.path.toLowerCase(),
              ),
    );

    setState(() {
      songs = foundSongs;
      loading = false;
    });
  }

  Future<void> playSong(int index) async {
    try {
      currentIndex = index;

      await player.stop();

      await player.play(
        DeviceFileSource(
          songs[index].path,
        ),
      );

      setState(() {
        isPlaying = true;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> pauseSong() async {
    await player.pause();

    setState(() {
      isPlaying = false;
    });
  }

  Future<void> resumeSong() async {
    await player.resume();

    setState(() {
      isPlaying = true;
    });
  }

  Future<void> playNext() async {
    if (songs.isEmpty) return;

    int nextIndex = currentIndex + 1;

    if (nextIndex >= songs.length) {
      nextIndex = 0;
    }

    await playSong(nextIndex);
  }

  Future<void> playPrevious() async {
    if (songs.isEmpty) return;

    int previousIndex =
        currentIndex - 1;

    if (previousIndex < 0) {
      previousIndex =
          songs.length - 1;
    }

    await playSong(previousIndex);
  }

  String formatTime(Duration d) {
    String twoDigits(int n) =>
        n.toString().padLeft(2, '0');

    return "${twoDigits(d.inMinutes)}:"
        "${twoDigits(d.inSeconds % 60)}";
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentSongName =
        currentIndex >= 0
            ? songs[currentIndex]
                .path
                .split('/')
                .last
            : "No song playing";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "PatsynMusic",
        ),
        centerTitle: true,
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Column(
              children: [
                const SizedBox(height: 20),

                const Icon(
                  Icons.album,
                  size: 140,
                  color: Colors.green,
                ),

                const SizedBox(height: 20),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Text(
                    currentSongName,
                    textAlign:
                        TextAlign.center,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Slider(
                  min: 0,
                  max: duration
                              .inSeconds >
                          0
                      ? duration
                          .inSeconds
                          .toDouble()
                      : 1,
                  value: position
                      .inSeconds
                      .toDouble()
                      .clamp(
                        0,
                        duration
                                    .inSeconds >
                                0
                            ? duration
                                .inSeconds
                                .toDouble()
                            : 1,
                      ),
                  onChanged:
                      (value) async {
                    await player.seek(
                      Duration(
                        seconds:
                            value.toInt(),
                      ),
                    );
                  },
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text(
                        formatTime(
                          position,
                        ),
                      ),
                      Text(
                        formatTime(
                          duration,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    IconButton(
                      iconSize: 55,
                      onPressed:
                          playPrevious,
                      icon: const Icon(
                        Icons
                            .skip_previous,
                      ),
                    ),

                    IconButton(
                      iconSize: 85,
                      onPressed: () {
                        if (currentIndex ==
                                -1 &&
                            songs
                                .isNotEmpty) {
                          playSong(0);
                        } else if (isPlaying) {
                          pauseSong();
                        } else {
                          resumeSong();
                        }
                      },
                      icon: Icon(
                        isPlaying
                            ? Icons
                                .pause_circle
                            : Icons
                                .play_circle,
                      ),
                    ),

                    IconButton(
                      iconSize: 55,
                      onPressed:
                          playNext,
                      icon: const Icon(
                        Icons.skip_next,
                      ),
                    ),
                  ],
                ),

                const Divider(),

                Expanded(
                  child: songs.isEmpty
                      ? const Center(
                          child: Text(
                            "No MP3 files found",
                          ),
                        )
                      : ListView.builder(
                          itemCount:
                              songs.length,
                          itemBuilder:
                              (context,
                                  index) {
                            String name =
                                songs[index]
                                    .path
                                    .split('/')
                                    .last;

                            bool selected =
                                currentIndex ==
                                    index;

                            return ListTile(
                              leading: Icon(
                                selected
                                    ? Icons
                                        .equalizer
                                    : Icons
                                        .music_note,
                                color:
                                    selected
                                        ? Colors
                                            .green
                                        : Colors
                                            .white,
                              ),
                              title: Text(
                                name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                              selected:
                                  selected,
                              onTap: () {
                                playSong(
                                  index,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
