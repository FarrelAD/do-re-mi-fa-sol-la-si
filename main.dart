import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 44100;

const notesFrequencies = {
  'Do': 261.63,
  'Re': 293.66,
  'Mi': 329.63,
  'Fa': 349.23,
  'Sol': 392.00,
  'La': 440.00,
  'Si': 493.88,
};

void main() async {
  const durationSeconds = 2;

  for (var entry in notesFrequencies.entries) {
    final noteName = entry.key;
    final frequency = entry.value;

    print('Generating sound for $noteName ($frequency Hz)...');
    final samples = generateSineWave(frequency, durationSeconds);
    final wavData = generateWavData(samples);

    final fileName = '${noteName.replaceAll(' ', '_')}.wav';
    await File('out/$fileName').writeAsBytes(wavData);
    print('Saved $noteName as $fileName');
  }

  print('All notes generated!');
}

Float32List generateSineWave(double frequency, int durationSeconds) {
  final totalSamples = sampleRate * durationSeconds;
  final samples = Float32List(totalSamples);

  for (var i = 0; i < totalSamples; i++) {
    final time = i / sampleRate;
    samples[i] = sin(2 * pi * frequency * time);
  }

  return samples;
}


List<int> generateWavData(Float32List samples) {
  final byteRate = sampleRate * 2;
  final blockAlign = 2;
  final wavHeader = ByteData(44);

  wavHeader.setUint8(0, 'R'.codeUnitAt(0));
  wavHeader.setUint8(1, 'I'.codeUnitAt(0));
  wavHeader.setUint8(2, 'F'.codeUnitAt(0));
  wavHeader.setUint8(3, 'F'.codeUnitAt(0));

  wavHeader.setUint32(4, 36 + samples.lengthInBytes, Endian.little);

  wavHeader.setUint8(8, 'W'.codeUnitAt(0));
  wavHeader.setUint8(9, 'A'.codeUnitAt(0));
  wavHeader.setUint8(10, 'V'.codeUnitAt(0));
  wavHeader.setUint8(11, 'E'.codeUnitAt(0));

  wavHeader.setUint8(12, 'f'.codeUnitAt(0));
  wavHeader.setUint8(13, 'm'.codeUnitAt(0));
  wavHeader.setUint8(14, 't'.codeUnitAt(0));
  wavHeader.setUint8(15, ' '.codeUnitAt(0));

  wavHeader.setUint32(16, 16, Endian.little);
  wavHeader.setUint16(20, 1, Endian.little);
  wavHeader.setUint16(22, 1, Endian.little);
  wavHeader.setUint32(24, sampleRate, Endian.little);
  wavHeader.setUint32(28, byteRate, Endian.little);
  wavHeader.setUint16(32, blockAlign, Endian.little);
  wavHeader.setUint16(34, 16, Endian.little);

  wavHeader.setUint8(36, 'd'.codeUnitAt(0));
  wavHeader.setUint8(37, 'a'.codeUnitAt(0));
  wavHeader.setUint8(38, 't'.codeUnitAt(0));
  wavHeader.setUint8(39, 'a'.codeUnitAt(0));
  wavHeader.setUint32(40, samples.lengthInBytes, Endian.little);

  final wavData = <int>[];
  wavData.addAll(wavHeader.buffer.asUint8List());

  for (final sample in samples) {
    final intSample = (sample * 32767).clamp(-32768, 32767).toInt();
    wavData.addAll(
      Uint8List.sublistView(ByteData(2)..setInt16(0, intSample, Endian.little))
    );
  }

  return wavData;
}
