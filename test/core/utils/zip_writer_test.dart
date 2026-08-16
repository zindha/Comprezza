import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:comprezza/core/utils/zip_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('zip_writer_test');
  });

  tearDown(() async {
    if (await temp.exists()) {
      await temp.delete(recursive: true);
    }
  });

  test('writes a readable ZIP archive containing every source file', () async {
    final File first = File('${temp.path}/a.txt')
      ..writeAsStringSync('hello compressed world');
    final File second = File('${temp.path}/b.txt')
      ..writeAsStringSync('second file payload');
    final String output = '${temp.path}/out.zip';

    await ZipWriter.write(
      outputPath: output,
      entries: <ZipEntry>[
        ZipEntry(sourcePath: first.path, name: 'a.txt'),
        ZipEntry(sourcePath: second.path, name: 'b.txt'),
      ],
    );

    final _ZipArchive archive = _ZipArchive.read(
      File(output).readAsBytesSync(),
    );
    expect(archive.entries, hasLength(2));
    expect(archive.entries[0].nameString, 'a.txt');
    expect(archive.entries[1].nameString, 'b.txt');
    expect(utf8.decode(archive.entries[0].data), 'hello compressed world');
    expect(utf8.decode(archive.entries[1].data), 'second file payload');
    // The stored CRC matches an independent bitwise implementation.
    for (final _ZipEntry entry in archive.entries) {
      expect(entry.crc, _crc32(entry.data));
    }
  });

  test('supports UTF-8 entry names', () async {
    final File source = File('${temp.path}/holiday.jpg')
      ..writeAsBytesSync(<int>[1, 2, 3, 4]);
    final String output = '${temp.path}/utf8.zip';

    await ZipWriter.write(
      outputPath: output,
      entries: <ZipEntry>[
        ZipEntry(sourcePath: source.path, name: 'नमस्ते_holiday.jpg'),
      ],
    );

    final _ZipArchive archive = _ZipArchive.read(
      File(output).readAsBytesSync(),
    );
    expect(archive.entries.single.nameString, 'नमस्ते_holiday.jpg');
    expect(archive.entries.single.data, <int>[1, 2, 3, 4]);
  });

  test('writes an empty but structurally valid archive', () async {
    final String output = '${temp.path}/empty.zip';
    await ZipWriter.write(outputPath: output, entries: const <ZipEntry>[]);

    final _ZipArchive archive = _ZipArchive.read(
      File(output).readAsBytesSync(),
    );
    expect(archive.entries, isEmpty);
    // The archive still starts with a local-file-header candidate area; the
    // EOCD parser must have found the terminator without any entries.
    expect(archive.centralOffset, greaterThanOrEqualTo(0));
  });

  test('archives identical entry names without clobbering offsets', () async {
    final File one = File('${temp.path}/one.jpg')
      ..writeAsBytesSync(<int>[1, 2, 3]);
    final File two = File('${temp.path}/two.jpg')
      ..writeAsBytesSync(<int>[4, 5, 6, 7, 8]);
    // Two separate source files sharing an entry name are legal ZIP entries.
    final String output = '${temp.path}/dup.zip';

    await ZipWriter.write(
      outputPath: output,
      entries: <ZipEntry>[
        ZipEntry(sourcePath: one.path, name: 'same.jpg'),
        ZipEntry(sourcePath: two.path, name: 'same.jpg'),
      ],
    );

    final _ZipArchive archive = _ZipArchive.read(
      File(output).readAsBytesSync(),
    );
    expect(archive.entries, hasLength(2));
    expect(archive.entries[0].data, <int>[1, 2, 3]);
    expect(archive.entries[1].data, <int>[4, 5, 6, 7, 8]);
  });
}

