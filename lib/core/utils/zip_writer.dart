import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A minimal, dependency-free ZIP writer.
///
/// The archive uses the STORE method (no re-compression). Compressed images
/// are already near-incompressible, so storing them inside the archive costs
/// no extra size while keeping the writer deterministic and free of third-
/// party archive dependencies. Payloads are streamed so memory stays bounded
/// even for large batches.
final class ZipWriter {
  const ZipWriter._();

  static final Uint32List _crcTable = _buildCrcTable();

  static Uint32List _buildCrcTable() {
    final Uint32List table = Uint32List(256);
    for (int index = 0; index < 256; index++) {
      int value = index;
      for (int bit = 0; bit < 8; bit++) {
        value = (value & 1) != 0 ? 0xEDB88320 ^ (value >> 1) : value >> 1;
      }
      table[index] = value;
    }
    return table;
  }

  /// Writes a STORE-method ZIP archive containing [entries] to [outputPath].
  ///
  /// The parent directory of [outputPath] must already exist. [modified] is
  /// used for every entry's DOS timestamp; it defaults to the current time.
  static Future<void> write({
    required String outputPath,
    required List<ZipEntry> entries,
    DateTime? modified,
  }) async {
    final DateTime stamp = modified ?? DateTime.now();
    final int dosTime = _dosTime(stamp);
    final int dosDate = _dosDate(stamp);
    final List<_CentralEntry> central = <_CentralEntry>[];
    final RandomAccessFile archive = await File(
      outputPath,
    ).open(mode: FileMode.write);
    try {
      for (final ZipEntry entry in entries) {
        final Uint8List name = Uint8List.fromList(utf8.encode(entry.name));
        final int offset = await archive.position();
        await archive.writeFrom(_localHeader(name, dosTime, dosDate));
        final _Payload payload = await _streamAndCrc(entry.sourcePath, archive);
        // Patch the CRC and both sizes into the placeholder local header.
        // Strict readers (e.g. Python's zipfile, Windows Explorer) trust the
        // local header sizes over the central directory, so they must match.
        final ByteData patch = ByteData(12)
          ..setUint32(0, payload.crc, Endian.little)
          ..setUint32(4, payload.size, Endian.little)
          ..setUint32(8, payload.size, Endian.little);
        await archive.setPosition(offset + 14);
        await archive.writeFrom(patch.buffer.asUint8List());
        // Resume writing after this entry's payload.
        await archive.setPosition(offset + 30 + name.length + payload.size);
        central.add(
          _CentralEntry(
            name: name,
            crc: payload.crc,
            size: payload.size,
            offset: offset,
          ),
        );
      }
      final int centralStart = await archive.position();
      for (final _CentralEntry entry in central) {
        await archive.writeFrom(_centralHeader(entry, dosTime, dosDate));
      }
      final int centralSize = (await archive.position()) - centralStart;
      await archive.writeFrom(
        _endOfCentralDirectory(
          entryCount: central.length,
          centralSize: centralSize,
          centralOffset: centralStart,
        ),
      );
    } finally {
      await archive.close();
    }
  }

  /// Copies [sourcePath] into [archive] while computing its CRC-32.
  static Future<_Payload> _streamAndCrc(
    String sourcePath,
    RandomAccessFile archive,
  ) async {
    final RandomAccessFile input = await File(sourcePath).open();
    int crc = 0xFFFFFFFF;
    int size = 0;
    final Uint8List chunk = Uint8List(64 * 1024);
    try {
      while (true) {
        final int read = await input.readInto(chunk);
        if (read <= 0) break;
        for (int index = 0; index < read; index++) {
          crc = _crcTable[(crc ^ chunk[index]) & 0xFF] ^ (crc >> 8);
        }
        await archive.writeFrom(chunk, 0, read);
        size += read;
      }
    } finally {
      await input.close();
    }
    return _Payload(crc: crc ^ 0xFFFFFFFF, size: size);
  }

