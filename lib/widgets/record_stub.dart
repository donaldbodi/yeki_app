// lib/widgets/record_stub.dart
// ════════════════════════════════════════════════════════════════
// STUB POUR LE PACKAGE record
// Utilisé quand le package n'est pas disponible (web / tests)
// ════════════════════════════════════════════════════════════════


// Stub pour RecordConfig
class RecordConfig {
  final Duration? silentTimeout;
  final int? bitRate;
  final int? sampleRate;

  const RecordConfig({
    this.silentTimeout,
    this.bitRate,
    this.sampleRate,
  });
}

// Stub pour AudioRecorder
class AudioRecorder {
  Future<bool> hasPermission() async => false;
  Future<void> start(RecordConfig config, {required String path}) async {}
  Future<String?> stop() async => null;
  void dispose() {}
}

// Stub pour la fonction globale
Future<String?> startRecording() async => null;
Future<String?> stopRecording() async => null;
bool get isRecording => false;