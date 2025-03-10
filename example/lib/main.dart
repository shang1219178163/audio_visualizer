import 'dart:async';
import 'dart:io';

import 'package:audio_visualizer/utils.dart';
import 'package:audio_visualizer/visualizers/audio_spectrum.dart';
import 'package:audio_visualizer/visualizers/visualizers.dart';
import 'package:flutter/material.dart';
import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'effect_one.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final pcmVisualizer = PCMVisualizer();
  final audioPlayer = VisualizerPlayer();
  final record = AudioRecorder();
  bool isRecording = false;
  StreamSubscription? _micData;

  @override
  void initState() {
    super.initState();
    setup();
  }

  void setup() async {
    pcmVisualizer.reset();
    await audioPlayer.initialize();
  }

  @override
  void dispose() {
    _micData?.cancel();
    pcmVisualizer.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  AudioVisualizer get source {
    return isRecording ? pcmVisualizer : audioPlayer;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Audio Visualizer')),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EffectOne()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.more_horiz),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecording ? Colors.deepOrangeAccent : null,
                  ),
                  onPressed: onMic,
                  child: const Text('Mic'),
                ),
                ElevatedButton(
                  onPressed: () {
                    audioPlayer.setDataSource(
                      "https://files.testfile.org/AUDIO/C/M4A/sample1.m4a",
                    );
                  },
                  child: const Text('HTTP'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final path = await downloadFile(
                      "https://files.testfile.org/anime.mp3",
                    );
                    audioPlayer.setDataSource("file://$path");
                  },
                  child: const Text('File'),
                ),
                ElevatedButton(
                  onPressed: () {
                    audioPlayer.setDataSource(
                      "asset://assets/sample.mp3",
                    );
                  },
                  child: const Text('Asset'),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    audioPlayer.play();
                  },
                  child: const Icon(Icons.play_arrow),
                ),
                ElevatedButton(
                  onPressed: () {
                    audioPlayer.pause();
                  },
                  child: const Icon(Icons.pause),
                ),
                ElevatedButton(
                  onPressed: () {
                    audioPlayer.stop();
                  },
                  child: const Icon(Icons.stop),
                ),
              ],
            ),
            ListenableBuilder(
              listenable: audioPlayer,
              builder: (context, child) {
                final value = audioPlayer.value;
                final positionStr = "${value.position}".split(".").first ?? "";
                final durationStr = "${value.duration}".split(".").first ?? "";

                if (value.duration == value.position) {
                  return const Text(
                    "加载中...",
                    textAlign: TextAlign.center,
                  );
                }
                return Text(
                  "Status: ${value.status} (${positionStr}/${durationStr})",
                  textAlign: TextAlign.center,
                );
              },
            ),
            Expanded(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                shrinkWrap: true,
                children: [
                  const Center(child: Text("Wave")),
                  const Center(child: Text("Frequency")),
                  ListenableBuilder(
                    listenable: source,
                    builder: (context, child) {
                      return BarVisualizer(
                        input: source.value.waveform,
                        color: Colors.greenAccent,
                        backgroundColor: Colors.transparent,
                        gap: 2,
                      );
                    },
                  ),
                  ListenableBuilder(
                    listenable: source,
                    builder: (context, child) {
                      return BarVisualizer(
                        input: getMagnitudes(source.value.fft),
                        color: Colors.greenAccent,
                        backgroundColor: Colors.transparent,
                        gap: 2,
                      );
                    },
                  ),
                  ListenableBuilder(
                    listenable: source,
                    builder: (context, child) {
                      return CircularBarVisualizer(
                        color: Colors.greenAccent,
                        input: source.value.waveform,
                        backgroundColor: Colors.transparent,
                        gap: 2,
                      );
                    },
                  ),
                  // ListenableBuilder(
                  //   listenable: source,
                  //   builder: (context, child) {
                  //     return CircularBarVisualizer(
                  //       color: Colors.yellowAccent,
                  //       input: getMagnitudes(source.value.fft).take(128).toList(),
                  //       backgroundColor: Colors.transparent,
                  //       gap: 2,
                  //     );
                  //   },
                  // ),
                  // ListenableBuilder(
                  //   listenable: source,
                  //   builder: (context, child) {
                  //     return MultiWaveVisualizer(
                  //       color: Colors.blueAccent,
                  //       input: source.value.waveform,
                  //       backgroundColor: Colors.black,
                  //     );
                  //   },
                  // ),
                  // ListenableBuilder(
                  //   listenable: source,
                  //   builder: (context, child) {
                  //     return MultiWaveVisualizer(
                  //       color: Colors.yellowAccent,
                  //       input: getMagnitudes(source.value.fft),
                  //       backgroundColor: Colors.black,
                  //     );
                  //   },
                  // ),
                  ListenableBuilder(
                    listenable: source,
                    builder: (context, child) {
                      return LineBarVisualizer(
                        color: Colors.blueAccent,
                        input: source.value.waveform,
                        backgroundColor: Colors.transparent,
                      );
                    },
                  ),
                  // ListenableBuilder(
                  //   listenable: source,
                  //   builder: (context, child) {
                  //     return LineBarVisualizer(
                  //       color: Colors.yellowAccent,
                  //       input: getMagnitudes(source.value.fft).take(128).toList(),
                  //       backgroundColor: Colors.black,
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onMic() async {
    if (await record.isRecording()) {
      _micData?.cancel();
      record.stop();
      setState(() {
        isRecording = false;
      });
      return;
    }
    final stream = await record.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
        sampleRate: 44100,
        numChannels: 1,
      ),
    );
    _micData = stream.listen((data) {
      pcmVisualizer.feed(data);
    });
    setState(() {
      isRecording = true;
    });
  }
}

Future<String> downloadFile(String url, {String? filename}) async {
  // Make HTTP request with streaming
  final response = await http.Client().send(http.Request('GET', Uri.parse(url)));

  if (response.statusCode != 200) {
    throw Exception('Failed to download file: ${response.statusCode}');
  }
  final directory = await getTemporaryDirectory();

  filename ??= url.split("/").last;
  final filePath = '${directory.path}/$filename';
  final file = File(filePath);

  // Create file and write chunks
  final sink = file.openWrite();
  await response.stream.forEach((chunk) {
    sink.add(chunk);
  });

  await sink.close();
  return filePath;
}