  static Uint8List _localHeader(Uint8List name, int dosTime, int dosDate) {
    final ByteData data = ByteData(30 + name.length);
    data.setUint32(0, 0x04034B50, Endian.little); // local file header
    data.setUint16(4, 20, Endian.little); // version needed
    data.setUint16(6, 0x0800, Endian.little); // general purpose: UTF-8 names
    data.setUint16(8, 0, Endian.little); // method: STORE
    data.setUint16(10, dosTime, Endian.little);
    data.setUint16(12, dosDate, Endian.little);
    data.setUint32(14, 0, Endian.little); // CRC patched after the payload
    data.setUint32(18, 0, Endian.little); // compressed size (patched)
    data.setUint32(22, 0, Endian.little); // uncompressed size (patched)
    data.setUint16(26, name.length, Endian.little);
    data.setUint16(28, 0, Endian.little); // extra field length
    data.buffer.asUint8List().setRange(30, 30 + name.length, name);
    return data.buffer.asUint8List();
  }

  static Uint8List _centralHeader(
    _CentralEntry entry,
    int dosTime,
    int dosDate,
  ) {
    final ByteData data = ByteData(46 + entry.name.length);
    data.setUint32(0, 0x02014B50, Endian.little); // central directory header
    data.setUint16(4, 0x031E, Endian.little); // version made by (Unix 3.0)
    data.setUint16(6, 20, Endian.little); // version needed
    data.setUint16(8, 0x0800, Endian.little); // UTF-8 names
    data.setUint16(10, 0, Endian.little); // method: STORE
    data.setUint16(12, dosTime, Endian.little);
    data.setUint16(14, dosDate, Endian.little);
    data.setUint32(16, entry.crc, Endian.little);
    data.setUint32(20, entry.size, Endian.little);
    data.setUint32(24, entry.size, Endian.little);
    data.setUint16(28, entry.name.length, Endian.little);
    data.setUint16(30, 0, Endian.little); // extra field length
    data.setUint16(32, 0, Endian.little); // comment length
    data.setUint16(34, 0, Endian.little); // disk number start
    data.setUint16(36, 0, Endian.little); // internal attributes
    data.setUint32(38, 0, Endian.little); // external attributes
    data.setUint32(42, entry.offset, Endian.little); // local header offset
    data.buffer.asUint8List().setRange(46, 46 + entry.name.length, entry.name);
    return data.buffer.asUint8List();
  }

  static Uint8List _endOfCentralDirectory({
    required int entryCount,
    required int centralSize,
    required int centralOffset,
  }) {
    final ByteData data = ByteData(22);
    data.setUint32(0, 0x06054B50, Endian.little); // end of central directory
    data.setUint16(4, 0, Endian.little); // disk number
    data.setUint16(6, 0, Endian.little); // disk with central directory
    data.setUint16(8, entryCount, Endian.little); // entries on this disk
    data.setUint16(10, entryCount, Endian.little); // total entries
    data.setUint32(12, centralSize, Endian.little);
    data.setUint32(16, centralOffset, Endian.little);
    data.setUint16(20, 0, Endian.little); // comment length
    return data.buffer.asUint8List();
  }

  static int _dosTime(DateTime value) =>
      (value.hour << 11) | (value.minute << 5) | (value.second ~/ 2);

  static int _dosDate(DateTime value) {
    final int year = value.year < 1980 ? 1980 : value.year;
    return ((year - 1980) << 9) | (value.month << 5) | value.day;
  }
}

/// One archive entry mapping a source file to its name inside the ZIP.
final class ZipEntry {
  const ZipEntry({required this.sourcePath, required this.name});

  /// Absolute path of the file to archive.
  final String sourcePath;

  /// Name the file receives inside the archive (may include folders).
  final String name;
}

final class _CentralEntry {
  const _CentralEntry({
    required this.name,
    required this.crc,
    required this.size,
    required this.offset,
  });

  final Uint8List name;
  final int crc;
  final int size;
  final int offset;
}

final class _Payload {
  const _Payload({required this.crc, required this.size});

  final int crc;
  final int size;
}
