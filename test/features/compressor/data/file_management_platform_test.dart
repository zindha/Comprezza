import 'dart:io';
import 'dart:typed_data';

import 'package:comprezza/core/errors/app_error.dart';
import 'package:comprezza/core/errors/error_code.dart';
import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/core/services/file_system_service.dart';
import 'package:comprezza/features/compressor/data/services/file_management/models/file_management_models.dart';
import 'package:comprezza/features/compressor/data/services/file_management/naming/file_naming_strategy.dart';
import 'package:comprezza/features/compressor/data/services/file_management/pickers/folder_picker_service.dart';
import 'package:comprezza/features/compressor/data/services/file_management/utilities/file_utilities.dart';
import 'package:comprezza/features/compressor/data/services/file_management/validators/file_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('utilities calculate a streaming SHA-256 checksum', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'comprezza_file_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final File file = File('${root.path}/photo.jpg')..writeAsStringSync('abc');
    final LocalFileUtilities utilities = LocalFileUtilities(
      fileSystem: _FakeFileSystem(),
    );

    final Result<String> result = await utilities.checksum(file.path);

    expect(result, isA<Success<String>>());
    expect(
      (result as Success<String>).value,
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('validator rejects zero-byte and unsupported files', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'comprezza_file_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final File empty = File('${root.path}/empty.jpg')..createSync();
    final File unsupported = File('${root.path}/note.txt')
      ..writeAsStringSync('x');
    final LocalFileValidator validator = LocalFileValidator(
      utilities: LocalFileUtilities(fileSystem: _FakeFileSystem()),
    );

    final Result<ManagedFile> emptyResult = await validator.validate(
      empty.path,
    );
    final Result<ManagedFile> unsupportedResult = await validator.validate(
      unsupported.path,
    );

    expect(
      (emptyResult as Failure<ManagedFile>).error.code,
      ErrorCode.invalidArgument,
    );
    expect(
      (unsupportedResult as Failure<ManagedFile>).error.code,
      ErrorCode.unsupportedPlatform,
    );
  });

  test('validator skips duplicate content in a batch', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'comprezza_file_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    const List<int> tinyPng = <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x44,
      0x41,
      0x54,
      0x08,
      0xD7,
      0x63,
      0xF8,
      0xCF,
      0xC0,
      0xF0,
      0x1F,
      0x00,
      0x05,
      0x00,
      0x01,
      0xFF,
      0x89,
      0x99,
      0x3D,
      0x1D,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ];
    final File first = File('${root.path}/one.png')..writeAsBytesSync(tinyPng);
    final File second = File('${root.path}/two.png')..writeAsBytesSync(tinyPng);
    final LocalFileValidator validator = LocalFileValidator(
      utilities: LocalFileUtilities(fileSystem: _FakeFileSystem()),
    );

    final Result<FileOperationSummary> result = await validator.validateMany(
      <String>[first.path, second.path],
    );

    expect(result, isA<Success<FileOperationSummary>>());
    final FileOperationSummary summary =
        (result as Success<FileOperationSummary>).value;
    expect(summary.accepted, hasLength(1));
    expect(summary.rejected, hasLength(1));
  });

  test('naming strategy sanitizes names and versions collisions', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'comprezza_file_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    const IntelligentFileNamingStrategy naming =
        IntelligentFileNamingStrategy();
    const FileNameRequest request = FileNameRequest(
      originalName: 'Vacation 2026!.jpg',
      suffix: 'Compressed',
      extension: 'webp',
    );
    final String name = naming.create(request);
    File('${root.path}/$name').writeAsStringSync('existing');

    final Result<File> result = await naming.collisionSafePath(root, request);

    expect(name, 'Vacation_2026_Compressed.webp');
    switch (result) {
      case Success<File>(value: final File file):
        expect(file.path, endsWith('_v2.webp'));
      case Failure<File>():
        fail('Expected a collision-safe output path.');
    }
  });

  test('folder scanner filters hidden and unsupported entries', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'comprezza_folder_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    File('${root.path}/photo.jpg').writeAsStringSync('x');
    File('${root.path}/note.txt').writeAsStringSync('x');
    File('${root.path}/.hidden.png').writeAsStringSync('x');
    final LocalFolderPickerService scanner = const LocalFolderPickerService();

    final Result<List<String>> result = await scanner.scan(root.path);

    expect(result, isA<Success<List<String>>>());
    switch (result) {
      case Success<List<String>>(value: final List<String> paths):
        expect(paths, hasLength(1));
        expect(paths.single, endsWith('photo.jpg'));
      case Failure<List<String>>():
        fail('Expected supported files from the selected folder.');
    }
  });
}

final class _FakeFileSystem implements FileSystemService {
  @override
  Future<Result<AppDirectories>> directories() async =>
      const Result<AppDirectories>.failure(
        AppError(code: ErrorCode.unavailable, message: 'unused'),
      );

  @override
  Future<List<File>> listFiles(
    Directory directory, {
    bool recursive = true,
  }) async => <File>[];

  @override
  Future<FileMetadata> stat(File file) async => FileMetadata(
    size: await file.length(),
    modified: await file.lastModified(),
  );

  @override
  Future<Result<Uint8List>> readBytes(File file) async =>
      Result<Uint8List>.success(await file.readAsBytes());

  @override
  Future<Result<File>> writeBytes(File file, Uint8List bytes) async =>
      Result<File>.success(await file.writeAsBytes(bytes));

  @override
  Future<Result<String>> readText(File file) async =>
      Result<String>.success(await file.readAsString());

  @override
  Future<Result<File>> copy(File source, File destination) async =>
      Result<File>.success(await source.copy(destination.path));

  @override
  Future<Result<File>> copyFromExternal(File source, File destination) async =>
      Result<File>.success(destination);

  @override
  Future<Result<File>> writeTextAtomic(File file, String contents) async =>
      Result<File>.success(file);

  @override
  Future<Result<File>> move(File source, File destination) async =>
      Result<File>.success(await source.rename(destination.path));

  @override
  Future<Result<Directory>> ensureChildDirectory(
    Directory parent,
    String name,
  ) async => Result<Directory>.success(Directory('${parent.path}/$name'));

  @override
  Future<Result<void>> safeDelete(
    FileSystemEntity entity, {
    bool recursive = false,
  }) async => const Result<void>.success(null);
}