/// Independent bitwise CRC-32 (IEEE 802.3), deliberately table-free so the
/// writer's table-based implementation is cross-checked.
int _crc32(Uint8List data) {
  int crc = 0xFFFFFFFF;
  for (final int byte in data) {
    crc ^= byte;
    for (int bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

final class _ZipArchive {
  const _ZipArchive({required this.entries, required this.centralOffset});

  final List<_ZipEntry> entries;
  final int centralOffset;

  /// Parses a minimal STORE-method ZIP: EOCD → central directory → entries.
  static _ZipArchive read(Uint8List bytes) {
    final int eocd = _findEndOfCentralDirectory(bytes);
    final ByteData data = ByteData.sublistView(bytes);
    final int totalEntries = data.getUint16(eocd + 10, Endian.little);
    final int centralSize = data.getUint32(eocd + 12, Endian.little);
    final int centralOffset = data.getUint32(eocd + 16, Endian.little);
    if (centralOffset + centralSize > bytes.length) {
      throw StateError('Central directory exceeds the archive.');
    }

    final List<_ZipEntry> entries = <_ZipEntry>[];
    int cursor = centralOffset;
    for (int index = 0; index < totalEntries; index++) {
      if (data.getUint32(cursor, Endian.little) != 0x02014B50) {
        throw StateError('Bad central directory signature.');
      }
      final int crc = data.getUint32(cursor + 16, Endian.little);
      final int size = data.getUint32(cursor + 24, Endian.little);
      final int nameLength = data.getUint16(cursor + 28, Endian.little);
      final int extraLength = data.getUint16(cursor + 30, Endian.little);
      final int commentLength = data.getUint16(cursor + 32, Endian.little);
      final int localOffset = data.getUint32(cursor + 42, Endian.little);
      final Uint8List name = Uint8List.sublistView(
        bytes,
        cursor + 46,
        cursor + 46 + nameLength,
      );
      cursor += 46 + nameLength + extraLength + commentLength;

      if (data.getUint32(localOffset, Endian.little) != 0x04034B50) {
        throw StateError('Bad local file header signature.');
      }
      // Strict readers trust the local header over the central directory, so
      // the writer must patch matching CRC and sizes into both places.
      final int localCrc = data.getUint32(localOffset + 14, Endian.little);
      final int localCompressed = data.getUint32(
        localOffset + 18,
        Endian.little,
      );
      final int localUncompressed = data.getUint32(
        localOffset + 22,
        Endian.little,
      );
      if (localCrc != crc) {
        throw StateError(
          'Local header CRC differs from the central directory.',
        );
      }
      if (localCompressed != size || localUncompressed != size) {
        throw StateError(
          'Local header sizes differ from the central directory.',
        );
      }
      final int localNameLength = data.getUint16(
        localOffset + 26,
        Endian.little,
      );
      final int localExtraLength = data.getUint16(
        localOffset + 28,
        Endian.little,
      );
      final int dataStart =
          localOffset + 30 + localNameLength + localExtraLength;
      final Uint8List payload = Uint8List.sublistView(
        bytes,
        dataStart,
        dataStart + size,
      );
      entries.add(_ZipEntry(name: name, crc: crc, data: payload));
    }
    return _ZipArchive(entries: entries, centralOffset: centralOffset);
  }

  /// Scans backwards from the end for the EOCD signature (0x06054B50).
  static int _findEndOfCentralDirectory(Uint8List bytes) {
    final int minOffset = bytes.length - 22 - 65535;
    for (
      int index = bytes.length - 22;
      index >= (minOffset < 0 ? 0 : minOffset);
      index--
    ) {
      if (bytes[index] == 0x50 &&
          bytes[index + 1] == 0x4B &&
          bytes[index + 2] == 0x05 &&
          bytes[index + 3] == 0x06) {
        return index;
      }
    }
    throw StateError('End of central directory not found.');
  }
}

final class _ZipEntry {
  const _ZipEntry({required this.name, required this.crc, required this.data});

  final Uint8List name;
  final int crc;
  final Uint8List data;

  String get nameString => utf8.decode(name);
}
