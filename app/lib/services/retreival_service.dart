import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final WebSocketChannel _channel = WebSocketChannel.connect(
    Uri.parse('ws://0.0.0.0:8000/ws'),
  );

  StreamController<Uint8List> recordingDataController =
      StreamController<Uint8List>();
  bool isWakewordDetected = false;
  Future<void> startStreaming(onTranscriptionReceived) async {
    print('Connected $_channel');
    var recorder = await _recorder.openRecorder();
    recorder!.startRecorder(
      bufferSize: 1024,
      toStream: recordingDataController.sink,
      codec: Codec.pcm16,
    );
    recordingDataController.stream.listen((buffer) {
      _channel.sink.add(buffer);
    }, onError: (error) {
      print('Error: $error');
    });

    print('Listening to server');
    _channel.stream.listen((message) {
      print('Received message from server: $message');
      if (message == "wake word detected") {
        print("Wake word detected!");
        isWakewordDetected = true;
        // Handle wake word detection, e.g., start full recording or other actions
      } else if (isWakewordDetected) {
        print("ASR Transcription: $message");
        onTranscriptionReceived(message);
      } else {
        print("No wake word detected");
      }
    }, onError: (error) {
      print('WebSocket Stream Error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  // void listenToServer() {
  //   print('Listening to server');
  //   _channel.stream.listen((message) {
  //     print('Received message from server: $message');
  //     if (message == "wake word detected") {
  //       print("Wake word detected!");
  //       // Handle wake word detection, e.g., start full recording or other actions
  //     } else {
  //       print("No wake word detected");
  //     }
  //   }, onError: (error) {
  //     print('WebSocket Stream Error: $error');
  //   }, onDone: () {
  //     print('WebSocket connection closed');
  //   });
  // }

  Future<void> stopStreaming() async {
    try {
      await _recorder.stopRecorder();
      await _channel.sink.close();
      print('Streaming stopped and WebSocket closed');
    } catch (e) {
      print('Error stopping streaming: $e');
    }
  }
}
